from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "__project_name__"
    app_env: str = "development"
    log_level: str = "INFO"
    database_url: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5432/__package__"
    )
    api_prefix: str = "/api"

    # CORS — comma-separated list of allowed origins, "*" allows all in dev only
    cors_origins: str = ""

    # Observability — empty values disable each integration
    otel_exporter_otlp_endpoint: str = ""
    otel_service_name: str = ""
    sentry_dsn: str = ""

    @property
    def cors_origins_list(self) -> list[str]:
        if not self.cors_origins:
            return []
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
