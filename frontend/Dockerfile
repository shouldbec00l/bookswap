# syntax=docker/dockerfile:1

# ---------- Етап 1: збірка статики (Node + Vite) ----------
FROM node:26-alpine AS build
WORKDIR /app

COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY index.html vite.config.js ./
COPY src ./src
RUN npm run build

# ---------- Етап 2: runtime (nginx з Alpine + статика) ----------
# Чому не nginxinc/nginx-unprivileged: у листопаді 2026 в nginx виправили критичні CVE
# (1.30.7 / 1.31.9), а офіційні образи nginxinc ще містили 1.30.6 / 1.31.7. Пакет nginx
# в Alpine 3.24 уже оновлений, тому збираємо runtime на ньому. Користувач nginx, порт 8080.
FROM alpine:3.24 AS runtime

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=build /app/dist /usr/share/nginx/html

# Версії пакетів не закріплюємо навмисно: потрібна найсвіжіша з виправленнями (див. ADR-0004).
# sed прибирає CRLF, якщо скрипт потрапив у репозиторій з Windows.
# hadolint ignore=DL3018
RUN apk upgrade --no-cache \
 && apk add --no-cache nginx gettext-envsubst \
 && sed -i 's/\r$//' /docker-entrypoint.sh \
 && chmod 755 /docker-entrypoint.sh \
 && mkdir -p /etc/nginx/conf.d /var/log/nginx \
 && chown -R nginx:nginx /etc/nginx/conf.d /var/log/nginx

# Значення за замовчуванням; у docker-compose перевизначається через оточення
ENV BACKEND_URL=http://backend:3000

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
