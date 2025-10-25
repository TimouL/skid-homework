# syntax=docker/dockerfile:1.7

# 构建阶段：使用 Node + pnpm 构建前端静态站点
FROM node:20-alpine AS builder

ENV PNPM_HOME=/root/.local/share/pnpm \
    PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

# 仅复制依赖申明文件以利用 Docker layer cache
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# 复制剩余源码并构建
COPY . .
RUN pnpm build

# 运行阶段：使用 Nginx 提供静态资源
FROM nginx:1.27-alpine AS runner

LABEL org.opencontainers.image.title="skid-homework" \
      org.opencontainers.image.description="Skid Homework – AI-assisted homework helper" \
      org.opencontainers.image.url="https://skid.996every.day"

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/healthz >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
