# pyright: reportMissingImports=false, reportUnknownMemberType=false, reportUnknownVariableType=false, reportUnknownArgumentType=false
"""Optional observability hooks (OpenTelemetry + Sentry).

All packages here are optional extras — install only when needed:

    uv add 'opentelemetry-distro[otlp]' \
           opentelemetry-instrumentation-fastapi \
           opentelemetry-instrumentation-sqlalchemy \
           opentelemetry-instrumentation-httpx
    uv add 'sentry-sdk[fastapi]'

`setup_observability` is a no-op when the relevant env vars are empty, so it
is safe to call unconditionally from `main.py`.
"""

from __future__ import annotations

import logging

from fastapi import FastAPI

logger = logging.getLogger(__name__)


def setup_observability(
    app: FastAPI, *, service_name: str, otlp_endpoint: str, sentry_dsn: str
) -> None:
    if otlp_endpoint:
        _setup_otel(app, service_name=service_name or "__package__")
    if sentry_dsn:
        _setup_sentry(sentry_dsn)


def _setup_otel(app: FastAPI, *, service_name: str) -> None:
    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import (
            OTLPSpanExporter,
        )
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
    except ImportError:
        logger.warning(
            "OTEL_EXPORTER_OTLP_ENDPOINT set but opentelemetry packages not installed; "
            "install with: uv add 'opentelemetry-distro[otlp]' opentelemetry-instrumentation-fastapi"
        )
        return

    resource = Resource.create({"service.name": service_name})
    provider = TracerProvider(resource=resource)
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(provider)
    FastAPIInstrumentor.instrument_app(app)

    for module_path, instrumentor_class in (
        ("opentelemetry.instrumentation.sqlalchemy", "SQLAlchemyInstrumentor"),
        ("opentelemetry.instrumentation.httpx", "HTTPXClientInstrumentor"),
    ):
        try:
            module = __import__(module_path, fromlist=[instrumentor_class])
            getattr(module, instrumentor_class)().instrument()
        except ImportError:
            pass


def _setup_sentry(sentry_dsn: str) -> None:
    try:
        import sentry_sdk
    except ImportError:
        logger.warning(
            "SENTRY_DSN set but sentry-sdk not installed; install with: uv add 'sentry-sdk[fastapi]'"
        )
        return

    sentry_sdk.init(dsn=sentry_dsn, traces_sample_rate=0.1)
