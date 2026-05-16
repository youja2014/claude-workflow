from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from __package__.application.users.create_user import CreateUserUseCase
from __package__.domain.repositories.user_repository import UserRepository
from __package__.infrastructure.db.repositories.user_repository import (
    SqlAlchemyUserRepository,
)
from __package__.infrastructure.db.session import get_session


def get_user_repo(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> UserRepository:
    return SqlAlchemyUserRepository(session)


def get_create_user_use_case(
    users: Annotated[UserRepository, Depends(get_user_repo)],
) -> CreateUserUseCase:
    return CreateUserUseCase(users)
