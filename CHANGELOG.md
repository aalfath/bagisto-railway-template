# Changelog

## 2.5.1-railway.1 (2026-11-18)

First release of the template.

- Bagisto 2.5.1, `webkul/bagisto:2.5.1@sha256:6973b5c5c3ad11e14b2fdb2691cced4fb331ecc08d227ed27e5cd7f407f90d14`, with Railway's MySQL.
- Unattended first install; the admin email comes from `BAGISTO_ADMIN_EMAIL` and the password is generated (`BAGISTO_ADMIN_PASSWORD`). The stock `admin123` login is never reachable.
- `APP_KEY` is generated per deployment; the start refuses to run without one.
- `storage/` on a volume; nginx on `$PORT`; health check `/up`; migrations on every start.
