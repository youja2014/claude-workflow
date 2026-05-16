---
name: fastapi-add-module
description: |
  FastAPI 프로젝트에 새 도메인 모듈을 4-layer hexagonal-lite (domain → application → infrastructure → api)
  구조로 생성하고 Alembic 마이그레이션, 단위/통합 테스트 스켈레톤, 라우터 등록까지 자동화한다.
  TRIGGER when: cwd 에 `src/<pkg>/{api,application,domain,infrastructure}/` 가 모두 존재하고 사용자가
  "새 모듈/엔티티/리소스 추가" 또는 "<X> CRUD 만들어줘" 형태로 요청.
  SKIP when: 단일 파일 변경(엔드포인트 1개 추가), 기존 모듈 수정, Flask/Django 등 다른 웹 프레임워크,
  도메인 레이어가 없는 단순 CRUD 스크립트.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# fastapi-add-module

FastAPI(`templates/python-fastapi` 기반) 프로젝트에 새 도메인 모듈을 추가하는 워크플로.

## 적용 조건

- 현재 작업 디렉토리에 `src/<package>/{api,application,domain,infrastructure}/` 가 존재
- `pyproject.toml` 에 `fastapi`, `sqlalchemy`, `alembic` 의존성 존재

이 조건을 만족하지 않으면 작업을 중단하고 사용자에게 알리세요.

## 입력

사용자에게 다음을 묻기:
1. **모듈 이름** (단수 명사, snake_case — 예: `user`, `order_item`)
2. **속성 목록** (이름:타입 — 예: `email:str, age:int, created_at:datetime`)
3. **CRUD 범위** (어떤 라우트를 만들지: create/read/update/delete 중 선택)

## 생성할 파일 (의존 순서대로)

### 1. Domain — `src/<package>/domain/entities/<module>.py`

```python
from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class <Module>:
    id: <IdType>
    # ... 사용자 입력 속성
```

### 2. Domain — `src/<package>/domain/repositories/<module>_repository.py`

```python
from __future__ import annotations
from typing import Protocol
from <package>.domain.entities.<module> import <Module>

class <Module>Repository(Protocol):
    async def get_by_id(self, id: <IdType>) -> <Module> | None: ...
    async def add(self, entity: <Module>) -> None: ...
    # ... 필요한 메서드
```

### 3. Application — `src/<package>/application/<module>/create_<module>.py`

```python
from __future__ import annotations
from dataclasses import dataclass
from <package>.domain.entities.<module> import <Module>
from <package>.domain.repositories.<module>_repository import <Module>Repository

@dataclass
class Create<Module>Command:
    # 입력 필드

class Create<Module>UseCase:
    def __init__(self, repo: <Module>Repository) -> None:
        self._repo = repo

    async def execute(self, cmd: Create<Module>Command) -> <Module>:
        ...
```

### 4. Infrastructure — `src/<package>/infrastructure/db/models/<module>.py`

```python
from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column
from <package>.infrastructure.db.base import Base

class <Module>Model(Base):
    __tablename__ = "<modules>"
    id: Mapped[int] = mapped_column(primary_key=True)
    # ... 매핑된 속성
```

### 5. Infrastructure — `src/<package>/infrastructure/db/repositories/<module>_repository.py`

도메인 Repository Protocol 구현체. ORM ↔ Domain 매퍼 함수 포함.

### 6. API — `src/<package>/api/schemas/<module>.py`

Pydantic v2 `BaseModel` 요청/응답 DTO:

```python
class <Module>CreateRequest(BaseModel):
    # 입력
class <Module>Response(BaseModel):
    # 응답
```

### 7. API — `src/<package>/api/v1/routes/<modules>.py`

FastAPI 라우터:

```python
router = APIRouter(prefix="/<modules>", tags=["<modules>"])

@router.post("", response_model=<Module>Response, status_code=201)
async def create(
    payload: <Module>CreateRequest,
    use_case: Annotated[Create<Module>UseCase, Depends(get_create_<module>_use_case)],
) -> <Module>Response: ...
```

### 8. API — `src/<package>/api/v1/deps.py` 에 Provider 추가

```python
def get_<module>_repo(...) -> <Module>Repository:
    return SqlAlchemy<Module>Repository(...)

def get_create_<module>_use_case(...) -> Create<Module>UseCase:
    return Create<Module>UseCase(repo=...)
```

### 9. 라우터 등록 — `src/<package>/main.py` 또는 `src/<package>/api/v1/__init__.py`

```python
from <package>.api.v1.routes import <modules>
app.include_router(<modules>.router, prefix="/v1")
```

### 10. Alembic 마이그레이션

```bash
cd <project_root>
uv run alembic revision --autogenerate -m "add <module> table"
```

생성된 마이그레이션 파일 검토 후 사용자에게 알림 (자동 적용 X).

### 11. 테스트 스켈레톤

- `tests/unit/application/<module>/test_create_<module>.py` — 도메인/use case 단위 테스트 (mock repo)
- `tests/integration/infrastructure/db/test_<module>_repository.py` — testcontainers
- `tests/e2e/api/v1/test_<modules>.py` — httpx TestClient

각 테스트는 최소 하나의 happy path + 에러 케이스 1개 포함.

## 완료 후 검증

```bash
uv run ruff check --fix
uv run ruff format
uv run pyright
uv run pytest tests/unit/application/<module> -v
```

마이그레이션은 사용자가 명시적으로 `alembic upgrade head` 실행하도록 안내.

## 안티패턴 (자동 차단)

- domain 파일에서 SQLAlchemy/Pydantic/FastAPI import 발견 시 → 작업 중단 후 사용자에게 알림
- ORM 모델을 response_model 에 직접 사용 → DTO 변환 강제
- Use case 안에 SQL 작성 → repository로 위임
