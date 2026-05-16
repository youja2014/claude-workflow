---
description: 현재 프로젝트에 pre-commit (Python) 또는 husky v9 + lint-staged + commitlint (TypeScript) 를 자동 설치합니다.
argument-hint: [--lang=auto|python|typescript]
---

# setup-hooks

현재 디렉토리의 프로젝트 유형을 감지하고 커밋 시점 강제 훅을 설정합니다.

## 감지 로직

1. `pyproject.toml` 존재 → Python
2. `package.json` 존재 → TypeScript
3. 둘 다 있음 → 둘 다 설치
4. `--lang` 명시 시 그것 우선

## Python 경로

```bash
# 1. 의존성 추가
uv add --dev pre-commit ruff pyright

# 2. .pre-commit-config.yaml 생성 (이미 있으면 skip)
# templates/python-*/.pre-commit-config.yaml 의 내용을 복사

# 3. install
uv run pre-commit install
uv run pre-commit install --hook-type commit-msg
```

기본 훅 구성:
- ruff-check (--fix)
- ruff-format
- pyright
- gitleaks (시크릿 차단)
- conventional-pre-commit (커밋 메시지 형식)
- check-added-large-files (500KB 초과 차단)
- end-of-file-fixer, trailing-whitespace
- detect-private-key

## TypeScript 경로

```bash
# 1. 의존성 추가
yarn add -D husky lint-staged @commitlint/cli @commitlint/config-conventional prettier eslint

# 2. husky 초기화
yarn husky init

# 3. .husky/pre-commit 작성
cat > .husky/pre-commit <<'EOF'
yarn lint-staged
EOF

# 4. .husky/commit-msg 작성
cat > .husky/commit-msg <<'EOF'
yarn commitlint --edit "$1"
EOF

# 5. package.json 에 lint-staged 추가
# 6. commitlint.config.js 생성
cat > commitlint.config.js <<'EOF'
module.exports = { extends: ['@commitlint/config-conventional'] };
EOF
```

기본 lint-staged 구성:
```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml,yaml}": ["prettier --write"]
}
```

## 검증

설치 후 다음으로 확인:
```bash
# Python
uv run pre-commit run --all-files

# TypeScript
yarn lint && yarn typecheck
```

## 주의

- pre-commit 에 **테스트 전체 실행을 넣지 마세요** (CI로 분리)
- `tsc --noEmit` 도 pre-commit 보다 pre-push로 (속도 이슈)
- 이미 hook이 있는 경우 덮어쓰지 말고 사용자에게 확인
