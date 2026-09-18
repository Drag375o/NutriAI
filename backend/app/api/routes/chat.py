"""Chat endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status

from app.ai.providers.base import AIProviderError
from app.ai.service import AIService
from app.api.dependencies import current_user
from app.models.user import User
from app.schemas.chat import AIStatus, ChatRequest, ChatResponse

router = APIRouter(prefix="/chat", tags=["chat"])

# One instance for the app. It holds no per-request state, so sharing it
# avoids rebuilding the provider on every call.
_service = AIService()


@router.get("/status", response_model=AIStatus)
async def ai_status(user: User = Depends(current_user)) -> AIStatus:
    """Whether the AI is reachable, so the UI can say so before a send."""
    return AIStatus(
        provider=_service.provider_name,
        model=_service.model,
        available=await _service.is_available(),
    )


@router.post("", response_model=ChatResponse)
async def ask(
    payload: ChatRequest, user: User = Depends(current_user)
) -> ChatResponse:
    try:
        result = await _service.ask(payload.message)
    except AIProviderError as e:
        # 503 rather than 500: the service is unavailable, not broken.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=e.message,
        )

    return ChatResponse(
        reply=result.content,
        model=result.model,
        prompt_tokens=result.prompt_tokens,
        completion_tokens=result.completion_tokens,
    )
    