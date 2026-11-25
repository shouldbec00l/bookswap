# syntax=docker/dockerfile:1

# ---------- Етап 1: збірка статики (Node + Vite) ----------
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---------- Етап 2: runtime (лише nginx + статика) ----------
# nginx-unprivileged: працює від користувача nginx (UID 101), слухає порт 8080
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

# Конфіг-шаблон; образ сам виконує envsubst при старті
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

# Значення за замовчуванням; у docker-compose перевизначається через оточення
ENV BACKEND_URL=http://backend:3000

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

# USER вже встановлено в базовому образі (nginx, UID 101)
