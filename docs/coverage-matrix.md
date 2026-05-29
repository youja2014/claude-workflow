# Coverage Matrix — stack × asset

본 메타 프로젝트의 자산이 각 stack 에 얼마나 적용 가능한지 명시. **빈칸 = 미구현 갭**. ✅ = 정식 지원, △ = 개념적 사용 가능 (본문 보강 권장), ❌ = 사용 불가, N/A = 의도적 비적용, — = 해당 없음.

자산 통계 (2026-05-17 기준): rules 13 / agents 6 / skills 11 / hooks 2 / templates 3 = **총 35**.

## Rules — 14 (`harness/global/rules/`)

| Asset | general | python-cli | python-fastapi | ts-nx (api) | ts-nx (web) | 비고 |
|---|---|---|---|---|---|---|
| `common/code-quality.md` | ✅ | — | — | — | — | DRY/KISS/YAGNI/네이밍 |
| `common/git.md` | ✅ | — | — | — | — | Conventional Commits. **브랜치 type 목록 명시 누락 (P1)** |
| `common/security.md` | ✅ | — | — | — | — | 시크릿/입력/의존성/로깅 |
| `common/agentic-workflow.md` | ✅ | — | — | — | — | 컨텍스트 관리/서브에이전트 깊이-1/멀티에이전트 기준/모델 티어링 (ADR-0004) |
| `python/style.md` | — | ✅ | ✅ | N/A | N/A | 타입 힌트/비동기/Import |
| `python/testing.md` | — | ✅ | ✅ | N/A | N/A | pytest/fixture/mock |
| `python/docker.md` | — | ✅ | ✅ | N/A | N/A | python:3.12-slim, uv |
| `python/cli.md` | — | ✅ | — | N/A | N/A | Typer 3-layer |
| `python/fastapi.md` | — | — | ✅ | N/A | N/A | 4-layer hexagonal-lite |
| `typescript/style.md` | — | N/A | N/A | ✅ | ✅ | strict TS, as const enum |
| `typescript/testing.md` | — | N/A | N/A | ✅ | ✅ | Vitest/Jest/supertest |
| `typescript/docker.md` | — | N/A | N/A | ✅ | ✅ | node:22-alpine. **EOL 메타 + npm Exit handler 워크어라운드 누락 (P1)** |
| `typescript/nestjs.md` | — | — | — | ✅ | — | 모듈별 헥사고날 |
| `typescript/react.md` | — | — | — | — | ✅ | FSD lite |

**Rules 갭**: 0 (모든 stack 이 자기 영역의 rules 를 가짐). 단 `common/git.md`, `typescript/docker.md` 의 **메타데이터 보강** 필요 (Phase 5 P1).

## Agents — 6 (`harness/global/agents/`)

| Asset | python | typescript | 비고 |
|---|---|---|---|
| `architect.md` | ✅ | **❌ (P0)** | 본문 "Python 시스템 아키텍트" 한정. `src/<package>/` 구조도 Python |
| `code-reviewer.md` | ✅ | **❌ (P0)** | 본문 "시니어 Python 코드 리뷰어" 한정. 체크리스트는 언어 무관이나 명시 Python |
| `build-error-resolver.md` | ✅ | **❌ (P0)** | uv/ruff/pyright/docker-compose 진단 명령 Python 한정 |
| `tdd-guide.md` | ✅ | △ | description 무관. **본문 예시 Python 만 — TS 예시 추가 권장 (P1)** |
| `clean-arch-detector.md` | ✅ FastAPI | ✅ NestJS | 양쪽 명시 — frontmatter 에 "Python 또는 TypeScript" |
| `fsd-violation-detector.md` | — | ✅ React | TS 전용 |

**Agents 갭**:
- **P0 (3건)**: architect / code-reviewer / build-error-resolver 의 TS 변형. 사용자 7th 세션 지적 사항
- **P1 (1건)**: tdd-guide 본문에 TS 예시 추가

**처방 방식 결정**: 본문에 `## TypeScript variant` 섹션 추가 (별도 파일 분리하지 않음). 이유:
- 별도 `architect-ts.md` 등으로 분리 시 frontmatter `description` 도 분리되어 동일 위임 시 둘 다 매칭 가능 → 혼선
- 본문 단일 + 언어별 섹션이 검색/유지보수 단순
- agents 디렉토리 파일 수 증가 안 함

## Skills — 11 (`harness/global/skills/`)

