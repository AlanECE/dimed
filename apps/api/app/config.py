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
        return self


settings = Settings()
