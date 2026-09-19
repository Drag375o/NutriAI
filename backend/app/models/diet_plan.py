"""Generated diet plans and the meals inside them."""

from datetime import date, datetime, timezone

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class DietPlan(Base):
    __tablename__ = "diet_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )

    # The day this plan is for. Indexed because "today's plan" is the most
    # common lookup in the app.
    plan_date: Mapped[date] = mapped_column(Date, index=True)

    # What the plan was built against, kept as a snapshot. The profile can
    # change later; this records what the plan actually assumed.
    target_calories: Mapped[int] = mapped_column(Integer)
    goal: Mapped[str | None] = mapped_column(String(24), nullable=True)

    # One or two sentences from the model on why the day is shaped this way.
    rationale: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    meals: Mapped[list["Meal"]] = relationship(
        back_populates="plan",
        cascade="all, delete-orphan",
        order_by="Meal.position",
    )

    @property
    def total_calories(self) -> int:
        return sum(m.calories for m in self.meals)

    @property
    def total_protein_g(self) -> float:
        return round(sum(m.protein_g or 0 for m in self.meals), 1)


class Meal(Base):
    __tablename__ = "meals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    plan_id: Mapped[int] = mapped_column(
        ForeignKey("diet_plans.id", ondelete="CASCADE"), index=True
    )

    # Ordering within the day. Stored rather than derived from time, so a
    # plan reads correctly even with vague times like "evening".
    position: Mapped[int] = mapped_column(Integer, default=0)

    # 'breakfast' | 'lunch' | 'dinner' | 'snack'
    slot: Mapped[str] = mapped_column(String(24))

    # Free text: "8:00 AM", "Around midday". Not parsed, only displayed.
    time_hint: Mapped[str | None] = mapped_column(String(40), nullable=True)

    name: Mapped[str] = mapped_column(String(160))
    portion: Mapped[str | None] = mapped_column(String(200), nullable=True)

    calories: Mapped[int] = mapped_column(Integer, default=0)
    protein_g: Mapped[float | None] = mapped_column(Float, nullable=True)
    carbs_g: Mapped[float | None] = mapped_column(Float, nullable=True)
    fat_g: Mapped[float | None] = mapped_column(Float, nullable=True)

    # An alternative the user can swap to. One line, not a full meal record.
    substitution: Mapped[str | None] = mapped_column(String(200), nullable=True)

    plan: Mapped[DietPlan] = relationship(back_populates="meals")