# Architecture

## 폴더 구조

(프로젝트의 디렉토리 트리와 각 책임을 1-2줄로 기술. 모노레포라면 apps/libs 구조 + 의존 방향 명시.)

```
<project-root>/
├── apps/
│   ├── api/         (backend — NestJS)
│   └── web/         (frontend — Vite + React)
├── libs/
│   └── shared-*/    (양 앱이 import 하는 공유 코드)
└── infra/           (DB, cache 등 인프라 정의)
```

## 의존 방향 (boundary)

(어떤 영역이 어떤 영역을 import 가능한지 화살표로 명시. ESLint enforce-module-boundaries 또는 동등한 룰이 강제하는 사실과 일치해야 함.)

## 핵심 라이브러리 선택

| 영역 | 라이브러리 | 선택 이유 |
|---|---|---|
| ORM | (e.g. Prisma) | (이유) |
| HTTP framework | (e.g. NestJS) | (이유) |
| Frontend | (e.g. React + Vite) | (이유) |

## 외부 시스템 의존성

(DB / cache / message queue / 외부 API 등. 각 항목에 1줄 — "왜 필요한지" 위주.)

## DB 스키마 ERD

물리 ERD — 실제 테이블 / 컬럼 / 타입 / PK·FK / 제약 / 인덱스. 도메인 ERD 와 별도 책임 ([`domain/erd.md`](./domain/erd.md) 참조).

**Truth 는 `apps/api/prisma/schema.prisma`** — 그 위의 ERD 는 자동 생성을 권장:

```bash
# apps/api/prisma/schema.prisma 에 generator 블록 추가
# generator erd { provider = "prisma-erd-generator" output = "../../../docs/schema.svg" }
# 의존성: yarn workspace api add -D prisma-erd-generator
yarn nx exec --project=api -- prisma generate
```

생성 결과를 아래에 임베드 또는 링크:

```
<!-- e.g. ![DB Schema](./schema.svg) -->
```

마이그레이션 추가 시 같이 갱신 (`prisma generate` 한 번 다시 실행).
