#!/bin/bash
# Railway wrapper, step 2 of 2: runs after the image's entrypoint has written
# .env and confirmed MySQL is reachable, before nginx starts.
#   - empty database: unattended install, then the admin from
#     BAGISTO_ADMIN_EMAIL / BAGISTO_ADMIN_PASSWORD (never the stock admin123)
#   - installed database: run new migrations (version updates)
set -e

APP_DIR=/var/www/bagisto
log() { echo "[railway-install] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
cd "$APP_DIR"

admins=$(php -r '
try {
  $p = new PDO("mysql:host=".getenv("DB_HOST").";port=".getenv("DB_PORT").";dbname=".getenv("DB_DATABASE"), getenv("DB_USERNAME"), getenv("DB_PASSWORD"));
  $t = $p->query("SHOW TABLES LIKE \"".(getenv("DB_PREFIX") ?: "")."admins\"")->fetchColumn();
  echo $t ? (int) $p->query("SELECT COUNT(*) FROM `".$t."`")->fetchColumn() : 0;
} catch (Exception $e) { fwrite(STDERR, $e->getMessage()."\n"); echo "error"; }')

if [ "$admins" = "error" ]; then
    log "ERROR: cannot read the database."
    exit 1
fi

if [ "$admins" = "0" ]; then
    if [ -z "$BAGISTO_ADMIN_EMAIL" ] || [ -z "$BAGISTO_ADMIN_PASSWORD" ]; then
        log "ERROR: set BAGISTO_ADMIN_EMAIL and BAGISTO_ADMIN_PASSWORD for the first install."
        exit 1
    fi
    if [ "$BAGISTO_ADMIN_PASSWORD" = "admin123" ] || [ "${#BAGISTO_ADMIN_PASSWORD}" -lt 12 ]; then
        log "ERROR: BAGISTO_ADMIN_PASSWORD must be at least 12 characters and not the stock admin123."
        exit 1
    fi
    log "Empty database: installing Bagisto (this takes a minute)..."
    rm -f storage/installed
    args="--no-interaction --force"
    if [ "${BAGISTO_SAMPLE_DATA:-false}" = "true" ]; then
        args="$args --demo-samples"
        log "Seeding the demo catalogue too (BAGISTO_SAMPLE_DATA=true)."
    fi
    # The installer's key:generate rewrites APP_KEY in .env; the service's
    # APP_KEY variable still wins, and is written back below.
    php artisan bagisto:install $args | grep -v -E '^(Email|Password):'
    sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env
    php /usr/local/share/bagisto/railway-admin.php
    log "Install finished. Admin: ${BAGISTO_ADMIN_EMAIL} (password in BAGISTO_ADMIN_PASSWORD)."
else
    log "Bagisto is installed (${admins} admin users): running migrations."
    php artisan migrate --force --no-interaction
    [ -f storage/installed ] || echo "Bagisto is successfully installed." > storage/installed
fi

php artisan storage:link --force --no-interaction >/dev/null 2>&1 || true
php artisan optimize:clear --no-interaction >/dev/null 2>&1 || true
php artisan optimize --no-interaction >/dev/null 2>&1 || true
find storage bootstrap/cache ! -user www-data -exec chown www-data:www-data {} + 2>/dev/null || true

log "Starting nginx, PHP-FPM, the queue worker and the scheduler."
exec "$@"
