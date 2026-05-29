# claude-workflow

Claude Code로 개발할 때 프로젝트 시작 시점부터 워크플로우를 강제하는 메타 프로젝트입니다.
3개 스택 (Python CLI, Python FastAPI, TypeScript Nx 모노레포 = NestJS API + Vite+React Web)에 대한
보일러플레이트와 `~/.claude/` 하네스 확장 컨텐츠를 한 곳에서 관리합니다.

## 구성

```
claude-workflow/
├── harness/      # ~/.claude/ 로 배포되는 컨텐츠 (rules, skills, agents, hooks)
├── templates/    # /scaffold 가 복사하는 스택별 보일러플레이트
└── scripts/      # 설치/검증/병합 스크립트
```

자세한 내용은 [`CLAUDE.md`](./CLAUDE.md) 참조.

## 빠른 시작

```bash
# 1. 환경 검증
bash scripts/doctor.sh

# 2. ~/.claude/ 로 하네스 컨텐츠 설치 (복사 + checksum 추적)
bash install.sh

# 3. Claude Code 재시작 후 슬래시 커맨드 확인
#    /scaffold my-api --stack=fastapi          (신규 프로젝트)
#    /scaffold                                 (기존 .git/ repo 안에서 — 컴포넌트별 옵트인 주입)
```

## 강제(Enforcement) 모델

| 시점 | 메커니즘 | 무엇을 강제하나 |
|---|---|---|
| **프로젝트 생성** | `/scaffold --stack=...` | 폴더 구조, 클린 아키텍처 레이어, 의존성 락, pre-commit/husky 설치 |
| **커밋** | pre-commit (Python) / husky v9 (TS) | lint, format, type check, conventional commits, gitleaks |
| **편집 중** | Claude Code hooks (PostToolUse Write\|Edit) | 저장 시 자동 포매팅 |
| **CI** | (선택) GitHub Actions 템플릿 | 전체 테스트 스위트, docker build |

## 설치 동작

`install.sh` 는 `harness/` 의 모든 파일을 `~/.claude/` 로 **복사**합니다 (심볼릭 링크 아님).
원본 checksum을 `~/.claude/.claude-workflow.lock` 에 기록해 재실행 시 변경 감지가 가능합니다.

- 동일한 파일 → skip
- 새 파일 → 자동 설치
- 변경 감지 → `[k]eep / [o]verwrite / [d]iff / [b]ackup&replace` 프롬프트
- `~/.claude/CLAUDE.local.md`, `~/.claude/settings.local.json` → **절대 건드리지 않음** (로컬 오버라이드 보호)
- `~/.claude/settings.json` → `scripts/settings-merge.py` 로 hook 중복 없이 머지

```bash
bash install.sh              # 대화형 충돌 처리
bash install.sh --yes        # 모든 충돌을 overwrite (CI/재설치용, 사용 주의)
bash install.sh --dry-run    # 무엇이 변경될지 출력만
bash uninstall.sh            # 설치한 파일만 제거, 로컬 오버라이드는 유지
```

## 검증 (CI 없이 강제)

```bash
make verify           # = make test (test-install + test-templates)
make install-git-hooks  # .githooks/pre-push 활성화 → push 직전 자동 verify
```

`make verify` 는 vendor-neutral. 외부 러너가 필요해지면 한 줄짜리 워크플로(`run: make verify`) 로
어디든(GitHub Actions, GitLab CI, Forgejo, 셀프호스트 act 등) 동일하게 동작합니다.

## 로컬 / 글로벌 분리

`~/.claude/` 에는 두 부류 파일이 공존합니다:

- **이 프로젝트가 제공 (install.sh 가 배포)**:
  - 광역 룰 — `rules/common/{code-quality,git,security,agentic-workflow}.md`
  - 스택별 룰 — `rules/python/*`, `rules/typescript/*`
  - 라이프사이클 skills — `skills/{scaffold,context-restore,context-save,plan,code-review,feature-orchestrator,...}/`
  - 전문 agents — `agents/{architect,code-reviewer,tdd-guide,build-error-resolver,clean-arch-detector,fsd-violation-detector}.md` (frontmatter `model:` 티어링)
  - 결정적 hooks — `hooks/{block-dangerous,format-on-save}.sh`
  - `settings.json` 일부 (hook 등록, `scripts/settings-merge.py` 가 안전 머지)
- **로컬 머신 전용 (덮어쓰기 절대 금지)**: `CLAUDE.local.md`, `settings.local.json`

기존 파일과 충돌하면 install.sh 는 `[k]eep / [o]verwrite / [d]iff / [b]ackup&replace` 를 인터랙티브로
묻습니다. 사용자가 직접 손본 자산은 [k]eep 으로 보존되며, 이 프로젝트가 강제로 덮어쓰지 않습니다.

## 스택별 클린 아키텍처 요약

- **Python CLI** (`templates/python-cli`): `commands → core ← adapters` (3-layer lite)
- **Python FastAPI** (`templates/python-fastapi`): `api → application → domain ← infrastructure` (4-layer hexagonal-lite)
- **TypeScript Nx 모노레포** (`templates/ts-nx`):
  - `apps/api` — NestJS, 모듈 = 바운디드 컨텍스트, 내부 4계층 + Prisma + 3종 엔티티 분리
  - `apps/web` — Vite+React, Feature-Sliced Design lite (`app→pages→widgets→features→entities→shared`)
  - `libs/shared-types` — 공유 타입
  - 프로젝트 간 경계는 `@nx/enforce-module-boundaries` (project.json `tags`) 로 자동 강제

자세한 룰은 `harness/global/rules/` 참조.

## 외부 스킬 카탈로그

추가 스킬이 필요하면 외부 레지스트리에서 cherry-pick 가능합니다:
- [Claude 프롬프트+스킬 모음](https://exultant-principle-9c5.notion.site/claude-34691cb23c4d806db398fd9fe5e1c364) — 75개 스킬 + 149개 프롬프트 카탈로그
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — 공식 superpowers 플러그인

권장 스킬:
- `using-git-worktrees` — 기능 개발 시 워크트리로 안전 분리
- `verification-before-completion` — 완료 선언 전 검증 명령 강제 (이 프로젝트는 일부를 Definition of Done으로 통합)
- `systematic-debugging` — 증상 수정 전 근본 원인 분석

## 라이선스

MIT
