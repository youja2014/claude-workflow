from __future__ import annotations

from fastapi import APIRouter

from __package__.api.v1.routes import health, users

router = APIRouter()
router.include_router(health.router)
router.include_router(users.router)
