# syntax=docker/dockerfile:1

# ---------- Етап 1: встановлення залежностей (build-середовище) ----------
FROM node:22-alpine AS deps
WORKDIR /app

# Спочатку лише маніфести залежностей: шар кешується, доки вони не змінились
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# ---------- Етап 2: runtime ----------
FROM node:22-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

# Лише готові залежності та код; npm-кеш і build-інструменти в образ не потрапляють
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src

# Безпека (Lab 3): оновлюємо пакети ОС і прибираємо npm/yarn/corepack з runtime.
# Застосунок стартує через `node`, менеджери пакетів йому не потрібні,
# а їхні вбудовані залежності (напр. brace-expansion) давали HIGH-CVE у Trivy.
# Виконується ще від root, до перемикання на непривілейованого користувача.
RUN apk upgrade --no-cache \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
           /opt/yarn-* /usr/local/bin/yarn /usr/local/bin/yarnpkg

# Непривілейований користувач (вбудований у образ node)
USER node

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

# exec-форма: node отримує SIGTERM напряму
CMD ["node", "src/index.js"]
