---
name: feature-orchestrator
description: |
  풀스택 feature 추가 요청 (backend + frontend + infra 동시 변경) 을 받았을 때 영역별 sub-agent
  로 병렬 디스패치합니다. 이 skill 은 메인 대화에서 실행되어 Agent 도구로 서브에이전트를 띄울 수
  있습니다 — agent 로 위임되면 깊이-1 제약상 서브에이전트 생성이 불가능하므로 skill 이어야 합니다
  (근거: docs/decisions/0004-orchestrator-as-skill.md).
  TRIGGER when: 사용자가 `/feature-orchestrator ...` 호출, "<X> 기능 추가", "<X> 페이지 + API",
  "풀스택 <X>", "주문 조회 + UI" 등 backend/frontend/infra 중 2+ 영역을 동시에 건드리는 입력,
  또는 `/plan` 결과 영역 2+개 (api, web, infra, libs/shared-types 중 2 이상) 식별 시.
  SKIP when: 변경 영역 1개 (fastapi-add-module / nestjs-add-module / react-add-feature 가 적합),
  프로토타입/탐색 코드 (계약이 자주 바뀌어 병렬 비용이 직렬보다 큼), 사용자가 명시적으로 단일 영역
  지정 ("backend 에만"), 단일 파일 1-2 줄 패치.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
argument-hint: "<feature-description>"
---

# feature-orchestrator

이 skill 은 backend / frontend / infra 가 동시에 변경되는 feature 요청을 받았을 때 **순차 처리 비용**과 **영역 전환 컨텍스트 재로딩 비용**을 동시에 줄이기 위해 사용합니다.

> **왜 agent 가 아니라 skill 인가** — Claude Code 서브에이전트는 자기 컨텍스트에서 독립 실행 후 요약만 회신하며 **다른 서브에이전트를 생성하는 도구(Agent/Task)가 없습니다 (깊이-1 제약, 실측 확인됨)**. 따라서 "영역별 서브에이전트를 병렬 dispatch" 하는 본 오케스트레이션은 agent 로 위임되면 작동하지 않습니다. skill 은 **메인 대화에서 실행**되어 `Agent` 도구를 그대로 쓸 수 있으므로 dispatch 가 가능합니다. 결정 근거: `docs/decisions/0004-orchestrator-as-skill.md`.

`$ARGUMENTS` 의 feature 요청을 다음 순서로 처리합니다.

## 트리거 / SKIP 조건

**적용 (오케스트레이션)**:
- 사용자 입력에 "기능 추가", "feature", "페이지 + API", "풀스택" 등 키워드 + 영역 2+개 변경 예상
- `/plan` 결과 영역 2+개 (api, web, infra, libs/shared-types 중 2 이상) 식별

**SKIP**:
- 변경 영역 1개 (예: "API 응답 필드 추가") — `fastapi-add-module` / `nestjs-add-module` / `react-add-feature` 가 직접 적합
- 프로토타입 / 탐색 코드 (계약이 자주 바뀌어 병렬 비용이 직렬보다 큼)
- 사용자가 명시적으로 영역 지정 ("backend 에만 X 추가")
- 단일 파일 1-2 줄 패치

## 단계 1 — 프로젝트 구조 감지

cwd 에서 다음 두 변형 중 어느 쪽인지 식별:

| 신호 | 변형 |
|---|---|
| `apps/api/` + `apps/web/` + `libs/` + `nx.json` | **A: Nx 모노레포** |
| `src/<pkg>/api/` + `pyproject.toml` (FastAPI) + 별도 frontend repo (또는 `apps/web/`) | **B: Python FastAPI + frontend** |
| 둘 다 매치 안 됨 | SKIP — 단일 스택 add-module skill 안내 |

구조가 모호하면 사용자에게 1줄 질문 후 진행.

## 단계 2 — 영역 식별 + 의존 그래프

feature 입력을 다음 영역으로 분류 (한 영역에 안 걸리면 생략):

- **backend** — REST/GraphQL 엔드포인트, 도메인 로직, DB 스키마, 마이그레이션
- **frontend** — 페이지, 컴포넌트, 폼, 상태, API 호출 훅
- **infra** — docker-compose 환경변수, 외부 서비스 추가, healthcheck, 마이그레이션 실행 순서
- **shared (계약)** — 양쪽이 의존하는 타입/스키마. 단계 3 의 산출물 위치

의존 그래프:
```
shared (계약) ──┬──> backend
                └──> frontend
infra ─ (보통 backend 환경변수 의존)
```
→ **계약 먼저, 그 다음 backend/frontend 병렬, infra 는 backend 변경 시점 기준 동시 진행 가능**.

## 단계 3 — 계약 (contract) 우선 정의

병렬 진행의 핵심. 계약을 먼저 확정해야 backend/frontend 가 서로 기다리지 않음.

### 변형 A — Nx 모노레포

`libs/shared-types/src/` 에 TS 타입 + Zod 스키마 또는 인터페이스 정의:

```ts
// libs/shared-types/src/order.ts
import { z } from 'zod';

export const OrderSchema = z.object({
  id: z.string().uuid(),
  totalAmount: z.number().nonnegative(),
  status: z.enum(['pending', 'paid', 'shipped']),
});
export type Order = z.infer<typeof OrderSchema>;
```

NestJS 는 동일 스키마를 `class-validator` DTO 로 wrap (또는 `nestjs-zod` 사용). React 는 동일 타입 import.

### 변형 B — Python FastAPI + frontend

backend Pydantic v2 모델이 단일 진실 (single source of truth). FastAPI 의 자동 OpenAPI 산출물을 frontend 가 타입 생성에 사용:

