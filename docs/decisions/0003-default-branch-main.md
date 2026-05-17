# 0003. Default branch = main (master 사용 금지)

- **Status**: Accepted
- **Date**: 2026-05-17

## Context

2026-05-17 7th 세션 진행 중 사용자가 본 repo 의 git branch 가 `master` 임을 발견하고 "master 안 쓰기로 한 거 아니었어?" 라고 질문 + "GitHub 에서 그렇게 발표한 거 아니야? 표준을 따라야지" 라고 명확한 의도 표명.

검색 결과 (본 ADR 작성 시점):

- 명문화된 "master 금지" 결정은 어디에도 없음
- `rules/common/git.md` L10: "main/master: 항상 배포 가능한 상태 유지" — 둘 다 허용 (정책 모호)
- 본 메타 repo 가 master 인 이유: `git init` 시 Windows 글로벌 `init.defaultBranch=master` 였기 때문 (의도 없음)
- 메타 프로젝트는 ADR-0001 (self-application) 위반 상태 — 자기 정책 부재

### 업계 표준 (2020-)

- GitHub: 2020-10 부터 신규 repo 기본 branch 를 `main` 으로 변경 (https://github.blog/2020-10-01-the-default-branch-for-newly-created-repositories-is-now-main/)
- GitLab / Bitbucket / Gitea: 같은 시기에 main 으로 변경
- 메인스트림 OSS: Linux, Node.js, npm, Vue, React 등 대부분 master → main 마이그레이션 완료
- git 2.28 (2020-07): `init.defaultBranch` 설정 추가로 사용자가 직접 선택 가능

본 프로젝트는 메타 시스템이라 표준 자체를 따르고 사용자에게 일관된 onboarding 을 제공할 책임이 있음.

## Decision

이 프로젝트의 모든 신규 repo / scaffold 산출물 / 메타 프로젝트 자체의 기본 branch 는 **`main`** 단일. master 사용 금지.

실 변경:

1. `rules/common/git.md`: "main/master" → "main" 단일. 작업 브랜치명 규약도 함께 보강 (type 목록 명시)
2. `scripts/scaffold.sh`: `git init -q -b main` 으로 신규 프로젝트 보장
3. 메타 프로젝트: `git branch -m master main` (본 ADR commit 직후)
4. 사용자 글로벌 git 설정 변경 권장 (강제 안 함):
   ```bash
   git config --global init.defaultBranch main
   ```
   (사용자 환경 변경이라 ADR 만으로는 강제 못 함 — 핸드오프에 가이드)

기존 사용자의 master repo 는 영향 없음. 본 정책은 신규 repo + 본 메타 프로젝트에만 적용.

## Alternatives

### A. main / master 병용 유지 (기존)

- 장점: 추가 작업 없음
- 단점: 정책 모호. 업계 표준 미준수. 사용자 의도와 어긋남
- **탈락**: 사용자 명시 거부 ("표준을 따라야지")

### B. main 정책 + 메타 repo 는 master 유지

- 장점: rename 비용 회피
- 단점: 메타 프로젝트가 자기 정책 위반 (ADR-0001 self-application 위반)
- **탈락**: 자기 적용 일관성 손상

### C. master 단일 정책 (반대 방향)

- 장점: Windows 글로벌 기본값과 일치
- 단점: 업계 표준 / 사용자 의도와 모두 어긋남
- **탈락**: 안티 트렌드

## Consequences

### 장점

- 업계 표준 일치
- 메타 시스템이 사용자에게 일관된 onboarding 제공
- ADR-0001 (self-application) + ADR-0002 (documentation-first) 일관성

### 비용

- 메타 repo rename (1 명령, 비파괴, remote 없으므로 영향 최소)
- 사용자 글로벌 git 설정 변경 권장 (사용자가 직접 실행)
- (선택) 향후 GitHub remote 생성 시 `gh repo create --default-branch main`

### 트레이드오프

- 사용자 글로벌 `init.defaultBranch` 가 master 로 남아있으면 메타 프로젝트 외부 git init 은 여전히 master. ADR 만으로는 강제 안 됨 — 권장만.
- `git config --global` 변경은 사용자 환경 외 다른 모든 프로젝트에도 영향. 사용자 결정 필요.

### 회귀 방지

- `rules/common/git.md` 정책 → 다음 install 시 사용자 글로벌에 자동 적용
- `scripts/scaffold.sh` 의 `-b main` → 신규 scaffold 는 자동 main
- 본 ADR 작성 → 같은 결정 재검토 불필요

## 참조

- 사용자 발견 + 의도: `docs/handoffs/2026-05-17.md`
- 의존: [`0001-self-application.md`](./0001-self-application.md), [`0002-documentation-first.md`](./0002-documentation-first.md)
- 업계 발표: https://github.blog/2020-10-01-the-default-branch-for-newly-created-repositories-is-now-main/
- git 2.28 release notes (init.defaultBranch 도입)
