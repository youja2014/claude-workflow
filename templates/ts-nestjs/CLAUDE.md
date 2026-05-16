# __project_name__ — Project Context for Claude

## 정체성

- **유형**: NestJS API (TypeScript, Node 20)
- **ORM**: Prisma (PostgreSQL)
- **패키지 매니저**: yarn (corepack)
- **테스트**: Jest + supertest

## 아키텍처 (모듈별 헥사고날)

각 NestJS 모듈 = DDD 바운디드 컨텍스트:

```
src/modules/<name>/
├── domain/             # 순수 도메인 (NestJS 데코레이터 없음)
├── application/        # use case (@Injectable)
├── infrastructure/     # 어댑터 (Prisma repository, mapper)
├── interface/          # controller + DTO (class-validator)
└── <name>.module.ts
```

의존 방향: `interface → application → domain ← infrastructure`

## 3종 엔티티 분리 (강제)

1. **DTO** — `interface/dto/` class-validator 부착
2. **Domain entity** — `domain/` 순수 TypeScript 클래스
3. **Prisma model** — Prisma가 생성한 `@prisma/client` 타입

`infrastructure/persistence/<name>.mapper.ts` 가 변환 담당.

## 새 모듈 추가

`/skill nestjs-add-module` 호출 권장.

## Definition of Done

1. **계획 명시**: commit message
2. **참조 확인**: 추가한 심볼이 다른 곳에서 사용됨
3. **테스트**:
   - `.spec.ts` — Jest 단위 (모킹된 포트)
   - `.e2e-spec.ts` — supertest + 실제 모듈
4. **로컬 검증**:
   ```bash
   yarn lint && yarn typecheck && yarn test && yarn docker:build
   ```
5. **마이그레이션**: `yarn prisma migrate dev --name <msg>` 후 SQL 검토
6. **자가 리뷰**: `git diff` 적대적 시각

## 절대 하지 말 것

- `domain/*.ts` 에 `@Injectable()`, `@nestjs/*` import
- Prisma 모델을 controller 응답에 직접 사용 (DTO 변환 강제)
- Controller에 비즈니스 로직 (use case로 위임)
- `--no-verify` 로 husky 우회
- npm 사용 (yarn 전용)

## 주요 명령

```bash
yarn install              # 의존성 + husky 자동 설치
yarn prisma:migrate       # 마이그레이션
yarn start:dev            # dev 서버 (http://localhost:3000)
yarn docker:up            # postgres + api 컨테이너
```

## 참조

- `~/.claude/rules/typescript/style.md`, `typescript/testing.md`, `typescript/docker.md`
- `~/.claude/rules/typescript/nestjs.md` — 이 스택 전용 룰
- `~/.claude/skills/nestjs-add-module/SKILL.md`
