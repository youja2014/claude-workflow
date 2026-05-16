---
description: 신규 프로젝트 생성 또는 기존 프로젝트 adoption. 3 스택(Python CLI/FastAPI, TS Nx 모노레포). 신규는 템플릿 복사. 기존은 컴포넌트별 옵트인 주입(.githooks/Makefile/docs/CLAUDE.md).
argument-hint: "<project-name> --stack=<cli|fastapi|nx-monorepo> [--desc=...]   |   (no args, inside an existing .git/ repo)"
---

# scaffold

`$ARGUMENTS` 를 파싱해 모드를 결정한 뒤 진행합니다:

- **신규 모드**: `<project-name>` + `--stack` 제공 → 3 스택 중 하나로 새 프로젝트 생성
- **기존 모드**: 인자 없음 + 현재 dir 에 `.git/` 있음 → 컴포넌트별 옵트인 주입

> ℹ️ 이 커맨드는 claude-workflow 의 scaffolder 입니다. 사용자의 별도 `_template/` 시스템 (있다면) 과는 무관합니다.

## 모드 결정 (실행 첫 단계)

1. `$ARGUMENTS` 에 `<project-name>` 또는 `--stack` 이 있음 → **신규 모드**
2. `$ARGUMENTS` 가 비어있고 현재 dir 에 `.git/` 가 있음 → **기존 모드**
3. 둘 다 아니면 에러: "신규는 <project-name> + --stack 필요, 기존은 .git/ 있는 dir 에서 실행하세요."

## claude-workflow 위치 확인 (양 모드 공통)

설치된 resolver 에 위임:

```bash
WORKFLOW_HOME="$(bash ~/.claude/scripts/find-workflow-home.sh)" || {
  echo "claude-workflow 경로를 찾을 수 없습니다. CLAUDE_WORKFLOW_HOME 환경변수를 설정하세요."
  exit 1
}
```

resolver 탐색 순서: `$CLAUDE_WORKFLOW_HOME` → 스크립트 자신의 부모 → `~/.claude/.claude-workflow.lock` 의 `# source_dir=` 라인.

---

## 신규 모드 흐름

### 인자

- `<project-name>` (필수) — 케밥/스네이크 자동 변환
- `--stack=<cli|fastapi|nx-monorepo>` (필수)
- `--desc="설명"` (선택)
- `--dest=<path>` (선택, 기본 `$(pwd)/<name>`)

예시:
- `/scaffold my-api --stack=fastapi --desc="주문 처리 API"`
- `/scaffold admin-monorepo --stack=nx-monorepo`

### 실행 단계

1. **doctor**: `bash "$WORKFLOW_HOME/scripts/doctor.sh"` — 실패 시 누락 도구 안내 후 중단
2. **scaffold**:
   ```bash
   bash "$WORKFLOW_HOME/scripts/scaffold.sh" \
     --stack <stack> --name <project-name> \
     --dest <dest> --desc "<desc>"
   ```
3. **결과 검증** — 생성된 dir 의 핵심 파일 확인:
   - Python (`cli`/`fastapi`): `pyproject.toml`, `src/<package>/`, `tests/`, `Dockerfile`, `.githooks/{commit-msg,pre-commit,pre-push}`
   - TS (`nx-monorepo`): `package.json`, `nx.json`, `tsconfig.base.json`, `eslint.config.mjs`, `.githooks/{commit-msg,pre-commit,pre-push}`, `apps/api/project.json`, `apps/web/project.json`, `libs/shared-types/project.json`
4. **다음 단계 안내** — 사용자에게 출력:
   ```
   cd <project-path>
   make doctor && make test && make docker-build
   ```

---

## 기존 모드 흐름

기존 프로젝트에 claude-workflow 컨벤션을 점진 도입.

### 1. 현재 dir 검증

`.git/` 가 없으면 에러: "기존 모드는 git 저장소 안에서만 동작합니다."

### 2. 스택 감지 + 사용자 확인

