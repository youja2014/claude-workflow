# Documentation Index

이 폴더는 프로젝트의 **안정 정보**(아키텍처/디자인/도메인)와 **변화 정보**(계획/결정/현황/인계)를 보관합니다. 단일 거대 CLAUDE.md 의 비대화를 막고 워크플로우 단계별로 위치를 분리하는 것이 목적입니다.

## 카테고리

| 항목 | 용도 | 갱신 빈도 |
|---|---|---|
| [`architecture.md`](./architecture.md) | 폴더 구조 + 라이브러리 선택 근거 | 구조 변경 시 |
| [`status.md`](./status.md) | 현재 진행 상황 한 페이지 | 퇴근 시 |
| [`design/`](./design/) | frontend UI/UX 문서 (mockup, 컴포넌트 가이드) | 디자인 결정 시 |
| [`domain/`](./domain/) | 도메인 용어 / 모델 / 비즈니스 룰 / 도메인 ERD (`erd.md`) | 도메인 학습/변경 시 |
| [`plans/`](./plans/) | `goals.md`(장기) / `wbs.md`(작업 분할) / `exec-plans/<feature>.md`(기능별 계획) | 출근·계획 단계 |
| [`decisions/`](./decisions/) | ADR (immutable, `NNNN-<topic>.md`) | 의사결정 시 |
| [`handoffs/`](./handoffs/) | 세션 인계 (`YYYY-MM-DD.md`, 누적) | 퇴근 시 |

## 워크플로우 매핑 (출근 → 퇴근)

| 단계 | 읽음 | 씀 |
|---|---|---|
| 출근 | `handoffs/<최신>`, `status.md`, `plans/wbs.md`, `decisions/*` | — |
| 계획 수립 | `architecture.md`, `domain/*`, `decisions/*` | `plans/exec-plans/<feature>.md` |
| 계획 검증 | `decisions/*` (충돌 검사) | 필요 시 `decisions/NNNN-*.md` 신규 |
| 개발 / 테스트 | 각 폴더의 `CLAUDE.md` (frontend/backend/infra/library 별) | 코드 |
| 퇴근 | `status.md` | `handoffs/<오늘>.md` + `status.md` 갱신 |

## 폴더별 CLAUDE.md (영역 특화 규칙)

광역 규칙은 루트 `CLAUDE.md`, 영역 특화 규칙은 해당 폴더의 `CLAUDE.md`. 예:

- `src/<package>/api/CLAUDE.md` — FastAPI 라우터/DTO 영역 (있다면)
- `src/<package>/application/CLAUDE.md` — use case 영역 (있다면)
- `src/<package>/domain/CLAUDE.md` — 도메인 영역 (Protocol 중심)
- `src/<package>/infrastructure/CLAUDE.md` — DB/외부 어댑터 영역 (있다면)
- `infra/CLAUDE.md` — 인프라 정의 (있다면)

단일 패키지 프로젝트라 sub-package 분리가 자연스럽지 않다면 광역 `CLAUDE.md` 하나로 충분.

규칙: **어디서 읽을지가 명확해야 한다.** 광역 규칙을 영역 md 에 중복 적기 금지. 영역 md 는 그 폴더에서만 의미 있는 규칙만.
