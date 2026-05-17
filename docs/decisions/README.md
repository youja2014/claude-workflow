# Architecture Decision Records (ADR)

기존 의사결정과의 충돌을 방지하고 *왜* 그렇게 결정했는지 보존합니다. 코드는 *무엇*만 보여줍니다.

## 명명

`NNNN-<short-topic>.md` — `NNNN` 은 4자리 일련번호 (0001 부터)

예: `0001-self-application.md`, `0002-documentation-first.md`

## 형식 (필수 섹션)

```markdown
# NNNN. <title>

- **Status**: Proposed | Accepted | Superseded by NNNN | Deferred
- **Date**: YYYY-MM-DD

## Context

(어떤 상황에서 결정해야 했는지)

## Decision

(무엇을 선택했는지)

## Alternatives

(고려한 다른 선택지와 탈락 이유)

## Consequences

(이 결정이 만드는 trade-off)
```

## 룰

- 한 번 작성된 ADR 의 **Status / Decision / Context** 는 immutable
- 결정이 바뀌면 새 ADR 을 작성하고 이전 것의 Status 를 `Superseded by NNNN` 으로
- 출근 시 / 계획 검증 시 이 폴더 전체를 훑어 충돌 검사

## memory/ ADR 과의 관계

`~/.claude/projects/.../memory/` 에 있는 ADR-001/002/003 은 Claude 의 cross-session 학습 메모. 본 폴더의 ADR 은 **repo 에 영구 보존되는 결정**. 둘은 다른 layer:

- memory ADR: Claude 행동 가이드, 사용자 dialogue 흐름의 일부, 시간 따라 stale 될 수 있음
- repo ADR: code/structure 결정의 timeline. immutable, git history 와 함께 시간추적

memory ADR 중 영구 보존 가치 있는 것은 repo ADR 로 승격 권장.
