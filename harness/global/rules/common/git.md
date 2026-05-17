# Git Rules

## 커밋
- Conventional Commits 형식: `<type>(<scope>): <description>`
- type: feat, fix, docs, refactor, test, chore, perf, ci
- 커밋은 하나의 논리적 변경만 포함
- WIP 커밋 금지 — 작업 완료 후 커밋

## 브랜치
- main/master: 항상 배포 가능한 상태 유지
- 브랜치명: `<type>/<short-description>` (feat/add-auth, fix/login-error)
- 장기 브랜치 금지 — 가능한 빨리 머지

## PR
- PR 제목: 70자 이하
- PR 본문: 변경 이유, 테스트 방법 포함
- 자체 코드 리뷰 후 PR 생성
- 큰 변경은 여러 PR로 분할

## .gitignore 필수 항목
- 가상환경: .venv/, venv/
- 환경변수: .env, .env.*
- IDE: .idea/, .vscode/
- 캐시: __pycache__/, .pytest_cache/, .ruff_cache/
- 빌드: dist/, build/, *.egg-info/
