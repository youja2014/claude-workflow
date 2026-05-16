---
name: nestjs-add-module
description: |
  NestJS 프로젝트에 새 모듈(바운디드 컨텍스트)을 헥사고날 4계층(domain/application/infrastructure/interface)
  으로 생성하고 Prisma 모델/마이그레이션, DI 바인딩, DTO, 컨트롤러, Jest 테스트 스켈레톤까지 만든다.
  TRIGGER when: cwd 에 `src/modules/` 또는 `apps/api/src/modules/` 와 대응하는
  `prisma/schema.prisma` (또는 `apps/api/prisma/schema.prisma`) 가 있고 사용자가
  "새 모듈 추가" 또는 "<X> 리소스 만들어줘" 형태로 요청.
  SKIP when: 단일 컨트롤러/엔드포인트 추가, 기존 모듈 내부 수정, NestJS 아닌 Express/Fastify 프로젝트,
  Prisma 없이 TypeORM/Mongoose 사용 중.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# nestjs-add-module

NestJS 프로젝트(`templates/ts-nestjs` 단일 앱 또는 `templates/ts-nx` 모노레포의 `apps/api`)에 새 모듈을 추가하는 워크플로.

## 적용 조건

다음 둘 중 하나의 **앱 루트**(`$APP_ROOT`)를 결정한 뒤 진행:

- 단일 NestJS: `$APP_ROOT = .` — `src/modules/`, `prisma/schema.prisma` 존재
- Nx 모노레포: `$APP_ROOT = apps/api` — `apps/api/src/modules/`, `apps/api/prisma/schema.prisma` 존재

추가로 (단일/Nx 공통):

- 어딘가의 `package.json` (앱 또는 root) 에 `@nestjs/core`, `@prisma/client` 의존성 존재

조건 미충족 시 작업 중단 후 사용자 안내. 이하 모든 경로는 `$APP_ROOT` 기준 상대경로로 표기.

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

단일 NestJS:
```bash
yarn prisma migrate dev --name add-<module>
```

Nx 모노레포 (스키마가 `apps/api/prisma/schema.prisma`):
```bash
yarn prisma migrate dev --name add-<module> --schema=apps/api/prisma/schema.prisma
```

### 13. 테스트

- `<module>.usecase.spec.ts` — Jest 단위 테스트 (모킹된 repo)
- `<module>.controller.e2e-spec.ts` — supertest + 실제 모듈

## 완료 후 검증

단일 NestJS:
```bash
yarn lint --fix
yarn typecheck
yarn test <module>
```

Nx 모노레포:
```bash
yarn nx lint api --fix
yarn nx typecheck api
yarn nx test api --testFile=<module>
```

Nx 의 경우 `apps/api/project.json` 의 `tags: ["scope:api", "type:app"]` 가 유지되는지 확인. 새 모듈을 라이브러리(`libs/`)로 분리한다면 `tags: ["scope:api", "type:feature"]` 를 명시해야 `@nx/enforce-module-boundaries` 가 동작한다.

## 안티패턴 (자동 차단)

- `domain/*.ts` 파일에 `@Injectable()` 또는 `@nestjs/*` import → 작업 중단
- Prisma 모델 타입을 Controller 응답에 직접 사용 → DTO 변환 강제
- Controller 안에 비즈니스 로직 → use case로 위임
