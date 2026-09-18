"""Request and response shapes for chat."""

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class ChatResponse(BaseModel):
    reply: str
    model: str

    # Useful while tuning prompts and watching the rate limit.
    prompt_tokens: int = 0
    completion_tokens: int = 0


class AIStatus(BaseModel):
    provider: str
    model: str
    available: bool