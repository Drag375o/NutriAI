"""Chat history: conversations and the messages inside them."""

from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Conversation(Base):
    __tablename__ = "conversations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )

    # Taken from the first user message until renaming exists.
    title: Mapped[str] = mapped_column(String(120), default="New conversation")

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    # Touched on every message, so the list can sort by recent activity.
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now
    )

    messages: Mapped[list["Message"]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="Message.created_at",
    )


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    conversation_id: Mapped[int] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True
    )

    # 'user' or 'assistant'. System prompts are rebuilt per request rather
    # than stored, so a prompt change applies to old conversations too.
    role: Mapped[str] = mapped_column(String(16))

    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    conversation: Mapped[Conversation] = relationship(back_populates="messages")