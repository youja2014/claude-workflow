# NestJS 프로젝트 룰

이 룰은 NestJS 헥사고날 모듈 구조 일반에 적용된다. `templates/ts-nx` 모노레포에서는 아래 `src/` 를 `apps/api/src/` 로, `prisma/` 를 `apps/api/prisma/` 로 읽는다. 단일 앱 NestJS 프로젝트(외부)에서는 그대로 루트 기준으로 읽으면 된다.

## 폴더 구조 (모듈별 헥사고날)

```
src/
├── modules/
│   └── users/                        # NestJS 모듈 = DDD 바운디드 컨텍스트
│       ├── domain/
│       │   ├── user.entity.ts        # 순수 도메인 엔티티
│       │   ├── user.repository.ts    # 포트 (interface + Symbol)
│       │   └── exceptions.ts
│       ├── application/
│       │   ├── commands/             # use case (mutation)
│       │   │   └── create-user.usecase.ts
│       │   └── queries/              # use case (read) — CQRS 도입 시
│       ├── infrastructure/
│       │   ├── persistence/
│       │   │   ├── user.prisma.repository.ts  # 어댑터
│       │   │   └── user.mapper.ts             # Domain ↔ Prisma
│       │   └── http/
│       ├── interface/
│       │   ├── user.controller.ts
│       │   └── dto/                  # class-validator DTO
│       │       ├── create-user.dto.ts
│       │       └── user.response.dto.ts
│       └── users.module.ts
├── shared/                           # 공용 도메인 프리미티브, 예외, 데코레이터
├── config/                           # @nestjs/config + Joi/Zod 검증
└── main.ts
```

## 의존 방향 (모듈 내부)

```
interface → application → domain ← infrastructure
```

- `domain/` 은 NestJS 데코레이터/`@Injectable()` 도 사용하지 않는 순수 TS
- `application/` 의 use case는 `@Injectable()` 가능, 도메인 포트만 의존
- `infrastructure/` 가 포트 구현. 모듈에서 `provide: USER_REPO, useClass: UserPrismaRepository`

## 포트 정의 (DI 키)

```ts
// domain/user.repository.ts
export const USER_REPOSITORY = Symbol('USER_REPOSITORY');
export interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

```ts
// users.module.ts
@Module({
  providers: [
    CreateUserUseCase,
    { provide: USER_REPOSITORY, useClass: UserPrismaRepository },
  ],
  controllers: [UserController],
})
export class UsersModule {}
```

```ts
// use case
constructor(@Inject(USER_REPOSITORY) private readonly users: UserRepository) {}
```

## 3종 엔티티 분리

1. **DTO** (`interface/dto/`) — class-validator 데코레이터 부착, HTTP 직렬화
2. **Domain entity** (`domain/`) — 순수 TS 클래스, 비즈니스 로직 + 불변식
3. **Persistence model** — Prisma 스키마가 생성한 `@prisma/client` 타입

`infrastructure/persistence/<name>.mapper.ts` 가 변환을 담당.

## ORM 선택

- **기본: Prisma** — DX 우수, 마이그레이션 자동화, 타입 안전
- **고성능/엣지: Drizzle** — SQL 투명성, Workers 배포
- TypeORM은 신규 프로젝트에서 비추천

## 검증

- 글로벌 `ValidationPipe`:

```ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
}));
```

- DTO에 `class-validator` 데코레이터 (`@IsEmail()`, `@MinLength(8)`)
- 환경변수: `@nestjs/config` + `Joi.object({...})` 또는 Zod 스키마

## 예외 처리

- 도메인 예외(`UserNotFoundException`)를 `application/` 에서 throw
- 글로벌 `ExceptionFilter` 가 HTTP 응답으로 변환
- 직접 `throw new HttpException()` 은 `interface/` 에서만

## 테스트

- 단위: `@nestjs/testing` 의 `Test.createTestingModule()` + 모킹된 포트
- 통합: 실제 Prisma + testcontainers
- e2e: `supertest` + 전체 모듈 부팅

## 안티패턴

- Controller에 비즈니스 로직 작성 → use case로 위임
- Repository에 비즈니스 규칙 작성 → 도메인 엔티티로 이동
- `forwardRef` 남발 → 모듈 경계 재설계 신호
- Prisma 모델을 컨트롤러 응답으로 직접 반환 → DTO로 변환 필수
