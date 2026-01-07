# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=20.15.1

FROM node:${NODE_VERSION}-slim AS base

# Workaround for corepack integrity issue
ENV COREPACK_INTEGRITY_KEYS=0

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Use apt cache (no cleanup!) and corepack
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    openssl \
    libssl3

RUN corepack enable

WORKDIR /app

# Workspace
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
# Apps
COPY apps/worker/package.json ./apps/worker/
# Packages
COPY packages/db/package.json ./packages/db/
COPY packages/json/package.json ./packages/json/
COPY packages/email/package.json ./packages/email/
COPY packages/redis/package.json ./packages/redis/
COPY packages/queue/package.json ./packages/queue/
COPY packages/logger/package.json ./packages/logger/
COPY packages/common/package.json ./packages/common/
COPY packages/constants/package.json ./packages/constants/
COPY packages/validation/package.json ./packages/validation/
COPY packages/integrations/package.json ./packages/integrations/

# ----------- BUILD STAGE -----------
FROM base AS build

WORKDIR /app

# Use pnpm cache (no prune!)
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --store-dir=/root/.pnpm-store

COPY apps/worker ./apps/worker
COPY packages ./packages
COPY tooling ./tooling

RUN pnpm db:codegen && \
    pnpm --filter worker run build

# ----------- PROD STAGE -----------
FROM base AS prod

WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/pnpm-lock.yaml ./

# Use pnpm cache for production install (no prune!)
RUN --mount=type=cache,target=/root/.pnpm-store \
    pnpm install --frozen-lockfile --prod --store-dir=/root/.pnpm-store

# ----------- FINAL STAGE -----------
FROM base AS runner

WORKDIR /app

COPY --from=build /app/package.json ./
COPY --from=prod /app/node_modules ./node_modules

# Apps
COPY --from=build /app/apps/worker ./apps/worker

# Packages
COPY --from=build /app/packages/db ./packages/db
COPY --from=build /app/packages/json ./packages/json
COPY --from=build /app/packages/email ./packages/email
COPY --from=build /app/packages/redis ./packages/redis
COPY --from=build /app/packages/logger ./packages/logger
COPY --from=build /app/packages/queue ./packages/queue
COPY --from=build /app/packages/common ./packages/common
COPY --from=build /app/packages/validation ./packages/validation
COPY --from=build /app/packages/integrations ./packages/integrations

RUN pnpm db:codegen

WORKDIR /app/apps/worker

EXPOSE 3000

CMD ["node", "dist/index.js"]
