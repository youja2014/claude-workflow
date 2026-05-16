# claude-workflow — Project Context for Claude

이 문서는 이 메타 프로젝트(`claude-workflow`) 자체를 작업할 때 Claude가 참조합니다.

## 정체성

- **목적**: Claude Code 사용자의 워크플로우(폴더 구조, 클린 아키텍처, lint/test/typecheck, git hook, Docker) / 코딩 컨벤션 / 도구 강제 시스템을 구축하고, **신규 프로젝트뿐 아니라 기존 프로젝트에도 안전하게 적용 가능하게** 만드는 메타 시스템.
- **1차 산출물**: `harness/` (글로벌 ~/.claude/ 에 배포) + `scripts/` (설치/적용/머지). `templates/` 는 **검증 sandbox + 참고용 reference repo** (1차 산출물 아님).
- **진입점**: `/scaffold` — 대상 디렉토리 상태로 신규/기존 자동 감지. 신규는 templates 복사, 기존은 컴포넌트별 옵트인 주입. (옛 `/new-project` 는 deprecation 대상 — Track A 에서 전환)
- **타깃 스택**: Python(uv) CLI/FastAPI, TypeScript(yarn) Nx 모노레포(NestJS API + Vite+React Web)
- **타깃 OS**: Windows 11 + bash + Docker
- **언어**: 사용자 응답 한국어, 파일/코드/주석은 영어

## 디렉토리 책임

- `harness/global/` — `~/.claude/` 에 배포되는 **글로벌** 컨텐츠. 모든 프로젝트 자동 적용. 사용자 절대 원칙: 범용 rules, 보안 hook, 범용 agent/skill/slash command. 수정 시 신중 (글로벌 영향).
- `harness/project/` — **프로젝트 옵트인** 주입용 자산. `/scaffold` 가 신규 scaffold 또는 기존 프로젝트 adoption 시 복사. 현재 내용: stack-agnostic 공통 git hooks (`commit-msg`, `pre-push`) + `install-git-hooks.sh`. 스택별 자산은 여기 두지 말 것 — 그건 `templates/<stack>/` 책임.
- `templates/` — 스택별 **검증 sandbox + reference repo**. `/scaffold` 가 신규 프로젝트 복사 원본으로 사용. 각 템플릿은 독립적으로 빌드 가능해야 함 (`make lint && make typecheck && make test && make docker-build`).
- `scripts/` — 설치/scaffold/검증/머지 로직. Windows bash에서 동작 보장.

## 작성 규칙

### 보일러플레이트 (templates/*)

- 파일 인코딩: UTF-8, 줄바꿈: **LF only** (`.gitattributes`로 강제)
- 모든 `__package__` / `__project_name__` / `__description__` 플레이스홀더는 `scripts/scaffold.sh` 가 치환
- 각 템플릿은 `pyproject.toml` 또는 `package.json` 에 모든 스크립트(`test`, `lint`, `format`, `typecheck`, `docker:build`, `docker:up`)를 정의
- 각 템플릿은 빌드 검증 가능: `make doctor && make install && make lint && make typecheck && make test && make docker-build` 모두 통과해야 함
- `.dockerignore` 필수, multi-stage Dockerfile, root 비실행

### 하네스 — 글로벌 (`harness/global/*`)

`install.sh` 가 그대로 `~/.claude/` 로 배포. 모든 프로젝트에 자동 적용:

- `rules/`: 항상 적용되는 코딩 표준 (Markdown)
- `skills/<name>/SKILL.md`: Claude가 자율 호출하는 워크플로
- `commands/<name>.md`: 사용자가 `/foo` 로 명시적 트리거 (장기적으로 skills 로 마이그레이션 — Track C)
- `agents/<name>.md`: 전문 서브에이전트
- `hooks/`: 결정적 강제 (Bash 스크립트). Windows bash 호환 + 절대 경로 (`C:/Users/youja/.claude/hooks/jq.exe` 등)
- `scripts/`: `~/.claude/scripts/` 에 함께 배포되는 헬퍼 (예: `find-workflow-home.sh`)
- `settings.json`: `~/.claude/settings.json` 에 머지될 조각 (`scripts/settings-merge.py` 가 안전 머지). 중복 hook 등록 금지

### 하네스 — 프로젝트 (`harness/project/*`)

`/scaffold` 가 신규 프로젝트 생성 또는 기존 프로젝트 adoption 시 대상 디렉토리로 복사. 옵트인:

- `.githooks/`: stack-agnostic 공통 git hooks (`commit-msg`, `pre-push`). 스택별 훅(`pre-commit` — Python/TS 도구 다름) 은 `templates/<stack>/.githooks/` 에 남음
- `scripts/install-git-hooks.sh`: stack-agnostic git hooks 활성화 스크립트

**원칙**: 모든 스택에 동일한 컨텐츠만 여기 둠. 스택별 변형이 필요하면 `templates/<stack>/` 쪽.

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
  - `hooks` — `harness/global/hooks/*` 한정 (글로벌 hook). 프로젝트 주입 hook 은 `harness/project/` scope
  - 생략 가능 — 단 가능한 한 명시
- BREAKING change: `<type>(<scope>)!: ...` + 본문에 `BREAKING CHANGE: <설명>` 한 줄
- 본문: "왜" 위주로 1-2 단락. "what" 은 diff가 말함
- WIP/squash-me 커밋 금지 — 작업 완료 후 단일 논리 변경으로 커밋
- 강제: `.githooks/commit-msg` 가 subject 정규식을 검증 (`bash scripts/install-git-hooks.sh` 로 활성화). `--no-verify` 우회는 의도적인 사람만 사용 — Claude 는 절대 사용 금지(`harness/global/hooks/block-dangerous.sh` 가 차단)

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
5. **결정 기록**: 트레이드오프가 있는 결정은 `harness/global/rules/` 또는 `README.md` 에 한 줄로 기록

## Claude Code 설정 우선순위 (공식 규칙)

Claude Code 는 설정 출처별 우선순위가 정해져 있음. 같은 이름의 skill / agent / command / hook 이 여러 출처에 있으면 **상위 출처가 이김**:

1. **Enterprise** (조직 강제 설정) — 가장 강함
2. **Personal** (`~/.claude/`) — 사용자 글로벌. **이 프로젝트의 1차 배포 대상.**
3. **Project** (`.claude/`) — 프로젝트별. 옵트인 주입.

**주의**: 이 규칙은 **Cursor 와 반대** (Cursor 는 Project > User). Cursor 출신 사용자는 "프로젝트 규칙이 글로벌을 덮을 것" 이라 기대하지만 Claude Code 에선 반대. 설계 시:
- 글로벌만 설치된 상태에서도 모든 워크플로가 동작해야 함 (프로젝트 컨텐츠는 항상 옵트인)
- 프로젝트 특화 규칙이 글로벌을 덮어야 한다면 **이름을 다르게** 짓거나 `plugin:<name>:` 네임스페이스 활용
- 사용자가 글로벌·프로젝트 분할 결정 시 이 우선순위를 명시적으로 안내

## 절대 하지 말 것

- `~/.claude/CLAUDE.local.md`, `~/.claude/settings.local.json` 수정
- `~/.claude/settings.json` 직접 편집 (반드시 `scripts/settings-merge.py` 경유)
- 심볼릭 링크 기본값화 (Windows 권한 이슈)
- `--no-verify` 로 pre-commit 우회
- `D:/Personal/workspace/_template/` 수정 (사용자 기존 시스템 — 별개로 두기로 결정)
