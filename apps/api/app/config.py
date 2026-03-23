from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://dimed:dimed@db:5432/dimed"
    redis_url: str = "redis://redis:6379/0"
    secret_key: str = "dev-secret-change-in-production"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    model_config = {"env_prefix": "DIMED_"}


settings = Settings()
