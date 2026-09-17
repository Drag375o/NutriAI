"""Database engine and session management."""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import PROJECT_ROOT, settings
from app.db.base import Base

# Resolve the SQLite path against the project root rather than the working
# directory, so the database is found wherever uvicorn is started from.
_url = settings.DATABASE_URL
if _url.startswith("sqlite:///./"):
    _url = f"sqlite:///{PROJECT_ROOT / _url.removeprefix('sqlite:///./')}"

engine = create_engine(
    _url,
    # SQLite blocks cross-thread use by default; FastAPI needs it permitted.
    connect_args={"check_same_thread": False} if _url.startswith("sqlite") else {},
    echo=False,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db() -> None:
    """Create any missing tables. Called once at startup.

    Fine while the schema is still moving. Alembic migrations arrive once
    real data exists and recreating tables stops being free.
    """
    from app.models import profile, user  # noqa: F401  (registers the models)

    Base.metadata.create_all(bind=engine)


def get_db() -> Generator[Session, None, None]:
    """One session per request, always closed."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()