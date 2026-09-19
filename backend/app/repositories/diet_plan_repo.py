"""Database access for diet plans. Every function is scoped to one user."""

from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.diet_plan import DietPlan, Meal
from app.schemas.diet_plan import GeneratedPlan


def get_for_date(db: Session, user_id: int, plan_date: date) -> DietPlan | None:
    return db.scalar(
        select(DietPlan).where(
            DietPlan.user_id == user_id,
            DietPlan.plan_date == plan_date,
        )
    )


def get_owned(db: Session, plan_id: int, user_id: int) -> DietPlan | None:
    """Ownership is part of the query, not a check afterwards."""
    return db.scalar(
        select(DietPlan).where(
            DietPlan.id == plan_id,
            DietPlan.user_id == user_id,
        )
    )


def list_for_user(db: Session, user_id: int, limit: int = 30) -> list[DietPlan]:
    return list(
        db.scalars(
            select(DietPlan)
            .where(DietPlan.user_id == user_id)
            .order_by(DietPlan.plan_date.desc())
            .limit(limit)
        )
    )


def save(
    db: Session,
    *,
    user_id: int,
    plan_date: date,
    target_calories: int,
    goal: str | None,
    generated: GeneratedPlan,
) -> DietPlan:
    """Store a generated plan, replacing any existing one for that date.

    One plan per day keeps the model simple. Regenerating is how someone
    gets a different day, rather than accumulating drafts.
    """
    existing = get_for_date(db, user_id, plan_date)
    if existing is not None:
        db.delete(existing)
        db.flush()

    plan = DietPlan(
        user_id=user_id,
        plan_date=plan_date,
        target_calories=target_calories,
        goal=goal,
        rationale=generated.rationale,
    )
    db.add(plan)
    db.flush()

    for position, meal in enumerate(generated.meals):
        db.add(
            Meal(
                plan_id=plan.id,
                position=position,
                slot=meal.slot,
                time_hint=meal.time_hint,
                name=meal.name,
                portion=meal.portion,
                calories=meal.calories,
                protein_g=meal.protein_g,
                carbs_g=meal.carbs_g,
                fat_g=meal.fat_g,
                substitution=meal.substitution,
            )
        )

    db.commit()
    db.refresh(plan)
    return plan


def delete(db: Session, plan: DietPlan) -> None:
    # Meals go with it via the cascade on the relationship.
    db.delete(plan)
    db.commit()