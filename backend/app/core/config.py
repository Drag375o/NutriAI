"""Application configuration, loaded once from the project-root .env file."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# config.py -> core -> app -> backend -> NutriAI (project root)
PROJECT_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=PROJECT_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_NAME: str = "NutriAI"
    APP_VERSION: str = "0.1.0"
    ENVIRONMENT: str = "development"

    HOST: str = "127.0.0.1"
    PORT: int = 8000
    API_V1_PREFIX: str = "/api/v1"

    CORS_ORIGINS: str = "*"

    AI_PROVIDER: str = "groq"
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen2.5:7b-instruct"

    DATABASE_URL: str = "sqlite:///./nutriai.db"

    @property
    def cors_origin_list(self) -> list[str]:
        """CORS_ORIGINS is a comma-separated string in .env; FastAPI wants a list."""
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT.lower() == "development"


@lru_cache
def get_settings() -> Settings:
    """Cached so the .env file is read once, not on every request."""
    return Settings()


settings = get_settings()