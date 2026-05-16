# __project_name__

__description__

## Quickstart

```bash
cp .env.example .env
yarn install
yarn dev               # http://localhost:5173
```

## Build & Deploy

```bash
yarn build             # outputs dist/ (static)
yarn docker:build      # nginx image
yarn docker:up         # http://localhost:8080
```

## Tests

```bash
yarn test              # Vitest
yarn test:e2e          # Playwright
```

See `CLAUDE.md` for FSD architecture rules.
