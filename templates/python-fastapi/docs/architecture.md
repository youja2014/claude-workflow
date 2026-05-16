# Architecture

## 폴더 구조

(프로젝트의 디렉토리 트리와 각 책임을 1-2줄로 기술. 루트 `CLAUDE.md` 의 4-layer hexagonal-lite 를 그대로 따르되, 실제 상황에 맞게 갱신.)

```
<project-root>/
├── src/<package>/
│   ├── api/             (FastAPI 라우터, deps, schemas/DTO)
│   ├── application/     (use case orchestration)
│   ├── domain/          (entities, Protocol — 프레임워크 무관)
│   ├── infrastructure/  (DB SQLAlchemy, 외부 HTTP/queue)
│   └── core/            (config, logging)
├── tests/{unit,integration,e2e}/
└── migrations/          (Alembic)
```

## 의존 방향 (boundary)

`api → application → domain ← infrastructure` — `domain/` 은 어떤 프레임워크도 import 하지 않음(Protocol 만 정의).

## 핵심 라이브러리 선택

| 영역 | 라이브러리 | 선택 이유 |
|---|---|---|
| HTTP framework | (e.g. FastAPI) | (이유) |
| ORM | (e.g. SQLAlchemy 2.0 async) | (이유) |
| 마이그레이션 | (e.g. Alembic async env) | (이유) |
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
- [ ] postgres 서비스 컨테이너 + `uv run alembic upgrade head`
- [ ] `uv run pytest -m "unit or e2e"` (integration 은 testcontainers 가 처리)
- [ ] secret scan (e.g. gitleaks)

**권장:**
- [ ] docker build (PR 시만, cache 적극 활용)
- [ ] coverage 리포트 업로드 (codecov 등)
- [ ] dependency audit (`uv pip compile` 결과로 `pip-audit`)

**고급(선택):**
- [ ] Python 멀티 버전 matrix (3.12 / 3.13)
- [ ] SAST (semgrep)
- [ ] 컨테이너 이미지 취약점 (trivy)
- [ ] Alembic 마이그레이션 역방향 적용 검증 (`downgrade -1 && upgrade head`)

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

## DB 스키마 ERD

물리 ERD — 실제 테이블 / 컬럼 / 타입 / PK·FK / 제약 / 인덱스. 도메인 ERD 와 별도 책임 ([`domain/erd.md`](./domain/erd.md) 참조).

**Truth 는 `src/<package>/infrastructure/db/models/*.py` (SQLAlchemy 모델) + Alembic 마이그레이션** — 그 위의 ERD 는 자동 생성을 권장:

```bash
# 예: eralchemy (DBMS 직접 inspect)
uv run eralchemy -i 'postgresql+asyncpg://postgres:postgres@localhost:5432/<dbname>' -o docs/schema.svg

# 또는 schemaspy / sqlalchemy-data-model-visualizer 등 — 프로젝트가 선택
```

생성 결과를 아래에 임베드 또는 링크:

```
<!-- e.g. ![DB Schema](./schema.svg) -->
```

마이그레이션(`alembic revision`) 추가 시 같이 갱신.
