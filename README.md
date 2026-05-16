# claude-workflow

Claude Code로 개발할 때 프로젝트 시작 시점부터 워크플로우를 강제하는 메타 프로젝트입니다.
4개 스택 (Python CLI, Python FastAPI, TypeScript NestJS, TypeScript Vite+React)에 대한
보일러플레이트와 `~/.claude/` 하네스 확장 컨텐츠를 한 곳에서 관리합니다.

## 구성

```
claude-workflow/
├── harness/      # ~/.claude/ 로 배포되는 컨텐츠 (rules, skills, commands, hooks)
├── templates/    # /new-project 가 복사하는 스택별 보일러플레이트
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
#    /scaffold my-api --stack=fastapi   (4-스택용; 기존 /new-project 는 _template/ 그대로)
#    /setup-hooks
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

`~/.claude/` 에는 두 종류 파일이 공존합니다:

- **글로벌 (이 프로젝트가 관리)**: `CLAUDE.md`, `settings.json`, `rules/`, `skills/`, `commands/`, `hooks/`, `agents/`
- **로컬 (사용자 머신 전용, 절대 덮어쓰지 않음)**: `CLAUDE.local.md`, `settings.local.json`

머신별 차이 (예: 회사 vs 개인, Windows vs Mac) 는 모두 `.local` 파일에 두세요.
이 프로젝트는 글로벌만 관리하며 로컬은 사용자 소유입니다.

## 스택별 클린 아키텍처 요약

- **Python CLI** (`templates/python-cli`): `commands → core ← adapters` (3-layer lite)
- **Python FastAPI** (`templates/python-fastapi`): `api → application → domain ← infrastructure` (4-layer hexagonal-lite)
- **TypeScript NestJS** (`templates/ts-nestjs`): 모듈 = 바운디드 컨텍스트, 내부 4계층 + Prisma + 3종 엔티티 분리
- **TypeScript Vite+React** (`templates/ts-vite-react`): Feature-Sliced Design lite (`app→pages→widgets→features→entities→shared`)

자세한 룰은 `harness/rules/` 참조.

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
