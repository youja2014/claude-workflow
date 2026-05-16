from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime

from __package__.domain.entities.user import User
from __package__.domain.exceptions import EmailAlreadyTakenError
from __package__.domain.repositories.user_repository import UserRepository


@dataclass(frozen=True)
class CreateUserCommand:
    email: str
    name: str


class CreateUserUseCase:
    def __init__(self, users: UserRepository) -> None:
        self._users = users

    async def execute(self, cmd: CreateUserCommand) -> User:
        existing = await self._users.get_by_email(cmd.email)
        if existing is not None:
            raise EmailAlreadyTakenError(cmd.email)
        user = User(
            id=0,  # repository assigns
            email=cmd.email,
            name=cmd.name,
            created_at=datetime.now(UTC),
        )
        return await self._users.add(user)
