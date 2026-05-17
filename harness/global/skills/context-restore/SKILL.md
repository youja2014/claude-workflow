---
name: context-restore
description: |
  지난 세션의 작업 컨텍스트를 복원해 이어 작업합니다 (출근 워크플로). docs/handoffs/
  최신 파일 → docs/status.md → docs/plans/wbs.md → docs/decisions/ 순으로 읽어
  "이전 진행 상황, 현재 우선순위, 미해결 결정사항" 을 요약하고 다음 작업을 제안합니다.
  TRIGGER when: 사용자가 `/context-restore` 호출, "출근", "어제 작업 이어줘",
  "지난 세션 컨텍스트 복원", "어디까지 했지" 형태의 컨텍스트 복원 요청.
  SKIP when: 신규 프로젝트 시작 (docs/handoffs/ 없음 → /scaffold 안내),
  단일 trivial 작업 (간단한 파일 1개 수정), 사용자가 명시적으로 "처음부터"
  새로 시작한다고 한 경우.
allowed-tools: [Read, Bash, Glob, Grep]
argument-hint: "[YYYY-MM-DD]  # 특정 날짜 handoff 지정. 비우면 최신"
---

# context-restore

`$ARGUMENTS` 에 날짜 (YYYY-MM-DD) 가 있으면 그 날짜의 handoff, 없으면 가장 최신을 복원합니다.

## 1. handoff 위치 결정 (우선순위)

1. `docs/handoffs/` (정식 — [[user-workflow]] 기준)
2. `.claude/context/` (구식, 사용자 글로벌 command 호환)
3. 둘 다 없음 → "이전 컨텍스트 없음. /scaffold 로 docs/ 구조 만들거나 직접 첫 handoff 작성" 안내

```bash
if [[ -d docs/handoffs ]]; then
  HANDOFF_DIR="docs/handoffs"
elif [[ -d .claude/context ]]; then
  HANDOFF_DIR=".claude/context"
else
  echo "no handoff directory; suggest /scaffold or manual setup"
  exit 0
fi
```

## 2. 대상 파일 선택

- `$ARGUMENTS` 가 비어있음 → `ls -1 "$HANDOFF_DIR" | sort -r | head -1`
- `$ARGUMENTS` 가 날짜 형태 → 매칭되는 파일

## 3. 컨텍스트 컴포넌트 로드 (모두 읽기)

순서대로:

1. **최신 handoff** — 어디까지 했는지, 다음에 할 일
2. `docs/status.md` — 현재 진행 상황 (퇴근 시 갱신되는 파일)
3. `docs/plans/wbs.md` — 작업 분해 구조
4. `docs/plans/exec-plans/*.md` — 진행 중인 기능별 실행 계획
5. `docs/decisions/*.md` — ADR (불변 결정)

각 파일이 없으면 그 단계는 skip.

## 4. 코드 상태와의 호환성 검증

- handoff 의 "다음 할 일" 에 언급된 파일/심볼이 현재 코드에 존재하는지 grep 으로 확인
- 충돌하는 부분이 있으면 사용자에게 알림
- `git log --oneline -10` 로 handoff 작성 후 추가된 커밋 확인

## 5. 사용자에게 요약 출력

다음 형식으로 보고:

```
## 복원된 컨텍스트 (YYYY-MM-DD)

**이전 작업:** (handoff 의 "한 일")
**현재 진행:** (status.md 또는 handoff 의 in-progress)
**다음 작업:** (handoff 의 "다음에 할 일" + 우선순위)
**미해결 결정:** (decisions/ 에서 "open" 상태)
**최근 커밋 (handoff 이후):** (git log)

추천 다음 단계: ...
```

## 참조

- [[user-workflow]] — 출퇴근 라이프사이클 정의
- `context-save` skill — 짝을 이루는 퇴근 워크플로
