# Status

**최종 갱신**: 2026-05-29 (9th session)

## 현재 상태

- branch: **`main`** (ADR-0003)
- 로컬 커밋 누적: **54** (8th session 6, 9th session 2; origin/main 은 52 까지 — 9th 2건 push 대기)
- working tree: clean (9th session App-1/App-2/App-3 커밋 완료)
- remote: ✅ `origin = https://github.com/youja2014/claude-workflow.git` — main tracking, push 완료
- 마지막 검증: pre-push `make verify` PASS (test-install + test-templates 3/3) — recovery commit push 시점

## 자가 평가 (8th session 끝, 사용자 "완성됐나?" 응답 반영)

- "혼자 쓰기에는 충분, 다른 사람에게 권유하려면 부족" 단계.
- 권유 가능 단계로 가려면 아래 "다음 후보" 의 #1 (외부 의존성 변동 흡수 전략), #3 (handoff hash 검증 룰), #4 (silent exclude 재발 감시) 가 선행 필요.

## 진행 중

- 없음 (7th session Phase 1-5 모두 완료, 8th session 의 GitHub backup 완료).

## 최근 완료

### 9th session (2026-05-29) — 리서치 기반 하네스 적용

"Claude 를 에이전트로 대형 개발에 빠르게 활용하는 법" 딥리서치 결과를 하네스에 적용:

- **App-1 (agent model 티어링)** — 6개 agent frontmatter 에 `model:` 추가. 스캔류 (`clean-arch-detector`, `fsd-violation-detector`) `haiku`, 리뷰/빌드/TDD `sonnet`, `architect` `opus`. 근거: 공식 문서 (`code.claude.com/sub-agents`) 의 비용 제어 가이드. **사실 확정**: `model` 유효값 = `sonnet`/`opus`/`haiku`/풀 ID/`inherit`. (커밋 `e9180cd`)
- **App-2 (orchestrator agent→skill)** — `feature-orchestrator` 를 agent 에서 skill 로 전환. **실측 확정**: 서브에이전트는 `tools:*` 라도 하위 에이전트 생성 도구가 없음 (깊이-1) → agent 로는 병렬 dispatch 불가, skill (메인 대화 실행) 만 가능. ADR-0004 작성. (커밋 `e9180cd`)
- **App-3 (agentic-workflow 글로벌 룰)** — `rules/common/agentic-workflow.md` 신설. 컨텍스트 관리(/clear·/compact·탐색 위임), Explore→Plan→Code→Commit, 서브에이전트 깊이-1/요약회신, 멀티에이전트 사용 기준(리서치 강함/코딩 약함·~15x 토큰), 노력 스케일링, 모델 티어링, 검증·보안. coverage-matrix Rules 13→14.

후속 (미적용): App-4 (`/plan` 4단계 강화), install orphan 정리 (제거된 자산 자동 삭제).

### 8th session (2026-05-17, 같은 날 두 번째 슬롯)

- `228af5a` `feat(harness): add feature-orchestrator agent for cross-area dispatch`
- `02b924d` `docs(skills): expand TypeScript variant table in build-fix/security-scan`
- `3ef34f4` `fix(templates/python-cli): relax reportUnknownMemberType for typer compat`
- `fe7618e` `chore(scripts): name make as pre-push dep in doctor + install-git-hooks`
- `46c1a1e` `fix(docs): recover docs/ tree silently excluded since 7th session` — 7th session 의 docs/ 16 파일이 `.git/info/exclude → docs/` 로 silent skip 되어 한 번도 commit 되지 않았음을 본 세션에서 발견 후 복구
- (본 commit) `docs: close 8th session (status + memory sync)`

핵심 결과:
- GitHub remote 등록 + 51 commits push (백업 완료).
- 글로벌 git `init.defaultBranch=main` (ADR-0003 정합).
- `winget install ezwinports.make` 완료 — 새 Claude Code 세션부터 자동 PATH 인식.
- pre-push blocker (pyright + make) 처방으로 self-application 일관성 유지.

상세: `docs/handoffs/2026-05-17-8th.md`.

### 7th session (2026-05-17, 같은 날 첫 번째 슬롯)

상세는 `docs/handoffs/2026-05-17.md`. 요약:

- Phase 1-5 (자기 적용 + coverage-matrix + eol-check + Node 22 + TS variant agents/skills).
- ADR-0003 main 단일 정책 도입 + master → main rename.
- format-on-save Windows dirname fixed-point 패치.

## Blocker

- 없음.

## 다음 후보 (출근 시 우선순위 시드)

1. **(ADR 후보) test-templates 외부 의존성 변동 흡수 전략** — A) lockfile commit / B) verify 범위 축소 + nightly / C) pyright 룰 사전 완화 (이미 시행). 트레이드오프 비교 후 결정.
2. memory ADR-001/002/003 → repo ADR 승격 검토 (영구 보존 가치 평가).
3. Linux/macOS 호환성 정적 리뷰 (install.sh / scaffold.sh / doctor.sh).
4. `make test-hooks` — hooks 자체의 systematic stdin JSON 검사.
5. (옵션) GitHub Actions minimal 워크플로 — branch protection 정도, pre-push 와 중복 회피.

## 미해결 (사용자 결정 대기)

- 위 "다음 후보" 1번의 A/B/C 선택.
