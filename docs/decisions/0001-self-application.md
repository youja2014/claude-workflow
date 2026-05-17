# 0001. Self-application — 메타 프로젝트에 자기 정체성 적용

- **Status**: Accepted
- **Date**: 2026-05-17

## Context

`claude-workflow` 의 한 줄 정체성:

> "신규+기존 프로젝트 어디에든 안전하게 적용 가능하게 만드는 메타 시스템"

그런데 본 프로젝트 자체는 (2026-05-17 7th 세션 진단 시점):

- git repo 존재 (24 커밋 누적)
- 명확히 "기존" 카테고리
- 그러나 `docs/{architecture, status, plans, decisions, handoffs, domain, design}/` 부재
- 사용자 워크플로 (`memory/user_workflow.md`) 의 docs/ 7 카테고리 표준이 적용 안 됨
- `/scaffold` existing 모드를 본인에게 한 번도 실행 안 함

즉 메타 시스템이 자기 정체성을 본인에게 적용하지 않음. 결과:

1. 세션 인계가 memory cumulative 로만 존재 (`project_session_handoff.md` 에 3rd~6th 누적) → 정보 압축 손실
2. status / plans 가 git log + memory 에 흩어짐 → 출근 시 컨텍스트 복원 비효율
3. 결정의 immutable timeline 없음 → 같은 결정 반복 검토 가능성

이 갭이 라이프사이클 자산 흡수 지연 (memory ADR-003), TS agent 변형 누락, Node EOL 모니터링 부재 등 다른 갭들의 root cause 로 작용한다고 판단 (본 세션 갭 진단의 카테고리 #3, `docs/handoffs/2026-05-17.md` 참조).

## Decision

메타 프로젝트에 `docs/` 7 카테고리 (README + architecture + status + design + domain + plans + decisions + handoffs) 를 부트스트랩 (Phase 1, commit `baab97a`).

memory 와 docs/ 의 역할을 명시 분리하고 `CLAUDE.md` 의 "정보 분류" 섹션에 명문화:

- **memory**: cross-session 학습된 정책 / 사용자 프로필 (정책성, 시간 무관)
- **docs/handoffs/**: 시간순 작업 timeline (immutable)
- **docs/decisions/**: immutable 결정 기록 (ADR)
- **docs/ 그 외**: 안정 정보 (architecture/domain) + 변화 정보 (status/plans)

## Alternatives

### A. 현 상태 유지 (memory + git log + ad-hoc)

- 장점: 추가 명문화 비용 없음
- 단점: 정체성 위반 지속. 같은 갭 누적 가능성. 사용자 워크플로 자기 검증 실패
- **탈락 사유**: 사용자 결정 "애매모호 진행 안 함, 명확한 명문화 우선" (ADR-0002 의 전제)

### B. memory 만 확장 (docs/ 없이)

- 장점: 작업 위치 분산 없음
- 단점: cumulative anti-pattern 강화. Phase 2-5 산출물 (ADR / coverage-matrix / eol-check 결과) 둘 곳 없음
- **탈락 사유**: Phase 1 의 docs/ 가 후속 Phase 의 그릇 역할

### C. docs/ 절반만 (status / handoffs 만)

- 장점: 최소 비용
- 단점: architecture / domain / decisions / plans 분산 안 됨
- **탈락 사유**: 7 카테고리는 `memory/user_workflow.md` 에서 이미 정의된 표준. 메타가 자기 표준을 깨면 사용자 신뢰 손상

## Consequences

### 장점

- 정체성 일치
- 갭 진단의 #3 (self-application), #4 (handoff fragility) 직접 해결
- Phase 2-5 후속 작업의 산출물 위치 명확
- 사용자 워크플로의 자기 검증 사례 — 메타 프로젝트 본인에게 적용해본 결과 동작함

### 비용

- 11 파일 1회 작성 비용 (Phase 1 완료)
- 매 세션 handoff / status 갱신 의무
- memory 의 cumulative 항목 일부를 docs/handoffs/ 로 이관 검토 필요 (별도 작업)

### 트레이드오프

- memory ADR (memory ADR-001/002/003) 과 repo ADR (이 폴더) 의 이중성
  - memory ADR: Claude 행동 가이드, 사용자 dialogue 흐름의 일부, stale 가능
  - repo ADR: code/structure 결정의 immutable timeline
  - **해결**: memory ADR 중 영구 보존 가치 있는 것은 repo ADR 로 승격 권장 (Phase 2 이후 검토 항목)

## 참조

- `docs/plans/exec-plans/2026-05-17-self-adoption.md` — 본 결정의 실행 계획 (Phase 1-5)
- 본 세션 갭 진단: `docs/handoffs/2026-05-17.md`
- 정체성 원본: `memory/project_definition.md`
- 사용자 워크플로 표준: `memory/user_workflow.md`
- 관련: [`0002-documentation-first.md`](./0002-documentation-first.md)
