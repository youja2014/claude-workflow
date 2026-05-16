# Handoffs

세션 간 인계 문서. **퇴근** 단계에서 생성하여 다음 **출근** 단계가 즉시 컨텍스트를 복원할 수 있게 합니다.

## 명명

`YYYY-MM-DD.md` (날짜별, 누적)

같은 날 여러 번 작성하면 `YYYY-MM-DD-<slot>.md` (e.g. `2026-05-16-evening.md`)

## 권장 형식

```markdown
# Handoff — YYYY-MM-DD

## 오늘 한 작업

- (커밋 해시 또는 PR 링크 + 한 줄 요약)

## 다음 출근 시 시작할 항목 (우선순위순)

1. (구체 작업 — `plans/wbs.md` 또는 `exec-plans/*` 와 링크)
2. ...

## 미해결 의문 / Blocker

- (있다면)

## 참고

- ADR: `decisions/NNNN-*.md`
- 계획: `plans/exec-plans/<feature>.md`
```

## 룰

- 한 번 작성된 handoff 는 immutable (다음날 수정 금지 — 새 handoff 작성)
- 출근 시 가장 최신 handoff 만 읽으면 컨텍스트 복원이 충분하도록 작성
