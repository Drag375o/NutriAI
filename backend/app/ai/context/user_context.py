"""Builds the profile context sent to the model.

Two rules drive this file. Never dump the whole database into a prompt:
irrelevant detail costs tokens and dilutes what matters. And never invent
a value — a missing field is simply absent, so the model asks rather than
guesses (master prompt sections 9 and 41).
"""

import re

from app.models.profile import Profile
from app.services.health_calc import (
    calculate_bmi,
    calculate_bmr,
    calculate_daily_calories,
)

# Fields worth including only when the question touches on them. Keys are
# the context sections; values are the words that make them relevant.
_TOPIC_TRIGGERS = {
    "energy": [
        "calorie", "kcal", "weight", "lose", "gain", "deficit", "surplus",
        "portion", "how much", "target", "bmi", "bmr", "metabolism",
    ],
    "activity": [
        "exercise", "workout", "gym", "run", "walk", "training", "active",
        "protein", "muscle", "recovery",
    ],
}


def build(profile: Profile | None, question: str) -> str | None:
    """Return the context block for this question, or None if there is none.

    Identity fields the model always needs are included unconditionally.
    Everything else has to earn its place.
    """
    if profile is None:
        return None

    lowered = question.lower()
    lines: list[str] = []

    # Always included: these change what is safe to suggest, regardless of
    # what was asked. An allergy is never irrelevant.
    if profile.diet_preference and profile.diet_preference != "none":
        lines.append(f"- Diet: {profile.diet_preference}")
    if profile.allergies:
        lines.append(f"- Allergic to or avoids: {profile.allergies}")
    if profile.restrictions:
        lines.append(f"- Other restrictions: {profile.restrictions}")
    if profile.conditions:
        lines.append(f"- Reported health conditions: {profile.conditions}")

    # Goal shapes almost every food answer, so it comes along too.
    if profile.goal:
        goal_text = {
            "lose": "losing weight",
            "gain": "gaining weight",
            "maintain": "maintaining their weight",
        }.get(profile.goal, profile.goal)
        lines.append(f"- Working towards: {goal_text}")

    if _matches(lowered, "energy"):
        lines.extend(_energy_lines(profile))

    if _matches(lowered, "activity") and profile.activity_level:
        lines.append(f"- Activity level: {profile.activity_level.replace('_', ' ')}")

    if not lines:
        return None

    return "\n".join(lines)


def _matches(question: str, topic: str) -> bool:
    return any(
        re.search(rf"\b{re.escape(word)}", question)
        for word in _TOPIC_TRIGGERS[topic]
    )


def _energy_lines(profile: Profile) -> list[str]:
    """Numbers, included only when the question is about them.

    Recomputed here rather than stored, so they can never disagree with the
    weight they came from.
    """
    lines: list[str] = []

    if profile.age:
        lines.append(f"- Age: {profile.age}")
    if profile.sex:
        lines.append(f"- Sex: {profile.sex}")
    if profile.weight_kg:
        lines.append(f"- Current weight: {profile.weight_kg} kg")
    if profile.target_weight_kg:
        lines.append(f"- Target weight: {profile.target_weight_kg} kg")

    if profile.height_cm and profile.weight_kg:
        bmi = calculate_bmi(profile.weight_kg, profile.height_cm)
        lines.append(f"- BMI: {bmi.value} ({bmi.category})")

        if profile.age:
            bmr = calculate_bmr(
                profile.weight_kg, profile.height_cm, profile.age, profile.sex
            )
            daily = calculate_daily_calories(
                bmr, profile.activity_level, profile.goal
            )
            lines.append(f"- Daily calorie target: {daily} kcal")

    return lines