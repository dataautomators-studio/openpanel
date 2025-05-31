# syntax=docker/dockerfile:1.7

FROM node:18-alpine

WORKDIR /app

# Copy package.json and install dependencies with npm cache mount
COPY apps/docs/package.json package.json
RUN --mount=type=cache,target=/root/.npm \
  npm install --production

# Copy your application code
COPY apps/docs/index.js index.js

EXPOSE 3000

CMD ["node", "index.js"]
