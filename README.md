# NutriAI

**Eat well, on your terms — your food, your goals, your data.**

A cross-platform nutrition and health application with an AI coach. Users
track their health metrics, receive a personalised calorie target, have a
day of meals built around it, and talk to an assistant that already knows
their profile.

Built with Flutter and FastAPI, currently targeting the web.

> **Status: feature complete.** Accounts, health profiles, BMI and calorie
> calculations, the AI coach, diet planning with PDF export, weight tracking,
> the administration panel, and on-device prescription reading all work end
> to end. What remains is a test suite and desktop and mobile builds.

---

## Why this project

Most nutrition apps either give generic advice or ask for your health data
without explaining where it goes. NutriAI is an attempt at something more
careful: guidance built on a profile you control, with the data handling
stated plainly rather than buried.

It is also a portfolio project, built to demonstrate cross-platform UI work,
clean API design, authentication done properly, and AI integration with a
real safety layer rather than a thin wrapper around a chat endpoint.

---

## Architecture

```
┌──────────────────────┐
│     NutriAI UI       │
│   Flutter / Dart     │
└──────────┬───────────┘
           │ REST
           ▼
┌──────────────────────┐
│      FastAPI         │
│      Python          │
└───┬──────┬───────┬───┘
    │      │       │
    ▼      ▼       ▼
┌────────┐ ┌──────────────┐ ┌────────────┐
│ SQLite │ │  AI Service  │ │  Tesseract │
└────────┘ └──────┬───────┘ │   (local)  │
                  ▼         └────────────┘
           ┌────────────┐
           │  Groq API  │
           └────────────┘
```

One Flutter codebase targets web, Windows, macOS, Linux, Android and iOS.
Web is the current build target.

### Stack

| Layer | Choice | Reasoning |
|---|---|---|
| Frontend | Flutter / Dart | One codebase across web, desktop and mobile |
| State | Riverpod | Shared state with loading and error states built in |
| Routing | go_router | Real URLs on web, working back button, route guards |
| Backend | FastAPI | Async Python, generated API docs, validation at the boundary |
| ORM | SQLAlchemy 2.0 | Typed models, portable to PostgreSQL without rewriting |
| Migrations | Alembic | Schema changes versioned and reversible, not hand-written |
| Database | SQLite | Zero configuration; one connection string from Postgres |
| Auth | bcrypt + JWT | Passwords unreadable by anyone, including administrators |
| AI | Groq | Fast inference behind a swappable provider interface |
| OCR | Tesseract | Runs locally, so prescription images never leave the machine |
| PDF | ReportLab | Server-side generation in the application's own palette |

---

## The AI layer

The part worth reading the code for.

**A provider interface, not a hardcoded client.** `AIProvider` defines the
contract; `GroqProvider` implements it. Nothing above that boundary knows
which model is running, so adding local inference through Ollama means
writing one new class and changing one line in `.env`.

**Context is selected, not dumped.** A naive implementation sends the whole
profile with every message. NutriAI's context builder chooses fields by
relevance: ask about calories and it includes age, sex, weight, BMI and the
target; ask whether rice is healthy and it does not. Allergies, dietary
restrictions and diagnosed conditions are always included, because they are
never irrelevant to a food suggestion. Measured difference between those two
questions: 529 versus 587 prompt tokens.

**Safety lives in code, not only in the prompt.** A prompt can be argued
with. Messages suggesting a medical emergency short-circuit before the model
is called at all and return a fixed response directing the person to urgent
care. Messages suggesting disordered eating attach an instruction that
suppresses calorie figures for that turn. Calorie targets are floored at
1,200 kcal in the calculation itself, regardless of stated goal, and any
generated plan falling below that floor is rejected before it reaches the
screen.

**Structured output is validated, not trusted.** Diet plans come back as
JSON, which models wrap in markdown fences, prefix with commentary, and
occasionally truncate mid-object. The parsing layer absorbs all of that and
distinguishes a truncated response from a malformed one, because the advice
differs. The plan's total is then checked against the target within a
250 kcal tolerance before it is stored.

**Conversations persist**, with the last ten messages supplied as context so
follow-up questions like "what about something lighter?" resolve correctly.

---

## Features

### Front page

