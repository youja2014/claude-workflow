---
description: 새 프로젝트를 3개 스택 템플릿(Python CLI/FastAPI, TypeScript Nx 모노레포) 중 하나로 생성하고 클린 아키텍처/lint/pre-commit/Docker를 자동 세팅합니다.
argument-hint: <project-name> --stack=<cli|fastapi|nx-monorepo> [--desc "..."]
---

# scaffold

`$ARGUMENTS` 를 파싱해 3개 스택(cli/fastapi/nx-monorepo) 중 하나로 새 프로젝트를 생성합니다.

> ℹ️ 기존 `/new-project` 커맨드는 사용자의 `_template/` (Python-only) 시스템 그대로. 이 커맨드는 별개 3-스택 시스템.

## 인자 형식

- `<project-name>` (필수) — 케밥/스네이크 자동 변환
- `--stack=<cli|fastapi|nx-monorepo>` (필수)
- `--desc="설명"` (선택)
- `--dest=<path>` (선택, 기본은 현재 디렉토리 하위)

예시:
- `/scaffold my-api --stack=fastapi --desc="주문 처리 API"`
- `/scaffold admin-monorepo --stack=nx-monorepo`

## 실행 단계

1. **인자 검증**: `$ARGUMENTS` 가 위 형식을 만족하는지 확인. 부족하면 사용자에게 물어보기.

2. **claude-workflow 위치 확인**: 설치된 resolver 에 위임
   ```bash
   WORKFLOW_HOME="$(bash ~/.claude/scripts/find-workflow-home.sh)" || {
     echo "claude-workflow 경로를 찾을 수 없습니다. CLAUDE_WORKFLOW_HOME 환경변수를 설정하세요."
     exit 1
   }
   ```
   resolver 탐색 순서: `$CLAUDE_WORKFLOW_HOME` → 스크립트 자신의 부모 → `~/.claude/.claude-workflow.lock` 의 `# source_dir=` 라인.
   `install.sh` 가 `harness/global/scripts/find-workflow-home.sh` 를 `~/.claude/scripts/` 로 함께 배포하므로 항상 사용 가능.

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
   - Python (`cli`/`fastapi`): `pyproject.toml`, `src/<package>/`, `tests/`, `Dockerfile`, `.pre-commit-config.yaml`
   - TS (`nx-monorepo`): `package.json`, `nx.json`, `tsconfig.base.json`, `eslint.config.mjs`, `.husky/pre-commit`, `apps/api/project.json`, `apps/web/project.json`, `libs/shared-types/project.json`

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
- **Nx 모노레포 / apps/api (NestJS)**: `domain/` → `@nestjs/*` import 금지, 3종 엔티티 분리 강제
- **Nx 모노레포 / apps/web (React)**: features 간 직접 import 금지 (FSD 의존 방향)
- **Nx 모노레포 (프로젝트 간)**: `@nx/enforce-module-boundaries` 가 `project.json` `tags` 기반으로 자동 강제

## 참조

- `~/.claude/rules/python/cli.md`, `python/fastapi.md`
- `~/.claude/rules/typescript/nestjs.md`, `typescript/react.md`
- `$CLAUDE_WORKFLOW_HOME/templates/<stack>/CLAUDE.md` — 스택별 세부 가이드
