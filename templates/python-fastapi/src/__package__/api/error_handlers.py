from __future__ import annotations

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

from __package__.domain.exceptions import (
    DomainError,
    EmailAlreadyTakenError,
    UserNotFoundError,
)

_STATUS_MAP: dict[type[DomainError], int] = {
    UserNotFoundError: status.HTTP_404_NOT_FOUND,
    EmailAlreadyTakenError: status.HTTP_409_CONFLICT,
}


def _problem_response(
    request: Request, exc: DomainError, http_status: int
) -> JSONResponse:
    return JSONResponse(
        status_code=http_status,
        content={
            "type": f"about:blank#{exc.__class__.__name__}",
            "title": exc.__class__.__name__,
            "status": http_status,
            "detail": str(exc),
            "instance": str(request.url.path),
        },
    )


async def domain_error_handler(request: Request, exc: Exception) -> JSONResponse:
    # FastAPI dispatches by isinstance against the registered class, so the
    # runtime type is always DomainError here. Use an explicit check (not assert)
    # because asserts are stripped under `python -O`.
    if not isinstance(exc, DomainError):
        raise TypeError(
            f"domain_error_handler invoked with non-DomainError: {type(exc).__name__}"
        )
    http_status = _STATUS_MAP.get(type(exc), status.HTTP_400_BAD_REQUEST)
    return _problem_response(request, exc, http_status)


def install_exception_handlers(app: FastAPI) -> None:
    """Register global handlers that map domain errors to RFC 7807-like JSON."""
    app.add_exception_handler(DomainError, domain_error_handler)
