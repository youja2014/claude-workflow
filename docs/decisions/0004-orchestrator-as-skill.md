# 0004. feature-orchestrator 는 agent 가 아니라 skill (서브에이전트 깊이-1 제약)

- **Status**: Accepted
- **Date**: 2026-05-29

## Context

`228af5a` (8th 세션) 에서 `feature-orchestrator` 를 **agent** (`harness/global/agents/feature-orchestrator.md`) 로 추가했다. 설계 의도는 풀스택 feature 요청을 받아 backend/frontend/infra 영역별 sub-agent 를 `Agent` 도구로 **병렬 디스패치** 하는 것이었다.

2026-05-29, "Claude 를 에이전트로 대형 개발에 활용하는 법" 딥리서치 중 Claude Code 서브에이전트 아키텍처를 점검하다 다음을 발견했다:

### 1차 문서 (Anthropic 공식)

- `code.claude.com/docs/en/sub-agents`: 서브에이전트는 "자기 컨텍스트 윈도에서 독립 실행 후 **요약만 회신**" 하며, 컨텍스트 보존이 목적. `model` frontmatter 로 `sonnet`/`opus`/`haiku`/풀 모델 ID/`inherit` 지정 가능 (기본 `inherit`), "Haiku 같은 저렴한 모델로 라우팅해 비용 제어" 명시.

### 실측 검증 (추측 배제)

`Agent` 도구로 `general-purpose` 서브에이전트를 띄워 도구 인벤토리를 보고하게 함:

- 결과: 로드된 도구 + deferred 도구 어디에도 **하위 에이전트 생성 도구 (Agent / Task / Workflow / Dispatch) 가 없음**.
- 결정적 증거: `general-purpose` 는 정의상 `Tools: *` (모든 도구) 인데도 서브에이전트 생성 도구가 없었음 → **`tools:` frontmatter 로도 우회 불가. 플랫폼이 깊이-2 를 금지**.

### 함의

`feature-orchestrator` 를 메인 대화가 **agent 로 위임** 하면, 그 서브에이전트는 `Agent` 도구가 없어 backend/frontend/infra 병렬 dispatch 를 **물리적으로 실행할 수 없다**. 즉 핵심 기능이 작동하지 않는 상태로 배포돼 있었다.

반면 **skill** 은 메인 대화 안에서 실행되며 (`Skill` 도구: "Execute a skill within the main conversation"), 메인 대화는 `Agent` 도구를 보유하므로 dispatch 가 가능하다. 기존 `/plan`, `/tdd` 등 위임을 동반하는 워크플로도 이미 skill 이다.

## Decision

`feature-orchestrator` 를 **agent → skill** 로 전환한다.

실 변경:

1. `harness/global/skills/feature-orchestrator/SKILL.md` 신설 — frontmatter `allowed-tools` 에 `Agent` 포함 (dispatch 가능의 핵심). 본문은 기존 agent 의 단계 1~5 플레이북 보존 + "skill 인 이유" 주석 + sub-agent 요약 회신 / worktree 격리 규칙 보강.
2. `harness/global/agents/feature-orchestrator.md` 제거.
3. 참조 갱신: `CLAUDE.md` (agents 목록에서 제거 + skills 목록에 추가 + 깊이-1 주석), `README.md`.

함께 적용한 관련 변경 (같은 리서치 산출):

4. 나머지 6개 agent 에 `model:` 티어링 frontmatter 추가 — 스캔류 (`clean-arch-detector`, `fsd-violation-detector`) `haiku`, 리뷰/빌드/TDD (`code-reviewer`, `build-error-resolver`, `tdd-guide`) `sonnet`, `architect` `opus`. 근거: 위 1차 문서의 비용 제어 가이드.

## Alternatives

### A. agent 유지 (현행)

- 장점: 추가 작업 없음, 자동 위임 (description 기반) 유지
- 단점: **핵심 기능이 작동하지 않음** (깊이-1 제약으로 dispatch 불가)
- **탈락**: 깨진 채로 두는 것

### B. agent 디렉토리에 두되 "메인 대화 플레이북" 으로 문서화

- 장점: 파일 이동 없음
- 단점: agents/ 는 위임 대상이라는 의미론과 충돌. 메인이 위임하면 여전히 깨짐. 사용자/Claude 혼란
- **탈락**: 의미론 불일치

### C. skill 로 전환 (채택)

- 장점: 메인 대화 실행 → `Agent` dispatch 작동. 기존 skill 생태계 (`/plan`, `/tdd`) 와 일관. 자동 호출 (description) + `/feature-orchestrator` 명시 호출 양쪽 지원
- 단점: 파일 이동 + 참조 갱신 비용. 호출 의미가 "agent 자동 위임" 에서 "skill" 로 바뀜
- **채택**: 유일하게 기능이 실제 작동하는 정합 해법

## Consequences

### 장점

- 오케스트레이션이 실제로 작동 (메인 대화에서 `Agent` 병렬 dispatch 가능)
- 모델 티어링으로 스캔류 에이전트 비용 절감 (Opus → Haiku)
- 하네스가 "서브에이전트 깊이-1" 이라는 플랫폼 제약을 명시적으로 반영 → 향후 오케스트레이션 자산은 skill 로 설계

### 비용

- 사용자가 재-install (`bash install.sh`) 해야 `~/.claude/` 에 반영. install.sh 는 신규 skill 을 복사하지만 **제거된 agent 파일 (`~/.claude/agents/feature-orchestrator.md`) 은 자동 삭제되지 않을 수 있음** (lock 추적 기반). 재발 방지 후보로 install 의 orphan 정리 검토 (후속).
- agent 자동 위임에 익숙한 흐름이 skill 호출로 바뀜 (description 자동 매칭은 유지되므로 체감 차이는 작음).

### 트레이드오프

- skill 은 메인 컨텍스트를 쓰므로, 오케스트레이션 단계 1~3 (구조 감지/계약 정의) 이 메인 컨텍스트를 소비. 단 무거운 영역 구현은 sub-agent 가 자기 컨텍스트에서 처리하므로 순효과는 절약.

### 회귀 방지

- 본 ADR + SKILL.md 주석으로 "오케스트레이션 = skill" 원칙 명문화
- `CLAUDE.md` 에 "서브에이전트는 다른 서브에이전트를 못 띄움 (깊이-1)" 한 줄 추가 → 향후 동일 실수 방지

## 참조

- 실측 근거 + 리서치: 2026-05-29 세션 (딥리서치 "Claude 에이전트 대형 개발" + 서브에이전트 도구 인벤토리 테스트)
- 1차 문서: https://code.claude.com/docs/en/sub-agents
- 의존: [`0001-self-application.md`](./0001-self-application.md) (메타 프로젝트 자기 적용 일관성)
- 영향 파일: `harness/global/skills/feature-orchestrator/SKILL.md` (신규), `harness/global/agents/feature-orchestrator.md` (제거), `CLAUDE.md`, `README.md`
