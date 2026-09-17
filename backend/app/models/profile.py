"""A user's health profile. One row per account."""

from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    # Unique: one profile per account. Deleting the user deletes the profile.
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True
    )

    age: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # 'male' | 'female' | 'other'. Free text rather than an enum, so this
    # stays easy to extend without a migration.
    sex: Mapped[str | None] = mapped_column(String(16), nullable=True)

    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)

    # 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'
    activity_level: Mapped[str | None] = mapped_column(String(24), nullable=True)

    # 'lose' | 'maintain' | 'gain'
    goal: Mapped[str | None] = mapped_column(String(24), nullable=True)
    target_weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Comma-separated for now. Each becomes its own table if it ever needs
    # querying rather than just displaying.
    diet_preference: Mapped[str | None] = mapped_column(String(64), nullable=True)
    allergies: Mapped[str | None] = mapped_column(String(500), nullable=True)
    restrictions: Mapped[str | None] = mapped_column(String(500), nullable=True)
    conditions: Mapped[str | None] = mapped_column(String(500), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now
    )