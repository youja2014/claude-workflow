---
name: react-add-feature
description: Vite + React 프로젝트에 새 feature 슬라이스를 Feature-Sliced Design 규칙대로 추가합니다. features/<name>/{api,model,ui} 폴더와 public API barrel, 라우트 추가, Vitest 테스트 스켈레톤까지 생성하고 FSD 의존 방향을 자동 검증합니다.
---

# react-add-feature

Vite + React(`templates/ts-vite-react` 기반) 프로젝트에 새 feature 슬라이스를 추가합니다.

## 적용 조건

- `src/features/`, `src/entities/`, `src/shared/` 디렉토리 존재
- `package.json` 에 `react`, `vite`, `@tanstack/react-query`, `zustand` 의존성 존재

미충족 시 작업 중단.

## 입력

1. **feature 이름** (kebab-case, 동사+명사 — 예: `auth-login`, `cart-add-item`)
2. **연관 엔티티** (선택 — 예: `user`, `product`) — 없으면 entities 참조 안 함
3. **유형**:
   - 서버 상태 필요 → TanStack Query 훅 생성
   - 클라이언트 상태 필요 → Zustand store 생성
   - 폼 → React Hook Form + Zod 스키마

## 생성할 파일

### 1. `src/features/<name>/api/use-<verb>.ts` (서버 상태)

```ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/shared/api';

export function use<Verb>() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: <Verb>Input) => api.post('/...', input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['...'] }),
  });
}
```

### 2. `src/features/<name>/model/store.ts` (클라이언트 상태, 필요 시)

```ts
import { create } from 'zustand';
interface State { ... }
export const use<Name>Store = create<State>(...)
```

### 3. `src/features/<name>/model/schema.ts` (폼이 있다면 Zod)

```ts
import { z } from 'zod';
export const <Name>Schema = z.object({ ... });
export type <Name>Values = z.infer<typeof <Name>Schema>;
```

### 4. `src/features/<name>/ui/<name>.tsx` (메인 컴포넌트)

훅을 호출하고 `shared/ui/` 또는 `entities/<x>/ui/` 만 import.

### 5. `src/features/<name>/index.ts` (public API)

```ts
export { <Name> } from './ui/<name>';
// 필요한 것만 명시적으로 re-export
```

⚠️ **`export *` 금지** — public API는 명시적으로.

### 6. 테스트 — `src/features/<name>/ui/<name>.spec.tsx`

```tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
// MSW 설정은 src/shared/test/ 에서 가져와 사용
```

### 7. 라우트 추가 (페이지 단위라면)

- `src/pages/<page>/index.tsx` 생성 — 이 페이지가 feature를 조합
- `src/app/router.tsx` 에 라우트 항목 추가 (lazy import)

## FSD 의존 방향 검증 (자동)

생성 후 ESLint 또는 ts-prune 등으로 다음을 확인:

- `features/<name>/` 에서 다른 `features/*` 직접 import → ❌ 차단
- `entities/`, `shared/` import → ✅ 허용
- `app/`, `pages/`, `widgets/` import → ❌ (역방향)

자동 검증이 어려우면 `import` 라인을 grep으로 점검:

```bash
grep -r "from '@/features" src/features/<name>/ --include='*.ts*' \
  | grep -v "from '@/features/<name>" \
  && echo "VIOLATION" && exit 1
```

## 완료 후 검증

```bash
yarn lint --fix
yarn typecheck
yarn test src/features/<name>
```

## 안티패턴 (자동 차단)

- features 간 직접 import → entities/shared로 끌어내리기 안내
- 컴포넌트 안에서 `fetch` 직접 호출 → `api/` 의 훅으로 분리
- prop drilling 3단계 이상 → Zustand slice 또는 컴포지션 권유
