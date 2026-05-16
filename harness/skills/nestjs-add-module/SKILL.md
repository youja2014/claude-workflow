---
name: nestjs-add-module
description: |
  NestJS 프로젝트에 새 모듈(바운디드 컨텍스트)을 헥사고날 4계층(domain/application/infrastructure/interface)
  으로 생성하고 Prisma 모델/마이그레이션, DI 바인딩, DTO, 컨트롤러, Jest 테스트 스켈레톤까지 만든다.
  TRIGGER when: cwd 에 `src/modules/` 와 `prisma/schema.prisma` 가 있고 사용자가
  "새 모듈 추가" 또는 "<X> 리소스 만들어줘" 형태로 요청.
  SKIP when: 단일 컨트롤러/엔드포인트 추가, 기존 모듈 내부 수정, NestJS 아닌 Express/Fastify 프로젝트,
  Prisma 없이 TypeORM/Mongoose 사용 중.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# nestjs-add-module

NestJS(`templates/ts-nestjs` 기반) 프로젝트에 새 모듈을 추가하는 워크플로.

## 적용 조건

- 현재 작업 디렉토리에 `src/modules/` 와 `prisma/schema.prisma` 존재
- `package.json` 에 `@nestjs/core`, `@prisma/client` 의존성 존재

조건 미충족 시 작업 중단 후 사용자 안내.

## 입력

1. **모듈 이름** (단수, kebab-case — 예: `user`, `order-item`)
2. **속성 목록** (`name:type` — 예: `email:string, age:int, createdAt:datetime`)
3. **CRUD 범위** (create/read/update/delete)

## 생성할 파일 (의존 순서)

### 1. Prisma 스키마 — `prisma/schema.prisma` 에 모델 추가

```prisma
model <Module> {
  id        String   @id @default(cuid())
  // ... 사용자 입력
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  @@map("<modules>")
}
```

### 2. Domain — `src/modules/<module>/domain/<module>.entity.ts`

```ts
export class <Module> {
  constructor(
    public readonly id: string,
    // ... 속성
  ) {}
}
```

### 3. Domain — `src/modules/<module>/domain/<module>.repository.ts`

```ts
export const <MODULE>_REPOSITORY = Symbol('<MODULE>_REPOSITORY');

export interface <Module>Repository {
  findById(id: string): Promise<<Module> | null>;
  save(entity: <Module>): Promise<void>;
}
```

### 4. Domain — `src/modules/<module>/domain/exceptions.ts`

```ts
export class <Module>NotFoundException extends Error {
  constructor(id: string) { super(`<Module> not found: ${id}`); }
}
```

### 5. Application — use case 파일들

`src/modules/<module>/application/commands/create-<module>.usecase.ts`:

```ts
@Injectable()
export class Create<Module>UseCase {
  constructor(@Inject(<MODULE>_REPOSITORY) private readonly repo: <Module>Repository) {}
  async execute(input: Create<Module>Input): Promise<<Module>> { ... }
}
```

### 6. Infrastructure — `src/modules/<module>/infrastructure/persistence/<module>.mapper.ts`

도메인 ↔ Prisma 변환 함수.

### 7. Infrastructure — `src/modules/<module>/infrastructure/persistence/<module>.prisma.repository.ts`

```ts
@Injectable()
export class <Module>PrismaRepository implements <Module>Repository {
  constructor(private readonly prisma: PrismaService) {}
  // 구현
}
```

### 8. Interface — DTO

- `src/modules/<module>/interface/dto/create-<module>.dto.ts` (class-validator)
- `src/modules/<module>/interface/dto/<module>.response.dto.ts`

### 9. Interface — `src/modules/<module>/interface/<module>.controller.ts`

```ts
@Controller('<modules>')
export class <Module>Controller {
  constructor(private readonly create<Module>: Create<Module>UseCase) {}

  @Post()
  async create(@Body() dto: Create<Module>Dto): Promise<<Module>ResponseDto> { ... }
}
```

### 10. Module 정의 — `src/modules/<module>/<modules>.module.ts`

```ts
@Module({
  controllers: [<Module>Controller],
  providers: [
    Create<Module>UseCase,
    { provide: <MODULE>_REPOSITORY, useClass: <Module>PrismaRepository },
  ],
  exports: [],
})
export class <Modules>Module {}
```

### 11. AppModule 등록 — `src/app.module.ts`

```ts
@Module({
  imports: [<Modules>Module],
})
export class AppModule {}
```

### 12. Prisma 마이그레이션

```bash
yarn prisma migrate dev --name add-<module>
```

### 13. 테스트

- `<module>.usecase.spec.ts` — Jest 단위 테스트 (모킹된 repo)
- `<module>.controller.e2e-spec.ts` — supertest + 실제 모듈

## 완료 후 검증

```bash
yarn lint --fix
yarn typecheck
yarn test <module>
```

## 안티패턴 (자동 차단)

- `domain/*.ts` 파일에 `@Injectable()` 또는 `@nestjs/*` import → 작업 중단
- Prisma 모델 타입을 Controller 응답에 직접 사용 → DTO 변환 강제
- Controller 안에 비즈니스 로직 → use case로 위임
