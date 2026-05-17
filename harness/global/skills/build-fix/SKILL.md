---
name: build-fix
description: |
  빌드/런타임 에러를 진단하고 수정합니다 ([[user-workflow]] 의 테스트 단계에서 실패 시
  재귀 위임). build-error-resolver agent 의 6 분류 (Import/Type/Dependency/Docker/Test/Lint)
  + 진단 명령어 + 자주 발생 매트릭스 (CRLF, 순환 참조, uv.lock 충돌) 적용.
  TRIGGER when: 사용자가 `/build-fix` 호출, "빌드 안 됨", "에러 났어", "lint 실패",
  "test 실패", "docker build 실패" 형태의 에러 진단/수정 요청.
  SKIP when: 에러 메시지 없이 막연히 "동작 안 함" 만 명시 (먼저 재현 + 에러 메시지 요청),
  요청이 사실은 새 기능 개발 (build 가 그 결과로 안 되는 거지 build 자체 문제 아님).
allowed-tools: [Read, Bash, Glob, Grep, Agent, Edit]
argument-hint: "[error-context]  # 에러 메시지 또는 실패 단계. 비우면 직전 명령 결과로부터 추정"
---

# build-fix

`$ARGUMENTS` 의 에러 컨텍스트를 기반으로 진단 → 해결 → 검증.

## 1. build-error-resolver agent 위임 검토

`~/.claude/agents/build-error-resolver.md` 가 있고 에러가 복잡 (여러 모듈 연관, stack trace 길음) 이면 agent 에 위임. 단순 lint/typo 는 직접 처리.

## 2. 에러 분류 (6 카테고리)

- **Import**: 모듈 없음, 순환 참조
- **Type**: pyright/mypy/tsc 불일치
- **Dependency**: 패키지 충돌, lock 파일 불일치
- **Docker**: 빌드 실패, 런타임 크래시, CRLF
- **Test**: pytest/jest/vitest 실패, fixture 문제
- **Lint**: ruff/eslint 위반

분류가 안 되면 사용자에게 추가 정보 요청 (전체 에러 + 최근 변경 파일).

## 3. 진단 명령어 실행

스택별:

### Python (uv)
```bash
uv pip check          # 의존성 충돌
uv tree               # 의존성 트리
uv run pyright src/ 2>&1 | head -50
uv run ruff check src/ tests/
uv run pytest -v --tb=short
```

### TypeScript / Nx
```bash
yarn nx run-many -t lint
yarn nx run-many -t typecheck
yarn nx run-many -t test
yarn install --check-files  # node_modules 무결성
```

### Docker
```bash
docker compose build --no-cache 2>&1
docker compose logs <service> 2>&1
```

## 4. 일반 해결 매트릭스

### Python

| 에러 | 원인 | 해결 |
|---|---|---|
| ModuleNotFoundError | 패키지 미설치 | `uv add <pkg>` |
| ImportError 순환참조 | 모듈 간 상호 import | `from __future__ import annotations` + TYPE_CHECKING 가드 |
| uv.lock 충돌 | 의존성 변경 | `uv lock` 재실행 |

### TypeScript / Nx

| 에러 | 원인 | 해결 |
|---|---|---|
| Nx project not found | tsconfig path / project.json 누락 | `yarn nx graph` 확인, `tsconfig.base.json` paths |
| `Cannot find module '@<ws>/<lib>'` | workspace paths 미설정 | `tsconfig.base.json` paths + `project.json` tags |
| `npm Exit handler never called` (Node 22+alpine) | npm/cli#8974 | yarn (corepack) 사용 또는 `node:22-slim` |
| `workspace:*` in production deps | Nx generatePackageJson 누수 | type-only export 는 `devDependencies` 로 이동 |
| `PrismaClient is not generated` | postinstall 누락 | Dockerfile 양 stage 에서 `yarn prisma generate` 명시 |
| `MODULE_TYPELESS_PACKAGE_JSON` | ESM/CJS 충돌 | `.cjs` 확장자 또는 `"type": "module"` |
| `EPERM symlink` (Windows yarn PnP) | yarn 4 기본 PnP | `.yarnrc.yml` 에 `nodeLinker: node-modules` |

### Docker (공통)

| 에러 | 원인 | 해결 |
|---|---|---|
| Docker CRLF 에러 | Windows 줄바꿈 | `.gitattributes` `* text=auto eol=lf` + `sed -i 's/\r$//' file` |
| Permission denied | root 권한 문제 | Dockerfile 에 `RUN useradd -m app && USER app` |
| compose race (`P1001` Prisma postgres) | DB ready 전 connect | compose healthcheck + `depends_on: { condition: service_healthy }` |

### Lint / 스타일 (양쪽)

| 에러 | 원인 | 해결 |
|---|---|---|
| ruff/eslint 자동 수정 가능 | 스타일 위반 | `--fix` 옵션 (`ruff check --fix` / `eslint --fix`) |

## 5. 적용 + 검증

수정 후 검증 명령 실행 (스택별):
- Python: `make verify` 또는 `uv run pytest && uv run ruff check && uv run pyright`
- TS Nx: `make verify` 또는 `yarn nx run-many -t lint,typecheck,test`
- 메타 프로젝트: `make verify` (= test-install + test-templates)

검증 실패 시 재진단 (recursion 1-2 회까지). 그 이상은 사용자에게 상황 보고하고 결정 요청.

## 6. 재발 방지

- 같은 에러가 반복되면 [[continuous-learning]] 패턴 따라 메모리 또는 rules 에 기록 권장
- 환경 의존 (Windows CRLF 등) 이면 `.gitattributes` / `.editorconfig` / hook 으로 강제

## 출력 형식

```markdown
## 에러 진단

### 에러 내용
[원본 메시지 또는 핵심 줄]

### 원인 분석
[근본 원인 — 표면 증상 아님]

### 해결 방법
1. [구체 단계 + 명령어]
2. ...

### 재발 방지
[같은 에러가 다시 발생하지 않도록 하는 조치]

### 검증
[실행한 검증 명령 + 결과]
```

## 참조

- build-error-resolver agent (위임 시 권위)
- `rules/python/{cli,fastapi,style,testing,docker}.md`, `rules/typescript/*.md`
