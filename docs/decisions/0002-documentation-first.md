# 0002. Documentation-first — 애매모호한 진행 대신 명확한 명문화

- **Status**: Accepted
- **Date**: 2026-05-17

## Context

2026-05-17 7th 세션의 갭 진단 시 사용자 명시 발언:

> "내 프로젝트의 목적에 따라 애매모호하게 '진행' 을 하지 말고 명확하게 명문화해서 남기는게 중요할 것 같"

본 메타 프로젝트는 사용자 워크플로 / 코딩 표준 / 도구 강제 시스템을 다룬다. 그 자체가 "암묵적 컨벤션을 명시적 자산으로 만드는" 작업이다. 그런데 프로젝트 자체 진행에서는 명문화 부족이 관찰됨:

- 결정 근거가 git history + memory dialogue 에 흩어짐 → 추적 어려움 (예: 라이프사이클 자산 흡수 결정 — memory ADR-003 작성 시점에야 명문화)
- "어떻게 진행할지" 가 plan 없이 즉흥적으로 시작되곤 함 → Phase 정의 후 중간 우회 발생 가능
- "왜 이렇게 결정" 의 추적이 미흡 → 같은 결정 재논의

사용자가 메타 시스템의 가치를 본인 프로젝트에 적용하려면 같은 명문화 기준이 본인 작업에도 적용되어야 함.

## Decision

이 프로젝트의 모든 **비-trivial 변경**은 아래 4 원칙을 따른다:

1. **계획**: 1-2 commit 으로 끝나지 않는 작업은 `docs/plans/exec-plans/<name>.md` 작성 후 시작. trivial fix (typo, 1줄 패치, 단순 rename) 제외
2. **결정**: trade-off 가 있는 결정은 `docs/decisions/NNNN-*.md` (ADR) 로 기록. "trade-off 가 다음 세션에서도 검토 가치가 있는가?" 가 임계값
3. **인계**: 세션 종료 시 `docs/handoffs/YYYY-MM-DD.md` 작성. 다음 출근 시 복원 가능하도록
4. **출처**: 수치 / 시간 / 외부 SoT 가 있는 자산은 출처를 명시. 예: `docs/architecture.md` 의 "외부 의존성" 표 SoT 컬럼

CLAUDE.md 의 "Definition of Done" 에 위 4 항목이 통합되어야 한다 (Phase 2 후속 검토).

## Alternatives

### A. 명문화 없이 코드만 진행 (기존)

- 장점: 작업 시작 빠름
- 단점: 결정 근거 손실. 같은 결정 반복. 메타 시스템 정체성 위반
- **탈락**: 사용자 명시 거부

### B. 모든 변경에 ADR 의무

- 장점: 추적성 극대화
- 단점: trivial fix 까지 ADR 작성 → 노이즈, 작업 시작 지연
- **탈락**: "trade-off 가 있는가" 임계값이 합리적

### C. 명문화는 commit message 본문에만

- 장점: 별도 파일 없이 git history 와 통합
- 단점: 결정 검색이 git log 의존, 결정 간 cross-link 어려움, ADR Status 변경 (Superseded) 추적 불가
- **탈락**: ADR 의 의도 (immutable + linkable) 와 부합 안 함

## Consequences

### 장점

- 결정 추적성 ↑ (`grep -r "decision X" docs/decisions/`)
- 다음 세션 컨텍스트 복원 비용 ↓
- 정체성 (명시적 컨벤션 시스템) 과 일치
- 메타 프로젝트 = 사용자 워크플로 검증 사례

### 비용

- 모든 비-trivial 변경에 명문화 추가 시간 (대략 +20-30%)
- exec-plan 작성 후 실제 진행이 어긋날 경우 plan 갱신 필요

### 트레이드오프

- **임계값의 모호함**: "trivial" 과 "비-trivial" 의 경계가 주관적
  - 가이드: ① 1-2 commit 으로 끝나는가, ② trade-off 가 있는가, ③ 다음 세션에서 검토 가치가 있는가 — 셋 중 하나라도 YES → ADR/exec-plan 작성
  - 너무 엄격하게 적용 시 작업 시작 지연 → 사용자가 단호하게 "그냥 진행" 지시하면 따름

### 회귀 방지

- `docs/decisions/README.md` 의 ADR 형식 (Status / Context / Decision / Alternatives / Consequences) 준수
- `docs/handoffs/README.md` 의 immutable 원칙 준수
- 본 ADR 자체가 위 4 원칙을 따른 사례

## 참조

- 사용자 강조 발언 출처: `docs/handoffs/2026-05-17.md` "사용자 결정" 섹션
- 본 ADR 의 전제: [`0001-self-application.md`](./0001-self-application.md)
- 실행 계획: `docs/plans/exec-plans/2026-05-17-self-adoption.md`
