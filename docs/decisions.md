# Decisions

Why NutriAI is built the way it is. Each entry records the choice, the
alternatives, and what it costs — including the ones that turned out to be
wrong and were changed.

---

## 1. Flutter and FastAPI rather than Django

**Decided:** at the start.

The previous version of this project was Django, which bundles an ORM,
templates, an admin site and a full user system. Rebuilding on FastAPI meant
writing authentication by hand instead of importing it.

That was the point. Django's user system is excellent and invisible — using
it teaches nothing about how sessions, hashing or authorisation actually
work. Writing it produced the decisions in sections 3, 4 and 5, none of
which would exist otherwise.

FastAPI also generates its own interactive documentation from type hints,
which was the only usable interface to this project for its first two weeks.

**Cost:** roughly two days of work Django would have given free.

---

## 2. Riverpod over Provider

**Decided:** before any UI existed.

Provider passes state down the widget tree. When the chat screen needs
profile data that onboarding wrote, Provider means threading it through
every widget in between. Riverpod lets any screen read any provider
directly, and gives loading, error and data states as one type — needed on
every AI call, every profile fetch, every weight query.

Chosen without code generation. The generated variant is more concise but
adds a build step, and this codebase is meant to be readable by someone
learning Flutter.

**Cost:** a steeper initial concept than Provider. Paid back by the third
screen.

---

## 3. bcrypt directly, not passlib

**Decided:** after passlib crashed on first use.

Every tutorial uses `passlib[bcrypt]`. It fails immediately against current
bcrypt releases:

```
AttributeError: module 'bcrypt' has no attribute '__about__'
```

passlib probes the bcrypt version at import, reading an attribute removed in
bcrypt 4.1. passlib's last release was 2020 and the fix has never shipped.

The common workaround is pinning `bcrypt<4.1` — keeping a current library
old so an abandoned one stays happy. Using `bcrypt` directly removes the
dependency entirely. The wrapper was doing nothing the standard library and
twenty lines could not.

**Cost:** the 72-byte truncation passlib handled silently is now explicit in
`security.py`. Arguably clearer for being visible.

---

## 4. Passwords are unreadable, including by administrators

**Decided:** when multi-user was specified, and defended when questioned.

The original request included administrators who could see usernames and
passwords. The second half is not something to implement carefully — it is
something not to implement.

Passwords are bcrypt hashes. The database holds `$2b$12$K8f3...`, and no
amount of access reverses it. Changing a password works by hashing the
attempt and comparing hashes, never by reading the stored one.

This is not caution. People reuse passwords across their bank and their
email, so a readable password store turns one breach into several.

Administrators can list accounts, disable them, trigger a password reset,
and delete them. A reset generates a new temporary password and shows it
once — a password the administrator just created, not the user's.

**Cost:** a forgotten password needs an administrator or an email service.
Email was dropped (section 12), so it needs an administrator.

---

## 5. One `users` table with a role column

**Decided:** after considering separate user and admin tables.

Two tables would mean two login endpoints, two token shapes, two auth
paths, and two places to get authorisation wrong. One table with
`role: 'user' | 'admin'` means one login screen and one dependency chain.

Role is read from the database on every request, never trusted from the
token, so revoking admin takes effect immediately rather than when the
token expires.

Admin accounts are created only by `scripts/create_admin.py`, gated behind
`ADMIN_CREATION_SECRET`. There is deliberately no API endpoint — the
registration route hardcodes `role='user'`, so no crafted payload can
produce an administrator.

---

## 6. Two kinds of disabled account

**Decided:** while designing account deletion.

`is_active: false` was originally going to serve both "the user paused
their account" and "an administrator disabled this account". Those
conflict: if signing in restores a paused account, and a ban uses the same
flag, then a banned user unbans themselves by signing in.

So there are two fields. `deactivated_at` is the user's own pause, cleared
when they sign in and confirm. `is_active` is administrative, and login
refuses regardless.

Reactivation is offered rather than automatic. Login returns **423 Locked**
with a shape the app recognises, and the user is asked whether to restore —
someone who deactivated deliberately and then signed in from habit should
not undo it by accident.

---

## 7. Groq rather than local Ollama

**Decided:** after the local-first plan met the hardware.