- **A landing page** at `/` explaining what the application does before
  asking for an email
- **An animated hero** — a field of drifting points that connect to their
  neighbours and part around the pointer, drawn directly rather than pulled
  from a package
- **The privacy claims are on it**, not buried behind a policy link

### Accounts and access

- **Registration and login**, with sessions that survive a refresh
- **bcrypt hashing**, so stored passwords cannot be read back by anyone,
  including database administrators
- **Role-based access** — users and admins share one login; role is read from
  the database on every request, so revoking it takes effect immediately
- **Admin creation** is terminal-only, gated behind a company secret, with no
  API endpoint that could be abused
- **Two kinds of disabled account** — a user's own pause, cleared by signing
  back in and confirming, and an administrative disable that cannot be
- **Account deletion** removes everything, cascading through profiles,
  conversations, plans and weight entries

### Health

- **Onboarding** — a four-step flow that saves as it goes, so a closed tab
  loses nothing, with both metric and imperial height entry
- **Health profile** — age, sex, height, weight, activity level, goal,
  dietary preferences, allergies, conditions
- **BMI** calculated and categorised against WHO adult bands, presented as
  one signal with its limitations stated rather than as a verdict
- **Calorie targets** from Mifflin-St Jeor BMR with activity multipliers and
  a goal adjustment, floored so the app cannot recommend unsafe restriction
- **Everything editable in place** — every value on the Health screen opens
  its own editor on a tap

### Planning and tracking

- **Personalised diet plans** built around the calorie target, the goal, and
  the restrictions, with an optional note to steer a particular day
- **PDF export**, generated server-side in the application's own palette
- **Weight history** with a chart drawn directly rather than through a
  charting library, so it matches the rest of the interface
- **Trend figures** — change since the first entry, change over the last
  week, and distance to target

### Coach

- **Conversations with history**, a sidebar of past chats, and deletion
- **Opening questions** chosen from the user's own profile
- **Markdown rendering** for structured answers

### Prescription reading

- **On-device OCR** — Tesseract runs locally, so the image never leaves the
  machine and is processed in memory rather than written to disk
- **A mandatory review step**, because OCR misreads drug names and a
  confidently wrong extraction is worse than none
- **Conditions only** — the user confirms what the document mentions and only
  that is stored. Medication is read and discarded, and the coach will not
  advise on it

### Administration

- A **separate panel** with its own visual language — black, white, and
  monospace throughout, because it is a data tool rather than an app screen
- **Account listing** with activity counts, never contents
- **Enable, disable, reset password, delete.** A reset issues a temporary
  password shown once — one the administrator has just created, never the
  user's own

### Interface

- **Adaptive layout** — labelled rail, icon rail, or bottom bar by width
- **Light and dark themes**, both designed deliberately rather than inverted,
  with a manual override that persists across restarts
- **Bundled fonts**, so the application works with no network connection
- **Data isolation** — every query scoped to the authenticated user; the user
  id comes from the token, never from a request parameter

### Planned

Food database covering South Asian and Bengali foods · Offline local AI via
Ollama · Windows, Android and iOS builds · A test suite

---

## Design

The interface takes its direction from editorial print rather than dashboard
software. Warm paper and ink, a single gold-to-orange accent family, and
structure carried by hairline rules instead of stacked cards.

**Palette** — Paper `#F2EFE6` · Linen `#E7E1D2` · Ink `#1C1A15` ·
Turmeric `#C8912F` · Ember `#B8501F`, with a separately tuned dark theme.

**Type** — Archivo for structure, IBM Plex Mono for numerals so weights and
calorie counts align in columns and do not jitter as digits change. League
Spartan appears once, on the authentication tagline; Sacramento appears once,
on the dashboard greeting. All four are bundled rather than fetched.

**Shape** — near-square corners throughout, with one signature move: primary
buttons have two opposite corners cut flat, like a stamped label.

**The landing hero is drawn, not photographed.** A particle field in
`CustomPaint`, pointer-reactive, in the same two accent colours as
everything else. No stock imagery anywhere in the application.

**One deliberate exception.** The Health screen is a bento grid of raised,
rounded tiles, sized against the viewport so it fills the pane on a desktop
and reflows to a single column on a phone. It breaks the rules the rest of
the application follows, and was kept because it works better there than a
ruled list did.

