# syntax=docker/dockerfile:1.7
ARG NODE_VERSION=22-alpine

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
ENV NODE_ENV=production
RUN apk add --no-cache openssl && corepack enable

COPY --from=build /workspace/dist/apps/api/main.js ./
COPY --from=build /workspace/dist/apps/api/prisma ./prisma

# Use source apps/api/package.json (clean dep/devDep split) instead of the
# Nx-generated dist/apps/api/package.json, which hoists devDeps (jest, ts-jest,
# ts-node, @types/*, @nestjs/testing, prisma CLI, pino-pretty, supertest) into
# dependencies and inflates the runtime image.
COPY apps/api/package.json ./source-package.json
RUN node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('./source-package.json'));delete p.devDependencies;fs.writeFileSync('./package.json',JSON.stringify(p,null,2))" \
 && rm source-package.json \
 && printf 'nodeLinker: node-modules\nenableGlobalCache: false\n' > .yarnrc.yml \
 && yarn install --no-immutable \
 && yarn cache clean

# Pre-generated Prisma client from the build stage (avoids needing the prisma
# CLI — which is a devDep — at runtime). Alpine base matches build stage.
COPY --from=build /workspace/node_modules/.prisma ./node_modules/.prisma

RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
EXPOSE 3000
CMD ["node", "main.js"]
