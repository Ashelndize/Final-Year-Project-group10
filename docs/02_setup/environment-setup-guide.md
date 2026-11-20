# Environment Setup Guide — Phase 1

**Project:** Smart Livestock Health and Farm Management System  
**Phase:** 1 — Development Environment Setup  
**Last updated:** 2026-11-20  
**Author:** Member C (WP-03)

---

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Repository layout](#2-repository-layout)
3. [Backend setup (Django + MySQL)](#3-backend-setup-django--mysql)
4. [MySQL database setup](#4-mysql-database-setup)
5. [Flutter / mobile setup](#5-flutter--mobile-setup)
6. [Verifying end-to-end connectivity](#6-verifying-end-to-end-connectivity)
7. [Common troubleshooting](#7-common-troubleshooting)
8. [Phase 1 acceptance criteria checklist](#8-phase-1-acceptance-criteria-checklist)

---

## 1. Prerequisites

Install the following tools before cloning the repository. All version
constraints are the minimum tested versions; newer patch releases are
generally safe.

| Tool | Minimum version | Notes |
|---|---|---|
| Python | 3.11.x | 3.12 also works |
| pip | 23.x | Upgrade with `pip install --upgrade pip` |
| Git | 2.40.x | |
| MySQL | 8.0.x | Community Server |
| Flutter | 3.19.x | Includes Dart 3.3.x |
| Dart | 3.3.x | Bundled with Flutter |
| Android SDK | API 34 | Via Android Studio or `sdkmanager` |
| VS Code (optional) | 1.88.x | With Dart + Flutter extensions |

### Verifying installed versions

Run these commands and compare against the table above:

```bash
python --version
pip --version
git --version
mysql --version
flutter --version
dart --version
flutter doctor          # Shows Android SDK status
```

Expected output format (actual version numbers will differ by machine):

```
Python 3.11.9
pip 24.0 from ... (python 3.11)
git version 2.44.0.windows.1
mysql  Ver 8.0.36 ...
Flutter 3.19.6 • channel stable
Dart SDK version: 3.3.4
```

**If any tool is missing:** See the [troubleshooting section](#7-common-troubleshooting).

---

## 2. Repository layout

After completing Phase 1, the repository has this structure:

```
Final-Year-Project-group10/
├── .env.example              # Template for environment variables (safe to commit)
├── .gitignore                # Covers Python, Django, Flutter, IDE, OS
├── MASTER_PROJECT_PROMPT.md  # Phase-by-phase development guide
├── PROGRESS.md               # Session-by-session progress log
├── README.md                 # Project overview
│
├── backend/                  # Django REST Framework backend (Member A / Member C)
│   ├── .env                  # Local secrets — gitignored, never commit
│   ├── config/
│   │   ├── __init__.py       # PyMySQL fallback registration
│   │   ├── asgi.py
│   │   ├── settings.py       # All settings loaded from env vars via python-decouple
│   │   ├── urls.py           # Root URL config
│   │   └── wsgi.py
│   ├── health_check/         # Phase 1 — GET /api/v1/health/
│   │   ├── __init__.py
│   │   ├── apps.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py
│   ├── manage.py
│   ├── requirements.txt
│   └── venv/                 # Python virtual environment — gitignored
│
├── mobile/                   # Flutter mobile app (Member B)
│   └── livestock_app/
│       ├── lib/
│       │   └── main.dart     # Phase 1 — health-check connectivity screen
│       ├── test/
│       │   └── widget_test.dart
│       ├── android/
│       │   └── app/src/main/AndroidManifest.xml
│       ├── analysis_options.yaml
│       └── pubspec.yaml
│
├── dashboard/                # Django templates authority dashboard (Member C)
│   └── .gitkeep              # Scaffolded in Phase 2
│
├── tests/                    # Integration and E2E tests
│   └── .gitkeep
│
└── docs/
    ├── 00_requirements/      # Phase 0 requirements documents (19 files)
    ├── 01_design/            # Architecture, ERD, wireframes
    ├── 02_setup/             # This file, mysql-setup.sql
    ├── 03_testing/           # Test plans
    ├── 04_deployment/        # Deployment guides
    └── 05_final_report/      # Final academic report
```

---

## 3. Backend setup (Django + MySQL)

### 3.1 Clone and navigate

```bash
git clone https://github.com/<org>/Final-Year-Project-group10.git
cd Final-Year-Project-group10
```

### 3.2 Create a Python virtual environment

```bash
cd backend
python -m venv venv
```

### 3.3 Activate the virtual environment

**Windows (Git Bash / MINGW64):**
```bash
source venv/Scripts/activate
```

**Windows (PowerShell):**
```powershell
.\venv\Scripts\Activate.ps1
```

**macOS / Linux:**
```bash
source venv/bin/activate
```

You should see `(venv)` at the start of your prompt.

### 3.4 Upgrade pip and install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

The `requirements.txt` includes PyMySQL as the MySQL driver. If you prefer
`mysqlclient` (requires MySQL C client libraries), see the
[mysqlclient troubleshooting note](#71-mysqlclient-fails-to-install-on-windows).

### 3.5 Create the local `.env` file

```bash
# From the backend/ directory
cp ../.env.example .env
```

Edit `backend/.env` and fill in your local MySQL credentials:

```dotenv
DJANGO_SECRET_KEY=dev-only-secret-key-not-for-production-abc123xyz
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
DB_ENGINE=django.db.backends.mysql
DB_NAME=livestock_db
DB_USER=livestock_user
DB_PASSWORD=your-actual-password-here
DB_HOST=127.0.0.1
DB_PORT=3306
```

**Never commit `backend/.env`.** It is listed in `.gitignore`.

### 3.6 Verify Django configuration

```bash
# From backend/ with venv active
python manage.py check
```

Expected output: `System check identified no issues (0 silenced).`

If MySQL is not yet set up, you will see a database connection error — this is
expected at this stage. See [Section 4](#4-mysql-database-setup) first.

### 3.7 Run database migrations

After completing the MySQL setup in Section 4:

```bash
python manage.py migrate
```

### 3.8 Start the development server

```bash
python manage.py runserver 8000
```

The server starts at `http://127.0.0.1:8000/`.

### 3.9 Verify the health-check endpoint

```bash
curl http://localhost:8000/api/v1/health/
```

Expected response:
```json
{"status": "ok", "service": "livestock-backend"}
```

Or open in a browser: `http://localhost:8000/api/v1/health/`

### 3.10 Run backend unit tests

```bash
python manage.py test health_check
```

---

## 4. MySQL database setup

### 4.1 Install MySQL 8.0

Download from: https://dev.mysql.com/downloads/mysql/  
Choose the "MySQL Installer for Windows" and select "Server only".

### 4.2 Create the database and user

Connect as root:

```bash
mysql -u root -p
```

Then run the setup script:

```sql
source docs/02_setup/mysql-setup.sql;
```

Or paste the commands manually — see `docs/02_setup/mysql-setup.sql` for the
full script with comments.

**Key commands:**
```sql
CREATE DATABASE livestock_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'livestock_user'@'127.0.0.1' IDENTIFIED BY 'your-strong-password';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, REFERENCES
    ON livestock_db.* TO 'livestock_user'@'127.0.0.1';
FLUSH PRIVILEGES;
```

### 4.3 Update `backend/.env`

Set `DB_PASSWORD` to the password you chose above.

### 4.4 Test the connection

```bash
# From backend/ with venv active
python manage.py check --database default
```

---

## 5. Flutter / mobile setup

### 5.1 Prerequisites

Ensure `flutter doctor` shows no errors (or only acceptable warnings):

```bash
flutter doctor
```

Minimum requirements:
- Flutter SDK installed and on PATH
- Android Studio installed with Android SDK (API 34)
- An AVD (Android Virtual Device) created, or a physical Android device

### 5.2 Navigate to the app directory

```bash
cd mobile/livestock_app
```

### 5.3 Install Dart packages

```bash
flutter pub get
```

### 5.4 Run static analysis

```bash
flutter analyze
```

Expected: `No issues found!` (or only info-level notices)

### 5.5 Run widget tests

```bash
flutter test
```

### 5.6 Start an Android emulator

Open Android Studio → Device Manager → Start a device,
or from the command line:

```bash
# List available emulators
flutter emulators

# Launch one (replace <emulator-id> with your emulator name)
flutter emulators --launch <emulator-id>
```

### 5.7 Run the app

With the emulator running and the Django backend running on port 8000:

```bash
flutter run
```

The app:
1. Opens with a green agriculture icon and the title "Livestock Manager".
2. On load, calls `http://10.0.2.2:8000/api/v1/health/` (the Android emulator
   loopback address that maps to `localhost` on the host machine).
3. Displays **"Backend: Connected ✓ (livestock-backend)"** if the backend is
   running, or **"Backend: Unreachable"** if it is not.
4. A **Refresh** button re-runs the connectivity check.

### 5.8 Physical device note

When running on a physical device on the same local network:
1. Find the host machine's local IP (`ipconfig` on Windows).
2. Change `_healthUrl` in `mobile/livestock_app/lib/main.dart` from
   `http://10.0.2.2:8000/...` to `http://<your-ip>:8000/...`.
3. Add your IP to `DJANGO_ALLOWED_HOSTS` in `backend/.env`.

---

## 6. Verifying end-to-end connectivity

### Full end-to-end test sequence

1. Start MySQL (verify it is running: `mysql -u livestock_user -p livestock_db`)
2. Start Django:
   ```bash
   cd backend && source venv/Scripts/activate && python manage.py runserver 8000
   ```
3. Verify backend directly:
   ```bash
   curl http://localhost:8000/api/v1/health/
   # Expected: {"status":"ok","service":"livestock-backend"}
   ```
4. Start the Android emulator.
5. Run the Flutter app: `cd mobile/livestock_app && flutter run`
6. The app should display **"Backend: Connected ✓ (livestock-backend)"**.

### API documentation (Swagger UI)

With the server running, open:
- Swagger UI: `http://localhost:8000/api/docs/`
- ReDoc: `http://localhost:8000/api/redoc/`
- Raw OpenAPI schema: `http://localhost:8000/api/schema/`

---

## 7. Common troubleshooting

### 7.1 `mysqlclient` fails to install on Windows

**Symptom:** `pip install mysqlclient` fails with a compiler error or
"mysql_config not found".

**Solution:** Use PyMySQL instead (already the default in `requirements.txt`).
PyMySQL is a pure-Python MySQL driver and does not require C compilation.

The `backend/config/__init__.py` file already registers PyMySQL as a drop-in
replacement for MySQLdb:

```python
import pymysql
pymysql.install_as_MySQLdb()
```

No further action is needed — just ensure `mysqlclient` is **not** in
`requirements.txt` (it is commented out by default).

### 7.2 `python manage.py check` fails with `OperationalError: (2003, "Can't connect to MySQL server")`

**Cause:** MySQL is not running, or the credentials in `backend/.env` are wrong.

**Fix:**
1. Start MySQL service: `net start MySQL80` (Windows) or `sudo service mysql start` (Linux)
2. Verify credentials in `backend/.env`
3. Test the connection: `mysql -u livestock_user -h 127.0.0.1 -p livestock_db`

### 7.3 `flutter doctor` reports Android SDK issues

**Common fix:** Open Android Studio → SDK Manager → install:
- Android SDK Platform 34
- Android SDK Build-Tools 34.x
- Android Emulator
- Android SDK Command-line Tools

Then run `flutter doctor --android-licenses` to accept all licenses.

### 7.4 Flutter app shows "Backend: Unreachable"

**Check these in order:**
1. Is the Django server running? (`python manage.py runserver 8000`)
2. Is the emulator using `10.0.2.2` (Android AVD loopback)? This is correct for
   the Android Emulator. iOS Simulator uses `127.0.0.1` instead.
3. Is the firewall blocking port 8000? Add an inbound rule for TCP 8000.
4. Check `DJANGO_ALLOWED_HOSTS` in `backend/.env` includes `localhost` and `127.0.0.1`.

### 7.5 `decouple.UndefinedValueError: SECRET_KEY not found`

**Cause:** `backend/.env` does not exist (you forgot to create it from `.env.example`).

**Fix:**
```bash
cd backend
cp ../.env.example .env
# Edit .env and fill in real values
```

### 7.6 `ModuleNotFoundError: No module named 'decouple'`

**Cause:** Virtual environment not activated.

**Fix:**
```bash
source venv/Scripts/activate   # Windows Git Bash
# or
.\venv\Scripts\Activate.ps1    # PowerShell
```

### 7.7 `flutter pub get` fails with version conflicts

**Fix:**
```bash
flutter pub upgrade
flutter pub get
```

If a specific package has a breaking change, pin the version in `pubspec.yaml`
and run `flutter pub get` again.

### 7.8 `CORS` errors when calling the API from a browser

The backend uses `django-cors-headers`. For development, the `CORS_ALLOWED_ORIGINS`
in `backend/.env` must include the origin of your frontend.

Add the missing origin:
```dotenv
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080
```

---

## 8. Phase 1 acceptance criteria checklist

| Criterion | How to verify | Status |
|---|---|---|
| Backend starts successfully | `python manage.py check` returns 0 issues | Requires MySQL |
| Database connection succeeds | `python manage.py check --database default` | Requires MySQL |
| Health-check responds with `{"status":"ok"}` | `curl http://localhost:8000/api/v1/health/` | Requires running server |
| Flutter app runs on emulator/device | `flutter run` launches without crash | Requires Flutter + Android SDK |
| App shows backend connection status | App UI displays "Connected ✓" or "Unreachable" | Requires both above |
| Another developer can reproduce setup | Follow this guide from scratch | Manual verification |

---

*End of environment setup guide.*
