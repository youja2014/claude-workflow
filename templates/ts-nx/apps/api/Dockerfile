# syntax=docker/dockerfile:1.7
ARG NODE_VERSION=20-alpine

FROM node:${NODE_VERSION} AS base
WORKDIR /workspace
RUN corepack enable

FROM base AS deps
COPY package.json yarn.lock .yarnrc.yml ./
COPY apps/api/package.json apps/api/package.json
COPY libs/shared-types/package.json libs/shared-types/package.json
RUN yarn install --immutable

FROM deps AS build
COPY . .
RUN yarn nx build api --skip-nx-cache

FROM node:${NODE_VERSION} AS runtime
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build --chown=app:app /workspace/dist/apps/api ./
USER app
EXPOSE 3000
CMD ["node", "main.js"]
