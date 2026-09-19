"""Diet plan generation: prompt, parse, validate.

The model is asked for JSON, but models add prose, wrap output in markdown
fences, and occasionally produce something unparseable. This layer absorbs
all of that, and rejects plans whose numbers are unsafe regardless of how
well-formed they are.
"""

import json
import re

from pydantic import ValidationError

from app.ai.prompts.diet_plan import DIET_PLAN, build as build_request
from app.ai.providers.base import AIProviderError, ChatMessage
from app.ai.service import AIService
from app.schemas.diet_plan import GeneratedPlan
from app.services.health_calc import MINIMUM_DAILY_CALORIES

# How far the plan's total may drift from the target before it is rejected.
# The prompt asks for 100; this allows more slack before failing outright,
# since a 200 kcal miss is still a usable day.
CALORIE_TOLERANCE = 250


class DietPlanError(Exception):
    """Generation failed in a way worth showing the user."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


def _extract_json(text: str) -> dict:
    """Pull a JSON object out of whatever the model returned.

    Handles markdown fences and leading commentary, both of which appear
    even when the prompt forbids them.
    """
    cleaned = text.strip()

    # Strip ```json ... ``` fences if present.
    fence = re.match(r"^```(?:json)?\s*(.*?)\s*```$", cleaned, re.DOTALL)
    if fence:
        cleaned = fence.group(1)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    # Fall back to the outermost braces, which survives leading prose.
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end <= start:
        raise DietPlanError("The AI did not return a usable plan. Try again.")

    try:
        return json.loads(cleaned[start : end + 1])
    except json.JSONDecodeError:
        raise DietPlanError("The AI did not return a usable plan. Try again.")


def _validate(plan: GeneratedPlan, target: int) -> None:
    """Reject plans that are unsafe or do not meet the target.

    These are code-level checks because a prompt instruction is a request,
    not a guarantee (master prompt section 44).
    """
    total = sum(m.calories for m in plan.meals)

    if total < MINIMUM_DAILY_CALORIES:
        raise DietPlanError(
            "That plan came out too low in calories to be safe. "
            "Generating again."
        )

    if abs(total - target) > CALORIE_TOLERANCE:
        raise DietPlanError(
            f"That plan came to {total} kcal against a target of {target}. "
            "Generating again."
        )


async def generate(
    service: AIService, *, target_calories: int, context: str | None, note: str | None
) -> GeneratedPlan:
    """Ask for a plan, parse it, and check it before returning."""
    request = build_request(target_calories, context)
    if note:
        request = f"{request}\n\n## What they asked for\n{note}\n\nThis takes priority over the general defaults."
        "This takes priority over the general defaults."
        
    messages = [
        ChatMessage(role="system", content=DIET_PLAN),
        ChatMessage(role="user", content=request),
    ]

    try:
        # Lower temperature than chat: this is structured output, and
        # creativity here mostly produces malformed JSON.
        result = await service.provider.complete(
            messages, max_tokens=1600, temperature=0.4
        )
    except AIProviderError as e:
        raise DietPlanError(e.message)

    raw = _extract_json(result.content)

    try:
        plan = GeneratedPlan.model_validate(raw)
    except ValidationError:
        raise DietPlanError(
            "The AI returned a plan in the wrong shape. Try again."
        )

    _validate(plan, target_calories)
    return plan