from __future__ import annotations

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from __package__.api.error_handlers import install_exception_handlers
from __package__.api.v1 import router as v1_router
from __package__.core.config import get_settings
from __package__.core.logging import configure_logging
from __package__.core.observability import setup_observability
from __package__.infrastructure.db.session import dispose_engine, init_engine


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    settings = get_settings()
    configure_logging(settings.log_level)
    init_engine(settings.database_url)
    try:
        yield
    finally:
        await dispose_engine()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
    )

    if settings.cors_origins_list:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins_list,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    install_exception_handlers(app)
    setup_observability(
        app,
        service_name=settings.otel_service_name,
        otlp_endpoint=settings.otel_exporter_otlp_endpoint,
        sentry_dsn=settings.sentry_dsn,
    )

    app.include_router(v1_router, prefix=f"{settings.api_prefix}/v1")
    return app


app = create_app()
