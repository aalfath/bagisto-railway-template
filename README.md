[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/bagisto-1?utm_medium=integration&utm_source=button&utm_campaign=bagisto)

# Bagisto on Railway

A one-click Railway template for [Bagisto](https://bagisto.com), the open-source Laravel e-commerce platform.

## What it deploys

| Service | Source | State |
|---|---|---|
| **Bagisto** | this repo: `Dockerfile` → `webkul/bagisto:2.5.1@sha256:6973b5c5c3ad11e14b2fdb2691cced4fb331ecc08d227ed27e5cd7f407f90d14` (nginx, PHP-FPM 8.4, queue worker and scheduler under Supervisor) | volume on `/var/www/bagisto/storage` (product images, uploads, logs) |
| **MySQL** | Railway's MySQL | volume on `/var/lib/mysql` (catalogue, orders, customers, sessions, cache, queue) |

On the first start, the wrapper installs Bagisto into the empty database without prompts, then sets the admin login from `BAGISTO_ADMIN_EMAIL` and the generated `BAGISTO_ADMIN_PASSWORD`, before the web server starts. The stock `admin@example.com` / `admin123` login never exists on a public URL. On later starts it runs the new database migrations, so version updates apply themselves.

Health check: `/up` (Laravel's health route, no login).

## Variables

| Variable | Default | Notes |
|---|---|---|
| `BAGISTO_ADMIN_EMAIL` | *(you enter it)* | Email for the admin login at `/admin`. Only read on the first install. |
| `BAGISTO_ADMIN_PASSWORD` | generated, 24 characters | Read it in the Bagisto service's Variables tab. Only read on the first install: change the password later in the admin panel. |
| `APP_KEY` | generated, 32 characters | Laravel encryption key. Don't change it after the install. |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Change it to your own domain if you add one. |
| `DB_*` | references to the MySQL service | Private network only. |
| `BAGISTO_SAMPLE_DATA` | `false` | Set to `true` before the first deploy to load Bagisto's demo catalogue. |
| `PORT` | `8080` | Port nginx listens on. |

Optional, add them yourself when you need them: `APP_TIMEZONE` (default `UTC`), `APP_LOCALE`, `APP_CURRENCY`. Mail (SMTP) is set in the admin panel under **Configure → Emails**.

## Updates

The Bagisto service builds from this repo. When the pinned version is bumped on `main`, Railway shows an "update available" notice on your project and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Database migrations run on the next start.

## Local test

```sh
docker build -t bagisto-railway .
# run it next to a MySQL 8+ server with DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME,
# DB_PASSWORD, APP_KEY (32 characters), APP_URL, BAGISTO_ADMIN_EMAIL and
# BAGISTO_ADMIN_PASSWORD (12+ characters) set, and a volume on /var/www/bagisto/storage
```

Upstream: [bagisto/bagisto](https://github.com/bagisto/bagisto) (MIT), [Docker docs](https://devdocs.bagisto.com/getting-started/installation.html).
