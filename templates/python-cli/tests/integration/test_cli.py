from __future__ import annotations

from typer.testing import CliRunner

from __package__.app import app


def test_hello_default(cli: CliRunner) -> None:
    result = cli.invoke(app, ["hello"])
    assert result.exit_code == 0
    assert "Hello, world!" in result.stdout


def test_hello_with_name(cli: CliRunner) -> None:
    result = cli.invoke(app, ["hello", "Claude"])
    assert result.exit_code == 0
    assert "Hello, Claude!" in result.stdout


def test_hello_shout(cli: CliRunner) -> None:
    result = cli.invoke(app, ["hello", "Claude", "--shout"])
    assert result.exit_code == 0
    assert "HELLO, CLAUDE!" in result.stdout


def test_version_command_prints_version(cli: CliRunner) -> None:
    result = cli.invoke(app, ["version"])
    assert result.exit_code == 0
    assert "0.1.0" in result.stdout
