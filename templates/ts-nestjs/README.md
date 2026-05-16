# __project_name__

__description__

## Quickstart

```bash
cp .env.example .env
yarn install
yarn docker:up           # postgres
yarn prisma:migrate
yarn start:dev           # http://localhost:3000
```

## Tests

```bash
yarn test                # 단위 (Jest)
yarn test:e2e            # e2e (supertest)
```

See `CLAUDE.md` for architecture and Definition of Done.
