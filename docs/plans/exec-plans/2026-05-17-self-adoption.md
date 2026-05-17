# Self-Adoption — 2026-05-17

## 목표

메타 프로젝트(`claude-workflow`) 가 자기 정체성("신규+기존 프로젝트 어디에든 적용") 을 본인에게 적용. 동시에 갭 진단에서 발견한 5 카테고리 (Drift / Coverage / Self-application / Handoff fragility / 회계 부재) 의 처방.

## 동기

직전 세션까지 발견된 갭들이 모두 외부 트리거(사용자 질문, advisor 지적)로 드러남:

1. Node 20 EOL 모니터링 부재 (사용자 지적, 2026-05-17)
2. agent Python 한정 (사용자 지적)
3. **메타 프로젝트에 docs/ 부재 = 자기 정체성 위반** (가장 뼈아픈 신호)
4. memory cumulative handoff 의 정보 압축 손실
5. 주기적 self-audit 메커니즘 없음

→ 본 처방은 위 5개를 각각 카테고리별로 처리. 핵심 원칙: **"애매모호한 진행" 대신 "명확한 명문화"** (user 강조).

## Phase 1 — docs/ 7 카테고리 부트스트랩

**목적**: 자기 적용 시작점. docs/ 구조가 없으면 이후 Phase 의 산출물 둘 곳이 없음.

**범위**:
- `docs/README.md` (인덱스 + memory 와의 역할 분리)
- `docs/architecture.md` (harness/templates/scripts 구조 + 자산 책임 매트릭스)
- `docs/status.md` (현재 상태 한 페이지)
- `docs/plans/{README.md, wbs.md}`
- `docs/plans/exec-plans/2026-05-17-self-adoption.md` (이 파일)
- `docs/decisions/README.md` (ADR 규칙)
- `docs/handoffs/{README.md, 2026-05-17.md}`
- `docs/domain/README.md` (메타 도메인 용어)
- `docs/design/README.md` (N/A 안내)

**검증**:
- `tree docs/` 가 templates 의 docs 구조와 동형
- 모든 파일에 frontmatter / 메타 채워짐 (placeholder 없음)

**커밋**: `feat(docs): bootstrap docs/ 7 categories for self-adoption`

## Phase 2 — 명문화 (F + 처방 ADR)

**목적**: 정책을 영구 보존 가능한 형태로 ADR 화.

**범위**:
- `CLAUDE.md` 에 "memory vs docs/handoffs/ 역할 분리" 정책 1 섹션 추가
- `docs/decisions/0001-self-application.md` — 메타 프로젝트 자기 적용 결정
- `docs/decisions/0002-documentation-first.md` — "명문화-first" 원칙 (user 강조 반영)

**검증**:
- CLAUDE.md 신규 섹션이 templates/<stack>/CLAUDE.md 와 모순되지 않음
- ADR 형식 (Status / Date / Context / Decision / Alternatives / Consequences) 준수

**커밋**: `docs: add memory/docs split policy + ADR 0001/0002`

## Phase 3 — coverage-matrix.md (B)

**목적**: stack × asset 매트릭스로 누락 자산을 명시. 빈칸 = 후속.

**범위**:
- `docs/coverage-matrix.md` 신규
- 행: rules / agents / skills / hooks 의 stack 별 항목
- 열: python-cli / python-fastapi / ts-nx (또는 general / python / typescript)
- 값: `✅` / `❌ (issue #N)` / `N/A`

**검증**:
- 현재 `harness/global/` 자산을 grep 으로 카운트한 결과와 매트릭스 ✅ 개수 일치
- 1-3 작업 (TS agent 변형 등) 이 빈칸으로 식별됨

**커밋**: `docs: add coverage matrix (stack × asset)`

## Phase 4 — Drift 모니터링 (C)

**목적**: 외부 표준의 시간 변화 감지 자동화.

**범위**:
- `scripts/eol-check.sh` — endoflife.date API 폴링 (node, python)
- `Makefile` `eol-check` target
- `docs/architecture.md` 의 "외부 의존성" 표에서 SoT 컬럼 활용 (이미 추가됨)

**검증**:
- `make eol-check` 가 현재 사용 중인 node:22, python:3.12 의 EOL 날짜 출력
- EOL 6 개월 이내면 경고 (exit code != 0 옵션)

**커밋**: `feat(scripts): add eol-check via endoflife.date`

## Phase 5 — 1-3 작업 묶음

**목적**: 진단 이전부터 펜딩이던 1-3 작업을 처방의 출력으로 통합.

**범위 (매트릭스 결과 따라 순서 정렬)**:
- `harness/global/rules/common/git.md` — 브랜치 type 목록 명시 (1줄)
- `harness/global/rules/typescript/docker.md` + `templates/ts-nx/apps/{api,web}/Dockerfile` — Node 22+alpine 유지하되 EOL 메타데이터 + npm "Exit handler" 워크어라운드 명문화
- `harness/global/agents/{architect,code-reviewer,build-error-resolver,tdd-guide}.md` — TS 변형 (방식: 본문에 TS 섹션 추가 vs 별도 `-ts.md` 파일 — coverage-matrix 의 결정 따름)

**검증**:
- `make verify` PASS 회귀 0
- coverage-matrix 의 빈칸이 ✅ 로 채워짐

**커밋**: 항목별 분리 — `docs(rules): clarify branch type list` / `docs(rules): document node 22-alpine constraints` / `feat(agents): add typescript variants`

## DoD (전체)

- [ ] Phase 1-5 모두 완료, 각 Phase 커밋 검증
- [ ] `docs/status.md` 갱신
- [ ] `docs/handoffs/2026-05-17.md` 가 Phase 1-N 의 결과 누적
- [ ] `make verify` PASS
- [ ] coverage-matrix 의 ❌ 가 모두 P1 wbs 항목 또는 명시적 N/A

## 알려진 트레이드오프

- **명문화 비용 ↑**: 11+ docs/ 파일 작성. 1회 비용이지만 작지 않음. 그러나 user 결정 ("애매모호 진행 안 함")
- **Phase 5 의 TS agent 변형 방식 결정**: 매트릭스 결과 보고 본문 확장 vs 별도 파일 결정. exec-plan 시점에 확정 안 함

## 참조

- 갭 진단: 본 세션 대화 (2026-05-17, 7th session)
- 정체성: [[project-definition]] (memory)
- 사용자 워크플로: [[user-workflow]] (memory)
- ADR-003 라이프사이클 흡수: [[project-lifecycle-assets-absorption]]
- 직전 세션 누적: [[project-session-handoff]]
