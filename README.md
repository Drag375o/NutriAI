# NutriAI

**Eat well, on your terms — your food, your goals, your data.**

A cross-platform nutrition and health application with an AI coach. Users
track their health metrics, receive a personalised calorie target, and talk
to an assistant that already knows their profile.

Built with Flutter and FastAPI, currently targeting the web.

> **Status: in active development.** Accounts, health profiles, BMI and
> calorie calculations, and the AI coach with persistent conversations all
> work end to end. Diet planning, progress charts, and the admin panel are
> not yet built. See the roadmap for what exists.

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
└──────┬───────┬───────┘
       │       │
       ▼       ▼
┌──────────┐ ┌──────────────┐
│  SQLite  │ │  AI Service  │
└──────────┘ └──────┬───────┘
                    ▼
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
| Database | SQLite | Zero configuration; one connection string from Postgres |
| Auth | bcrypt + JWT | Passwords unreadable by anyone, including administrators |
| AI | Groq | Fast inference behind a swappable provider interface |

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
target; ask whether rice is healthy and it does not. Allergies and dietary
restrictions are always included, because they are never irrelevant to a food
suggestion. Measured difference between those two questions: 529 versus 587
prompt tokens.

**Safety lives in code, not only in the prompt.** A prompt can be argued
with. Messages suggesting a medical emergency short-circuit before the model
is called at all and return a fixed response directing the person to urgent
care. Messages suggesting disordered eating attach an instruction that
suppresses calorie figures for that turn. Calorie targets are floored at
1,200 kcal in the calculation itself, regardless of stated goal.

**Conversations persist**, with the last ten messages supplied as context so
follow-up questions like "what about something lighter?" resolve correctly.

---

## Features

### Working

- **Accounts** — registration, login, sessions that survive a refresh
- **Password security** — bcrypt hashing, so stored passwords cannot be read
  back by anyone, including database administrators
- **Role-based access** — users and admins share one login; role decides reach
- **Admin creation** — terminal-only, gated behind a company secret, with no
  API endpoint that could be abused
- **Onboarding** — a four-step flow that saves as it goes, so a closed tab
  loses nothing, with both metric and imperial height entry
- **Health profile** — age, sex, height, weight, activity level, goal,
  dietary preferences, allergies, restrictions
- **BMI** — calculated and categorised against WHO adult bands, presented as
  one signal with its limitations stated rather than as a verdict
- **Calorie targets** — Mifflin-St Jeor BMR with activity multipliers and a
  goal adjustment, floored so the app cannot recommend unsafe restriction
- **Dashboard** — the day's numbers, live from the profile
- **AI coach** — conversations with history, a sidebar of past chats,
  deletion, and opening questions chosen from the user's own profile
- **Data isolation** — every query scoped to the authenticated user; the user
  id comes from the token, never from a request parameter
- **Adaptive layout** — labelled rail, icon rail, or bottom bar by width
- **Light and dark themes** — both designed deliberately, not inverted

### Planned

Personalised diet plans · PDF export · Weight tracking and progress charts ·
Settings and data management · Admin panel · Prescription reading with
on-device OCR · Food database covering South Asian and Bengali foods ·
Offline local AI via Ollama

---

## Design

The interface takes its direction from editorial print rather than dashboard
software. Warm paper and ink, a single gold-to-orange accent family,
structure carried by hairline rules instead of stacked cards, and no shadows
or gradients anywhere.

**Palette** — Paper `#F2EFE6` · Linen `#E7E1D2` · Ink `#1C1A15` ·
Turmeric `#C8912F` · Ember `#B8501F`, with a separately tuned dark theme.

**Type** — Archivo for structure, IBM Plex Mono for numerals so weights and
calorie counts align in columns and do not jitter as digits change.

**Shape** — near-square corners throughout, with one signature move: primary
buttons have two opposite corners cut flat, like a stamped label.

Accent colours come in two variants, one for fills and one for text, because
the gold that works as a chart line fails WCAG contrast as a word.

---

## Getting started

### Requirements

