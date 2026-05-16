from __future__ import annotations

from datetime import UTC, datetime

import pytest

from __package__.application.users.create_user import (
    CreateUserCommand,
    CreateUserUseCase,
)
from __package__.domain.entities.user import User
from __package__.domain.exceptions import EmailAlreadyTakenError


class _FakeUserRepo:
    def __init__(self) -> None:
        self._by_email: dict[str, User] = {}
        self._next_id: int = 1

    async def get_by_id(self, user_id: int) -> User | None:
        for u in self._by_email.values():
            if u.id == user_id:
                return u
        return None

    async def get_by_email(self, email: str) -> User | None:
        return self._by_email.get(email)

    async def add(self, user: User) -> User:
        stored = User(
            id=self._next_id,
            email=user.email,
            name=user.name,
            created_at=user.created_at,
        )
        self._next_id += 1
        self._by_email[stored.email] = stored
        return stored


@pytest.mark.unit
async def test_create_user_persists_new_user() -> None:
    repo = _FakeUserRepo()
    use_case = CreateUserUseCase(repo)

    result = await use_case.execute(
        CreateUserCommand(email="alice@example.com", name="Alice")
    )

    assert result.id == 1
    assert result.email == "alice@example.com"
    assert result.created_at <= datetime.now(UTC)


@pytest.mark.unit
async def test_create_user_rejects_duplicate_email() -> None:
    repo = _FakeUserRepo()
    use_case = CreateUserUseCase(repo)
    await use_case.execute(CreateUserCommand(email="dup@x.com", name="A"))

    with pytest.raises(EmailAlreadyTakenError):
        await use_case.execute(CreateUserCommand(email="dup@x.com", name="B"))