```python
# src/<pkg>/api/schemas/order.py
from pydantic import BaseModel

class OrderResponse(BaseModel):
    id: str
    total_amount: float
    status: Literal['pending', 'paid', 'shipped']
```

frontend 측 타입 생성 (병렬 진행 가능 시점부터):
```bash
# 백엔드 실행 중일 때:
npx openapi-typescript http://localhost:8000/openapi.json -o src/shared/api/schema.ts
# 또는 backend 가 export 한 openapi.json 파일에서:
npx openapi-typescript ./openapi.json -o src/shared/api/schema.ts
```

계약 단계 산출물 = backend 의 Pydantic 모델 + 생성된 `schema.ts`.

## 단계 4 — 영역별 병렬 디스패치

`Agent` 도구를 **한 메시지에 multi-tool-use** 로 호출. 영역별 sub-agent 는 자기 영역의 컨텍스트만 잡음 → 메인 컨텍스트 재로딩 비용 없음. 각 sub-agent 프롬프트에는 **목적 + 계약 참조 + 완료 기준** 을 명시 (모호한 지시는 중복·엇나감을 부름).

```
[메인 대화 — 이 skill 실행 중]
계약 확정 완료. 3 sub-agent 병렬 호출:

Agent(subagent_type=architect,
      description="Backend feature impl",
      prompt="apps/api/src/modules/orders/ 에 NestJS 모듈 추가.
              계약: libs/shared-types/src/order.ts:OrderSchema.
              완료 기준: yarn nx test api PASS + module 등록 확인.")

Agent(subagent_type=architect,
      description="Frontend feature impl",
      prompt="apps/web/src/features/order-list/ FSD 슬라이스 추가.
              계약: libs/shared-types/src/order.ts:Order 타입 사용.
              완료 기준: yarn nx test web PASS + 라우트 등록.")

Agent(subagent_type=build-error-resolver,
      description="Infra wiring",
      prompt="docker-compose.yml 에 orders 모듈 환경변수 추가.
              backend healthcheck 가 orders 의존 시 대기.
              완료 기준: docker compose up 시 healthy.")
```

병렬 제약:
- 같은 파일을 두 sub-agent 가 동시에 수정하면 충돌 → 단계 2 에서 변경 파일 집합을 영역별로 명확히 분리. 충돌 위험이 크면 `isolation: worktree` 로 격리.
- 계약 변경이 발생하면 단계 3 으로 롤백 후 재진행 (재시도 1회까지).
- sub-agent 는 **요약만 회신** — 장문 결과를 그대로 받으면 메인 컨텍스트가 오염됨.

## 단계 5 — 결과 통합 + 검증

3 영역 결과 머지 후 통합 검증:

### 변형 A (Nx)
```bash
yarn nx affected -t lint,typecheck,test
yarn nx run-many -t build
docker compose up --wait    # healthcheck 통과 확인
```

### 변형 B (Python FastAPI + frontend)
```bash
# backend
uv run pytest && uv run ruff check && uv run pyright
# frontend
yarn nx test web && yarn nx typecheck web   # 또는 yarn test && yarn typecheck
# 계약 정합성
diff <(curl -s localhost:8000/openapi.json | jq -S) <(cat openapi.json | jq -S)
```

검증 실패 시 — 어느 영역에서 깨졌는지 식별 후 해당 sub-agent 만 재호출 (단계 4 부분 재실행).

## 위임 가능한 sub-agent (영역별 권장)

| 영역 | 변형 A (Nx) | 변형 B (Python+frontend) |
|---|---|---|
| backend | `architect` (TS variant) + `nestjs-add-module` skill | `architect` (Python) + `fastapi-add-module` skill |
| frontend | `architect` (TS variant) + `react-add-feature` skill | `react-add-feature` skill |
| infra | `build-error-resolver` (Docker 카테고리) | 동상 |
| 검증 | `code-reviewer` + `clean-arch-detector` / `fsd-violation-detector` | 동상 (Python variant) |

## 출력 형식

```markdown
## feature-orchestrator 결과

### 입력
[feature 요청 원문]

### 구조 감지
변형: A (Nx) / B (Python+frontend)
영역: backend, frontend, infra, shared

### 계약 (단계 3)
[정의된 타입/스키마 파일 경로 + 핵심 필드]

### 병렬 디스패치 (단계 4)
- backend sub-agent: [영역 요약 + 결과]
- frontend sub-agent: [영역 요약 + 결과]
- infra sub-agent: [영역 요약 + 결과]

### 통합 검증 (단계 5)
[실행한 명령 + 결과 PASS/FAIL]

### 후속 작업
[남은 사항 — 마이그레이션, 시드, 문서 등]
```

## 출력 규칙

- 메인 대화 노이즈 최소화 — sub-agent 호출 로그는 본인 컨텍스트, 메인 에는 요약만
- 영역별 sub-agent 결과를 영역별로 명확히 구분해 보고
- 계약 변경이 단계 3 이후 발생하면 명시 경고 ("계약이 변경됨 → 단계 3 재진입 필요")

## 참조

- `architect` — 영역별 설계 위임 시 권위 (model: opus)
- `code-reviewer`, `clean-arch-detector`, `fsd-violation-detector` — 검증 단계 위임
- `fastapi-add-module` / `nestjs-add-module` / `react-add-feature` skill — 영역별 add-module 표준
- `rules/typescript/{nestjs,react}.md`, `rules/python/fastapi.md` — 변형별 룰
- `docs/decisions/0004-orchestrator-as-skill.md` — agent → skill 전환 결정 근거
- `[[user-workflow]]` 의 개발 단계 — 본 skill 은 단일 영역이 아닌 feature 단위에서 호출됨
