# Python FastAPI 프로젝트 룰

## 폴더 구조 (4-layer hexagonal-lite)

```
src/<package>/
├── api/                       # interface layer
│   ├── v1/
│   │   ├── routes/            # FastAPI 라우터
│   │   │   └── users.py
│   │   └── deps.py            # Depends() 의존성 주입
│   └── schemas/               # Pydantic v2 요청/응답 DTO
├── application/               # use case 계층
│   └── users/
│       └── create_user.py     # CreateUserUseCase
├── domain/                    # 순수 도메인 (프레임워크 무관)
│   ├── entities/
│   ├── value_objects/
│   ├── repositories.py        # Repository Protocol 정의
│   └── exceptions.py
├── infrastructure/            # adapters
│   ├── db/
│   │   ├── models/            # SQLAlchemy 2.0 DeclarativeBase, Mapped
│   │   ├── repositories/      # IUserRepo 구현체
│   │   └── session.py
│   └── external/              # HTTP/메시지큐 어댑터
├── core/
│   ├── config.py              # pydantic-settings
│   └── logging.py             # structlog 설정
└── main.py                    # FastAPI 인스턴스 + lifespan

migrations/                    # alembic
├── env.py                     # async 엔진용
└── versions/

tests/
├── unit/                      # domain/application 단위 (DB 없음)
├── integration/               # repository + 실DB (testcontainers)
└── e2e/                       # httpx + TestClient
```

## 의존 방향

```
api ──▶ application ──▶ domain ◀── infrastructure
```

- `domain/` 은 어떤 프레임워크/라이브러리도 import 금지 (SQLAlchemy, Pydantic 모두 NO)
- `application/` 은 domain + repository Protocol 만 안다
- `infrastructure/` 가 Protocol을 구현. `api/deps.py` 가 `Depends()` 로 주입

## 3종 엔티티 분리 (필수)

1. **DTO** — `api/schemas/` 의 Pydantic v2 BaseModel (요청/응답 직렬화)
2. **Domain entity** — `domain/entities/` 의 `@dataclass` 또는 일반 클래스 (순수 비즈니스)
3. **ORM model** — `infrastructure/db/models/` 의 SQLAlchemy DeclarativeBase

세 객체는 절대 같지 않다. mapper 함수 또는 클래스 메서드로 변환:

```python
# infrastructure/db/repositories/user_repository.py
def _to_domain(orm: UserORM) -> User:
    return User(id=orm.id, email=orm.email, ...)
```

## 의존성 주입

- 기본은 **FastAPI `Depends`** — 90% 케이스에 충분
- `api/deps.py` 에 Provider 함수 정의:

```python
def get_user_repo(db: Annotated[AsyncSession, Depends(get_session)]) -> UserRepository:
    return SqlAlchemyUserRepository(db)
```

- Use case 30개+ / 복잡한 스코프 필요 시에만 `dishka` 검토

## 핵심 의존성

- `fastapi` + `uvicorn[standard]`
- `sqlalchemy[asyncio]` (2.0+) + `asyncpg`
- `alembic` — 마이그레이션
- `pydantic` v2 + `pydantic-settings`
- 테스트: `httpx` + `pytest-asyncio` + `factory-boy` + `testcontainers-postgres`

## 안티패턴

- `domain/` 에서 `pydantic.BaseModel` import 금지
- SQLAlchemy 모델을 그대로 response에 반환 금지 — 반드시 DTO로 변환
- 라우터 함수에 비즈니스 로직 작성 금지 — use case로 위임
- 글로벌 `engine = create_engine(...)` 금지 — lifespan에서 생성 후 의존성 주입

## 마이그레이션

- `alembic/env.py` 를 async 엔진용으로 커스터마이즈
- 모든 마이그레이션은 코드 리뷰 — 데이터 손실 SQL은 별도 작업
- `alembic revision --autogenerate` 후 반드시 수동 검토

## 테스트 분리

- `unit/`: 도메인 로직 + use case (DB 없음, mock 없음 — pure)
- `integration/`: testcontainers-postgres 로 실DB. Repository 검증
- `e2e/`: `httpx.AsyncClient(transport=ASGITransport(app=app))` 로 라우트 검증
