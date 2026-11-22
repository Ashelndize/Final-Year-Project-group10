# Administrator Manual

**Project:** Smart Livestock Health and Farm Management System
**Audience:** System administrators and veterinary authority officers
**Date:** 2026-11-22

---

## Table of contents

1. [System overview for administrators](#1-system-overview-for-administrators)
2. [Django admin panel](#2-django-admin-panel)
3. [Authority dashboard](#3-authority-dashboard)
4. [User account management](#4-user-account-management)
5. [Disease report management](#5-disease-report-management)
6. [Announcement management](#6-announcement-management)
7. [Audit log review](#7-audit-log-review)
8. [Suspicious-activity flags](#8-suspicious-activity-flags)
9. [AI health assistant](#9-ai-health-assistant)
10. [System health check](#10-system-health-check)
11. [Routine maintenance tasks](#11-routine-maintenance-tasks)

---

## 1. System overview for administrators

The system has two separate administrative interfaces:

| Interface | URL | Audience | Authentication |
|---|---|---|---|
| **Authority dashboard** | `/authority/` | Veterinary authority officers | Django session login |
| **Django admin panel** | `/admin/` | System administrators (IT staff) | Django session login (staff/superuser) |
| **REST API** | `/api/v1/` | Mobile app + API clients | JWT tokens |
| **API documentation** | `/api/docs/` | Developers | None (public) |

**Role summary:**

| Role | Can do |
|---|---|
| `FARMER` | Manage own farm, animals, health records; request vet assistance |
| `VET` | Respond to assistance requests; submit disease reports |
| `AUTHORITY` | Review disease reports; publish/withdraw announcements; view suspicious flags |
| `ADMIN` | Full system access; manage users; view audit log |

---

## 2. Django admin panel

Access at `/admin/` with a superuser account.

### Creating the first superuser

```bash
cd backend
source venv/bin/activate    # or venv\Scripts\activate on Windows
python manage.py createsuperuser
```

### Key admin actions

| Task | Admin path |
|---|---|
| Create / deactivate user accounts | Accounts → Custom users |
| Verify a veterinarian | Accounts → Vet profiles → Set `is_verified = True` |
| Assign ADMIN or AUTHORITY role | Accounts → Custom users → Change role field |
| View all farms | Farms → Farms |
| View all disease reports | Reports → Disease reports |
| View all audit events | Audit → Audit events (read-only) |
| View all notifications | Notifications → Notifications |
| Manage vaccination protocols | Health → Vaccination protocols |

### Security notes for the admin panel

- The admin panel uses session-based authentication (not JWT). It is served at `/admin/` and must only be accessible over HTTPS in production.
- Do not log in to the admin panel from a shared computer.
- The admin panel can read all data including health records. The admin role should be used sparingly.

---

## 3. Authority dashboard

Access at `/authority/login/` with an account that has `role = AUTHORITY` or `role = ADMIN`.

### Dashboard pages

| Page | URL | Purpose |
|---|---|---|
| Login | `/authority/login/` | Session login for authority staff |
| Overview | `/authority/` | Summary of pending reports and recent announcements |
| Disease reports | `/authority/reports/` | List of all submitted disease reports |
| Report detail | `/authority/reports/<id>/` | Review a report; change status; add review notes |
| Announcements | `/authority/announcements/` | List all announcements |
| New announcement | `/authority/announcements/create/` | Draft a new official announcement |
| Announcement detail | `/authority/announcements/<id>/` | Publish, update, or withdraw |
| User management | `/authority/users/` | View and deactivate user accounts |
| Monitoring | `/authority/monitoring/` | Disease trends and report statistics |
| Suspicious flags | `/authority/suspicious/` | View and dismiss suspicious-activity flags |
| Audit viewer | `/authority/audit/` | (ADMIN only) View all audit events |

### Session management

- Authority dashboard sessions expire after the configured `SESSION_COOKIE_AGE` (default 2 hours).
- Always click **Log out** when finished, especially on shared machines.
- The JWT tokens issued by the mobile API are separate from dashboard sessions — logging out of the dashboard does not invalidate mobile sessions.

---

## 4. User account management

### Creating a new AUTHORITY or ADMIN account

AUTHORITY and ADMIN accounts cannot be self-registered. They must be created by an ADMIN.

**Via Django admin:**
1. Go to `/admin/accounts/customuser/add/`
2. Set `username`, `password`, `first_name`, `last_name`, `email`
3. Set `role` to `AUTHORITY` or `ADMIN`
4. For ADMIN: also tick `is_staff = True` and `is_superuser = True`
5. Save

**Via API (admin-only endpoint):**
```bash
# Not yet implemented — use Django admin
```

### Verifying a veterinarian

Vets self-register with `role = VET` but must be verified before treating their account as a licensed professional.

1. Go to `/admin/accounts/vetprofile/`
2. Find the vet by username
3. Set `is_verified = True`
4. Save

### Deactivating an account

1. Go to `/admin/accounts/customuser/`
2. Find the user
3. Untick `is_active`
4. Save — the user can no longer log in

**Note:** Deactivating an account does not invalidate active JWT tokens that were already issued. For immediate lockout, also run:

```bash
# Blacklist all outstanding refresh tokens for the user
# (manual step — no automated endpoint yet)
# From Django shell:
python manage.py shell
>>> from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
>>> from accounts.models import CustomUser
>>> user = CustomUser.objects.get(username='target_user')
>>> for token in OutstandingToken.objects.filter(user=user):
...     BlacklistedToken.objects.get_or_create(token=token)
```

---

## 5. Disease report management

### Report status workflow

```
SUBMITTED → UNDER_REVIEW → ACCEPTED_FOR_ASSESSMENT → REJECTED
                         ↘
                          CLOSED
```

### Reviewing a report

1. Navigate to `/authority/reports/<id>/`
2. Click **Start review** — status moves to `UNDER_REVIEW`
3. Add `review_notes`
4. Choose one of:
   - **Accept for assessment** → status moves to `ACCEPTED_FOR_ASSESSMENT`
   - **Reject** → requires a reason in `review_notes`

### Confirming an outbreak

After assessment, if the report warrants an official announcement:
1. Use the **Confirm outbreak** action on the report detail page
2. This marks `is_confirmed_outbreak = True` on the report
3. Draft an announcement (see §6)

**Important:** Outbreak confirmation is a human judgment call. The system does not automatically confirm outbreaks based on report volume or patterns.

---

## 6. Announcement management

### Announcement lifecycle

```
DRAFT → PUBLISHED → WITHDRAWN
      ↘ (never published)
        (deleted by admin)
```

### Creating and publishing an announcement

1. Go to `/authority/announcements/create/`
2. Fill in:
   - **Title** (required)
   - **Type:** `GENERAL`, `ADVISORY`, `ALERT`, or `EMERGENCY`
   - **Content** (required)
   - **Prevention guidance** (optional)
   - **Affected species** (optional)
   - **Affected area** (optional)
3. Click **Save as draft**
4. Review the draft
5. Click **Publish** to make it visible to all FARMER and VET users

Publishing triggers an in-app notification to all active FARMER and VET users.

### Withdrawing an announcement

1. Navigate to the announcement detail
2. Click **Withdraw**
3. Enter a **withdrawal reason** (required)
4. Confirm — status moves to `WITHDRAWN`

Withdrawn announcements remain in the system for audit purposes but are no longer shown to farmers.

---

## 7. Audit log review

The audit log is accessible to ADMIN role only.

**Via authority dashboard:** `/authority/audit/` (ADMIN only)
**Via Django admin:** `/admin/audit/auditevent/`
**Via API:** `GET /api/v1/audit-events/` (requires ADMIN JWT token)

### Audit log columns

| Column | Meaning |
|---|---|
| `timestamp` | UTC time of the event |
| `actor` | Username of the user who performed the action |
| `action` | One of: `CREATE`, `UPDATE`, `DELETE`, `LOGIN_SUCCESS`, `LOGIN_FAIL`, `LOGOUT`, `PERMISSION_DENIED` |
| `target_type` | Model name affected (e.g. `Farm`, `DiseaseReport`) |
| `target_id` | Primary key of the affected record |
| `description` | Human-readable summary |
| `ip_address` | Client IP at the time of the event |

**Note:** Audit events cannot be edited or deleted through the UI. Any attempt to modify audit records directly in the database is itself a security concern and should be investigated.

---

## 8. Suspicious-activity flags

Suspicious-activity flags are created automatically by the backend when defined thresholds are crossed (e.g. rapid repeated failed logins, unusual report volume).

### Reviewing flags

1. Go to `/authority/suspicious/` (AUTHORITY or ADMIN)
2. Each flag shows:
   - User involved
   - Type of suspicious activity
   - Timestamp
   - Severity level
3. After investigation, click **Dismiss** with a reason

Dismissals are recorded in the audit log.

### Flag types

| Type | Trigger |
|---|---|
| `RAPID_LOGIN_ATTEMPTS` | More than 5 failed logins within 10 minutes |
| `MASS_REPORT_SUBMISSION` | More than 10 disease reports within 1 hour |
| `UNUSUAL_API_VOLUME` | More than 200 API calls within 5 minutes |
| `DATA_SCRAPING_PATTERN` | Sequential ID enumeration detected |

---

## 9. AI health assistant

The AI assistant is currently configured as `kb_only` (knowledge-base only, no external LLM). It answers questions from a curated set of livestock health articles.

**Configuration in `.env`:**
```ini
ASSISTANT_ENABLED=False    # Set True to activate
ASSISTANT_PROVIDER=kb_only
```

When disabled, the assistant endpoint returns a `503 Service Unavailable` response with a message directing the user to consult a veterinarian.

**Safety rules (always enforced regardless of provider):**
- Drug dosage, prescription, and diagnosis requests are refused
- Every response carries the disclaimer: "General information — not a diagnosis"
- No external animal data is sent to any third-party provider

---

## 10. System health check

```bash
curl http://localhost:8000/api/v1/health/
```

Expected response:
```json
{"status": "ok", "database": "connected", "timestamp": "2026-11-22T..."}
```

If the database is unavailable the response is `{"status": "degraded", "database": "error"}` with HTTP 503.

### Manual system check

```bash
cd backend
source venv/bin/activate
python manage.py check --deploy
# Expected: System check identified no issues (0 silenced).
```

---

## 11. Routine maintenance tasks

| Frequency | Task | Command |
|---|---|---|
| Daily | Database backup | `./backend/scripts/backup.sh` (see backup guide) |
| Weekly | Rotate expired JWT tokens from the blacklist table | `python manage.py flushexpiredtokens` |
| Weekly | Review suspicious-activity flags | Authority dashboard → Suspicious flags |
| Monthly | Review audit log for anomalies | Authority dashboard → Audit viewer |
| Monthly | Update Python dependencies | `pip install --upgrade -r requirements.txt` (test first) |
| Monthly | Rotate `DJANGO_SECRET_KEY` | Update `.env`, restart Gunicorn (invalidates all sessions) |
| Per release | Re-run full test suite | `python manage.py test --verbosity=2` |
| Per release | Regenerate OpenAPI schema | `python manage.py spectacular --file schema.yml` |
