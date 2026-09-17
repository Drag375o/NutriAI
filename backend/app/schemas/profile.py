"""Request and response shapes for the profile endpoints."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Sex = Literal["male", "female", "other"]
Activity = Literal["sedentary", "light", "moderate", "active", "very_active"]
Goal = Literal["lose", "maintain", "gain"]


class ProfileUpdate(BaseModel):
    """Every field optional, so onboarding can save one screen at a time."""

    age: int | None = Field(default=None, ge=13, le=120)
    sex: Sex | None = None
    height_cm: float | None = Field(default=None, ge=80, le=250)
    weight_kg: float | None = Field(default=None, ge=25, le=400)
    activity_level: Activity | None = None
    goal: Goal | None = None
    target_weight_kg: float | None = Field(default=None, ge=25, le=400)
    diet_preference: str | None = Field(default=None, max_length=64)
    allergies: str | None = Field(default=None, max_length=500)
    restrictions: str | None = Field(default=None, max_length=500)
    conditions: str | None = Field(default=None, max_length=500)


class BMIRead(BaseModel):
    value: float
    category: str
    note: str


class ProfileRead(BaseModel):
    """The stored profile plus everything derived from it."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    age: int | None
    sex: str | None
    height_cm: float | None
    weight_kg: float | None
    activity_level: str | None
    goal: str | None
    target_weight_kg: float | None
    diet_preference: str | None
    allergies: str | None
    restrictions: str | None
    conditions: str | None

    # Computed on read, never stored, so they cannot drift out of sync
    # with the weight they came from. Null until the inputs exist.
    bmi: BMIRead | None = None
    daily_calories: int | None = None

    # True when there is enough here to personalise AI advice.
    is_complete: bool = False