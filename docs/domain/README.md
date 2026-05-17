# Domain — claude-workflow 메타 어휘

본 메타 프로젝트의 도메인 용어. 코드와 문서 양쪽에서 일관되게 사용.

## 핵심 개념

| 용어 | 정의 |
|---|---|
| **Harness** | `~/.claude/` 로 배포되는 글로벌 자산 묶음 (rules/agents/skills/hooks/scripts). 모든 프로젝트에 자동 적용 |
| **Asset** | harness 의 한 단위. rules/<file>.md, agents/<name>.md, skills/<name>/SKILL.md 등 |
| **Template** | 신규 프로젝트 복사 원본. `templates/<stack>/`. 검증 sandbox + reference repo 역할 |
| **Stack** | 프로젝트 타입. 현재 3 종: `python-cli`, `python-fastapi`, `ts-nx` |
| **Scaffold** | 신규 프로젝트 생성(템플릿 복사) 또는 기존 프로젝트 adoption(컴포넌트 옵트인 주입) |
| **New mode** | scaffold 의 신규 프로젝트 모드. 빈 디렉토리 → 템플릿 전체 복사 |
| **Existing mode** | scaffold 의 기존 프로젝트 모드. 컴포넌트 옵트인 메뉴 (CLAUDE.md / .githooks / Makefile / docs/ 등) |
| **Personal config** | `~/.claude/` 의 설정. Claude Code 공식 우선순위 중 2위 |
| **Project config** | `<proj>/.claude/` 의 설정. 공식 우선순위 3위. Cursor 와 반대 |

## 자산 구분

| 자산 종류 | 위치 | 트리거 |
|---|---|---|
| Rule | `rules/{common,python,typescript}/*.md` | 모든 작업 시 자동 참조 (Claude 가 컨텍스트에 로드) |
| Agent | `agents/<name>.md` | 명시 위임 시 (Task tool with subagent_type) |
| Skill | `skills/<name>/SKILL.md` | Claude 자율 호출 또는 `/<name>` 사용자 트리거 |
| Hook | `hooks/<name>.sh` | settings.json 의 matcher 충족 시 (PreToolUse, PostToolUse) |

## 워크플로우 단계 (사용자 라이프사이클)

`출근 → 계획 → 검증 → 개발 → 테스트 → 배포 → 최종확인 → 퇴근`

자세한 매핑은 memory `[[user-workflow]]` 또는 `docs/README.md` 의 "워크플로우 매핑" 표.

## 디자인 패턴 어휘

| 패턴 | 위치 | 의미 |
|---|---|---|
| **Hexagonal-lite** | Python FastAPI / TS NestJS | 4-layer (interface → application → domain ← infrastructure) |
| **3-layer lite** | Python CLI | `commands → core ← adapters` |
| **FSD (Feature-Sliced Design)** | React | `app → pages → widgets → features → entities → shared` |
| **Vendor-neutral** | CI / hook 정책 | 특정 vendor (GitHub Actions, husky 등) 에 묶이지 않게. 대안: shell script + Makefile + 체크리스트 |
| **Drift** | Phase 4 도메인 | 외부 표준 (LTS, EOL) 이 바뀌는데 우리 자산은 안 따라가는 현상 |
| **Coverage 갭** | Phase 3 도메인 | (stack × asset) 매트릭스의 빈칸 |
| **Self-application** | Phase 1 / ADR-0001 도메인 | 메타 시스템이 자기 정체성을 자기에게 적용 |
