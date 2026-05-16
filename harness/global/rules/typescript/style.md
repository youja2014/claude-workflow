# TypeScript Style Rules

## 타입

- `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`
- `any` 사용 금지. 외부 라이브러리 타입이 부족하면 `unknown` 후 좁히기
- 명시적 함수 시그니처 — 반환 타입 추론 의존 금지 (public API 한정)
- enum 대신 `as const` 객체 + union 타입 사용 (tree-shakeable)

```ts
// 좋음
export const ROLE = { Admin: 'admin', User: 'user' } as const;
export type Role = (typeof ROLE)[keyof typeof ROLE];

// 나쁨 (TS enum)
export enum Role { Admin = 'admin', User = 'user' }
```

## 모듈

- `import type { Foo }` — 타입 전용 import 명시
- 와일드카드 export (`export *`) 지양 — barrel은 명시적 re-export
- 순환 import 금지

## 비동기

- `await` 누락은 lint로 차단 (`@typescript-eslint/no-floating-promises`)
- `Promise.all` 적극 활용 (의존 없는 작업 병렬화)
- top-level await 는 ESM 모듈에서만

## Null / Undefined

- `??` (nullish coalescing) 사용, `||` 는 명시적으로 falsy 처리할 때만
- 함수 매개변수는 `value?: T` (옵셔널) 또는 `value: T | undefined` 명시
- 빈 객체 리턴은 `{}` 대신 `Record<string, never>` 또는 명시적 타입

## 네이밍

- 파일: kebab-case (`user-repository.ts`)
- 타입/클래스/컴포넌트: PascalCase
- 변수/함수: camelCase
- 상수: SCREAMING_SNAKE_CASE 만 진짜 불변일 때

## 문자열

- 템플릿 리터럴 우선 (`` `${a}-${b}` ``)
- 다국어 메시지는 i18n 라이브러리로

## 경로

- `tsconfig.json` paths alias 적극 활용 (`@/`, `~/`)
- 깊은 상대 경로 (`../../../`) 3단계 이상이면 alias 도입

## 에러

- 커스텀 에러 클래스로 도메인 에러 구분
- 절대 빈 `catch` 금지 — `catch (err) { logger.error(err); throw err; }` 같이 처리
- `unknown` 에서 좁히기: `if (err instanceof DomainError)`
