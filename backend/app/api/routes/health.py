"""Service health endpoint."""

from fastapi import APIRouter

from app.core.config import settings

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict:
    return {
        "status": "ok",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "ai_provider": settings.AI_PROVIDER,
        # Never return the key itself - only whether one was loaded.
        "ai_key_configured": bool(settings.GROQ_API_KEY),
    }