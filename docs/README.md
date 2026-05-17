# Documentation Index — claude-workflow

이 폴더는 메타 프로젝트(`claude-workflow`) 의 **안정 정보**(아키텍처/도메인)와 **변화 정보**(계획/결정/현황/인계)를 보관합니다.

> **왜 메타 프로젝트에 docs/ 가 있는가?** 본 프로젝트의 정체성은 "신규+기존 프로젝트 어디에든 안전하게 적용 가능한 메타 시스템". 본인 프로젝트는 명확히 "기존" 카테고리이므로 자기 정체성을 위반하지 않으려면 자체 docs/ 가 있어야 한다. (ADR-0001 참조)

## 카테고리

| 항목 | 용도 | 갱신 빈도 |
|---|---|---|
| [`architecture.md`](./architecture.md) | harness/templates/scripts 구조 + 자산 책임 매트릭스 | 구조 변경 시 |
| [`status.md`](./status.md) | 현재 진행 상황 한 페이지 | 퇴근 시 |
| [`coverage-matrix.md`](./coverage-matrix.md) | stack × asset 매트릭스 (Phase 3 산출물) | 자산 추가/제거 시 |
| [`design/`](./design/) | N/A — 메타 프로젝트는 UI 없음 | (사용 안 함) |
| [`domain/`](./domain/) | 메타 도메인 용어 (rules/agents/skills/hooks 의미) | 어휘 추가 시 |
| [`plans/`](./plans/) | `wbs.md` (작업 분할) + `exec-plans/<feature>.md` | 출근·계획 단계 |
| [`decisions/`](./decisions/) | ADR (immutable, `NNNN-<topic>.md`) | 의사결정 시 |
| [`handoffs/`](./handoffs/) | 세션 인계 (`YYYY-MM-DD.md`) | 퇴근 시 |

## 워크플로우 매핑 (출근 → 퇴근)

| 단계 | 읽음 | 씀 |
|---|---|---|
| 출근 | `handoffs/<최신>`, `status.md`, `plans/wbs.md`, `decisions/*` | — |
| 계획 수립 | `architecture.md`, `domain/*`, `decisions/*` | `plans/exec-plans/<feature>.md` |
| 계획 검증 | `decisions/*` (충돌 검사) | 필요 시 `decisions/NNNN-*.md` 신규 |
| 개발 / 검증 | `~/.claude/rules/`, `harness/global/` 자산 | 코드 |
| 퇴근 | `status.md` | `handoffs/<오늘>.md` + `status.md` 갱신 |

## memory/ 와의 역할 분리 (ADR-0001 부속)

- **`memory/`** (`~/.claude/projects/.../memory/`) — Claude 의 cross-session **학습된 정책/패턴/사용자 프로필**. 시간 무관, 정책성.
- **`docs/handoffs/`** — **시간순 작업 인계**. 누가 무엇을 결정·실행했는지의 timeline.
- **`docs/decisions/`** — **immutable 결정 기록 (ADR)**. memory 의 정책성 항목 중 영구 보존이 필요한 것은 ADR 로 승격.

memory 가 cumulative 하게 비대해지는 것은 anti-pattern. 시간순 흐름은 handoffs/, 영구 결정은 decisions/.
