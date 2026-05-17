# TypeScript Docker Rules

## Base image 정책

- Base: `node:22-alpine` (서버) 또는 `nginx:alpine` (정적 SPA)
- **EOL**: Node 22 Jod LTS = 2027-04 (Maintenance 단계, 2025-10 진입). 다음 LTS = Node 24 Krypton (Active LTS, 2026-10 까지 Active). drift 체크: `bash scripts/eol-check.sh` (ADR Phase 4)
- alpine 캐비엇: `npm ci` / `npm install` 의 "Exit handler never called" 버그가 Node 22/24 + Alpine 조합에서 보고됨 (https://github.com/npm/cli/issues/8974). 본 프로젝트는 **yarn (corepack)** 사용으로 우회. npm 직접 호출 회피 권장.
- musl libc 호환성 — native binary 가 있는 패키지 (예: prisma, sharp) 는 alpine 변형 확인 필요. 호환 안 되면 `node:22-slim` (Debian glibc) 으로 전환

## Dockerfile

- **multi-stage build** 필수: builder → runtime
- `corepack enable` 로 yarn 활성화 (Node 16.10+ 내장)
- 의존성 → 소스 순서로 COPY (레이어 캐시 최적화)
- non-root 유저 실행

### NestJS 예시

```dockerfile
# --- builder ---
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

# --- runtime ---
FROM node:22-alpine AS runtime
RUN corepack enable && addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/package.json /app/yarn.lock ./
RUN yarn install --frozen-lockfile --production && yarn cache clean
COPY --from=builder /app/dist ./dist
USER app
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### Vite SPA 예시

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

## docker-compose

- 개발 시 소스 볼륨 마운트 (`./src:/app/src`) + `node_modules` 는 이름붙은 볼륨
- `env_file: .env` 로 환경변수 로드
- healthcheck 설정

## .dockerignore (필수)

```
node_modules/
.git/
.env
.env.*
dist/
build/
coverage/
.vscode/
.idea/
*.log
.DS_Store
Thumbs.db
```

## 보안

- 시크릿을 Dockerfile에 hardcoding 금지
- `ARG` 로 시크릿 전달 금지 — 빌드 캐시에 남음
- runtime 환경변수 또는 Docker secrets 사용
- 이미지 스캔: `docker scan` 또는 trivy
