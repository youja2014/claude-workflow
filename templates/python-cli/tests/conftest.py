from __future__ import annotations

import pytest
from typer.testing import CliRunner

__all__ = ["CliRunner"]


@pytest.fixture
def cli() -> CliRunner:
    return CliRunner()
