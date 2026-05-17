# Work Breakdown Structure

메타 프로젝트의 모든 trackable work. 우선순위 = 위에서 아래.

## P0 — 현재 처방 (2026-05-17 시작, 자기 적용)

상세 계획: [`exec-plans/2026-05-17-self-adoption.md`](./exec-plans/2026-05-17-self-adoption.md)

- [x] Phase 1 — docs/ 7 카테고리 부트스트랩
- [ ] Phase 2 — 명문화 (CLAUDE.md memory 정책 + ADR 0001/0002)
- [ ] Phase 3 — `docs/coverage-matrix.md`
- [ ] Phase 4 — `scripts/eol-check.sh` + Makefile
- [ ] Phase 5 — 1-3 작업 묶음

## P1 — 처방 후 후속 (Phase 5 매트릭스 결과에 따라 우선순위 재정렬)

- [ ] TS agent 변형 — architect / code-reviewer / build-error-resolver / tdd-guide 의 TypeScript 변형
- [ ] git.md 브랜치 type 목록 명시 (1줄 패치)
- [ ] Node 22+alpine 메타데이터 + npm "Exit handler" 워크어라운드 명문화

## P2 — 백업 / 공유 (사용자 결정 대기)

- [ ] remote 설정 + push (URL 제공 필요)

## P3 — 호환성 / 확장 (트랙 외, 자율 가능)

- [ ] Linux/macOS 호환성 정적 리뷰 (install.sh / scaffold.sh / doctor.sh)
- [ ] Python 3.13 default 검토 (Phase 4 eol-check 결과 활용)

## 완료된 트랙 (이력)

| 트랙 | 시점 | 핵심 |
|---|---|---|
| E (정체성 재정의) | 2026-05-17 | `0f0caaf` |
| A (`/scaffold` 신설 + harness 분할) | 2026-05-17 | `0d5ded8` 외 4 |
| B (신규/기존 자동 감지) | 2026-05-17 | `afeb44d` 외 3 |
| C (commands → skills, ADR-001) | 2026-05-17 | `06a1e4c` + `2f24e7a` |
| D (플러그인 패키징, ADR-002) | 2026-05-17 | `0f298e0` (Defer) |
| ADR-003 (라이프사이클 자산 흡수) | 2026-05-17 | `5889087` ~ `52f2f65` (6 커밋) |
| Phase 8 (정보 아키텍처 + vendor-neutral) | 2026-05-17 | `8f98dcb` 외 5 |
