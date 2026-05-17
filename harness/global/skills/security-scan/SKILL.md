---
name: security-scan
description: |
  프로젝트의 보안 취약점을 스캔합니다 ([[user-workflow]] 의 검증 단계, 또는 배포 직전).
  rules/common/security.md 기준으로 시크릿/입력 검증/의존성/Docker 보안 6 항목 검사
  + 심각도별 분류 + 수정 코드 제안. 외부 도구 (gitleaks, trivy 등) 가 있으면 활용,
  없으면 grep 기반 정적 검사.
  TRIGGER when: 사용자가 `/security-scan` 호출, "보안 점검", "취약점 확인",
  "배포 전 점검", "시크릿 누출 검사" 형태의 보안 검토 요청. PR/배포 직전 단계.
  SKIP when: 변경사항이 보안과 무관 (문서/주석/포매팅만), 이미 동일 범위로
  보안 스캔이 끝남, 외부 보안 도구가 별도로 돌고 있어 중복.
allowed-tools: [Read, Bash, Glob, Grep, Agent]
---

# security-scan

## 1. 검사 범위 결정

기본: 변경된 파일 (`git diff --name-only`). 사용자가 `$ARGUMENTS` 로 경로 지정하면 그 경로.
전체 검사가 필요하면 명시적으로 "전체 스캔" 호출 받기.

## 2. 6 항목 검사 (rules/common/security.md 기준)

### (a) 하드코딩 시크릿
```bash
# API 키, 토큰, 비밀번호 패턴
grep -rEn "(api[_-]?key|secret|token|password|passwd)['\"]?\s*[:=]\s*['\"][^'\"]{8,}" \
  --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.go" \
  src/ apps/ libs/ 2>/dev/null

# 외부 도구가 있으면 우선:
command -v gitleaks >/dev/null && gitleaks detect --no-banner
```

### (b) .env / .gitignore 정합성
- `.env`, `.env.*` 가 `.gitignore` 에 포함됐는지
- `git ls-files | grep -E '^\.env'` 가 비어있는지 (실수로 커밋된 적 없는지)
- `.env.example` 만 커밋되어 있는지

### (c) SQL 인젝션
```bash
# 문자열 포매팅으로 쿼리 생성하는 패턴
grep -rEn 'execute\([^)]*[fF]"' --include="*.py" src/    # f-string
grep -rEn "execute\([^)]*\+.*\)" --include="*.py" src/   # 문자열 연결
grep -rEn "raw\(['\"]\s*SELECT" --include="*.ts" --include="*.py" .
```

파라미터 바인딩 (`?`, `$1`, `:name`) 만 안전.

### (d) 입력 검증 누락
- API 핸들러에서 Pydantic / class-validator / Zod 등 검증 스키마 사용 여부
- 파일 경로 입력에 `..` 차단 (path traversal)
- 외부 redirect URL whitelist 검증
- React: `dangerouslySetInnerHTML` 사용처에 sanitization (DOMPurify 등) — `grep -rn dangerouslySetInnerHTML apps/web/src/`

### (d-1) 클라이언트 환경변수 누설 (TS / Vite 전용)
- Vite 는 `VITE_*` 프리픽스만 클라이언트 번들에 노출. 비밀이 잘못 노출되면 빌드 결과에 영구 박힘
- 점검: `grep -rEn "VITE_[A-Z_]+(SECRET|TOKEN|PASSWORD|KEY)" apps/web/`
- 점검: `.env` 의 `VITE_*` 항목 중 비밀 키워드 포함 여부

### (e) 안전하지 않은 의존성
```bash
# Python
uv pip check 2>&1
command -v pip-audit >/dev/null && pip-audit

# TS
yarn npm audit 2>&1 || npm audit 2>&1

# 컨테이너 이미지
command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL .
```

### (f) Docker 보안
- Dockerfile 에 `USER app` (또는 non-root) 있는지
- 시크릿이 빌드 ARG / ENV 로 들어가지 않는지
- `.dockerignore` 에 `.env`, `.git` 포함
- compose 의 `secrets:` 또는 외부 secret 매니저 사용 여부

## 3. 결과 분류

| 심각도 | 정의 | 대응 |
|---|---|---|
| **CRITICAL** | 운영 영향 — 시크릿 누출, SQL injection, public 입력 검증 누락 | 즉시 수정, 배포 차단 |
| **HIGH** | 가까운 미래 risk — 알려진 취약 의존성, non-root 미사용 | 다음 PR 또는 단기 |
| **MEDIUM** | 깊이 있는 검토 필요 | 후속 이슈 |
| **LOW / INFO** | 모범 사례 권장 | 작성자 판단 |

## 4. 수정 코드 제안

CRITICAL/HIGH 에는 구체 수정 코드 또는 명령:

```python
# Before (CRITICAL — SQL injection)
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# After
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

## 5. 부수 산출물

- `.env.example` 없으면 생성 제안 (필요 환경 변수 목록만, 값 없이)
- gitleaks/trivy/pip-audit 가 없는데 검사 가치 있으면 설치 안내 (`winget install`, `uv tool install`)

## 6. 결과 보고

```
## 보안 스캔 결과

**스코프:** <파일 N 개 / 전체>

### CRITICAL (M 건)
- `path/to/file.py:42` — 하드코딩 시크릿 (token=...)
  → .env 로 이동 + `.gitignore` 추가

### HIGH (K 건)
- ...

**결론:** safe-to-merge / blocked / needs-revision
**도구 권장:** gitleaks, trivy, pip-audit (없으면 설치 안내)
```

## 6b. TypeScript variant — 도구 대체

본 SKILL 의 6 항목 + 심각도 분류는 stack 무관. 도구·점검 포인트만 분기:

| 항목 | Python | TypeScript / Nx |
|---|---|---|
| 의존성 audit | `uv pip check`, `pip-audit` | `yarn npm audit` |
| 컨테이너 이미지 | `trivy fs` | `trivy fs` (공통) |
| 시크릿 스캔 | `gitleaks detect` (공통) | `gitleaks detect` (공통) |
| 입력 검증 스키마 | Pydantic v2 | class-validator (NestJS), Zod (Vite/React) |
| 클라이언트 비밀 누설 | — | **`VITE_*` 프리픽스만 번들 노출** — 비밀 키워드 점검 (위 d-1) |
| XSS / DOM | Jinja autoescape 등 | `dangerouslySetInnerHTML` + DOMPurify (위 d) |
| Docker non-root | `USER app` | `USER app` (공통) |

빠른 참조: TS / Nx 점검 최소 셋
```bash
# VITE_* 환경변수 비밀 누설
grep -rEn "VITE_[A-Z_]+(SECRET|TOKEN|PASSWORD|KEY)" apps/web/ .env* 2>/dev/null

# dangerouslySetInnerHTML 사용처 sanitization 확인
grep -rn dangerouslySetInnerHTML apps/web/src/

# 의존성 + 이미지
yarn npm audit
command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL .
```

자세한 룰: `~/.claude/rules/typescript/{docker,react,nestjs}.md`, `~/.claude/rules/common/security.md`.

## 참조

- `rules/common/security.md` — 보안 룰 출처
- `rules/python/docker.md` / `rules/typescript/docker.md` — 컨테이너 보안