The original brief specified local-first AI with no cloud dependency. The
realistic local options on the target hardware were small quantised models,
and a model that invents calorie counts is worse than no AI in an app whose
job is telling someone what is in their dinner.

Groq serves larger models with a 128k context at around 500 tokens per
second. A diet plan finishes in two seconds rather than forty, which is the
difference between a feature and a demo.

**The honest cost:** health data leaves the machine. The README says
"local-first architecture with an optional cloud provider", never "your data
never leaves your device". An overclaim an interviewer spots undermines
everything else on the page.

The `AIProvider` interface exists so `OllamaProvider` is a new file rather
than a rewrite. A base class with one implementation is a code smell; this
one has a second implementation planned(or will be undecidedly droped) and the seams already cut for it.

---


## 8. The model lives in `.env`

**Decided:** after `llama-3.3-70b-versatile` stopped existing mid-build.

Groq retires models without notice. A model that worked on a Tuesday
returned `model_not_found` on a Wednesday. `scripts/list_models.py` prints
what an account can currently use.

`GROQ_MODEL` is configuration, not code. Currently `openai/gpt-oss-20b`.

---

## 9. Context is selected, not dumped

**Decided:** when the coach started giving generic advice.

The naive implementation sends the whole profile with every message.
`ai/context/user_context.py` chooses fields by relevance instead: a calorie
question pulls in age, sex, weight, BMI and the target; asking whether rice
is healthy does not. Allergies and dietary restrictions are always
included, because they are never irrelevant to a food suggestion.

Measured: 529 prompt tokens for "Is rice healthy?" against 587 for a calorie
question. The gap widens with a fuller profile, and over thousands of
requests it is the difference between hitting a rate limit and not.

---

## 10. Safety is code, not only prompt

**Decided:** when writing the system prompt, and reinforced after watching
the model volunteer advice to eat less.

A prompt is a request. A model can be argued out of one, and a sufficiently
sympathetic conversation will do it without anyone intending to.

So three things are enforced in code:

- **Urgent medical phrases** short-circuit in `ai/service.py` before the
  model is called at all, returning a fixed response directing the person
  to urgent care. No round trip, no chance of a fluent wrong answer.
- **Distress phrases** attach an instruction that suppresses calorie
  figures for that turn.
- **The 1200 kcal floor** is applied in `health_calc.py`, so no goal, no
  activity level and no combination of the two produces a lower target.

The prompt carries the rest, including a rule added after observing the
model suggest tightening a deficit in response to slow progress — harmless
from 1800 kcal, dangerous near the floor.

---

## 11. Diet plans are JSON, not prose

**Decided:** before writing the generation prompt.

Prose would have been trivial: ask for a day of meals, display the reply.
But then nothing can be counted, validated or exported — it is a chat
message on a different screen.

Structured output means each meal is a record with calories and macros, so
the total can be checked against the target, a plan below the calorie floor
can be rejected before it is shown, and the PDF has something to lay out.

**Cost:** models return malformed JSON, wrap output in markdown fences, and
add commentary the prompt forbade. `diet_plan_service.py` absorbs all of
that and distinguishes a truncated reply from a malformed one, because the
advice differs.

Also learned: `max_tokens` too low truncates the JSON mid-object, which
looks like intermittent failure rather than a limit. Raised from 1600 to
2500 after roughly half of generations failed.

---

## 12. PDF download, no email

**Decided:** after the previous project's SMTP work went badly.

Email needs a mail service, credentials in `.env`, and a queue so sending
does not block the request. It also means health data sitting unencrypted in
an inbox indefinitely, which would need the privacy section rewritten.

Download covers what people actually want, has no external dependency, and
works offline. `reportlab` generates the PDF server-side in the app's own
palette, so an exported plan looks like it came from NutriAI rather than
from a report generator.

---

## 13. SQLite foreign keys must be switched on

**Decided:** after discovering an orphaned profile.

`ondelete="CASCADE"` is a database-level rule, and **SQLite ignores foreign
keys entirely unless enabled per connection**. Deleting a user left its
profile behind, silently.

`db/session.py` now issues `PRAGMA foreign_keys=ON` on every connection via
a SQLAlchemy event listener.

Worth recording because it works fine in development either way — the
damage is invisible until something counts the rows.

---

## 14. Weight is stored on the profile, edited only in Health

**Decided:** when adding weight tracking.

