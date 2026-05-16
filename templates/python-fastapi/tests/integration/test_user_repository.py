from __future__ import annotations

import pytest

pytestmark = pytest.mark.integration


@pytest.mark.skip(reason="example; enable when testcontainers is configured")
async def test_user_repository_round_trip() -> None:
    # Wire up testcontainers-postgres here, then exercise SqlAlchemyUserRepository.
    raise NotImplementedError
