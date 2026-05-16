# __project_name__ — Project Context for Claude

## 정체성

- **유형**: Python FastAPI 서비스 (async, SQLAlchemy 2.0)
- **DB**: PostgreSQL (asyncpg)
- **마이그레이션**: Alembic (async env.py)
- **패키지 매니저**: uv
- **타깃 Python**: 3.12+

## 아키텍처 (4-layer hexagonal-lite)

```
api → application → domain ← infrastructure
```

```
src/__package__/
├── api/             # FastAPI 라우터, deps, schemas (DTO)
├── application/     # use case (orchestration)
├── domain/          # entities, repositories(Protocol), exceptions — 프레임워크 무관
├── infrastructure/  # db(SQLAlchemy), external HTTP/queue
├── core/            # config, logging
└── main.py
```

## 3종 엔티티 분리 (강제)

- DTO: `api/schemas/` Pydantic v2 BaseModel
- Domain entity: `domain/entities/` 순수 `@dataclass`
- ORM model: `infrastructure/db/models/` SQLAlchemy `DeclarativeBase`

세 객체는 절대 동일하면 안 됨. mapper 함수로 변환.

## 새 모듈 추가

`/skill fastapi-add-module` 호출 권장. domain → application → infrastructure → api 순으로 파일과 테스트가 자동 생성됩니다.

## Definition of Done

1. **계획 명시**: commit message 또는 issue
2. **참조 확인**: 추가/변경된 심볼이 호출처에서 실제 사용됨
3. **테스트**:
   - `unit/`: 도메인/use case 단위 (mock repo)
   - `integration/`: testcontainers-postgres 로 repository 검증
   - `e2e/`: httpx TestClient로 라우트 검증
4. **로컬 검증**:
   ```bash
   make lint && make typecheck && make test && make docker-build
   ```
5. **마이그레이션 검토**: `alembic revision --autogenerate` 후 생성된 SQL을 수동 확인
6. **자가 리뷰**: `git diff` 적대적 시각으로 한 번

## 절대 하지 말 것

- `domain/` 에서 FastAPI / SQLAlchemy / Pydantic import (Protocol 만 정의)
- SQLAlchemy 모델을 그대로 response_model 사용 → DTO 변환 필수
- 라우터 함수에 비즈니스 로직 (use case로 위임)
- 글로벌 `engine = create_engine(...)` — lifespan에서 관리
- `pyproject.toml` 직접 편집 (`uv add` / `uv remove` 사용)
- `--no-verify` pre-commit 우회

## 주요 명령

```bash
make install               # uv sync + pre-commit
make run                   # uvicorn dev server
make migrate-rev MSG="..."  # 새 마이그레이션
make migrate-up            # 적용
make docker-up             # postgres + api 컨테이너 기동
```

## 참조

- `~/.claude/rules/python/style.md`, `python/testing.md`, `python/docker.md`
- `~/.claude/rules/python/fastapi.md` — 이 스택 전용 룰
- `~/.claude/skills/fastapi-add-module/SKILL.md` — 새 모듈 추가 워크플로
