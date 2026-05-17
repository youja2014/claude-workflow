---
name: code-review
description: |
  현재 변경된 파일들을 코드 리뷰합니다 ([[user-workflow]] 의 검증 단계). git diff 로
  변경사항 추출 → code-reviewer agent 체크리스트 적용 → rules/ 기준 검증 →
  CRITICAL / WARNING / SUGGESTION / GOOD 4 단계 분류 + CRITICAL 에는 수정 코드 제안.
  TRIGGER when: 사용자가 `/code-review` 호출, "리뷰해줘", "코드 검토", "이거 PR
  올려도 될까", 커밋/PR 직전 단계의 검증 요청.
  SKIP when: git diff 가 비어있음 (변경사항 없음), 사용자가 명시적으로 "리뷰 말고
  바로 커밋" 요청, 이미 동일 변경 범위로 리뷰가 끝난 경우.
allowed-tools: [Read, Bash, Glob, Grep, Agent]
---

# code-review

## 1. 변경 범위 추출

```bash
# staged 우선, 없으면 unstaged
git diff --cached --name-only
# 비어있으면:
git diff --name-only
# 둘 다 비어있으면:
git log --name-only -1  # 가장 최근 커밋만 리뷰
```

변경된 파일 목록 + 라인 단위 diff 를 확보.

## 2. code-reviewer agent 위임 검토

`~/.claude/agents/code-reviewer.md` 가 있고 변경 규모가 큼 (5+ 파일 또는 200+ 라인) 이면
agent 에 위임. 작으면 직접 진행.

## 3. 5 가지 체크리스트 (code-reviewer agent 기준과 동일)

### (a) 정확성
- 명세 / 의도와 일치하는가
- edge case (empty, null, boundary, concurrent) 처리
- off-by-one, 잘못된 조건 분기

### (b) 보안
- 시크릿 하드코딩 (`rules/common/security.md`)
- 입력 검증 누락 (path traversal, SQL injection)
- 의존성 취약점

### (c) 품질
- DRY/KISS/YAGNI (`rules/common/code-quality.md`)
- 함수 50줄 이하, 매개변수 4개 이하
- 네이밍 명확성

### (d) 스택별 규칙
- Python: `rules/python/style.md`, `rules/python/testing.md`
- FastAPI: `rules/python/fastapi.md` — domain layer SQLAlchemy/Pydantic import 금지
- CLI: `rules/python/cli.md` — core/ 외부 라이브러리 import 금지
- TypeScript: `rules/typescript/style.md`, `rules/typescript/testing.md`
- NestJS: `rules/typescript/nestjs.md` — domain 에 @nestjs/* import 금지
- React: `rules/typescript/react.md` — FSD 의존 방향

### (e) 테스트
- 변경된 로직에 대응되는 테스트 존재
- 핵심 비즈니스 로직 / 에러 경로 커버
- 외부 의존성만 mock, 내부 mock 금지

## 4. 결과 분류

| 심각도 | 정의 | 대응 |
|---|---|---|
| **CRITICAL** | 머지 차단. 보안/정확성 문제, 운영 영향 | 수정 코드 제안 필수 |
| **WARNING** | 머지 가능하나 곧 해결 권장 | 다음 PR 또는 후속 이슈 |
| **SUGGESTION** | 선택적 개선 | 작성자 판단 |
| **GOOD** | 잘된 부분 (positive feedback) | — |

## 5. 결과 보고

다음 형식:

```
## 코드 리뷰 결과

**파일 N 개, +X / -Y 라인**

### CRITICAL (M 건)
- `path/to/file.py:42` — <한 줄 요약>
  ```python
  # 제안:
  ...
  ```

### WARNING (K 건)
- ...

### SUGGESTION (L 건)
- ...

### GOOD
- ...

**결론:** merge-ok / blocked / needs-revision
```

## 참조

- code-reviewer agent — 동일 체크리스트 (위임 시 그쪽이 권위)
- `rules/common/code-quality.md`, `rules/common/security.md`
- 스택별 `rules/<stack>/*.md`
