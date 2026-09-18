"""Database access for conversations and messages."""

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.conversation import Conversation, Message

# How many past messages accompany a new question. Ten keeps recent context
# without sending an entire history on every turn; long conversations will
# need summarising rather than a bigger number.
HISTORY_LIMIT = 10


def _now() -> datetime:
    return datetime.now(timezone.utc)


def list_for_user(db: Session, user_id: int, limit: int = 50) -> list[Conversation]:
    return list(
        db.scalars(
            select(Conversation)
            .where(Conversation.user_id == user_id)
            .order_by(Conversation.updated_at.desc())
            .limit(limit)
        )
    )


def get_owned(db: Session, conversation_id: int, user_id: int) -> Conversation | None:
    """Fetch a conversation only if this user owns it.

    Ownership is part of the query, not a check afterwards, so there is no
    path that returns someone else's conversation.
    """
    return db.scalar(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id,
        )
    )


def create(db: Session, user_id: int, title: str) -> Conversation:
    conversation = Conversation(user_id=user_id, title=_trim_title(title))
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return conversation


def add_message(
    db: Session, conversation: Conversation, role: str, content: str
) -> Message:
    now = _now()

    message = Message(
        conversation_id=conversation.id,
        role=role,
        content=content,
        created_at=now,
    )
    db.add(message)

    # Bump the parent so the conversation list sorts by real activity.
    # Set from `now` rather than message.created_at, which is still None
    # until the flush applies the column default.
    conversation.updated_at = now

    db.commit()
    db.refresh(message)
    return message


def recent_messages(
    db: Session, conversation_id: int, limit: int = HISTORY_LIMIT
) -> list[Message]:
    """The last few messages, returned oldest first for the model."""
    rows = list(
        db.scalars(
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
        )
    )
    return list(reversed(rows))


def delete(db: Session, conversation: Conversation) -> None:
    # Messages go with it via the cascade on the relationship.
    db.delete(conversation)
    db.commit()


def _trim_title(text: str) -> str:
    """First line of the opening message, shortened, as a working title."""
    title = text.strip().split("\n")[0]
    return title[:117] + "..." if len(title) > 120 else title