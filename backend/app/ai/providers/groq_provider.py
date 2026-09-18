"""Groq implementation of AIProvider.

Groq serves open models on custom hardware at roughly 500 tokens per second,
with a 128k context window on the free tier. Fast enough that a diet plan
finishes in about two seconds rather than forty.
"""

import asyncio

import httpx

from app.ai.providers.base import (
    AIProvider,
    AIProviderError,
    ChatMessage,
    ChatResult,
)
from app.core.config import settings

_BASE_URL = "https://api.groq.com/openai/v1"

# Groq's free tier allows roughly 30 requests per minute. A brief wait and
# one retry covers the occasional burst without stalling the request.
_MAX_RETRIES = 2
_RETRY_DELAY_SECONDS = 2.0


class GroqProvider(AIProvider):
    def __init__(self, api_key: str | None = None, model: str | None = None):
        self._api_key = api_key or settings.GROQ_API_KEY
        self._model = model or settings.GROQ_MODEL

    @property
    def name(self) -> str:
        return "groq"

    @property
    def model(self) -> str:
        return self._model

    async def is_available(self) -> bool:
        return bool(self._api_key)

    async def complete(
        self,
        messages: list[ChatMessage],
        *,
        max_tokens: int = 1024,
        temperature: float = 0.6,
    ) -> ChatResult:
        if not self._api_key:
            raise AIProviderError(
                "The AI service is not configured. Add a Groq API key to .env."
            )

        payload = {
            "model": self._model,
            "messages": [m.to_dict() for m in messages],
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        last_error: AIProviderError | None = None

        for attempt in range(_MAX_RETRIES + 1):
            try:
                return await self._request(payload)
            except AIProviderError as e:
                last_error = e
                if not e.retryable or attempt == _MAX_RETRIES:
                    raise
                # Linear backoff is enough here: the limit is per minute,
                # and a couple of seconds usually clears a burst.
                await asyncio.sleep(_RETRY_DELAY_SECONDS * (attempt + 1))

        raise last_error  # unreachable, but keeps the type checker honest

    async def _request(self, payload: dict) -> ChatResult:
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{_BASE_URL}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self._api_key}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )
        except httpx.TimeoutException:
            raise AIProviderError(
                "The AI took too long to respond. Try again.", retryable=True
            )
        except httpx.RequestError:
            raise AIProviderError(
                "Could not reach the AI service. Check your internet connection."
            )

        if response.status_code == 429:
            raise AIProviderError(
                "The AI service is busy. Trying again in a moment.",
                retryable=True,
            )

        if response.status_code == 401:
            # Deliberately vague to the user; the detail belongs in logs.
            raise AIProviderError("The AI service rejected our credentials.")

        if response.status_code >= 500:
            raise AIProviderError(
                "The AI service is having trouble. Try again shortly.",
                retryable=True,
            )

        if response.status_code != 200:
            # Surface the provider's own message during development; a
            # production build would log this and show something generic.
            raise AIProviderError(
                f"AI service error {response.status_code}: {response.text[:300]}"
            )

        return self._parse(response.json())

    @staticmethod
    def _parse(body: dict) -> ChatResult:
        try:
            choice = body["choices"][0]
            usage = body.get("usage", {})
            return ChatResult(
                content=choice["message"]["content"].strip(),
                model=body.get("model", "unknown"),
                prompt_tokens=usage.get("prompt_tokens", 0),
                completion_tokens=usage.get("completion_tokens", 0),
            )
        except (KeyError, IndexError, AttributeError):
            raise AIProviderError("The AI sent back something unreadable.")