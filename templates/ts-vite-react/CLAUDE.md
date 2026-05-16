# __project_name__ — Project Context for Claude

## 정체성

- **유형**: Vite + React 19 SPA (TypeScript)
- **라우터**: react-router v7 (Declarative mode — SPA static build)
- **서버 상태**: TanStack Query v5
- **클라이언트 상태**: Zustand v5
- **폼**: React Hook Form + Zod
- **스타일**: Tailwind CSS
- **빌드/배포**: nginx multi-stage Docker

## 아키텍처 (Feature-Sliced Design lite)

```
src/
├── app/         # 앱 초기화 (providers, router, index.tsx)
├── pages/       # 라우트별 페이지
├── widgets/     # 합성 블록 (필요 시)
├── features/    # 사용자 가치 단위 (login, add-to-cart)
├── entities/    # 비즈니스 엔티티 (user, product)
└── shared/      # 디자인 시스템, API 클라이언트, lib, config
```

의존 방향 (상위 → 하위만):
```
app → pages → widgets → features → entities → shared
```

같은 레이어 간 직접 import 금지 (features끼리 X). 각 슬라이스는 `index.ts` public API만 노출.

## 상태 분리

| 종류 | 도구 | 위치 |
|---|---|---|
| 서버 상태 | TanStack Query | `features/<x>/api/use-*.ts` |
| 클라이언트 | Zustand | `features/<x>/model/store.ts` |
| 폼 | RHF + Zod | 폼 컴포넌트 |
| URL | React Router | 페이지 컴포넌트 |

## 새 feature 추가

`/skill react-add-feature` 호출 권장. `features/<name>/{api,model,ui}` + `index.ts` 자동 생성 + FSD 의존 방향 검증.

## Definition of Done

1. **계획 명시**: commit message
2. **참조 확인**: 추가/변경한 컴포넌트/훅이 실제 사용됨
3. **테스트**:
   - `*.spec.tsx` — Vitest + Testing Library (단위)
   - `test/e2e/` — Playwright (e2e)
4. **로컬 검증**:
   ```bash
   yarn lint && yarn typecheck && yarn test && yarn build && yarn docker:build
   ```
5. **브라우저 확인**: 골든패스 + 엣지케이스 실제 클릭 (`yarn dev`)
6. **자가 리뷰**: `git diff` 적대적 시각

## 절대 하지 말 것

- features 간 직접 import (entities/shared로 끌어내리기)
- 컴포넌트 안에서 `fetch` 직접 호출 (api 훅으로 분리)
- 글로벌 Context로 서버 상태 관리 (TanStack Query로)
- Atomic Design 전면 도입 (`shared/ui/` 에만 디자인 시스템으로)
- `--no-verify` husky 우회
- npm 사용 (yarn 전용)

## 주요 명령

```bash
yarn install
yarn dev               # http://localhost:5173
yarn build             # 정적 빌드 (dist/)
yarn docker:build      # nginx 이미지
yarn test:e2e          # Playwright
```

## 참조

- `~/.claude/rules/typescript/style.md`, `typescript/testing.md`, `typescript/docker.md`
- `~/.claude/rules/typescript/react.md` — 이 스택 전용 룰
- `~/.claude/skills/react-add-feature/SKILL.md`