`weight_entries` holds the dated history. `profile.weight_kg` holds the most
recent value, updated on every write.

That is denormalised on purpose. BMI, BMR and the calorie target all need
the current weight, and every screen reads it — a subquery on each of those
reads would be worse than one cached column kept in sync in one place.

But the interface does not mirror the storage. Weight is editable only from
Health, because it is a measurement that changes weekly, not an attribute
of a person. Profile holds account settings. Storage shape and interface
shape are allowed to differ.

---

## 15. `init_db()` instead of migrations

**Decided:** at the start, and increasingly regretted.

`Base.metadata.create_all()` creates missing tables at startup. It does not
alter existing ones — so adding `deactivated_at` to the user model required
a hand-written `ALTER TABLE` against the live database.

That is acceptable for one developer with a database they can delete. It
stops being acceptable the moment a second person has to reproduce the
schema, or real data exists that cannot be recreated.

**Alembic is owed.** This entry exists so that is a recorded decision rather
than an oversight.

---

## 16. Bento layout on Health only

**Decided:** as an experiment, and kept.

The rest of the app uses hairline rules, near-square corners and no
shadows — a deliberate reaction against the card-grid look that section 50
of the brief rules out.

Health broke that: twelve rounded, raised tiles in a quilted grid where
columns derive from available width and row height from available height.

It was tried because the ruled-list version read as a settings page rather
than a health screen. It was kept because it works. Whether the other five
screens follow is unresolved — an inconsistency, and recorded as one rather
than left to look accidental.

The palette and typography did not change. Only the surfaces did.

---

## 17. Bundled fonts

**Decided:** at the start for speed, revisited once the app was working.

`google_fonts` fetches Archivo, IBM Plex Mono, League Spartan and Sacramento
at runtime. That is four serial requests to Google's servers before text
renders in the right face, and it made the app unusable offline.

The four families are now bundled as `.ttf` assets, with only the weights
the theme actually asks for — eight files, around 850 KB. `google_fonts` and
its 28 transitive packages are gone.

**What it did not do:** the JavaScript bundle stayed at 2.9 MB. The
expectation was that removing 28 packages would shrink it, and that was
wrong — most of those were `path_provider` platform implementations that
tree-shaking had already dropped from the web build. Recorded because the
prediction was worth checking rather than assuming.

**What it did do:** removed four blocking network requests from every load,
and made the app work with no internet connection at all.

## 18. Token in a query string, for one endpoint

**Decided:** when the PDF download returned 401.

A browser download is a plain navigation and cannot carry an `Authorization`
header. So `/diet-plans/{id}/pdf` accepts the token as a query parameter
through a dedicated dependency, `current_user_from_query`.

The token is still verified and ownership is still checked. The tradeoff is
that it appears in browser history and server logs, which is why it is used
on exactly one endpoint and nowhere else.

---

## 19. Ports and processes

Not architecture, but it cost hours.

- `--web-hostname 0.0.0.0` breaks Flutter's debug websocket and produces a
  blank white page with no useful error.
- Port 8080 is held on this machine by Windows SearchHost. The frontend
  runs on 5173.
- `uvicorn --reload` leaves an orphaned process holding port 8000 if it is
  not quit with `Ctrl+C`. The socket survives the process and nothing can
  bind until it clears.

---

## 20. What is not built, and why

**Multi-day plan generation.** The coach handles "how should my week look"
well enough — three days in detail plus a line on rotating the rest — that
seven sequential generation calls would solve a problem already half solved.
Deferred until the need is confirmed rather than assumed.

**Prescription reading.** Agreed approach: `pytesseract` and `Pillow`
locally, so the image never leaves the device, with a mandatory review
screen because OCR misreads drug names and a confidently wrong extraction is
worse than none. Only *conditions* would be kept and used — reasoning about
medication is outside what this application should do, however accurate the
extraction. The initial plan was to use pytesseract to extract the texts and
then using API to provide health analysis and do description which was later 
dropped out as a decision while building.  

**Onboarding prefill.** Not built, and now unnecessary. Onboarding is a
first-run flow: a new account is sent there from the login screen, and
every field it collects is editable afterwards from Health with a single
tap. Prefilling would only matter if onboarding were the editing route,
and it is not.

**Tests.** The honest gap. `health_calc.py` is pure functions with no
dependencies and should have had tests from the first day.