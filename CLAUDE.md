# claude-workflow — Project Context for Claude

이 문서는 이 메타 프로젝트(`claude-workflow`) 자체를 작업할 때 Claude가 참조합니다.

## 정체성

- **목적**: Claude Code 사용자가 새 프로젝트를 시작할 때 워크플로우(폴더 구조, 클린 아키텍처, lint/test/typecheck, pre-commit)를 강제하는 시스템
- **타깃 스택**: Python(uv) CLI/FastAPI, TypeScript(yarn) Nx 모노레포(NestJS API + Vite+React Web)
- **타깃 OS**: Windows 11 + bash + Docker
- **언어**: 사용자 응답 한국어, 파일/코드/주석은 영어

## 디렉토리 책임

- `harness/` — `~/.claude/` 에 배포되는 컨텐츠. 글로벌 영향. 수정 시 신중.
- `templates/` — `/new-project` 가 복사하는 스택별 보일러플레이트. 각 템플릿은 독립적으로 빌드 가능해야 함.
- `scripts/` — 설치/검증/머지 로직. Windows bash에서 동작 보장.

## 작성 규칙

### 보일러플레이트 (templates/*)

- 파일 인코딩: UTF-8, 줄바꿈: **LF only** (`.gitattributes`로 강제)
- 모든 `__package__` / `__project_name__` / `__description__` 플레이스홀더는 `scripts/scaffold.sh` 가 치환
- 각 템플릿은 `pyproject.toml` 또는 `package.json` 에 모든 스크립트(`test`, `lint`, `format`, `typecheck`, `docker:build`, `docker:up`)를 정의
- 각 템플릿은 빌드 검증 가능: `make doctor && make install && make lint && make typecheck && make test && make docker-build` 모두 통과해야 함
- `.dockerignore` 필수, multi-stage Dockerfile, root 비실행

### 하네스 (harness/*)

- `rules/`: 항상 적용되는 코딩 표준 (Markdown)
- `skills/<name>/SKILL.md`: Claude가 자율 호출하는 워크플로
- `commands/<name>.md`: 사용자가 `/foo` 로 명시적 트리거
- `hooks/`: 결정적 강제 (Bash 스크립트). Windows bash 호환 + 절대 경로 (`C:/Users/youja/.claude/hooks/jq.exe` 등)
- `settings.json`: `~/.claude/settings.json` 에 머지될 조각 (`scripts/settings-merge.py` 가 안전 머지). 중복 hook 등록 금지

### 스크립트 (scripts/*)

- `install.sh`: 복사 + checksum 추적. `.local` 파일 절대 보존.
- `scaffold.sh`: 템플릿 복사 + 플레이스홀더 치환 + git init + pre-commit/husky 설치
- `doctor.sh`: uv, yarn, docker, git, python>=3.12, node lts 검증
- `settings-merge.py`: `settings.partial.json` 을 `~/.claude/settings.json` 에 hook 중복 없이 머지

## Commit & Versioning (이 프로젝트의 모든 커밋)

### Conventional Commits

- 형식: `<type>(<scope>): <subject>` — subject 70자 이하, 명령형, 마침표 없음
- **type 허용**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`
- **scope** (이 프로젝트에서 자주 쓰는 것):
  - `templates/ts-nx`, `templates/python-cli`, `templates/python-fastapi` — 보일러플레이트 변경
  - `harness` — 룰/스킬/커맨드/훅 (글로벌 영향)
  - `scripts` — install/scaffold/test 로직
  - `hooks` — `harness/hooks/*` 한정
  - 생략 가능 — 단 가능한 한 명시
- BREAKING change: `<type>(<scope>)!: ...` + 본문에 `BREAKING CHANGE: <설명>` 한 줄
- 본문: "왜" 위주로 1-2 단락. "what" 은 diff가 말함
- WIP/squash-me 커밋 금지 — 작업 완료 후 단일 논리 변경으로 커밋

### Semantic Versioning (해석 규칙)

이 프로젝트는 별도 VERSION/태그를 발급하지 않는 메타 시스템이지만, commit type 자체는 SemVer 영향도로 해석할 수 있어야 합니다:

- `fix:` → **PATCH** (호환 가능한 버그/race/문서 수정)
- `feat:` → **MINOR** (호환 가능한 신규 기능, 신규 템플릿/스킬 추가 등)
- `feat!:` / `fix!:` / 본문에 `BREAKING CHANGE:` → **MAJOR** (사용자 워크플로 깨짐: 플래그 제거, 디렉토리 구조 변경, 플레이스홀더 명 변경 등)

**판단 기준**:
- 사용자의 기존 `~/.claude/` 또는 scaffold 결과물이 그대로 동작하면 PATCH 또는 MINOR
- 기존 사용자가 수동 마이그레이션을 해야 하면 MAJOR (`!` 표기 필수)
- 예시: `feat(templates)!: drop legacy ts-nestjs/ts-vite-react` (commit `7107501`) — `--stack=nestjs` 가 제거되어 사용자 워크플로 깨짐 → MAJOR

## Definition of Done (이 프로젝트의 모든 변경)

PR/커밋 전에 반드시:

1. **계획 명시**: 변경 의도가 issue/commit message에 1줄 이상 (commit 형식은 위 "Commit & Versioning" 따름)
2. **참조 검증**: 추가/변경된 파일이 다른 파일에서 참조되는지 grep으로 확인
3. **로컬 검증**: `bash install.sh --dry-run` 으로 install 결과 확인
4. **템플릿 검증**: 수정한 템플릿이 실제로 `cd templates/<stack> && make lint && make typecheck && make test` 통과
5. **결정 기록**: 트레이드오프가 있는 결정은 `harness/rules/` 또는 `README.md` 에 한 줄로 기록

## 절대 하지 말 것

- `~/.claude/CLAUDE.local.md`, `~/.claude/settings.local.json` 수정
- `~/.claude/settings.json` 직접 편집 (반드시 `scripts/settings-merge.py` 경유)
- 심볼릭 링크 기본값화 (Windows 권한 이슈)
- `--no-verify` 로 pre-commit 우회
- `D:/Personal/workspace/_template/` 수정 (사용자 기존 시스템 — 별개로 두기로 결정)
