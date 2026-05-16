# __project_name__ — Project Context for Claude

## 정체성

- **유형**: Nx 모노레포 (yarn 4, integrated)
- **apps/api**: NestJS 10 (포트 3000, `/health`)
- **apps/web**: Vite + React 19 SPA (포트 5173)
- **libs/shared-types**: 양쪽이 import 하는 공유 타입 (`HealthStatus` 등)

## 문서 위치

이 `CLAUDE.md` 는 *광역 불변 정책* (의존 방향, 절대 하지 말 것, DoD)만 둡니다. 변화하는 정보(계획/현황/의사결정/인계) 와 영역별 가이드는 `docs/` 에서 관리합니다. 진입점: [`docs/README.md`](./docs/README.md).

## 구조

```
apps/
├── api/        scope:api, type:app   — NestJS controller + DI
└── web/        scope:web, type:app   — Vite + React SPA

libs/
└── shared-types/  scope:shared, type:util  — 양 앱 공유 타입

eslint.config.mjs   ← @nx/enforce-module-boundaries (의존 방향 강제)
nx.json             ← target defaults + caching
tsconfig.base.json  ← workspace paths: @<project>/shared-types 등
```

## 의존 방향 (ESLint 가 강제, 위반 시 lint fail)

```
scope:api ──▶ scope:shared ◀── scope:web
```

- `scope:api` 는 `scope:api`, `scope:shared` 만 import 가능
- `scope:web` 는 `scope:web`, `scope:shared` 만 import 가능
- `scope:shared` 는 다른 shared 만 가능 (외부 의존성은 OK)

따라서 `apps/web` 이 `apps/api` 의 코드를 직접 import 하는 건 불가능. 공통 코드는 반드시 `libs/shared-*` 로 분리.

## 새 라이브러리 / feature 추가

```bash
# Nx 생성기 사용 (project.json + tsconfig + tags 자동)
yarn nx g @nx/js:lib libs/<name> --tags=scope:<api|web|shared>,type:<feature|util>
```

수동으로 만들면 `project.json` 의 `"tags"` 를 반드시 채울 것. 빈 tags 는 boundary 검사 우회로 이어짐.

## Definition of Done

1. **계획 명시**: commit message
2. **참조 확인**: 추가/변경한 export 가 실제 사용됨
3. **테스트**: 단위(jest/vitest) + e2e (Playwright 또는 supertest)
4. **로컬 검증**:
   ```bash
   make lint && make typecheck && make test && make build
   ```
5. **affected only**: 큰 변경 후엔 `yarn nx affected -t lint test build` 로 회귀 확인
6. **자가 리뷰**: `git diff` 적대적 시각

## 절대 하지 말 것

- `apps/web` 에서 `apps/api` import (boundary 위반 — 공통은 `libs/shared-*` 로)
- `project.json` 의 `tags` 누락 (boundary 검사 우회로 이어짐)
- 한 프로젝트가 다른 프로젝트 디렉토리를 상대경로(`../../apps/...`)로 import — 반드시 `@<project>/<lib>` 워크스페이스 path
- npm 사용 (yarn 전용)
- `--no-verify` 로 git hook 우회 (`.githooks/commit-msg`, `pre-commit`, `pre-push`)
- `libs/shared-types` 에 런타임 코드 추가 (타입/인터페이스 전용 유지). 런타임 값 공유가 필요하면 `libs/shared-utils` 같은 새 라이브러리를 만들고 해당 app `package.json` 의 `dependencies` 에 추가할 것. 이유: shared-types는 컴파일 타임에 erase 되므로 api `devDependencies` 에만 두어 Nx 의 `generatePackageJson` 이 `workspace:*` 를 production 의존성에 포함하지 않게 함.

## 주요 명령

```bash
yarn install
yarn nx serve api          # NestJS dev
yarn nx serve web          # Vite dev
yarn graph                 # 브라우저로 의존 그래프
yarn nx affected -t test   # 변경된 것만 테스트
make docker-up             # postgres + api + web 컨테이너
```

## 참조

- `~/.claude/rules/typescript/style.md`, `typescript/testing.md`, `typescript/docker.md`
- `~/.claude/rules/typescript/nestjs.md` — apps/api 관련
- `~/.claude/rules/typescript/react.md` — apps/web 관련
- Nx 공식: https://nx.dev
