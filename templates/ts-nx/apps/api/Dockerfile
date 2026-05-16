# syntax=docker/dockerfile:1.7
ARG NODE_VERSION=20-alpine

FROM node:${NODE_VERSION} AS base
WORKDIR /workspace
RUN apk add --no-cache openssl && corepack enable

FROM base AS deps
COPY package.json yarn.lock .yarnrc.yml ./
COPY apps/api/package.json apps/api/package.json
COPY apps/web/package.json apps/web/package.json
COPY libs/shared-types/package.json libs/shared-types/package.json
RUN yarn install --immutable

FROM deps AS build
COPY . .
RUN cd apps/api && yarn exec prisma generate --schema=./prisma/schema.prisma
RUN yarn nx build api --skip-nx-cache

FROM node:${NODE_VERSION} AS runtime
WORKDIR /app
RUN apk add --no-cache openssl && corepack enable
COPY --from=build /workspace/dist/apps/api ./
RUN printf 'nodeLinker: node-modules\nenableGlobalCache: false\n' > .yarnrc.yml \
 && yarn install --no-immutable \
 && yarn exec prisma generate --schema=./prisma/schema.prisma \
 && yarn cache clean
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
EXPOSE 3000
CMD ["node", "main.js"]
