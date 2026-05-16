# __project_name__

Nx 모노레포 (apps/api: NestJS, apps/web: Vite+React, libs/shared-types: 공유 타입).

## 빠른 시작

```bash
yarn install
yarn nx serve api      # http://localhost:3000/health
yarn nx serve web      # http://localhost:5173
yarn graph             # 의존 그래프 시각화
```

Docker:
```bash
make docker-build && make docker-up
```

## 의존 방향 (enforce-module-boundaries)

`eslint.config.mjs` 가 ESLint 룰로 강제:

| sourceTag | onlyDependOnLibsWithTags |
|---|---|
| `scope:api` | `scope:api`, `scope:shared` |
| `scope:web` | `scope:web`, `scope:shared` |
| `scope:shared` | `scope:shared` |
| `type:app` | `type:feature`, `type:util` |
| `type:feature` | `type:feature`, `type:util` |
| `type:util` | `type:util` |

위반 시 `yarn lint` 가 실패. 새 라이브러리 추가 시 `project.json` 의 `tags` 를 반드시 명시.

## 새 라이브러리 추가

```bash
# 백엔드 전용 feature lib
yarn nx g @nx/js:lib libs/api-feature-orders --tags=scope:api,type:feature

# 양쪽에서 쓰는 유틸
yarn nx g @nx/js:lib libs/shared-utils --tags=scope:shared,type:util
```

## 명령 요약

| 명령 | 동작 |
|---|---|
| `yarn lint` | 전 프로젝트 lint + boundaries 검사 |
| `yarn typecheck` | 전 프로젝트 tsc --noEmit |
| `yarn test` | 전 프로젝트 테스트 |
| `yarn build` | 전 앱 빌드 |
| `yarn nx affected -t lint test build` | 변경된 것만 |
| `yarn graph` | 의존 그래프 (브라우저) |

## 참조

- `~/.claude/rules/typescript/*.md`
- Nx docs: https://nx.dev
- enforce-module-boundaries: https://nx.dev/recipes/enforce-module-boundaries
