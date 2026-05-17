# Python Docker Rules

## Dockerfile
- Base image: `python:3.12-slim` (alpine은 C 확장 빌드 문제)
- multi-stage build 필수 (base → production / development)
- uv는 COPY --from으로 설치: `COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv`
- 의존성 파일(pyproject.toml, uv.lock)을 먼저 복사하여 레이어 캐시 활용
- 소스 코드는 마지막에 복사
- root 유저로 실행하지 말 것 — `RUN useradd -m app && USER app`
- .dockerignore 필수

## docker-compose
- development target 사용
- 소스 코드는 volume mount: `./src:/app/src`
- env_file로 환경변수 관리
- PYTHONDONTWRITEBYTECODE=1, PYTHONUNBUFFERED=1 설정

## .dockerignore 필수 내용
```
.venv/
__pycache__/
.git/
.pytest_cache/
.ruff_cache/
*.pyc
.env
.env.*
dist/
build/
```

## 보안
- 시크릿을 Dockerfile에 넣지 말 것
- 빌드 인자(ARG)로 시크릿 전달 금지
- Docker secrets 또는 환경변수 사용
- 이미지 크기 최소화: 불필요한 패키지 설치 금지
