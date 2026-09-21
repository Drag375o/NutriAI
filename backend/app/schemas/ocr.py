"""Shapes for image text extraction."""

from pydantic import BaseModel, Field


class OcrStatus(BaseModel):
    """Whether the feature can be offered at all."""

    available: bool
    reason: str | None = None


class OcrResult(BaseModel):
    """Raw extracted text, for the user to review and correct.

    Deliberately not parsed into fields. OCR misreads drug names and
    dosages, and presenting a guess as structured data would hide that.
    """

    text: str

    # Tesseract's own confidence is unreliable on photographs, so this is
    # a rough signal for the UI rather than a number to display.
    likely_poor: bool = False


class ConditionsUpdate(BaseModel):
    """What the user confirmed after reviewing.

    Only conditions are stored. Drug names are read and discarded: NutriAI
    does not reason about medication, so keeping them would serve no
    purpose and create a record nobody asked for.
    """

    conditions: str = Field(max_length=500)