- Flutter 3.27+ with Chrome
- Python 3.11
- A Groq API key — free at [console.groq.com](https://console.groq.com)

### Setup

```bash
git clone https://github.com/Drag375o/NutriAI.git
cd NutriAI
cp .env.example .env
```

Fill in `.env`:

```
JWT_SECRET=<python -c "import secrets; print(secrets.token_urlsafe(48))">
GROQ_API_KEY=<your key>
GROQ_MODEL=openai/gpt-oss-20b
ADMIN_CREATION_SECRET=<a secret of your choosing>
```

Groq retires models periodically. `python scripts/list_models.py` prints what
your key can currently use.

**Backend**

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Runs at `http://localhost:8000`. Interactive API documentation, generated
from the code, is at `/docs`.

**Frontend**

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 5173
```

**Creating an administrator**

```bash
python scripts/create_admin.py
```

Prompts for the company secret from `.env`, then the account details. This is
the only way an admin account can be created — there is no API endpoint for
it, by design.

---

## Project structure

```
NutriAI/
├── backend/
│   └── app/
│       ├── api/          routes and shared dependencies
│       ├── core/         configuration and security
│       ├── db/           engine, session, base
│       ├── models/       SQLAlchemy tables
│       ├── schemas/      Pydantic request and response shapes
│       ├── services/     business logic and health calculations
│       ├── repositories/ all database access
│       └── ai/           providers, prompts, context, safety
├── frontend/
│   └── lib/
│       ├── app/          theme, router, root widget
│       ├── core/         networking, shared widgets, constants
│       └── features/     one folder per feature
├── scripts/
└── docs/
```

Business logic stays out of route handlers, and database access stays in
repositories, so swapping SQLite for PostgreSQL touches one layer.

---

## API

All endpoints under `/api/v1`.

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/health` | — | Service status and configuration |
| `POST` | `/auth/register` | — | Create an account |
| `POST` | `/auth/login` | — | Sign in, returns a JWT |
| `GET` | `/auth/me` | Bearer | Current account |
| `POST` | `/auth/change-password` | Bearer | Requires the current password |
| `GET` | `/profile` | Bearer | Profile with BMI and calorie target |
| `PATCH` | `/profile` | Bearer | Partial update |
| `GET` | `/chat/status` | Bearer | Whether the AI is reachable |
| `GET` | `/chat/suggestions` | Bearer | Opening questions from the profile |
| `POST` | `/chat` | Bearer | Send a message |
| `GET` | `/conversations` | Bearer | List conversations |
| `GET` | `/conversations/{id}` | Bearer | One conversation with messages |
| `DELETE` | `/conversations/{id}` | Bearer | Delete a conversation |

---

## Privacy and data handling

Stated plainly, because health data deserves it.

**What is stored** — your email, name, the health details you enter, and your
conversations, in a SQLite database on whatever machine runs the backend.
Passwords are stored as bcrypt hashes, which cannot be reversed. No
administrator can read your password.

**What leaves the machine** — the AI coach uses Groq's API, so the profile
details relevant to a question are sent to Groq when you use it. Not your
name, not your email, and nothing at all until you use an AI feature.

**What this project does not claim** — it is not local-first in the strict
sense while a cloud provider is in use. An `OllamaProvider` for fully local
inference is planned, and the provider interface exists so it can be added
without changes elsewhere. Until then, the accurate description is
"local-first architecture with an optional cloud provider".

There is no analytics, no tracking, and no third-party service beyond the AI
provider.

---

## Health and safety

NutriAI gives general wellness and nutrition guidance. It is not a medical
device and does not diagnose anything.

The safety behaviour is built into the architecture rather than left to a
prompt. Calorie targets are floored at 1,200 kcal regardless of goal. BMI is
presented descriptively, with its limitations acknowledged. Messages
suggesting a medical emergency bypass the model entirely and return guidance
to seek urgent care. Messages suggesting disordered eating suppress calorie
figures and redirect toward professional support.

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
- [ ] Personalised diet plans
- [ ] PDF export
- [ ] Weight tracking and progress charts
- [ ] Settings and data management
- [ ] Admin panel
- [ ] Prescription reading with on-device OCR
- [ ] Bundled fonts and full offline support
- [ ] Windows, Android and iOS builds
- [ ] Local AI via Ollama
- [ ] Food database covering South Asian and Bengali foods

---

## Acknowledgements

A rebuild and substantial rethink of an earlier Django project,
[FitWell](https://github.com/minhaz-42/FitWell-Using-Django), sharing its
feature concepts but none of its code, architecture or visual design.

---

## Author

**Atahar Hossain Piash** — [@Drag375o](https://github.com/Drag375o)