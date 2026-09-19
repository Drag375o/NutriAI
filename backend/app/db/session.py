"""Database engine and session management."""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import PROJECT_ROOT, settings
from app.db.base import Base

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine

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

# SQLite ships with foreign key enforcement disabled, per connection. Without
# this, ON DELETE CASCADE is silently ignored and deleting a user leaves its
# profile, plans, conversations and weight entries orphaned in the database.
if _url.startswith("sqlite"):

    @event.listens_for(Engine, "connect")
    def _enable_foreign_keys(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db() -> None:
    """Create any missing tables. Called once at startup.

    Fine while the schema is still moving. Alembic migrations arrive once
    real data exists and recreating tables stops being free.
    """
    from app.models import (  # noqa: F401
        conversation,
        diet_plan,
        profile,
        user,
        weight_entry,
    )

    Base.metadata.create_all(bind=engine)


def get_db() -> Generator[Session, None, None]:
    """One session per request, always closed."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()