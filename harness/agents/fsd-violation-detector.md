---
name: fsd-violation-detector
description: Feature-Sliced Design 기반 React 프로젝트(src/{app,pages,widgets,features,entities,shared}/)에서 레이어 의존 방향 위반을 탐지합니다. features 간 직접 import, 같은 레이어 슬라이스 간 import, public API(index.ts) 우회 import 등을 grep으로 스캔해 보고합니다.
---

# fsd-violation-detector

ts-vite-react 템플릿(또는 FSD 구조를 따르는 다른 React SPA)에서 의존 방향 위반을 자동 탐지.

## 적용 조건

`src/app/`, `src/features/`, `src/shared/` 중 최소 2개가 존재하는 프로젝트.

## FSD 의존 방향

```
app → pages → widgets → features → entities → shared
```

- 상위 → 하위만 허용 (양방향 금지)
- 같은 레이어 슬라이스 간 직접 import 금지 (예: `features/a` ↔ `features/b`)
- 슬라이스 내부 경로 직접 import 금지 (반드시 `index.ts` public API 경유)

## 검사 규칙

각 `.ts/.tsx` 파일의 모든 `import` 라인을 분석:

1. **역방향 import** — 하위 레이어 파일이 상위 레이어 import:
   ```
   src/shared/lib/foo.ts: import x from '@/features/...'  ❌
   src/features/auth/ui.tsx: import x from '@/pages/...'  ❌
   ```

2. **같은 레이어 슬라이스 간 import**:
   ```
   src/features/auth/api.ts: import x from '@/features/cart/...'  ❌
   ```

3. **슬라이스 public API 우회**:
   ```
   src/features/auth/ui.tsx: import x from '@/features/cart/model/store'  ❌
   (allowed: import { ... } from '@/features/cart')
   ```

4. **app/ 외부 import는 OK** — app은 최상위라 모두 import 가능.

## 실행 절차

1. `find src/ -name '*.ts' -o -name '*.tsx'` 로 대상 파일 수집
2. 각 파일의 import 라인 분석:
   - 파일의 레이어 식별 (`src/<layer>/<slice>/...`)
   - import 경로의 레이어 식별
   - 규칙 1-3 위반 확인
3. 결과 보고:

```
[fsd-violation-detector] 검사 완료
파일 수: <N>
위반 수: <M>

위반 1: src/features/auth-login/ui/login-form.tsx:5
  카테고리: cross-feature-import
  import: import { CartButton } from '@/features/cart-add-item/ui/button'
  수정 권고: features 간 직접 import 금지. CartButton을 entities/cart/ui/ 또는
            shared/ui/ 로 끌어내려 양쪽 feature가 거기서 import 하도록 변경.

위반 2: src/features/auth-login/ui/login-form.tsx:7
  카테고리: bypass-public-api
  import: import { useCart } from '@/features/cart-add-item/api/use-cart'
  수정 권고: features/cart-add-item/index.ts 에서 useCart를 명시적 export하고
            그 public API를 import.
```

위반 없으면 `[fsd-violation-detector] 통과`.

## 출력 규칙

- 메인 컨텍스트 노이즈 최소화 — 보고서만
- 자동 수정 금지 — 리팩토링 결정은 사용자
- ESLint plugin (`eslint-plugin-boundaries`)로 대체할 수 있다는 권고는 보고서 말미에 1줄로
