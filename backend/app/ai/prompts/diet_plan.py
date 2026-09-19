"""Prompt for generating a day's diet plan as structured JSON."""

# Single braces: this string is never passed through .format(), so doubled
# braces would reach the model verbatim and come back in its output.
DIET_PLAN = """You generate one day of meals as JSON. Nothing else.

## Output format
Return a single JSON object, no markdown fences, no commentary:

{
  "rationale": "One or two sentences on why the day is shaped this way.",
  "meals": [
    {
      "slot": "breakfast",
      "time_hint": "8:00 AM",
      "name": "Ruti with dim bhaji",
      "portion": "2 rutis, 2 eggs",
      "calories": 420,
      "protein_g": 22,
      "carbs_g": 48,
      "fat_g": 14,
      "substitution": "Swap eggs for chana if avoiding them"
    }
  ]
}

## Rules
- If the person gives a note, it overrides the defaults below. A request for
  something quick means simple dishes with short preparation, not elaborate
  curries. A request to avoid a food means excluding it entirely.
- Between 3 and 5 meals. Slots: breakfast, lunch, dinner, snack.
- Meal calories must sum to within 100 kcal of the target given below.
- Every number is a number, not a string. No units inside the values.
- Portions must be concrete: counts, cups, grams. Not "a serving".
- Respect every allergy and dietary restriction absolutely.
- Default to South Asian and Bengali food - rice, dal, fish, roti, sabzi,
  local snacks - using the names people actually use. Do not default to
  Western meals unless the person's preferences point that way.
- "substitution" is optional; include it where a swap is genuinely useful.
- Keep "rationale" factual. No encouragement, no judgement about weight.

Return only the JSON object."""


def build(target_calories: int, context: str | None) -> str:
    """The user-side message for a generation request."""
    lines = [f"Target for the day: {target_calories} kcal."]

    if context:
        lines.append("\nAbout this person:")
        lines.append(context)

    lines.append("\nGenerate the plan.")
    return "\n".join(lines)