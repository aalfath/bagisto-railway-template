#!/bin/bash
# Railway wrapper, step 1 of 2: runs as root before the image's own entrypoint.
#   - seeds and hands the storage volume to www-data
#   - makes nginx listen on $PORT
#   - sets production defaults the image leaves at local values
# Then the image's entrypoint (.env overrides, config cache, waits for MySQL)
# runs railway-install.sh, which installs or migrates and starts Supervisor.
set -e

APP_DIR=/var/www/bagisto
log() { echo "[railway-start] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

PORT="${PORT:-8080}"

# --- Storage volume -------------------------------------------------------
if [ ! -d "$APP_DIR/storage/framework" ]; then
    log "Empty storage volume: seeding folders."
    cp -a /opt/bagisto-storage-seed/. "$APP_DIR/storage/"
fi
mkdir -p "$APP_DIR/storage/app/public" "$APP_DIR/storage/app/private" \
         "$APP_DIR/storage/framework/cache/data" "$APP_DIR/storage/framework/sessions" \
         "$APP_DIR/storage/framework/views" "$APP_DIR/storage/framework/testing" \
         "$APP_DIR/storage/logs"
chown www-data:www-data "$APP_DIR/storage"
find "$APP_DIR/storage" ! -user www-data -exec chown www-data:www-data {} + 2>/dev/null || true

# --- nginx on $PORT -------------------------------------------------------
sed -i -E "s/listen (\[::\]:)?[0-9]+ default_server;/listen \1${PORT} default_server;/" /etc/nginx/conf.d/bagisto.conf
log "nginx listens on ${PORT}."

# --- Production defaults (any variable set on the service wins) ------------
cd "$APP_DIR"
set_env() {
    if grep -q "^$1=" .env; then sed -i "s|^$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi
}
set_env APP_ENV "${APP_ENV:-production}"
set_env APP_DEBUG "${APP_DEBUG:-false}"
set_env APP_NAME "\"${APP_NAME:-Bagisto}\""
set_env LOG_LEVEL "${LOG_LEVEL:-warning}"
# One log file per day on the volume, kept 14 days, instead of one growing file.
set_env LOG_STACK "${LOG_STACK:-daily}"
export APP_TIMEZONE="${APP_TIMEZONE:-UTC}"
export SESSION_SECURE_COOKIE="${SESSION_SECURE_COOKIE:-true}"

exec /usr/local/bin/entrypoint.sh /usr/local/bin/railway-install.sh "$@"
