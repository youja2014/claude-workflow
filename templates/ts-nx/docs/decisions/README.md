# Architecture Decision Records (ADR)

기존 의사결정과의 충돌을 방지하고 *왜* 그렇게 결정했는지 보존합니다. 코드는 *무엇*만 보여줍니다.

## 명명

`NNNN-<short-topic>.md` — `NNNN` 은 4자리 일련번호 (0001 부터)

예: `0001-use-prisma-orm.md`, `0002-postgres-not-mysql.md`

## 형식 (필수 섹션)

```markdown
# NNNN. <title>

- **Status**: Proposed | Accepted | Superseded by NNNN
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
