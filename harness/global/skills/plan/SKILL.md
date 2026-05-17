---
name: plan
description: |
  기능 구현 계획을 수립합니다 ([[user-workflow]] 의 계획 수립 단계). 요구사항 정의 →
  모듈/파일/함수 식별 → 레이어 구조 매핑 → 구현 순서 + 단계별 검증 방법 → 기존 코드
  영향 분석. 결과를 docs/plans/exec-plans/<feature>.md 에 저장하거나 사용자에게
  요약 출력. architect agent 가 있으면 위임 가능.
  TRIGGER when: 사용자가 `/plan ...` 호출, "X 기능 어떻게 구현할까", "이거 설계해줘",
  "<기능> 계획 세워줘" 형태의 설계/계획 요청. 코드 작성 시작 전 단계.
  SKIP when: 단순 버그 수정 (1-2 파일, 명확한 위치), trivial 작업 (rename, typo,
  주석 수정), 이미 docs/plans/exec-plans/ 에 같은 기능 계획 존재 (그 경우 update 안내).
allowed-tools: [Read, Write, Bash, Glob, Grep, Agent]
argument-hint: "<feature-description>"
---

# plan

`$ARGUMENTS` 의 기능에 대해 다음 순서로 분석합니다.

## 1. architect agent 위임 검토

`~/.claude/agents/architect.md` 가 있고 기능 규모가 비-trivial (3+ 파일) 이면 우선 architect agent 에 위임. 작은 기능은 직접 진행.

## 2. 컨텍스트 로드

기존 결정 / 도메인 / 아키텍처를 먼저 읽어 충돌 회피:

- `docs/architecture.md` — 폴더 구조 + 라이브러리 선택 근거
- `docs/domain/*` — 도메인 용어/모델/룰
- `docs/decisions/*.md` — 기존 ADR (불변)
- 영역별 `<area>/CLAUDE.md` (예: `apps/api/CLAUDE.md`)

## 3. 요구사항 정의

- 입력 / 출력 / 부수효과
- 성공 기준 (DoD): 어떤 검증이 통과해야 끝난 것인지
- 비-목표 (out of scope)

## 4. 모듈/파일/함수 식별

스택별 레이어 구조 기준:

### Python CLI
`Models → Config → Adapters → Core (도메인) → Commands (CLI)` — core 는 외부 import 금지

### Python FastAPI
`Models → Config → Repository → Service → API` — domain 은 SQLAlchemy/Pydantic/FastAPI import 금지

### Nx 모노레포 (apps/api NestJS)
`domain (PoJo) → application (DTO + UseCase) → infrastructure (Repo impl) → interface (Controller)`

### Nx 모노레포 (apps/web React, FSD)
`shared → entities → features → widgets → pages` — features 간 직접 import 금지

각 레이어에서 추가/수정될 파일을 구체적으로 나열:
- 신규 파일: 경로 + 책임 한 줄
- 수정 파일: 경로 + 어떤 부분이 어떻게 바뀌는지

## 5. 구현 순서 + 단계별 검증

각 단계마다 어떤 명령으로 검증할지 명시 (TDD 친화):

```
1. 도메인 모델 추가 (src/.../domain/X.py)
   → 검증: uv run pytest tests/domain/test_X.py (실패 예상)
2. 모델 구현
   → 검증: 1번 테스트 통과
3. Repository 인터페이스
   → 검증: typecheck 통과
...
```

## 6. 기존 코드 영향 분석

- 어떤 모듈이 변경되는지 grep 으로 dependent 추적
- breaking change 가 있는지 (시그니처 변경, public API 제거)
- 마이그레이션 필요 시 단계 분리

## 7. 산출물 저장

`docs/plans/exec-plans/` 가 있으면 `<feature-slug>.md` 로 저장. 없으면 사용자에게 요약 출력만.

저장 시 frontmatter:
```yaml
---
feature: <slug>
created: YYYY-MM-DD
status: draft  # draft | in-progress | done | abandoned
related-decisions: []
---
```

## 8. 결과 보고

사용자에게:
- 영향 받는 파일 수 / 예상 신규 파일 수
- 구현 단계 수 + 각 단계의 추정 난이도
- 차단 이슈 (현재 코드와 충돌, 미결정 사항 등) 가 있다면 명시

## 참조

- `rules/common/code-quality.md` — DRY/KISS/YAGNI
- `rules/<stack>/*` — 스택별 패턴
- architect agent (있다면)
