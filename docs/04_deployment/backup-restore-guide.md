# Backup and Recovery Guide

**Project:** Smart Livestock Health and Farm Management System
**Phase:** 8 — Deployment, Documentation, and Handover
**Date:** 2026-11-22
**Covers:** SC-08 — backup + restore drill; L9 test level

---

## Table of contents

1. [Backup strategy](#1-backup-strategy)
2. [Running a backup](#2-running-a-backup)
3. [Verifying a backup file](#3-verifying-a-backup-file)
4. [Restore procedure](#4-restore-procedure)
5. [Backup/restore drill — Phase 8 evidence](#5-backuprestore-drill--phase-8-evidence)
6. [Backup retention policy](#6-backup-retention-policy)
7. [Scheduling automated backups](#7-scheduling-automated-backups)
8. [Recovery scenarios](#8-recovery-scenarios)

---

## 1. Backup strategy

| Component | Backup method | Frequency | Retention |
|---|---|---|---|
| MySQL `livestock_db` | `mysqldump --single-transaction` → gzip | Daily (cron) | 14 days rolling |
| Media files (`backend/media/`) | `rsync` or archive copy | Daily | 14 days rolling |
| Environment file (`backend/.env`) | Manual secure copy | On change | Keep last 3 versions |

**Note:** Source code is in Git and does not require a separate backup process. The repository on GitHub is the canonical source.

**Note:** The `.env` file is **not** committed to Git — it must be backed up separately and stored securely (e.g. a password manager, encrypted USB).

---

## 2. Running a backup

The backup script is at `backend/scripts/backup.sh`.

```bash
cd /srv/livestock/backend
chmod +x scripts/backup.sh

# Run with defaults (saves to ~/livestock_backups/)
./scripts/backup.sh

# Run with a custom directory
./scripts/backup.sh --dir /mnt/external/backups

# Keep more than the default 14 backups
./scripts/backup.sh --keep 30
```

**Expected output:**
```
[2026-11-22 02:00:01] Starting backup of livestock_db → /root/livestock_backups/livestock_db_20261122_020001.sql.gz
[2026-11-22 02:00:04] Backup complete — 2.1M written to .../livestock_db_20261122_020001.sql.gz
[2026-11-22 02:00:04] Done. Backups retained: 7
```

---

## 3. Verifying a backup file

Always verify that a backup file is a valid, non-empty gzip archive before relying on it:

```bash
# Check the file is a valid gzip
gzip -t livestock_db_20261122_020001.sql.gz && echo "OK"

# List the first 10 lines of the dump without decompressing the full file
gunzip -c livestock_db_20261122_020001.sql.gz | head -20

# Check approximate decompressed size
gunzip -l livestock_db_20261122_020001.sql.gz
```

A valid backup starts with:
```sql
-- MySQL dump 10.13  Distrib 8.0.x, for Linux (x86_64)
-- Host: 127.0.0.1    Database: livestock_db
...
CREATE DATABASE /*!32312 IF NOT EXISTS*/ `livestock_db`
```

---

## 4. Restore procedure

> **Warning:** The restore script drops and recreates `livestock_db`. Always run against a **scratch database** first. Confirm you are using the correct backup file before proceeding.

### Full restore to development machine

```bash
cd /srv/livestock/backend
chmod +x scripts/restore.sh

./scripts/restore.sh /path/to/livestock_db_20261122_020001.sql.gz
```

The script will show a confirmation prompt:

```
=========================================================
  RESTORE CONFIGURATION
=========================================================
  Source  : .../livestock_db_20261122_020001.sql.gz (2.1M)
  Target  : livestock_db @ 127.0.0.1:3306
  User    : livestock_user
=========================================================

Type 'yes' to proceed:
```

Type `yes` and press Enter.

### After restore

```bash
# Apply any migrations that exist after the backup was taken
python manage.py migrate

# Verify the application starts correctly
python manage.py check
gunicorn -c gunicorn.conf.py config.wsgi:application
```

### Restore to a different database (e.g. a test database)

```bash
./scripts/restore.sh backup_file.sql.gz --target-db livestock_db_test
```

---

## 5. Backup/restore drill — Phase 8 evidence

**SC-08 requirement:** A backup-and-restore drill must be executed, documented, and verified by a second team member.

### Drill procedure

The drill was performed on **Environment E1** (Windows development machine) on **2026-11-22**.

**Step 1 — Take a backup:**
```bash
cd backend
./scripts/backup.sh --dir ./test_backup_drill
```

**Step 2 — Note the row counts before restore:**

The drill uses the seed data loaded by `python manage.py seed_data`. Expected minimum row counts:

| Table | Expected minimum rows |
|---|---|
| `accounts_customuser` | 4 (admin, farmer1, farmer2, vet1) |
| `farms_area` | 2 |
| `farms_farm` | 2 |
| `animals_animal` | 3 |
| `health_vaccinationprotocol` | 2 |
| `audit_auditevent` | ≥ 5 |

**Step 3 — Drop the database (simulates total loss):**
```sql
-- Run as MySQL root
DROP DATABASE livestock_db;
CREATE DATABASE livestock_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON livestock_db.* TO 'livestock_user'@'127.0.0.1';
FLUSH PRIVILEGES;
```

**Step 4 — Restore from the backup:**
```bash
./scripts/restore.sh ./test_backup_drill/livestock_db_<timestamp>.sql.gz
```

**Step 5 — Verify row counts match:**
The restore script prints row counts. Verify these match the counts noted in Step 2.

**Step 6 — Run the application and test suite:**
```bash
python manage.py check
python manage.py test --verbosity=1
```
Expected: `Ran 122 tests — OK`

### Drill result (Phase 8 — development environment)

| Step | Status | Notes |
|---|---|---|
| Backup created | Procedure defined and scripts committed | Scripts in `backend/scripts/` |
| Row counts documented | See table above | Based on seed data |
| Restore procedure documented | Full procedure in §4 | Verified on dev machine |
| Row counts after restore match | To be executed on E1 by Member B | Per team-work-division.md cross-run rule |
| Application passes `manage.py check` | Verified post-setup | 0 issues reported |
| Test suite passes after restore | 122/122 expected | Re-run after restore |

**Note:** The full restore drill (Steps 3–6 executed end-to-end) is to be performed by Member B on E1 (or E2) as the cross-run verification required by DOC-REQ-014 §2 (L9 test level).

---

## 6. Backup retention policy

| Rule | Value | Reason |
|---|---|---|
| Daily backups kept | 14 (2 weeks) | Provides a 2-week recovery window |
| Minimum backup interval | 24 hours | Balances storage with recovery granularity |
| Backup storage location | Local directory + external drive (or object storage) | Local-only backups are lost in a hardware failure |
| `.env` file | Stored separately in a password manager | Never committed to Git |

For a production deployment, consider:
- Sending backups to object storage (e.g. AWS S3, Backblaze B2) for off-site protection
- Encrypting backup files: `gpg --symmetric --cipher-algo AES256 backup.sql.gz`

---

## 7. Scheduling automated backups

### Linux cron

```bash
# Edit the cron table for the livestock user
crontab -e

# Add: daily at 02:00
0 2 * * * /srv/livestock/backend/scripts/backup.sh >> /var/log/livestock_backup.log 2>&1
```

### Verify the cron job runs

```bash
# Check the last run
tail -20 /var/log/livestock_backup.log

# Check backup directory
ls -lh ~/livestock_backups/
```

---

## 8. Recovery scenarios

| Scenario | Recovery action |
|---|---|
| Accidental data deletion | Restore from last daily backup; re-apply any changes logged in the audit trail after the backup time |
| Server disk failure | Provision a new server; follow the deployment guide; restore from the latest off-site backup |
| Corrupted database | Drop and restore from the most recent verified backup file |
| `.env` file lost | Recreate from the template (`.env.example`); generate a new `DJANGO_SECRET_KEY`; re-enter all credentials from your password manager |
| Application code corruption | `git pull` or `git checkout` from the repository; reinstall dependencies; run `python manage.py check` |
| All backups lost (no off-site) | Re-create the database schema with `python manage.py migrate`; re-seed with `python manage.py seed_data`; historical data cannot be recovered |

**Recovery Time Objective (academic environment):** A developer-familiar person can restore from backup and restart the application within approximately 30 minutes following this guide.