| Asset | general | python-cli | python-fastapi | ts-nx | 비고 |
|---|---|---|---|---|---|
| `context-restore` | ✅ | ✅ | ✅ | ✅ | lifecycle. docs/handoffs/ 의존 |
| `context-save` | ✅ | ✅ | ✅ | ✅ | lifecycle |
| `plan` | ✅ | ✅ | ✅ | ✅ | lifecycle. architect agent 위임 |
| `code-review` | ✅ | ✅ | ✅ | ✅ | lifecycle. code-reviewer agent 위임 |
| `build-fix` | ✅ | ✅ | ✅ | ✅ | `## 6b. TypeScript variant` 섹션 (commit `0b16187` + 일관성 보강) |
| `security-scan` | ✅ | ✅ | ✅ | ✅ | `## 6b. TypeScript variant` 섹션 + VITE_* 누설 d-1 (commit `0b16187` + 일관성 보강) |
| `tdd` | ✅ | ✅ | ✅ | ✅ | `## 5b. TypeScript variant` 섹션 (commit `0b16187`) |
| `scaffold` | ✅ | ✅ | ✅ | ✅ | 신규/기존 자동 감지. 3 스택 |
| `fastapi-add-module` | — | — | ✅ | N/A | 4-layer 모듈 추가 |
| `nestjs-add-module` | — | — | N/A | ✅ (apps/api) | 헥사고날 + Prisma |
| `react-add-feature` | — | — | N/A | ✅ (apps/web) | FSD 슬라이스 |

**Skills 갭**: 0 (P1 3건 모두 해결됨, commit `0b16187` + 일관성 후속).
- 의도적 N/A: stack-specific add-module 은 그 stack 만 (정상)

## Hooks — 2 (`harness/global/hooks/`)

| Asset | matcher | 검증 | 비고 |
|---|---|---|---|
| `block-dangerous.sh` | PreToolUse: Bash | ✅ | --no-verify / push --force / rm -rf 등 차단 |
| `format-on-save.sh` | PostToolUse: Write\|Edit | ✅ (2026-05-17 패치) | dirname 무한 루프 fix (`7896766`) |

**Hooks 갭**: 0. 단 self-test 패턴 부재 — Phase 4 후속 검토 항목 (`make test-hooks` 가능성).

## Templates — 3 (`templates/`)

| Stack | 존재 | 빌드 검증 | 비고 |
|---|---|---|---|
| `python-cli` | ✅ | (마지막 `make verify` PASS) | Typer + uv |
| `python-fastapi` | ✅ | 동상 | FastAPI + SQLAlchemy 2.0 + Alembic |
| `ts-nx` | ✅ | 동상 | Nx 모노레포 (NestJS API + Vite React Web) |

**Templates 갭**: 0.

## Phase 5 우선순위 (매트릭스 결과 → 1-3 작업 매핑)

본 매트릭스에서 도출된 P0/P1 항목을 Phase 5 의 작업 순서로 매핑:

| # | 작업 | 우선순위 | 영향 자산 |
|---|---|---|---|
| 1 | git.md 브랜치 type 목록 명시 (1줄 패치) | P1 | `rules/common/git.md` |
| 2 | typescript/docker.md EOL 메타 + npm "Exit handler" 워크어라운드 명문화 | P1 | `rules/typescript/docker.md` |
| 3a | **architect TS variant** | **P0** | `agents/architect.md` |
| 3b | **code-reviewer TS variant** | **P0** | `agents/code-reviewer.md` |
| 3c | **build-error-resolver TS variant** | **P0** | `agents/build-error-resolver.md` |
| 3d | tdd-guide TS 예시 보강 | P1 | `agents/tdd-guide.md` |
| 3e | skills build-fix / security-scan / tdd 의 TS dispatch 분기 | P1 ✅ | `skills/build-fix/SKILL.md` 외 (commit `0b16187` + 일관성 보강) |

**처방 방식 (재확인)**: agents 본문에 `## TypeScript variant` 섹션 추가. 별도 파일 분리하지 않음.

## 미해결 후속

- **make test-hooks** — 본 세션 format-on-save bug 발견을 일반화. 모든 hook 의 stdin JSON 테스트 케이스 정의 (Phase 4 후속 또는 별도 트랙)
- **memory ADR → repo ADR 승격** — memory ADR-001/002/003 중 영구 보존 가치 있는 항목 (Phase 2 후속 검토 항목)
- **Python 3.13 / Node 24 검토** — Phase 4 `make eol-check` 결과 활용 (2026-10 Node 22 maintenance 진입, 2027-04 EOL)

## 참조

- 본 매트릭스의 동기: `docs/handoffs/2026-05-17.md` 갭 카테고리 #2 (Coverage 갭)
- 실행 계획: `docs/plans/exec-plans/2026-05-17-self-adoption.md` Phase 3 + 5
- 의존 결정: `docs/decisions/0001-self-application.md`, `0002-documentation-first.md`
