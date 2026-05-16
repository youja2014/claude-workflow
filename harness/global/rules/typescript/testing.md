# TypeScript Testing Rules

## 프레임워크

- 단위/통합: **Vitest** (Vite 프로젝트), **Jest** (NestJS 기본)
- e2e: **supertest** (NestJS), **Playwright** (브라우저)
- React UI: **@testing-library/react** + MSW (API mock)

## 파일 위치

```
src/
├── modules/users/
│   ├── user.service.ts
│   └── user.service.spec.ts        # 같은 폴더, .spec.ts
└── ...

test/
├── e2e/                            # 전체 시스템 테스트
└── fixtures/
```

## 네이밍

- `<filename>.spec.ts` — 단위/통합
- `<filename>.e2e-spec.ts` — e2e
- 테스트 이름: `it('returns 401 when password is invalid', ...)` — 영문 BDD 스타일

## AAA 패턴

```ts
it('creates user with hashed password', async () => {
  // Arrange
  const dto = { email: 'a@b.com', password: 'plain' };
  // Act
  const user = await service.create(dto);
  // Assert
  expect(user.passwordHash).not.toBe('plain');
});
```

## Mock 정책

- **외부 의존성만 mock**: HTTP, DB, 파일 시스템, 시계
- **내부 모듈 mock 금지** — 리팩토링에 취약. 진짜 객체 사용 + 테스트 컨테이너
- DB 통합 테스트는 testcontainers (Postgres) 또는 in-memory SQLite

## 커버리지

- 라인 80% 이상 권장 (CI gate)
- 100% 추구 금지 — 의미 있는 테스트에 집중
- 도메인 로직은 100% 커버

## 안티패턴

- `jest.spyOn` 으로 내부 메서드 spy 후 호출 횟수만 검증 → 행위 테스트로
- `setTimeout` 대신 `vi.useFakeTimers()` 또는 `jest.useFakeTimers()`
- `console.log` 잔존 — eslint로 차단
