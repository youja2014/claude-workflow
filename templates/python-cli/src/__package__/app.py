from __future__ import annotations

import typer

from __package__.commands import hello as hello_cmd
from __package__.commands import version as version_cmd

app = typer.Typer(
    name="__project_kebab__",
    help="__description__",
    no_args_is_help=True,
    add_completion=False,
)

app.command(name="hello")(hello_cmd.run)
app.command(name="version")(version_cmd.run)


def main() -> None:
    app()


if __name__ == "__main__":
    main()
