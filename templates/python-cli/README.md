# __project_name__

__description__

## Quickstart

```bash
make install
make test
make run ARGS="--help"
```

## Docker

```bash
make docker-build
docker run --rm __project_kebab__:latest --help
```

## Project layout

```
src/__package__/
├── app.py          # Typer entrypoint
├── commands/       # CLI subcommands (interface layer)
├── core/           # Pure business logic
├── adapters/       # I/O adapters
└── config.py       # Settings (pydantic-settings)
```

See `CLAUDE.md` for the full architecture rules and Definition of Done.
