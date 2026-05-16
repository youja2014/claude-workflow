# React (Vite SPA) 프로젝트 룰

이 룰은 Vite + React 단일 페이지 앱(SPA) 의 FSD 구조 일반에 적용된다. `templates/ts-nx` 모노레포에서는 아래 `src/` 를 `apps/web/src/` 로 읽고, 외부의 단일 SPA 프로젝트에서는 루트 기준 그대로 읽는다. Nx 의 경우 `@nx/enforce-module-boundaries` 가 프로젝트 간 경계를 자동으로 강제하므로, 이 룰은 **앱 내부 FSD** 만 다룬다.

## 폴더 구조 (Feature-Sliced Design lite)

```
src/
├── app/                       # 앱 초기화: providers, router, 글로벌 스타일
│   ├── providers/
│   │   ├── query-provider.tsx
│   │   └── theme-provider.tsx
│   ├── router.tsx
│   └── index.tsx
├── pages/                     # 라우트별 페이지 (얇은 조합 레이어)
│   ├── home/
│   └── user-detail/
├── widgets/                   # 페이지 단위 합성 (헤더, 사이드바)
├── features/                  # 사용자 가치 단위 (login, add-to-cart)
│   └── auth-login/
│       ├── api/               # TanStack Query 훅
│       │   └── use-login.ts
│       ├── model/             # Zustand slice, 로컬 상태
│       │   └── store.ts
│       ├── ui/                # 컴포넌트
│       │   └── login-form.tsx
│       └── index.ts           # public API (배럴)
├── entities/                  # 비즈니스 엔티티 (user, product)
│   └── user/
│       ├── api/
│       ├── model/             # 타입, 도메인 함수
│       └── ui/                # 엔티티 카드 등
└── shared/                    # 재사용 가능
    ├── ui/                    # 디자인 시스템 (Button, Input ...)
    ├── lib/                   # 유틸 함수
    ├── api/                   # axios/fetch 클라이언트 인스턴스
    └── config/                # 환경변수, 상수
```

## 의존 방향 (상위 → 하위만 허용)

```
app → pages → widgets → features → entities → shared
```

- 같은 레이어 간 직접 import 금지 (features끼리 직접 X → entities/shared 거치기)
- 각 슬라이스는 `index.ts` public API만 외부 노출
- 작은 앱이면 `pages + features + shared` 3개 레이어로 lite 운영

## 라우팅

- **react-router v7 (Declarative mode)** — Vite SPA + static 빌드 호환
- `app/router.tsx` 에서 lazy import 로 코드 스플리팅:

```ts
import { createBrowserRouter, lazy } from 'react-router';

const HomePage = lazy(() => import('@/pages/home'));
```

- TanStack Router는 100% 타입 안전이 필요하면 검토 — 작은 SPA에는 과잉

## 상태 관리 분리

| 상태 종류 | 도구 | 위치 |
|---|---|---|
| 서버 상태 | TanStack Query | `features/<name>/api/use-*.ts` |
| 클라이언트 상태 | Zustand | `features/<name>/model/store.ts` 또는 `entities/<name>/model/` |
| 폼 상태 | React Hook Form + Zod | 폼 컴포넌트 내부 |
| URL 상태 | React Router params + search params | 페이지 컴포넌트 |

### Zustand slice 패턴

```ts
import { create } from 'zustand';

interface AuthState {
  user: User | null;
  setUser: (u: User | null) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

### TanStack Query 훅 패턴

```ts
export function useUserQuery(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => userApi.getById(id),
  });
}
```

## 폼

- React Hook Form + Zod resolver
- Zod 스키마 → `z.infer<typeof Schema>` 로 타입 추출 (DRY)

```ts
const Schema = z.object({ email: z.string().email() });
type FormValues = z.infer<typeof Schema>;
const form = useForm<FormValues>({ resolver: zodResolver(Schema) });
```

## 스타일링

- **Tailwind CSS** (utility-first) — 디자인 토큰은 `tailwind.config.ts`
- `shared/ui/` 의 컴포넌트는 cva (`class-variance-authority`) 로 variant 관리
- CSS Modules는 Tailwind로 표현 어려운 복잡한 애니메이션에만

## 테스트

- **Vitest + @testing-library/react** — 단위/통합
- **MSW** — API mock (HTTP 레이어에서 가로채기, fetch mock보다 우월)
- **Playwright** — e2e (`test/e2e/`)

## 빌드 / 배포

- `yarn build` → `dist/` (정적 파일)
- nginx 단일 컨테이너로 배포 (Dockerfile multi-stage)
- 환경변수: `VITE_*` 프리픽스만 클라이언트 노출
- `vite.config.ts` 에 `build.sourcemap: true` (프로덕션 디버깅용)

## 안티패턴

- features 간 직접 import → entities/shared로 끌어내리기
- 글로벌 Context로 서버 상태 관리 → TanStack Query로
- 컴포넌트 안에서 fetch → 훅으로 분리
- Atomic Design 전면 도입 → `shared/ui/` (디자인 시스템) 에만 적용
- prop drilling 3단계 이상 → Zustand slice 또는 컴포지션 재설계
