"""Request and response shapes for chat."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)

    # Omit to start a new conversation.
    conversation_id: int | None = None


class MessageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role: str
    content: str
    created_at: datetime


class ChatResponse(BaseModel):
    conversation_id: int
    reply: MessageRead
    model: str

    # Useful while tuning prompts and watching the rate limit.
    prompt_tokens: int = 0
    completion_tokens: int = 0


class ConversationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    created_at: datetime
    updated_at: datetime


class ConversationDetail(ConversationRead):
    messages: list[MessageRead] = []


class AIStatus(BaseModel):
    provider: str
    model: str
    available: bool