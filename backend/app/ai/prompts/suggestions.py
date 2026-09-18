"""Suggested opening questions, chosen from the profile.

Rules rather than a model call: the suggestions appear the moment a screen
loads, cost nothing, and can never invent a question about information the
user has not given us.
"""

from app.models.profile import Profile

# Shown when there is no profile to work from. Answerable without knowing
# anything about the person.
_GENERAL = [
    "What makes a balanced meal?",
    "How much protein do I actually need?",
    "Are carbohydrates bad for me?",
    "What should I eat before exercise?",
]

_BY_GOAL = {
    "lose": [
        "How do I lose weight without feeling hungry all day?",
        "What should dinner look like tonight?",
    ],
    "maintain": [
        "How do I stay at my current weight?",
        "Is my daily intake about right?",
    ],
    "gain": [
        "How do I gain weight in a healthy way?",
        "What should I eat after training?",
    ],
}

_BY_ACTIVITY = {
    "sedentary": "I sit at a desk all day. How should I eat around that?",
    "light": "How should I eat on days I do not exercise?",
    "moderate": "How should I fuel a moderate training week?",
    "active": "What should I eat on heavy training days?",
    "very_active": "How do I eat enough for how much I train?",
}

# How many the UI shows. Four fits one row on desktop and two on mobile,
# and stays under the point where choosing becomes work.
LIMIT = 4


def build(profile: Profile | None) -> list[str]:
    """Four questions suited to what we know about this person."""
    if profile is None:
        return _GENERAL[:LIMIT]

    suggestions: list[str] = []

    if profile.goal in _BY_GOAL:
        suggestions.extend(_BY_GOAL[profile.goal])

    if profile.daily_calories_available:
        suggestions.append("How many calories should I be eating each day?")

    if profile.allergies:
        first = profile.allergies.split(",")[0].strip()
        if first:
            suggestions.append(f"What can I eat instead of {first}?")

    if profile.diet_preference and profile.diet_preference != "none":
        suggestions.append(
            f"Give me a {profile.diet_preference} dinner idea for tonight."
        )

    if profile.activity_level in _BY_ACTIVITY:
        suggestions.append(_BY_ACTIVITY[profile.activity_level])

    # Top up from the general list so the row is never half empty.
    for question in _GENERAL:
        if len(suggestions) >= LIMIT:
            break
        if question not in suggestions:
            suggestions.append(question)

    return suggestions[:LIMIT]