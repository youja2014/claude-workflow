---
description: 새 프로젝트를 4개 스택 템플릿 중 하나로 생성하고 클린 아키텍처/lint/pre-commit/Docker를 자동 세팅합니다.
argument-hint: <project-name> --stack=<cli|fastapi|nestjs|vite-react> [--desc "..."]
---

# scaffold

`$ARGUMENTS` 를 파싱해 4개 스택(cli/fastapi/nestjs/vite-react) 중 하나로 새 프로젝트를 생성합니다.

> ℹ️ 기존 `/new-project` 커맨드는 사용자의 `_template/` (Python-only) 시스템 그대로. 이 커맨드는 별개 4-스택 시스템.

## 인자 형식

- `<project-name>` (필수) — 케밥/스네이크 자동 변환
- `--stack=<cli|fastapi|nestjs|vite-react>` (필수)
- `--desc="설명"` (선택)
- `--dest=<path>` (선택, 기본은 현재 디렉토리 하위)

예시:
- `/scaffold my-api --stack=fastapi --desc="주문 처리 API"`
- `/scaffold admin-dash --stack=vite-react`

## 실행 단계

1. **인자 검증**: `$ARGUMENTS` 가 위 형식을 만족하는지 확인. 부족하면 사용자에게 물어보기.

2. **claude-workflow 위치 확인**: 해석 스크립트에 위임
   ```bash
   WORKFLOW_HOME="$(bash ~/.claude/scripts/find-workflow-home.sh 2>/dev/null \
                   || bash "$CLAUDE_WORKFLOW_HOME/scripts/find-workflow-home.sh")"
   ```
   탐색 순서: `$CLAUDE_WORKFLOW_HOME` → 스크립트 자신의 부모 → `~/.claude/.claude-workflow.lock` 의 `# source_dir=` 라인.
   모두 실패하면 사용자에게 경로 입력 요청.

3. **doctor 실행**: 필수 도구 검증
   ```bash
   bash "$WORKFLOW_HOME/scripts/doctor.sh"
   ```
   실패하면 누락된 도구를 안내하고 중단.

4. **scaffold 호출**:
   ```bash
   bash "$WORKFLOW_HOME/scripts/scaffold.sh" \
     --stack <stack> \
     --name <project-name> \
     --dest <dest> \
     --desc "<desc>"
   ```

5. **결과 검증**: 생성된 디렉토리의 핵심 파일 존재 확인
   - Python: `pyproject.toml`, `src/<package>/`, `tests/`, `Dockerfile`, `.pre-commit-config.yaml`
   - TS: `package.json`, `src/`, `Dockerfile`, `.husky/pre-commit`, `tsconfig.json`

6. **다음 단계 안내**: 사용자에게 출력
   ```
   다음 단계:
     cd <project-path>
     make doctor  (또는 yarn doctor)
     make test
     make docker-build
   ```

## 클린 아키텍처 강제 사항 (참고)

생성된 프로젝트는 다음 규칙을 강제합니다. 사용자가 이 규칙을 어기면 pre-commit 또는 lint가 차단:

- **Python CLI**: `core/` → 외부 라이브러리 import 금지
- **Python FastAPI**: `domain/` → SQLAlchemy/Pydantic/FastAPI import 금지
- **NestJS**: `domain/` → `@nestjs/*` import 금지, 3종 엔티티 분리 강제
- **React**: features 간 직접 import 금지 (FSD 의존 방향)

## 참조

- `~/.claude/rules/python/cli.md`, `python/fastapi.md`
- `~/.claude/rules/typescript/nestjs.md`, `typescript/react.md`
- `$CLAUDE_WORKFLOW_HOME/templates/<stack>/CLAUDE.md` — 스택별 세부 가이드
