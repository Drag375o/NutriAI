"""Chat endpoints: ask, and manage conversation history."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.ai.context import user_context
from app.ai.prompts import suggestions as suggestion_prompts
from app.ai.providers.base import AIProviderError, ChatMessage
from app.ai.service import AIService
from app.api.dependencies import current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories import conversation_repo, profile_repo
from app.schemas.chat import (
    AIStatus,
    ChatRequest,
    ChatResponse,
    ConversationDetail,
    ConversationRead,
    MessageRead,
)

router = APIRouter(tags=["chat"])

# One instance for the app. It holds no per-request state, so sharing it
# avoids rebuilding the provider on every call.
_service = AIService()


@router.get("/chat/status", response_model=AIStatus)
async def ai_status(user: User = Depends(current_user)) -> AIStatus:
    """Whether the AI is reachable, so the UI can say so before a send."""
    return AIStatus(
        provider=_service.provider_name,
        model=_service.model,
        available=await _service.is_available(),
    )


@router.get("/chat/suggestions", response_model=list[str])
def chat_suggestions(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> list[str]:
    """Opening questions suited to this person's profile.

    Lives on the backend so the rules sit beside the context builder rather
    than being duplicated in Dart.
    """
    profile = profile_repo.get_or_create(db, user.id)
    return suggestion_prompts.build(profile)


@router.post("/chat", response_model=ChatResponse)
async def ask(
    payload: ChatRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> ChatResponse:
    # Resume a conversation, or start one titled from this first message.
    if payload.conversation_id is None:
        conversation = conversation_repo.create(db, user.id, payload.message)
        history: list[ChatMessage] = []
    else:
        conversation = conversation_repo.get_owned(
            db, payload.conversation_id, user.id
        )
        if conversation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="That conversation does not exist.",
            )
        history = [
            ChatMessage(role=m.role, content=m.content)
            for m in conversation_repo.recent_messages(db, conversation.id)
        ]

    conversation_repo.add_message(db, conversation, "user", payload.message)

    # Only the profile fields this question actually needs.
    profile = profile_repo.get_or_create(db, user.id)
    context = user_context.build(profile, payload.message)

    try:
        result = await _service.ask(
            payload.message, context=context, history=history
        )
    except AIProviderError as e:
        # 503 rather than 500: unavailable, not broken. The user's message
        # stays saved, so they can retry without retyping it.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=e.message
        )

    reply = conversation_repo.add_message(
        db, conversation, "assistant", result.content
    )

    return ChatResponse(
        conversation_id=conversation.id,
        reply=MessageRead.model_validate(reply),
        model=result.model,
        prompt_tokens=result.prompt_tokens,
        completion_tokens=result.completion_tokens,
    )


@router.get("/conversations", response_model=list[ConversationRead])
def list_conversations(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> list[ConversationRead]:
    return [
        ConversationRead.model_validate(c)
        for c in conversation_repo.list_for_user(db, user.id)
    ]


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
def read_conversation(
    conversation_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> ConversationDetail:
    conversation = conversation_repo.get_owned(db, conversation_id, user.id)
    if conversation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That conversation does not exist.",
        )
    return ConversationDetail.model_validate(conversation)


@router.delete("/conversations/{conversation_id}", status_code=204)
def delete_conversation(
    conversation_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> None:
    conversation = conversation_repo.get_owned(db, conversation_id, user.id)
    if conversation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That conversation does not exist.",
        )
    conversation_repo.delete(db, conversation)