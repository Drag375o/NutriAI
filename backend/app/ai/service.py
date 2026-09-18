"""The AI service: provider selection and code-level safety.

Nothing above this layer talks to a provider directly, and nothing below it
knows about users or profiles.
"""

import re

from app.ai.prompts.system import NUTRITION_COACH
from app.ai.providers.base import AIProvider, AIProviderError, ChatMessage, ChatResult
from app.ai.providers.groq_provider import GroqProvider
from app.core.config import settings

# Phrases that suggest a medical emergency. Matched before the model sees
# the message, because a model can be talked out of caution and a regex
# cannot (master prompt section 44).
_URGENT_PATTERNS = [
    r"\bchest pain\b",
    r"\bcan'?t breathe\b",
    r"\btrouble breathing\b",
    r"\bpassed out\b",
    r"\bfainted\b",
    r"\bcoughing up blood\b",
    r"\bsevere pain\b",
]

_URGENT_RESPONSE = (
    "What you are describing could need urgent medical attention, and that "
    "is beyond what I can help with.\n\n"
    "Please contact a doctor or your local emergency service now. If symptoms "
    "are severe or getting worse, go to the nearest emergency department.\n\n"
    "I am here for nutrition questions whenever you need them."
)

# Phrases suggesting disordered eating. These do not block the reply, but
# they add an instruction the model must follow for that turn.
_DISTRESS_PATTERNS = [
    r"\bstarv\w*\b",
    r"\bpurge\b",
    r"\bthrow up\b",
    r"\bmake myself sick\b",
    r"\bhate my body\b",
    r"\bdisgusting\b",
    r"\b(\d{3})\s*calories? a day\b",
]

_DISTRESS_GUIDANCE = (
    "\n\n## This turn\n"
    "The person may be in distress about food or their body. Do not give "
    "calorie numbers, targets, or restriction plans in this reply. Respond "
    "warmly, acknowledge how they feel without amplifying it, and gently "
    "suggest speaking to a doctor or registered dietitian. Do not diagnose."
)


class AIService:
    """Picks a provider and runs requests through the safety checks."""

    def __init__(self, provider: AIProvider | None = None):
        self._provider = provider or self._build_provider()

    @staticmethod
    def _build_provider() -> AIProvider:
        """Provider chosen by configuration, not hardcoded.

        An OllamaProvider added here is the only change needed to run
        NutriAI fully offline.
        """
        if settings.AI_PROVIDER == "groq":
            return GroqProvider()
        raise AIProviderError(
            f"Unknown AI provider '{settings.AI_PROVIDER}'. Check AI_PROVIDER in .env."
        )

    @property
    def provider_name(self) -> str:
        return self._provider.name

    @property
    def model(self) -> str:
        return self._provider.model

    async def is_available(self) -> bool:
        return await self._provider.is_available()

    async def ask(
        self,
        message: str,
        *,
        context: str | None = None,
        history: list[ChatMessage] | None = None,
    ) -> ChatResult:
        """Answer one message.

        Urgent situations short-circuit before the model is called at all:
        no round trip, no chance of a fluent but wrong answer.
        """
        if self._is_urgent(message):
            return ChatResult(content=_URGENT_RESPONSE, model="safety-layer")

        system = NUTRITION_COACH
        if context:
            system = f"{system}\n\n## About this person\n{context}"
        if self._suggests_distress(message):
            system = f"{system}{_DISTRESS_GUIDANCE}"

        messages = [ChatMessage(role="system", content=system)]
        if history:
            messages.extend(history)
        messages.append(ChatMessage(role="user", content=message))

        return await self._provider.complete(messages)

    @staticmethod
    def _is_urgent(text: str) -> bool:
        lowered = text.lower()
        return any(re.search(p, lowered) for p in _URGENT_PATTERNS)

    @staticmethod
    def _suggests_distress(text: str) -> bool:
        lowered = text.lower()
        return any(re.search(p, lowered) for p in _DISTRESS_PATTERNS)