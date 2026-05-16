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
