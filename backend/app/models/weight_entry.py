"""Dated weight records."""

from datetime import date, datetime, timezone

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class WeightEntry(Base):
    __tablename__ = "weight_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )

    # The day being recorded, not when it was typed. Someone can log
    # yesterday's weigh-in this morning. Indexed because every query here
    # sorts or filters by it.
    recorded_on: Mapped[date] = mapped_column(Date, index=True)

    weight_kg: Mapped[float] = mapped_column(Float)

    # Optional context: "after holiday", "morning, before food".
    note: Mapped[str | None] = mapped_column(String(200), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)