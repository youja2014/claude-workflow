# Architecture — claude-workflow

## 정체성

Claude Code 사용자의 워크플로우 / 코딩 컨벤션 / 도구 강제 시스템을 구축하고, **신규/기존 프로젝트 어디에든 안전하게 적용** 가능하게 만드는 메타 시스템.

- 1차 산출물: `harness/` + `scripts/`
- 검증 sandbox + reference repo: `templates/`
- 진입점: `/scaffold` (skill, 신규/기존 자동 감지)

## 폴더 구조

```
claude-workflow/
├── harness/
│   ├── global/             # ~/.claude/ 로 배포 — 모든 프로젝트 자동 적용
│   │   ├── rules/          # 코딩 표준 (common, python/, typescript/)
│   │   ├── agents/         # 서브에이전트 (architect, code-reviewer, ...)
│   │   ├── skills/         # 워크플로우 (scaffold, plan, code-review, ...)
│   │   ├── hooks/          # 결정적 강제 (block-dangerous, format-on-save)
│   │   ├── scripts/        # 자산 헬퍼 (find-workflow-home.sh)
│   │   └── settings.json   # hook 등록 머지 조각
│   └── project/            # /scaffold 가 대상 프로젝트로 복사 — 옵트인
│       ├── .githooks/      # commit-msg, pre-push (stack-agnostic)
│       └── scripts/        # install-git-hooks.sh
├── templates/              # 신규 프로젝트 복사 원본 + 검증 sandbox
│   ├── python-cli/
│   ├── python-fastapi/
│   └── ts-nx/              # NestJS API + Vite/React Web (Nx 모노레포)
├── scripts/                # install.sh / scaffold.sh / doctor.sh / settings-merge.py
├── docs/                   # 이 폴더 (메타 프로젝트의 운영 문서)
├── .githooks/              # 메타 프로젝트 자체의 git hooks
├── .claude-plugin/         # plugin.json PoC (ADR-002, Defer 상태)
├── CLAUDE.md               # 광역 불변 정책
├── Makefile                # verify / test-install / test-templates
└── install.sh              # ~/.claude/ 배포 진입점
```

## 의존 방향 (boundary)

- `templates/<stack>/` 은 독립적으로 빌드 가능 (`make lint && make typecheck && make test && make docker-build`)
- `harness/global/` 의 자산은 외부 의존 없음 (rules 는 markdown, scripts 는 bash + jq)
- `harness/project/` 는 모든 스택 공통만. 스택별 변형은 `templates/<stack>/.githooks/` 로
- `scripts/` 는 idempotent (재실행 안전)

## 자산 책임 매트릭스

| 디렉토리 | 배포 경로 | 적용 시점 | 책임 |
|---|---|---|---|
| `harness/global/rules/` | `~/.claude/rules/` | install.sh 한 번 + 자동 적용 | 코딩 표준 (모든 작업 시 자동 참조) |
| `harness/global/agents/` | `~/.claude/agents/` | 동상 | 서브에이전트 (위임 시 활성) |
| `harness/global/skills/` | `~/.claude/skills/` | 동상 | 워크플로우 (Claude 자율 또는 `/<name>` 트리거) |
| `harness/global/hooks/` | `~/.claude/hooks/` | 동상 | PreToolUse / PostToolUse 강제 |
| `harness/global/scripts/` | `~/.claude/scripts/` | 동상 | 자산이 참조하는 헬퍼 |
| `harness/project/` | `<프로젝트>/.githooks` + `<프로젝트>/scripts/` | /scaffold 시 옵트인 | stack-agnostic git hooks |
| `templates/<stack>/` | `<신규-프로젝트>/` | /scaffold 신규 시 복사 | 보일러플레이트 |

상세 stack × asset 커버리지는 [`coverage-matrix.md`](./coverage-matrix.md) 참조.

## Claude Code 설정 우선순위 (공식)

```
Enterprise > Personal (~/.claude/) > Project (.claude/)
```

- 1차 배포는 Personal (install.sh). 모든 프로젝트 자동 적용
- 프로젝트별 특화는 `harness/project/` 옵트인 주입 — 덮어쓰기 아님
- skill / command 동명 충돌 시 **skill 이 이김** (Anthropic 공식)
- **주의**: Cursor 와 반대 (Cursor: Project > User)

## 외부 의존성

| 시스템 | 용도 | SoT (Source of Truth) |
|---|---|---|
| Python | 3.12+ (uv 관리) | python.org / endoflife.date |
| Node.js | 22 (Jod LTS) | nodejs.org / endoflife.date |
| Docker | multi-stage build | docker.com |
| jq | hook 스크립트 (Windows: `C:/Users/youja/.claude/hooks/jq.exe`) | (절대 경로 hardcoded) |
| endoflife.date | EOL 모니터링 (Phase 4) | https://endoflife.date/api |

## CI / 검증

본 메타 프로젝트는 **vendor-neutral 정책** ([[feedback-vendor-neutral]]) 으로 CI 파일 없음. 대신:

```bash
make verify           # test-install + test-templates 통합
make test-install     # install.sh dry-run 검증
make test-templates   # 3 템플릿 각각 lint/typecheck/test/docker-build
make eol-check        # endoflife.date 폴링 (Phase 4 산출물)
```

`.githooks/pre-push` 가 `make verify` 를 강제. 자세한 CI 권장 jobs 는 각 템플릿의 `docs/architecture.md` 참조.
