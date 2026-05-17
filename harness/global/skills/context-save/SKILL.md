---
name: context-save
description: |
  현재 세션 작업을 정리하고 다음 세션에서 복원 가능한 형태로 저장합니다 (퇴근 워크플로).
  docs/handoffs/YYYY-MM-DD.md 신규 작성 + docs/status.md 갱신. 한 일 / 진행 중 /
  다음 할 일 / 결정사항 / 미해결 이슈 5 섹션 구조.
  TRIGGER when: 사용자가 `/context-save` 호출, "퇴근", "오늘 작업 정리", "이거 마무리하고
  내일 이어서 할 수 있게", "세션 정리" 형태의 마무리 요청.
  SKIP when: WIP 작업 도중 (작업 단위가 안 끝남 — 끝낸 후 호출 안내), 변경사항이
  전혀 없음 (`git status` 빈 출력 + 새 결정 없음), 사용자가 단순히 "다음" 으로 넘어가는
  경우 (별도 세션 종료 의도 없음).
allowed-tools: [Read, Write, Bash, Glob, Grep]
argument-hint: "[summary-keyword]  # 파일명 suffix 로 들어감. 비우면 자동 생성"
---

# context-save

오늘 세션 작업을 다음 세션에서 이어갈 수 있게 정리합니다.

## 1. 저장 위치 결정

1. `docs/handoffs/` (정식 — [[user-workflow]] 기준)
2. `.claude/context/` (구식, 사용자 글로벌 command 호환)
3. 둘 다 없으면 사용자에게 어느 위치에 만들지 물어봄 (또는 /scaffold 안내)

## 2. 파일명 결정

- 형식: `YYYY-MM-DD[-<keyword>].md` (today 기준)
- `$ARGUMENTS` 가 있으면 keyword 로 사용
- 같은 날짜 파일이 이미 있으면 `-2`, `-3` 식으로 suffix (또는 기존 파일 update 옵션)

## 3. 캡처 항목 분석

세션 도중 정보를 모아 다음 5 섹션 구성:

### 한 일 (Done)
- `git log` (오늘 추가된 커밋, 또는 세션 시작 시점부터)
- 추가/수정된 파일 (이름과 주요 변경 요점)
- 통과한 검증 (`make test`, `make lint`, `make typecheck`, `make docker-build`)

### 진행 중 (In-Progress)
- `git status` 의 unstaged/staged 변경
- 미완료 함수/모듈 (TODO 주석)
- 실패한 검증 단계

### 다음 할 일 (Next)
- 사용자가 다음 세션에서 우선해야 할 작업
- 의존성 (X 가 끝나야 Y 가능)
- 추정 소요 시간 (있으면)

### 결정사항 (Decisions)
- 이번 세션에서 내린 트레이드오프
- 새 ADR 이 생겼다면 `docs/decisions/NNNN-<topic>.md` 작성 후 링크
- 메모리에 저장한 새 feedback / project 메모리 슬러그 (`[[name]]`)

### 미해결 이슈 (Open)
- 디버깅 중 끝나지 않은 가설
- 외부 의존성 대기 (사용자 응답, 라이브러리 결정)

## 4. status.md 갱신

`docs/status.md` 가 있으면:
- "현재 진행 상황" 섹션을 오늘 한 일 기준으로 업데이트
- 마지막 업데이트 날짜 갱신
- 이번 세션의 핵심 변화 1-2 줄 요약

## 5. git 상태 정리 안내 (자동 실행 안 함, 안내만)

- staged 가 있는데 커밋 안 됐으면: "다음 변경을 커밋할지 결정하세요" 알림 + 추천 commit message
- 큰 unstaged 변경이 있으면: "WIP 커밋 대신 별도 브랜치 stash 권장"

## 6. 결과 보고

```
## 퇴근 완료

저장됨: docs/handoffs/YYYY-MM-DD-<keyword>.md
status.md 갱신: <last-line>
미커밋 변경: <count> files
다음 세션 시작 시: /context-restore 또는 "출근"
```

## 참조

- [[user-workflow]] — 출퇴근 라이프사이클 정의
- `context-restore` skill — 짝을 이루는 출근 워크플로
- 커밋 정책: `rules/common/git.md`
