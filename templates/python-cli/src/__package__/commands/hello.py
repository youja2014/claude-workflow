from __future__ import annotations

from typing import Annotated

import typer
from rich.console import Console

from __package__.core.greeting import build_greeting

console = Console()


def run(
    name: Annotated[str, typer.Argument(help="Who to greet.")] = "world",
    shout: Annotated[bool, typer.Option("--shout", help="Uppercase output.")] = False,
) -> None:
    """Print a greeting."""
    message = build_greeting(name=name, shout=shout)
    console.print(message)
