# Architecture

## 폴더 구조

(프로젝트의 디렉토리 트리와 각 책임을 1-2줄로 기술. 루트 `CLAUDE.md` 의 3-layer 아키텍처를 그대로 따르되, 실제 상황에 맞게 갱신.)

```
<project-root>/
├── src/<package>/
│   ├── commands/    (interface: Typer 서브커맨드)
│   ├── core/        (순수 비즈니스 로직 — 외부 라이브러리 import 금지)
│   └── adapters/    (외부 I/O: 파일/HTTP/DB)
├── tests/
│   ├── unit/
│   └── integration/
└── infra/           (DB 등 외부 의존; 있다면)
```

## 의존 방향 (boundary)

`commands → core ← adapters` — `core/` 는 어떤 외부 라이브러리도 import 하지 않음. 위반 시 lint 또는 자체 가드에서 차단.

## 핵심 라이브러리 선택

| 영역 | 라이브러리 | 선택 이유 |
|---|---|---|
| CLI 파서 | (e.g. Typer) | (이유) |
| 설정 | (e.g. pydantic-settings) | (이유) |
| 로깅 | (e.g. structlog) | (이유) |

## 외부 시스템 의존성

(DB / cache / message queue / 외부 API 등. 각 항목에 1줄 — "왜 필요한지" 위주.)

## CI / 검증

본 템플릿은 **vendor 종속 CI 파일을 포함하지 않음** — GitHub Actions / GitLab CI / CircleCI 등 사용자가 선택. 아래는 vendor 무관 권장 jobs.

### 로컬 1차 검증 (개인 머신)

```bash
make lint && make typecheck && make test && make docker-build
```

### CI 권장 jobs (vendor 무관, 공유 환경)

**필수:**
- [ ] `uv sync --frozen --all-extras --dev` — lockfile 무결성
- [ ] `uv run ruff check src tests`
- [ ] `uv run ruff format --check src tests`
- [ ] `uv run pyright`
- [ ] `uv run pytest`
- [ ] secret scan (e.g. gitleaks)

**권장:**
- [ ] docker build (PR 시만, cache 적극 활용)
- [ ] coverage 리포트 업로드 (codecov 등)
- [ ] dependency audit (`pip-audit`)

**고급(선택):**
- [ ] Python 멀티 버전 matrix (3.12 / 3.13)
- [ ] SAST (semgrep)
- [ ] 컨테이너 이미지 취약점 (trivy)

### 트리거 권장

- `push` to `main`/`master`: 전체
- `pull_request`: 전체
- 다른 branch: skip (비용 절감)

### vendor 별 파일 위치 (선택 시 작성)

| vendor | 위치 |
|---|---|
| GitHub Actions | `.github/workflows/ci.yml` |
| GitLab CI | `.gitlab-ci.yml` |
| CircleCI | `.circleci/config.yml` |
| Drone | `.drone.yml` |