Accent colours come in two variants, one for fills and one for text, because
the gold that works as a chart line fails WCAG contrast as a word.

---

## Getting started

### Requirements

- Flutter 3.27+ with Chrome
- Python 3.11
- A Groq API key — free at [console.groq.com](https://console.groq.com)
- [Tesseract OCR](https://github.com/UB-Mannheim/tesseract/wiki), optional —
  only needed for prescription reading

### Setup

```bash
git clone https://github.com/Drag375o/NutriAI.git
cd NutriAI
cp .env.example .env
```

Fill in `.env`:

```
SECRET_KEY=<python -c "import secrets; print(secrets.token_urlsafe(48))">
GROQ_API_KEY=<your key>
GROQ_MODEL=openai/gpt-oss-20b
ADMIN_CREATION_SECRET=<a secret of your choosing>

# Only needed for prescription reading. On macOS and Linux the binary is
# usually on PATH and this can be left blank.
TESSERACT_PATH=C:\Program Files\Tesseract-OCR\tesseract.exe
```

Groq retires models periodically. `python scripts/list_models.py` prints what
your key can currently use.

**Backend**

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

alembic upgrade head
uvicorn app.main:app
```

Runs at `http://localhost:8000`. Interactive API documentation, generated
from the code, is at `/docs`.

**Frontend**

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080
```

**Creating an administrator**

```bash
python scripts/create_admin.py
```

Prompts for the company secret from `.env`, then the account details. This is
the only way an admin account can be created — there is no API endpoint for
it, by design.

**Changing the schema**

```bash
alembic revision --autogenerate -m "what changed"
alembic upgrade head
```

Read the generated migration before applying it: autogenerate treats a rename
as a drop plus an add.

---

## Project structure

```
NutriAI/
├── backend/
│   ├── alembic/          migrations, versioned and committed
│   └── app/
│       ├── api/          routes and shared dependencies
│       ├── core/         configuration and security
│       ├── db/           engine, session, base
│       ├── models/       SQLAlchemy tables
│       ├── schemas/      Pydantic request and response shapes
│       ├── services/     health calculations, plans, PDF, OCR
│       ├── repositories/ all database access
│       └── ai/           providers, prompts, context, safety
├── frontend/
│   ├── assets/
│   │   ├── fonts/        bundled typefaces
│   │   └── images/
│   └── lib/
│       ├── app/          theme, router, root widget
│       ├── core/         networking, shared widgets, constants
│       └── features/     one folder per feature
├── scripts/
└── docs/
    └── decisions.md      why the project is built the way it is
```

Business logic stays out of route handlers, and database access stays in
repositories, so swapping SQLite for PostgreSQL touches one layer.

---

## API

All endpoints under `/api/v1`.

### Accounts

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | — | Service status and configuration |
| `POST` | `/auth/register` | — | Create an account, always as a user |
| `POST` | `/auth/login` | — | Sign in; 423 if the account is paused |
| `POST` | `/auth/reactivate` | — | Restore a paused account and sign in |
| `GET` | `/auth/me` | Bearer | Current account |
| `PATCH` | `/auth/me` | Bearer | Change name or email |
| `POST` | `/auth/change-password` | Bearer | Requires the current password |
| `POST` | `/auth/deactivate` | Bearer | Pause the account |
| `POST` | `/auth/delete` | Bearer | Permanent; requires the password |

### Health and planning

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/profile` | Bearer | Profile with BMI and calorie target |
| `PATCH` | `/profile` | Bearer | Partial update |
| `GET` | `/chat/status` | Bearer | Whether the AI is reachable |
| `GET` | `/chat/suggestions` | Bearer | Opening questions from the profile |
| `POST` | `/chat` | Bearer | Send a message |
| `GET` | `/conversations` | Bearer | List conversations |
| `GET` | `/conversations/{id}` | Bearer | One conversation with messages |
| `DELETE` | `/conversations/{id}` | Bearer | Delete a conversation |
| `POST` | `/diet-plans` | Bearer | Generate a plan for today |
| `GET` | `/diet-plans/today` | Bearer | Today's plan, if there is one |
| `GET` | `/diet-plans/{id}/pdf` | Query | Download as PDF |
| `GET` | `/weights` | Bearer | History with a trend summary |
| `POST` | `/weights` | Bearer | Record a weigh-in |
| `DELETE` | `/weights/{id}` | Bearer | Remove an entry |

### Prescription reading

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/ocr/status` | Bearer | Whether extraction is set up |
| `POST` | `/ocr/extract` | Bearer | Read an image; stores nothing |
| `PATCH` | `/ocr/conditions` | Bearer | Save what the user confirmed |

### Administration

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/admin/stats` | Admin | Counts across all accounts |
| `GET` | `/admin/users` | Admin | Accounts with activity counts |
| `PATCH` | `/admin/users/{id}` | Admin | Enable or disable |
| `POST` | `/admin/users/{id}/reset-password` | Admin | Issue a temporary password |
| `DELETE` | `/admin/users/{id}` | Admin | Delete an account |

The PDF endpoint takes its token from the query string rather than a header,
because a browser download is a plain navigation and cannot carry one. It is
the only endpoint that does.

---

## Privacy and data handling

Stated plainly, because health data deserves it.

**What is stored** — your email, name, the health details you enter, your
conversations, plans and weight history, in a SQLite database on whatever
machine runs the backend. Passwords are stored as bcrypt hashes, which cannot
be reversed. No administrator can read your password.

**What leaves the machine** — the AI coach and the plan generator use Groq's
API, so the profile details relevant to a request are sent to Groq when you
use them. Not your name, not your email, and nothing at all until you use an
AI feature.

**Prescription images never leave the machine.** Tesseract runs locally, the
image is held in memory and discarded, and only the conditions you review and
confirm are saved. Medication is read and thrown away.

**What this project does not claim** — it is not local-first in the strict
sense while a cloud provider is in use. An `OllamaProvider` for fully local
inference is planned, and the provider interface exists so it can be added
without changes elsewhere. Until then, the accurate description is
"local-first architecture with an optional cloud provider".

**Deleting your account deletes everything**, cascading through profile,
conversations, plans and weight entries.

There is no analytics, no tracking, and no third-party service beyond the AI
provider.

---

## Health and safety

NutriAI gives general wellness and nutrition guidance. It is not a medical
device and does not diagnose anything.

The safety behaviour is built into the architecture rather than left to a
prompt. Calorie targets are floored at 1,200 kcal regardless of goal, and any
generated plan below that floor is rejected rather than shown. BMI is
presented descriptively, with its limitations acknowledged. Messages
suggesting a medical emergency bypass the model entirely and return guidance
to seek urgent care. Messages suggesting disordered eating suppress calorie
figures and redirect toward professional support. The coach will not suggest
eating less in response to slow progress, whatever the numbers say.

Where a diagnosed condition is on file it shapes food advice, because a
diabetic needs different breakfast guidance than someone without. Medication
is not discussed at all — that is a question for the doctor who prescribed it.

For medical concerns, consult a qualified healthcare professional.

---

## Roadmap

- [x] Project setup, design system, navigation shell
- [x] Accounts, bcrypt hashing, JWT sessions, admin creation
- [x] Health profile, BMI, calorie targets
- [x] Login and registration
- [x] Onboarding flow and Health screen
- [x] Today dashboard
- [x] AI coach — provider interface, context selection, safety layer,
      conversation history, suggested questions
- [x] Personalised diet plans
- [x] PDF export
- [x] Weight tracking and progress charts
- [x] Settings, theme persistence, account lifecycle
- [x] Administration panel
- [x] Prescription reading with on-device OCR
- [x] Alembic migrations
- [x] Bundled fonts and offline support
- [x] Landing page with an animated hero

---

## Documentation

`docs/decisions.md` records why the project is built the way it is —
including the choices that turned out to be wrong and were changed. Twenty
entries, covering authentication, the AI provider, the database, and the
things that broke along the way.

---

## Known gaps

**No tests.** `health_calc.py` is pure functions with no dependencies, and is
the code where being wrong actually matters. It should have had them from the
first day.

**SQLite** is fine for one machine. A deployment with real concurrency would
want PostgreSQL, which the repository layer is already shaped for.

---

## Author

**Atahar Hossain Piash** — [@Drag375o](https://github.com/Drag375o)