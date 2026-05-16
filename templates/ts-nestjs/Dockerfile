FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY package.json yarn.lock .yarnrc.yml* ./
RUN yarn install --immutable
COPY . .
RUN yarn prisma generate && yarn build

# Strip devDependencies using npm prune. npm reads package.json and removes
# anything not in `dependencies`, regardless of which package manager installed
# the tree. This avoids the @yarnpkg/plugin-workspace-tools dependency that
# `yarn workspaces focus --production` would require (the plugin would need to
# be committed under .yarn/plugins/, which most teams skip).
FROM builder AS pruner
RUN npm prune --omit=dev

FROM node:20-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/package.json ./
COPY --from=pruner  /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health >/dev/null 2>&1 || exit 1
CMD ["node", "dist/main.js"]
