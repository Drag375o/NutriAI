"""Request and response shapes for diet plans."""

from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Slot = Literal["breakfast", "lunch", "dinner", "snack"]


class GeneratedMeal(BaseModel):
    """One meal as the model returns it.

    Validated here rather than trusted: a model can return a negative
    calorie count or a slot we do not recognise, and this is where that
    gets caught.
    """

    slot: Slot
    time_hint: str | None = Field(default=None, max_length=40)
    name: str = Field(min_length=1, max_length=160)
    portion: str | None = Field(default=None, max_length=200)
    calories: int = Field(ge=0, le=3000)
    protein_g: float | None = Field(default=None, ge=0, le=300)
    carbs_g: float | None = Field(default=None, ge=0, le=500)
    fat_g: float | None = Field(default=None, ge=0, le=300)
    substitution: str | None = Field(default=None, max_length=200)


class GeneratedPlan(BaseModel):
    """The whole reply, before it is saved."""

    rationale: str | None = Field(default=None, max_length=600)
    meals: list[GeneratedMeal] = Field(min_length=1, max_length=8)


class MealRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slot: str
    time_hint: str | None
    name: str
    portion: str | None
    calories: int
    protein_g: float | None
    carbs_g: float | None
    fat_g: float | None
    substitution: str | None


class DietPlanRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    plan_date: date
    target_calories: int
    goal: str | None
    rationale: str | None
    created_at: datetime
    meals: list[MealRead] = []

    # Computed from the meals, so they can never disagree with them.
    total_calories: int = 0
    total_protein_g: float = 0


class DietPlanSummary(BaseModel):
    """For the list view, without the meals."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    plan_date: date
    target_calories: int
    total_calories: int = 0


class GenerateRequest(BaseModel):
    # Omit for today. Lets someone plan tomorrow in advance.
    plan_date: date | None = None

    # Free text steered at the generation: "something quick", "no fish".
    note: str | None = Field(default=None, max_length=300)