`scaffold.sh` 가 `pyproject.toml` / `package.json` 으로 스택을 자동 감지하지만 우선 Claude 가 한 번 더 사용자에게 알려주고 확인 받으세요:

- `pyproject.toml` + `fastapi` 키워드 → `fastapi`
- `pyproject.toml` + (기타) → `cli`
- `package.json` → `nx-monorepo`
- 둘 다 있음 → 사용자에게 명시 요청 (`--stack=...`)

### 3. 컴포넌트 선택 (AskUserQuestion, multiSelect)

다음 6 컴포넌트를 사용자에게 multi-select 로 제시:

| 컴포넌트 | 설치되는 파일 | 의존 |
|---|---|---|
| `githooks-universal` | `.githooks/commit-msg`, `.githooks/pre-push` | (없음) |
| `githooks-stack` | `.githooks/pre-commit` (Python ruff / TS prettier+eslint) | 스택 |
| `install-script` | `scripts/install-git-hooks.sh` | (없음) |
| `makefile` | `Makefile` (verify/lint/typecheck/test/docker-* 타깃) — placeholder 치환 | 스택 + 프로젝트명 |
| `docs-skeleton` | `docs/{README, architecture, status, design/, domain/, plans/, decisions/, handoffs/}` | 스택 |
| `claude-md` | `CLAUDE.md` — placeholder 치환 | 스택 + 프로젝트명 |

권장 기본 셋: `githooks-universal`, `githooks-stack`, `install-script` (안전, 부수효과 적음).

### 4. dry-run 으로 영향 미리보기

```bash
bash "$WORKFLOW_HOME/scripts/scaffold.sh" --mode=existing \
  --components=<selected-comma-list> --dry-run
```

출력의 `[dry] install` 라인을 사용자에게 보여주고 확인 받기.

### 5. 실행

```bash
bash "$WORKFLOW_HOME/scripts/scaffold.sh" --mode=existing \
  --components=<selected-comma-list>
```

### 6. 결과 보고

`scaffold.sh` 출력에서 `installed` / `skipped` 카운트를 사용자에게 정리:
- installed: 새로 추가된 파일 목록
- skipped (이미 존재): 사용자가 이미 가진 파일 (덮어쓰지 않음)

### 충돌 처리 정책 (v1)

`scaffold.sh` 는 destination 파일이 이미 있으면 **자동 skip** (idempotent). 덮어쓰기 기능은 v1 에 없습니다. 사용자가 덮어쓰고 싶다면:

1. 해당 파일 수동 삭제 → 재실행
2. 또는 `git stash` → 재실행 → `git stash pop` 으로 diff 비교 후 머지

이 정책은 안전 우선. 향후 버전에서 `--on-conflict=k|o|b` 추가 검토.

---

## 클린 아키텍처 강제 사항 (참고)

신규 모드로 생성되거나 `claude-md` 컴포넌트로 주입된 프로젝트는 다음 규칙을 강제합니다. 사용자가 이 규칙을 어기면 `.githooks/pre-commit` 또는 lint 가 차단:

- **Python CLI**: `core/` → 외부 라이브러리 import 금지
- **Python FastAPI**: `domain/` → SQLAlchemy/Pydantic/FastAPI import 금지
- **Nx 모노레포 / apps/api (NestJS)**: `domain/` → `@nestjs/*` import 금지, 3종 엔티티 분리 강제
- **Nx 모노레포 / apps/web (React)**: features 간 직접 import 금지 (FSD 의존 방향)
- **Nx 모노레포 (프로젝트 간)**: `@nx/enforce-module-boundaries` 가 `project.json` `tags` 기반으로 자동 강제

## 참조

- `~/.claude/rules/python/cli.md`, `python/fastapi.md`
- `~/.claude/rules/typescript/nestjs.md`, `typescript/react.md`
- `$CLAUDE_WORKFLOW_HOME/templates/<stack>/CLAUDE.md` — 스택별 세부 가이드
- `$CLAUDE_WORKFLOW_HOME/harness/project/` — 기존 모드 주입 자산 (.githooks, install-git-hooks.sh)
