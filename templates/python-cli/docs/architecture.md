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
