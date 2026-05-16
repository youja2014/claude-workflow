# TypeScript Docker Rules

## Dockerfile

- Base: `node:20-alpine` (서버) 또는 `nginx:alpine` (정적 SPA)
- **multi-stage build** 필수: builder → runtime
- `corepack enable` 로 yarn 활성화 (Node 16.10+ 내장)
- 의존성 → 소스 순서로 COPY (레이어 캐시 최적화)
- non-root 유저 실행

### NestJS 예시

```dockerfile
# --- builder ---
FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build

# --- runtime ---
FROM node:20-alpine AS runtime
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
FROM node:20-alpine AS builder
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
