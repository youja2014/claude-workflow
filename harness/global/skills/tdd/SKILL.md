---
name: tdd
description: |
  TDD (Test-Driven Development) 방식으로 기능을 구현합니다 ([[user-workflow]] 의 개발 단계).
  RED (실패 테스트) → GREEN (최소 구현) → REFACTOR (개선) 사이클을 한 번 또는 여러 번
  반복. tdd-guide agent 위임 가능. 각 단계마다 pytest/vitest 로 검증.
  TRIGGER when: 사용자가 `/tdd <기능>` 호출, "TDD 로 만들어줘", "테스트 먼저 작성하고
  구현해줘", "RED-GREEN 사이클로" 형태의 TDD 요청.
  SKIP when: 단순 1 줄 fix (테스트 먼저가 과함), prototype / 탐색적 코드 (요구사항이
  불명확해 테스트가 추측이 됨 — 먼저 요구사항 정리 권장), 이미 구현 코드가 있고
  뒤늦게 테스트만 추가하는 경우 (이건 retro-test 라 별개 워크플로).
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
argument-hint: "<feature-description>"
---

# tdd

`$ARGUMENTS` 의 기능을 RED → GREEN → REFACTOR 사이클로 구현.

## 1. tdd-guide agent 위임 검토

`~/.claude/agents/tdd-guide.md` 가 있고 기능이 비-trivial (3+ 사이클 예상) 이면 agent 에 위임.
단순 한 사이클이면 직접 진행.

## 2. 요구사항 1 줄 정리

`$ARGUMENTS` 를 한 줄 요구사항으로 명확히. 사용자에게 확인 받음 — 모호하면 진행 안 함.

```
요구사항: <함수/클래스>는 <입력>이 주어질 때 <기대 출력>을 반환한다.
edge case: <empty/null/boundary/concurrent>
```

## 3. 사이클 진행 (반복)

### RED — 실패하는 테스트 작성

```python
# tests/test_<module>.py
def test_<행위>_<조건>_<기대결과>():
    # arrange
    ...
    # act
    result = target_under_test(input)
    # assert
    assert result == expected
```

```bash
uv run pytest tests/test_<module>.py -v
# → FAIL 또는 ImportError (target 이 아직 없음). 이게 정상.
```

테스트가 실패 이유가 "구현 없음" 인지 "테스트 자체 오류" 인지 확인. 후자면 테스트부터 고침.

### GREEN — 최소 구현

```python
# src/<pkg>/<module>.py
def target_under_test(input):
    return expected  # 하드코딩도 OK — 다음 테스트가 일반화 강제
```

```bash
uv run pytest tests/test_<module>.py -v
# → PASS
```

완벽 구현 시도 금지. 테스트만 통과시킴.

### REFACTOR — 개선

- 중복 제거 (DRY)
- 네이밍 개선
- 함수 분할 (50 줄 이하)
- 테스트 자체도 리팩토링 대상 (중복 fixture, 명확성)

```bash
uv run pytest tests/test_<module>.py -v
# → 여전히 PASS 인지 확인. 실패하면 즉시 롤백.
```

## 4. 다음 사이클 결정

- 더 잘게 쪼개야 할 edge case 가 남음 → RED 부터 다시
- 요구사항 충족됐고 코드 깨끗함 → 완료

## 5. 최종 검증

### Python
```bash
uv run pytest -v                          # 전체 테스트 (회귀 확인)
uv run ruff check src/ tests/            # lint
uv run pyright src/                       # type
make verify                               # 메타 프로젝트면
```

### TypeScript / Nx
```bash
yarn nx run-many -t test                  # 전체 테스트 (또는 nx affected)
yarn nx run-many -t lint
yarn nx run-many -t typecheck
make verify
```

## 5b. TypeScript variant — 도구 대체

본 SKILL 의 RED → GREEN → REFACTOR 사이클은 동일. 도구만 stack 별 분기:

| 항목 | Python | TypeScript |
|---|---|---|
| 단위 테스트 (web) | pytest | Vitest (`apps/web`) |
| 단위 테스트 (api) | pytest | Jest (`apps/api`, NestJS) |
| watch 모드 | `pytest-watch` | `yarn vitest` / `yarn jest --watch` |
| 단일 테스트 | `pytest tests/test_x.py::test_y -v` | `yarn vitest x.test.ts` / `yarn jest --testNamePattern="..."` |
| Assertion | `assert`, `pytest.raises` | `expect().toBe()`, `expect().toThrow()` |
| mock 라이브러리 | `pytest-monkeypatch`, `unittest.mock` | `vi.mock()`, `jest.mock()`, MSW (HTTP) |

RED 예시 (TS, vitest):
```ts
import { describe, it, expect } from 'vitest';
import { calculateProfit } from './profit-calculator';

describe('calculateProfit', () => {
  it('returns total profit for valid trades', () => {
    const result = calculateProfit([{ buy: 100, sell: 150 }]);
    expect(result.totalProfit).toBe(50);
  });
});
```
→ `yarn vitest profit-calculator` 실행 → FAIL (target 없음). 정상.

자세한 룰: `~/.claude/rules/typescript/testing.md` + tdd-guide agent 본문.

## 6. 규칙

- 실패하는 테스트 없이 프로덕션 코드를 작성하지 말 것
- 한 번에 하나의 테스트만 작성
- 리팩토링 시 새 기능 추가 금지 (별도 RED 사이클)
- mock 은 외부 의존성에만 (rules/python/testing.md)

## 출력 형식

각 사이클:

```markdown
### RED [사이클 N]: <테스트 설명>
[테스트 코드]
실행 결과: FAIL (이유: ...)

### GREEN: <구현 설명>
[최소 구현 코드]
실행 결과: PASS

### REFACTOR: <개선 설명>
[변경된 부분만]
실행 결과: PASS (회귀 없음)
```

## 참조

- tdd-guide agent (위임 시 권위)
- `rules/python/testing.md` — fixture, assertion, mock, 커버리지
- [[user-workflow]] 의 개발 단계
