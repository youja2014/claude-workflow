# Python CLI 프로젝트 룰

## 폴더 구조 (3-layer lite)

```
src/<package>/
├── __init__.py
├── app.py              # Typer 엔트리포인트 (app = typer.Typer())
├── commands/           # 각 서브커맨드 1파일 (interface layer)
│   ├── __init__.py
│   └── <verb>.py       # e.g. sync.py
├── core/               # 순수 비즈니스 로직 (CLI/IO 독립)
├── adapters/           # 파일/HTTP/외부 API 어댑터
├── config.py           # pydantic-settings 환경변수 로딩
└── constants.py
```

`pyproject.toml` 에 `[project.scripts]` 로 엔트리포인트 등록:

```toml
[project.scripts]
<project-kebab> = "<package>.app:app"
```

## 의존 방향

- `commands → core ← adapters` (단방향)
- `core/` 는 Typer/requests/sqlite/외부 라이브러리 import 금지
- `adapters/` 는 외부 라이브러리를 캡슐화. core는 인터페이스(Protocol)만 안다.
- 테스트 시 어댑터를 fake로 교체

## 핵심 의존성

- `typer` — CLI 프레임워크 (click 기반)
- `pydantic-settings` — 환경변수 / .env 로딩
- `structlog` — 구조화 로깅
- `rich` — Typer가 자동으로 활용하는 출력 포매팅

## 안티패턴

- `core/` 에서 `print` 호출 금지 — Typer는 `commands/` 에서만 사용
- 글로벌 변수로 설정 보관 금지 — `config.py` 의 `Settings()` 인스턴스를 의존성 주입
- `sys.exit()` 를 core/adapters 에서 호출 금지 — 예외를 raise하고 commands/에서 처리

## 테스트

- Typer CLI 자체는 `typer.testing.CliRunner` 로 e2e 테스트
- `core/` 는 일반 pytest로 단위 테스트 (mock 불필요)
- `adapters/` 는 외부 의존성이 있는 부분만 통합 테스트

## 빌드/배포

- multi-stage Dockerfile + non-root user
- `uv build` 로 wheel 생성 가능
- `uv tool install .` 로 시스템 전역 설치 (개발용)
