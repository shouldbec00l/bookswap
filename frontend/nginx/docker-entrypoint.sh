#!/bin/sh
# Підставляє BACKEND_URL у шаблон і запускає nginx на передньому плані.
set -eu

: "${BACKEND_URL:=http://backend:3000}"
export BACKEND_URL

# Підставляємо лише BACKEND_URL, щоб не зачепити nginx-змінні ($uri, $host тощо)
envsubst '${BACKEND_URL}' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
