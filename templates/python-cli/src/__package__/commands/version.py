from __future__ import annotations

from rich.console import Console

from __package__ import __version__

console = Console()


def run() -> None:
    """Print the package version."""
    console.print(__version__)
