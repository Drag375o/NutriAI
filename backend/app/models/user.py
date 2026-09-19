"""User accounts. Both people using NutriAI and the admins managing it."""

from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(80))

    # Bcrypt hash. Never the password itself, and never returned by any endpoint.
    password_hash: Mapped[str] = mapped_column(String(255))

    # 'user' | 'admin'. Only the create_admin script can set 'admin'.
    role: Mapped[str] = mapped_column(String(16), default="user", index=True)

    # Deactivated accounts cannot log in, but their data is preserved.
    # Set by an administrator; a user cannot clear this themselves.
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)    

    # When the user paused their own account. Cleared when they sign back
    # in and choose to restore it. Kept separate from is_active so that a
    # user reactivating themselves cannot undo an administrator's ban.
    deactivated_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True
    )

    # Set when an admin resets a password; forces a change at next login.
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)