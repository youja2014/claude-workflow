# syntax=docker/dockerfile:1.7
ARG NODE_VERSION=20-alpine
ARG NGINX_VERSION=1.27-alpine

FROM node:${NODE_VERSION} AS base
WORKDIR /workspace
RUN corepack enable

FROM base AS deps
COPY package.json yarn.lock .yarnrc.yml ./
COPY apps/web/package.json apps/web/package.json
COPY libs/shared-types/package.json libs/shared-types/package.json
RUN yarn install --immutable

FROM deps AS build
COPY . .
RUN yarn nx build web --skip-nx-cache

FROM nginx:${NGINX_VERSION} AS runtime
COPY --from=build /workspace/dist/apps/web /usr/share/nginx/html
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
