# Deployment Guide

**Project:** Smart Livestock Health and Farm Management System
**Phase:** 8 — Deployment, Documentation, and Handover
**Date:** 2026-11-22
**Environment target:** Production-like single-host Linux server (or free-tier PaaS)

---

## Table of contents

1. [Hosting options and prerequisites](#1-hosting-options-and-prerequisites)
2. [Server preparation](#2-server-preparation)
3. [MySQL production database setup](#3-mysql-production-database-setup)
4. [Backend deployment](#4-backend-deployment)
5. [Nginx reverse proxy](#5-nginx-reverse-proxy)
6. [systemd service](#6-systemd-service)
7. [Authority dashboard](#7-authority-dashboard)
8. [Mobile APK build and distribution](#8-mobile-apk-build-and-distribution)
9. [Production configuration checklist (TC-SEC-08)](#9-production-configuration-checklist-tc-sec-08)
10. [Post-deployment verification](#10-post-deployment-verification)
11. [Hosting costs and options](#11-hosting-costs-and-options)

---

## 1. Hosting options and prerequisites

### Recommended topology for academic submission

The project was developed and tested on a local Windows development machine (E1) and can be demonstrated running on that machine. For a production-like deployment use **one Linux VPS or free-tier server**.

| Option | Cost | Notes |
|---|---|---|
| Local dev machine (E1) | Free | Sufficient for assessment demo |
| Oracle Cloud Free Tier (ARM) | Free | 4 vCPU, 24 GB RAM — good for small demos |
| Render.com free web service | Free tier | 512 MB RAM; cold starts on free plan |
| Railway.app | Free trial | MySQL add-on available |
| DigitalOcean Droplet (1 GB) | ~$6/month | Simplest VPS; full control |

### Server prerequisites (Linux)

```
Ubuntu 22.04 LTS (or equivalent)
Python 3.11+
MySQL 8.0+
Nginx 1.24+
Git
```

Install on Ubuntu:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3.11 python3.11-venv python3-pip mysql-server nginx git curl
```

---

## 2. Server preparation

```bash
# Create a dedicated user (do not run the app as root)
sudo adduser livestock
sudo usermod -aG www-data livestock

# Clone the repository
sudo -u livestock git clone https://github.com/<org>/Final-Year-Project-group10.git /srv/livestock
cd /srv/livestock/backend

# Create the virtual environment
sudo -u livestock python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn      # not in requirements.txt (dev-only runner is manage.py runserver)
```

---

## 3. MySQL production database setup

```sql
-- Run as MySQL root
CREATE DATABASE livestock_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'livestock_user'@'127.0.0.1' IDENTIFIED BY '<strong-password>';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW,
      SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER
  ON livestock_db.* TO 'livestock_user'@'127.0.0.1';
FLUSH PRIVILEGES;
```

---

## 4. Backend deployment

### 4.1 Environment file

```bash
cd /srv/livestock/backend
cp /srv/livestock/.env.example .env
nano .env
```

Minimum values to set for production:

```ini
DJANGO_SECRET_KEY=<generate with: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())">
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=your-server-ip,your-domain.com

DB_PASSWORD=<strong-password>
DB_HOST=127.0.0.1

# After HTTPS confirmed:
DJANGO_SECURE_SSL_REDIRECT=True
DJANGO_SECURE_HSTS_SECONDS=31536000
DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### 4.2 Apply migrations and collect static

```bash
cd /srv/livestock/backend
source venv/bin/activate

python manage.py check --deploy        # must report 0 issues (or note each one)
python manage.py migrate
python manage.py collectstatic --no-input
python manage.py seed_data             # populate demo data (optional for production)
```

### 4.3 Test the Gunicorn startup

```bash
cd /srv/livestock/backend
source venv/bin/activate
gunicorn -c gunicorn.conf.py config.wsgi:application
# Ctrl+C to stop — use systemd for the production daemon
```

---

## 5. Nginx reverse proxy

Create `/etc/nginx/sites-available/livestock`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect all HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate     /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy strict-origin-when-cross-origin;

    location /static/ {
        alias /srv/livestock/backend/staticfiles/;
        expires 7d;
    }

    location /media/ {
        alias /srv/livestock/backend/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/livestock /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Obtain a free TLS certificate (requires a domain pointed to the server)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 6. systemd service

Create `/etc/systemd/system/livestock.service`:

```ini
[Unit]
Description=Smart Livestock Health and Farm Management System — Gunicorn
After=network.target mysql.service

[Service]
Type=notify
User=livestock
Group=www-data
WorkingDirectory=/srv/livestock/backend
Environment="PATH=/srv/livestock/backend/venv/bin"
ExecStart=/srv/livestock/backend/venv/bin/gunicorn \
    -c gunicorn.conf.py \
    config.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable livestock
sudo systemctl start livestock
sudo systemctl status livestock
```

---

## 7. Authority dashboard

The authority dashboard runs on the same Django process and is served at `/authority/`.
No additional process is required.

**Dashboard URL:** `https://your-domain.com/authority/login/`

**First-time admin setup:**
```bash
cd /srv/livestock/backend
source venv/bin/activate
python manage.py createsuperuser
```

---

## 8. Mobile APK build and distribution

### Build a release APK

```bash
cd mobile/livestock_app

# Update the API base URL in the app config before building
# File: lib/core/api/api_service.dart — change the baseUrl to your production server

flutter pub get
flutter build apk --release --target-platform android-arm64

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Distribution options

| Option | Method |
|---|---|
| Direct install (academic demo) | Share the `.apk` via USB or file link; enable "Install from unknown sources" on the device |
| Firebase App Distribution | Free; requires a Google account; best for team testing |
| Google Play (production) | Requires a $25 one-time developer registration; appropriate for a live product |

For the academic submission, the direct `.apk` method is sufficient.

---

## 9. Production configuration checklist (TC-SEC-08)

Run `python manage.py check --deploy` on the production server. This checks:

| Check | Expected result |
|---|---|
| `DEBUG = False` | PASS |
| `SECRET_KEY` is not the default | PASS |
| `ALLOWED_HOSTS` is not `['*']` | PASS |
| `SECURE_SSL_REDIRECT = True` | PASS (after HTTPS) |
| `SECURE_HSTS_SECONDS >= 31536000` | PASS (after HTTPS) |
| `SESSION_COOKIE_SECURE = True` | PASS (after HTTPS) |
| `CSRF_COOKIE_SECURE = True` | PASS (after HTTPS) |
| `SECURE_CONTENT_TYPE_NOSNIFF = True` | PASS |
| `X_FRAME_OPTIONS = 'DENY'` | PASS |

Additional manual checks:

| Check | Method |
|---|---|
| `.env` not in the repository | `git ls-files backend/.env` → no output |
| No `requirements.txt` secrets | Review the file |
| Error pages do not show stack traces | Browse to a 404 URL in production |
| `/api/docs/` requires authentication if sensitive | Currently public — restrict with `SERVE_INCLUDE_SCHEMA = True` and authentication in `SPECTACULAR_SETTINGS` if needed |
| Health check endpoint returns `{"status": "ok"}` | `curl https://your-domain.com/api/v1/health/` |

---

## 10. Post-deployment verification

After deploying, verify the following from a clean browser session and from the mobile app:

```
[ ] Health check:        GET /api/v1/health/                → {"status": "ok"}
[ ] Unauthenticated:     GET /api/v1/farms/                 → HTTP 401
[ ] Register:            POST /api/v1/auth/register/        → HTTP 201
[ ] Login:               POST /api/v1/auth/login/           → HTTP 200 + tokens
[ ] Farm create:         POST /api/v1/farms/                → HTTP 201
[ ] Dashboard login:     GET  /authority/login/             → login page
[ ] Swagger docs:        GET  /api/docs/                    → Swagger UI
[ ] Admin panel:         GET  /admin/                       → login page
```

---

## 11. Hosting costs and options

| Resource | Dev/demo | Production |
|---|---|---|
| Backend server | Windows dev machine | Oracle Cloud free tier or $6/month DigitalOcean |
| MySQL | Local MySQL 8 | Managed MySQL on Railway or same VPS |
| TLS certificate | Not required | Let's Encrypt (free) |
| APK distribution | Direct `.apk` file | Firebase App Distribution (free) |
| Backups | Manual | Cron `backup.sh` daily to local or object storage |
| **Total cost (demo)** | **$0** | **$0–$6/month** |

For the academic submission all features can be demonstrated on the development machine (E1) without any cloud hosting costs.
