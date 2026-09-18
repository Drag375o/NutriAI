"""The interface every AI provider implements."""

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class ChatMessage:
    """One turn in a conversation. Role is 'system', 'user' or 'assistant'."""

    role: str
    content: str

    def to_dict(self) -> dict:
        return {"role": self.role, "content": self.content}


@dataclass(frozen=True)
class ChatResult:
    """A completed reply, plus what it cost."""

    content: str
    model: str
    prompt_tokens: int = 0
    completion_tokens: int = 0


class AIProviderError(Exception):
    """Something went wrong talking to the model.

    Carries a message safe to show a user, because the layers above should
    not have to translate provider-specific failures into human language.
    """

    def __init__(self, message: str, *, retryable: bool = False):
        super().__init__(message)
        self.message = message

        # True for rate limits and timeouts: trying again may work.
        self.retryable = retryable


class AIProvider(ABC):
    """A source of chat completions.

    Implementations must not leak provider-specific types or errors past
    this boundary. Everything above sees ChatMessage, ChatResult and
    AIProviderError, nothing else.
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """Short identifier, e.g. 'groq'. Shown in diagnostics."""

    @property
    @abstractmethod
    def model(self) -> str:
        """The model currently in use."""

    @abstractmethod
    async def complete(
        self,
        messages: list[ChatMessage],
        *,
        max_tokens: int = 1024,
        temperature: float = 0.6,
    ) -> ChatResult:
        """Generate one reply to a conversation."""

    @abstractmethod
    async def is_available(self) -> bool:
        """Whether this provider can currently serve requests."""