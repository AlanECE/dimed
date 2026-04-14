from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    environment: Literal["development", "test", "production"] = "development"
    database_url: str = "postgresql+asyncpg://dimed:dimed@db:5432/dimed"
    redis_url: str = "redis://redis:6379/0"
    secret_key: str = "dev-secret-change-in-production"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    cookie_secure: bool = False

    frontend_url: str = "http://localhost:3000"
    email_verification_ttl_hours: int = 24

    google_client_id: str = ""

    smtp_host: str = "mailhog"
    smtp_port: int = 1025
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from: str = "no-reply@dimed.dz"
    smtp_from_name: str = "DIMED"
    smtp_tls: bool = False
    smtp_ssl: bool = False

    # OCR via OpenRouter (free vision models)
    openrouter_api_key: str = ""
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    ocr_model: str = "google/gemma-3-27b-it:free"
    ocr_timeout_seconds: float = 45.0

    model_config = {"env_prefix": "DIMED_"}

    @model_validator(mode="after")
    def validate_security_defaults(self) -> "Settings":
        if self.environment != "production":
            return self

        if self.secret_key == "dev-secret-change-in-production":
            raise ValueError("DIMED_SECRET_KEY must be set in production")
        if not self.cookie_secure:
            raise ValueError("DIMED_COOKIE_SECURE must be true in production")
        if self.database_url == "postgresql+asyncpg://dimed:dimed@db:5432/dimed":
            raise ValueError(
                "DIMED_DATABASE_URL must not use the development default in production"
            )
        if not self.google_client_id:
            raise ValueError("DIMED_GOOGLE_CLIENT_ID must be set in production")
        return self


settings = Settings()
