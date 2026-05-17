# Status

**최종 갱신**: 2026-05-17 (8th session)

## 현재 상태

- branch: **`main`** (ADR-0003)
- 로컬 커밋 누적: **51+** (8th session 5 commits 포함, 본 commit 으로 + 1)
- working tree: clean (본 commit 직후)
- remote: ✅ `origin = https://github.com/youja2014/claude-workflow.git` — main tracking, push 완료
- 마지막 검증: pre-push `make verify` PASS (test-install + test-templates 3/3) — 8th session 의 push 직전 실행 시점

## 진행 중

- 없음 (7th session Phase 1-5 모두 완료, 8th session 의 GitHub backup 완료).

## 최근 완료

### 8th session (2026-05-17, 같은 날 두 번째 슬롯)

- `228af5a` `feat(harness): add feature-orchestrator agent for cross-area dispatch`
- `02b924d` `docs(skills): expand TypeScript variant table in build-fix/security-scan`
- `3ef34f4` `fix(templates/python-cli): relax reportUnknownMemberType for typer compat`
- `fe7618e` `chore(scripts): name make as pre-push dep in doctor + install-git-hooks`
- (본 commit) `docs: wrap up 8th session (push + status + handoff)`

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
