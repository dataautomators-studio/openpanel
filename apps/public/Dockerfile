# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=22.15.0

FROM node:${NODE_VERSION}-slim AS base

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

ARG REDIS_URL
ENV REDIS_URL=$REDIS_URL

ARG CLICKHOUSE_URL
ENV CLICKHOUSE_URL=$CLICKHOUSE_URL

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable

# This is how you use --mount=type=cache correctly:
RUN --mount=type=cache,target=/var/cache/apt \
  apt update && \
  apt install -y curl

RUN curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n && \
  bash n $NODE_VERSION && \
  rm n && \
  npm install -g n

WORKDIR /app

COPY package.json package.json
COPY pnpm-lock.yaml pnpm-lock.yaml
COPY pnpm-workspace.yaml pnpm-workspace.yaml
COPY apps/public/package.json apps/public/package.json
COPY packages/db/package.json packages/db/package.json
COPY packages/redis/package.json packages/redis/package.json
COPY packages/queue/package.json packages/queue/package.json
COPY packages/common/package.json packages/common/package.json
COPY packages/constants/package.json packages/constants/package.json
COPY packages/validation/package.json packages/validation/package.json
COPY packages/sdks/sdk/package.json packages/sdks/sdk/package.json
COPY packages/sdks/_info/package.json packages/sdks/_info/package.json

# ----------- BUILD STAGE -----------
FROM base AS build

WORKDIR /app/apps/public

RUN --mount=type=cache,target=/root/.pnpm-store \
  pnpm install --frozen-lockfile --ignore-scripts --store-dir=/root/.pnpm-store

WORKDIR /app
COPY apps/public apps/public
COPY packages packages
COPY tooling tooling
RUN pnpm db:codegen

WORKDIR /app/apps/public
RUN pnpm run build

# ----------- PROD STAGE -----------
FROM base AS prod

WORKDIR /app/apps/public

RUN --mount=type=cache,target=/root/.pnpm-store \
  pnpm install --frozen-lockfile --prod --ignore-scripts --store-dir=/root/.pnpm-store

# ----------- FINAL STAGE -----------
FROM base AS runner

COPY --from=build /app/package.json /app/package.json
COPY --from=prod /app/node_modules /app/node_modules

# Apps
COPY --from=build /app/apps/public /app/apps/public
# Apps node_modules
COPY --from=prod /app/apps/public/node_modules /app/apps/public/node_modules

# Packages
COPY --from=build /app/packages/db /app/packages/db
COPY --from=build /app/packages/redis /app/packages/redis
COPY --from=build /app/packages/common /app/packages/common
COPY --from=build /app/packages/queue /app/packages/queue
COPY --from=build /app/packages/constants /app/packages/constants
COPY --from=build /app/packages/validation /app/packages/validation
COPY --from=build /app/packages/sdks/sdk /app/packages/sdks/sdk
COPY --from=build /app/packages/sdks/_info /app/packages/sdks/_info

# Packages node_modules
COPY --from=prod /app/packages/db/node_modules /app/packages/db/node_modules
COPY --from=prod /app/packages/redis/node_modules /app/packages/redis/node_modules
COPY --from=prod /app/packages/common/node_modules /app/packages/common/node_modules
COPY --from=prod /app/packages/queue/node_modules /app/packages/queue/node_modules
COPY --from=prod /app/packages/validation/node_modules /app/packages/validation/node_modules

RUN pnpm db:codegen

WORKDIR /app/apps/public

EXPOSE 3000

CMD ["pnpm", "start"]
