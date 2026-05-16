# __project_name__ — Project Context for Claude

## 정체성

- **유형**: Python CLI (Typer 기반)
- **패키지 매니저**: uv
- **타깃 Python**: 3.12+
- **배포**: Docker (multi-stage) + 옵션으로 `uv tool install`

## 문서 위치

이 `CLAUDE.md` 는 *광역 불변 정책* (의존 방향, 절대 하지 말 것, DoD)만 둡니다. 변화하는 정보(계획/현황/의사결정/인계)와 영역별 가이드는 `docs/` 에서 관리합니다. 진입점: [`docs/README.md`](./docs/README.md).

## 아키텍처 (3-layer lite)

```
src/__package__/
├── app.py              # Typer 엔트리포인트
├── commands/           # 서브커맨드 (interface)
├── core/               # 순수 비즈니스 로직 — 외부 라이브러리 import 금지
├── adapters/           # I/O 어댑터 (파일, HTTP, DB)
├── config.py           # pydantic-settings
└── constants.py
```

의존 방향: `commands → core ← adapters`

## Definition of Done

새 기능을 "완료"로 선언하기 전에 반드시:

1. **계획 명시**: 변경 의도를 commit message 또는 issue에 1줄 이상
2. **참조 확인**: 추가/변경된 심볼이 호출처에서 실제 사용됨을 grep
3. **테스트 작성**: 최소 happy path 1개 + 에러 케이스 1개 (`tests/unit/` 또는 `tests/integration/`)
4. **로컬 검증** (모두 통과):
   ```bash
   make lint
   make typecheck
   make test
   make docker-build
   ```
5. **자가 리뷰**: `git diff` 를 적대적 시각으로 한 번 읽기 (보안, 엣지케이스, 의도하지 않은 변경)

## 절대 하지 말 것

- `core/` 에서 `typer`, `requests`, `httpx`, DB 라이브러리 import
- `core/` 에서 `print` 호출 (출력은 `commands/` 에서)
- `--no-verify` 로 pre-commit 우회
- `pyproject.toml` 직접 편집 (`uv add` / `uv remove` 사용)

## 주요 명령

```bash
make install        # uv sync + pre-commit install
make run ARGS="..." # CLI 실행
make test           # pytest
make docker-build   # 이미지 빌드
```

## 참조

- `~/.claude/rules/python/style.md`, `python/testing.md`, `python/docker.md`
- `~/.claude/rules/python/cli.md` — 이 스택 전용 룰
