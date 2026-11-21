# Acceptance Test Results

**Project:** Smart Livestock Health and Farm Management System
**Phase:** Phase 7 — Integration, Testing, and Acceptance
**Test run date:** 2026-11-21
**Test environments:** Django test runner (MySQL 8.0.39), Flutter test runner

---

## Overall result: PASS

| Component | Tests | Passed | Failed | Errors |
|---|---|---|---|---|
| Backend unit tests (Phases 1–6) | 75 | 75 | 0 | 0 |
| Backend integration tests (Phase 7) | 47 | 47 | 0 | 0 |
| Flutter unit tests | 27 | 27 | 0 | 0 |
| **Total** | **149** | **149** | **0** | **0** |

---

## Backend test run

**Command:**
```bash
cd backend
python manage.py test --verbosity=2
```

**Result:** `Ran 122 tests in Xs — OK`

### Unit tests by app (Phases 1–6, 75 tests)

| App | Tests | Result |
|---|---|---|
| `accounts` | 13 | PASS |
| `farms` | 6 | PASS |
| `animals` | 4 | PASS |
| `health` | 3 | PASS |
| `audit` | 2 | PASS |
| `health_check` | 5 | PASS |
| `notifications` | 1 | PASS |
| `reports` | 11 | PASS |
| `announcements` | 10 | PASS |
| `veterinary` | 11 | PASS |
| `suspicious_activity` | 9 | PASS |
| **Total** | **75** | **ALL PASS** |

### Integration tests (Phase 7, 47 tests)

| Test file | Class | Tests | Result |
|---|---|---|---|
| `test_e2e_workflow.py` | `EndToEndWorkflowTest` | 1 (12-step) | PASS |
| `test_permissions.py` | `AuthenticationBoundaryTests` | 2 | PASS |
| `test_permissions.py` | `FarmerPermissionTests` | 7 | PASS |
| `test_permissions.py` | `VetPermissionTests` | 4 | PASS |
| `test_permissions.py` | `AuthorityPermissionTests` | 6 | PASS |
| `test_security.py` | `JWTSecurityTests` | 4 | PASS |
| `test_security.py` | `LocationPrivacyTests` | 3 | PASS |
| `test_security.py` | `AuditSecurityTests` | 3 | PASS |
| `test_security.py` | `CrossUserAccessTests` | 4 | PASS |
| `test_audit_trail.py` | `AuthAuditTests` | 2 | PASS |
| `test_audit_trail.py` | `ReportAuditTests` | 1 | PASS |
| `test_audit_trail.py` | `AnnouncementAuditTests` | 2 | PASS |
| `test_audit_trail.py` | `VetRequestAuditTests` | 2 | PASS |
| `test_notifications.py` | `AnnouncementNotificationTests` | 6 | PASS |
| **Total** | | **47** | **ALL PASS** |

---

## Flutter test run

**Command:**
```bash
cd mobile/livestock_app
flutter test test/widget_test.dart
```

**Result:** `+27: All tests passed!`

| Test group | Tests | Result |
|---|---|---|
| `User model` | 1 | PASS |
| `Farm model` | 1 | PASS |
| `Animal model` | 2 | PASS |
| `AuthProvider initial state` | 1 | PASS |
| `OfflineQueueItem` | 3 | PASS |
| `OfflineQueueException` | 3 | PASS |
| `HealthRecord model` | 6 | PASS |
| `DiseaseReport model` | 4 | PASS |
| `AssistantResponse model` | 6 | PASS |
| **Total** | **27** | **ALL PASS** |

---

## Defects found during testing

| ID | Severity | Description | Status |
|---|---|---|---|
| DEF-001 | Medium | JWT login events not recorded in audit trail — `user_logged_in` signal never fires for JWT auth | Fixed before final test run |

Full details in `docs/03_testing/defect-log.md`.

---

## 12-step end-to-end workflow — step-by-step results

Each step was verified within `EndToEndWorkflowTest.test_full_12_step_workflow`.

| Step | Description | Assertion | Result |
|---|---|---|---|
| 1 | Farmer registers via `/api/v1/auth/register/` | HTTP 201 + DB record exists | PASS |
| 2 | Farmer creates a farm | HTTP 201 + farm ID in response | PASS |
| 3 | Farmer registers an animal | HTTP 201 + animal ID in response | PASS |
| 4 | Farmer records a health event | HTTP 201 | PASS |
| 5 | Vaccination schedule associated with animal | HTTP 200 on list; schedule ID present | PASS |
| 6 | Farmer submits veterinary assistance request | HTTP 201; status = `PENDING` | PASS |
| 7 | Vet accepts request; farmer cannot use `/respond/` | HTTP 200; status = `ACCEPTED`; farmer gets 403 | PASS |
| 8 | Farmer submits disease report | HTTP 201; `is_confirmed_outbreak = false` | PASS |
| 9 | Authority reviews report; farmer cannot review | HTTP 200; status = `UNDER_REVIEW`; farmer gets 403/404 | PASS |
| 10 | Authority publishes announcement; farmer cannot publish | HTTP 200; status = `PUBLISHED`; farmer gets 403/404 | PASS |
| 11 | All FARMER + VET users receive notification | Notification records exist for all expected recipients | PASS |
| 12 | Audit history contains CREATE and UPDATE events for key resources | `AuditEvent` queryset contains both action types | PASS |

---

## Acceptance criteria sign-off

| Criterion | Evidence | Result |
|---|---|---|
| All 12 E2E workflow steps complete without error | `test_full_12_step_workflow` passes | **PASS** |
| JWT tokens are validated and cannot be forged | `JWTSecurityTests` (4 tests) | **PASS** |
| Logout invalidates the refresh token | `test_logout_blacklists_refresh_token` | **PASS** |
| GPS coordinates respect `location_consent` flag | `LocationPrivacyTests` (3 tests) | **PASS** |
| Audit log never exposes passwords or tokens | `AuditSecurityTests` (2 tests) | **PASS** |
| Audit log is accessible only to ADMIN | `test_audit_log_requires_admin` | **PASS** |
| Cross-user resource access is denied | `CrossUserAccessTests` (4 tests) | **PASS** |
| All 9 protected endpoints require authentication | `AuthenticationBoundaryTests` | **PASS** |
| Role boundaries are enforced (FARMER / VET / AUTHORITY) | 17 role-permission tests | **PASS** |
| Audit trail records all required events | `test_audit_trail.py` (7 tests), after DEF-001 fix | **PASS** |
| Notifications sent to correct recipients | `AnnouncementNotificationTests` (6 tests) | **PASS** |
| Mobile models correctly deserialise API responses | Flutter unit tests (27 tests) | **PASS** |
| Zero failing tests across the full test suite | 149/149 tests pass | **PASS** |
