"""Request and response shapes for weight tracking."""

from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class WeightEntryCreate(BaseModel):
    weight_kg: float = Field(ge=25, le=400)

    # Omit for today.
    recorded_on: date | None = None

    note: str | None = Field(default=None, max_length=200)


class WeightEntryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    recorded_on: date
    weight_kg: float
    note: str | None


class WeightTrend(BaseModel):
    """What the Progress screen shows above the chart.

    Every field is optional because a new user has no history, and a
    screen that needs all of this to render would show nothing at all.
    """

    latest: float | None = None
    latest_on: date | None = None

    starting: float | None = None
    starting_on: date | None = None

    target: float | None = None

    # Signed: negative is a loss. Over the whole record, and over 7 days.
    total_change: float | None = None
    recent_change: float | None = None

    # How far from the target, unsigned. Null without a target.
    to_target: float | None = None

    entry_count: int = 0


class WeightHistory(BaseModel):
    entries: list[WeightEntryRead] = []
    trend: WeightTrend