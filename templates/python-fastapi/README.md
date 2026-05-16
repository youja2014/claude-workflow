# __project_name__

__description__

## Quickstart

```bash
cp .env.example .env
make install
make docker-up        # postgres
make migrate-up
make run              # http://localhost:8000
```

## Tests

```bash
make test-unit         # fast, no docker
make test-integration  # needs docker
make test-e2e
```

See `CLAUDE.md` for architecture rules and Definition of Done.
