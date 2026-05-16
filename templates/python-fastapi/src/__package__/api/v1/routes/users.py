from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status

from __package__.api.schemas.user import UserCreateRequest, UserResponse
from __package__.api.v1.deps import get_create_user_use_case
from __package__.application.users.create_user import (
    CreateUserCommand,
    CreateUserUseCase,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreateRequest,
    use_case: Annotated[CreateUserUseCase, Depends(get_create_user_use_case)],
) -> UserResponse:
    user = await use_case.execute(
        CreateUserCommand(email=payload.email, name=payload.name)
    )
    return UserResponse(
        id=user.id, email=user.email, name=user.name, created_at=user.created_at
    )
