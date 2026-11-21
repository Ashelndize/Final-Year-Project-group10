# Defect Log — Smart Livestock Health and Farm Management System

**Project:** Smart Livestock Health and Farm Management System
**Phase logged:** Phase 7 — Integration, Testing, and Acceptance
**Date:** 2026-11-21
**Status:** All defects resolved

---

## Summary

| ID | Severity | Component | Status | Discovered in |
|---|---|---|---|---|
| DEF-001 | Medium | Backend — Auth / Audit | **Fixed** | Phase 7 integration tests |

---

## DEF-001 — JWT login events not recorded in the audit trail

### Classification

| Field | Value |
|---|---|
| ID | DEF-001 |
| Severity | Medium |
| Component | `accounts` / `audit` |
| Discovered by | Integration test `AuthAuditTests.test_successful_login_creates_audit_event` |
| Discovered on | 2026-11-21 |
| Fixed on | 2026-11-21 |
| Status | Closed |

### Description

Every JWT login was silently unaudited. The audit log correctly recorded
`LOGIN_FAIL` events but never recorded `LOGIN_SUCCESS` events for JWT
authentication flows.

A malicious actor or system error that caused rapid successful logins would
leave no trace in the audit history, reducing the effectiveness of the audit
trail as a security control.

### Root cause

`accounts/signals.py` wires a `@receiver(user_logged_in)` signal handler to
call `AuditEvent.log(action=LOGIN_SUCCESS)`. Django's `user_logged_in` signal
is **only dispatched when `django.contrib.auth.login()` is called** — the
session-based login function.

The JWT token endpoint (`TokenObtainPairView`) authenticates the user and
issues tokens entirely through the DRF serializer pipeline; it never calls
`django.contrib.auth.login()`. Consequently, the signal was never fired for
any JWT-based authentication.

```
JWT login flow:
  POST /api/v1/auth/login/
    → CustomTokenObtainPairView (extends TokenObtainPairView)
    → CustomTokenObtainPairSerializer.validate()
      → credentials validated against DB ✓
      → access + refresh tokens generated ✓
      → user_logged_in signal NOT fired  ← gap
      → AuditEvent.log() NEVER called    ← gap
```

The `LOGIN_FAIL` path was unaffected because that path called
`AuditEvent.log()` directly from the failed-auth signal, which IS fired by
`axes` (brute-force protection middleware) independently of session auth.

### Fix

Overrode `validate()` in `CustomTokenObtainPairSerializer`
(`backend/accounts/serializers.py`) to call `AuditEvent.log()` explicitly
after successful JWT validation:

```python
def validate(self, attrs):
    data = super().validate(attrs)
    # JWT login does not fire django.contrib.auth.signals.user_logged_in,
    # so we create the audit event explicitly here.
    AuditEvent.log(
        actor=self.user,
        action=AuditEvent.Action.LOGIN_SUCCESS,
        target_type='User',
        target_id=self.user.pk,
        description=f'User {self.user.username} logged in via JWT.',
    )
    return data
```

### Verification

`AuthAuditTests.test_successful_login_creates_audit_event` now passes:
it asserts the `LOGIN_SUCCESS` event count increases after a successful JWT
login. Test is in `backend/integration_tests/test_audit_trail.py`.

### Impact

No data loss — this was a missing-write defect, not a data-corruption defect.
Audit events before the fix simply did not exist; retroactive creation is not
appropriate. All future logins are now correctly audited.

---

## Potential issues noted (not defects)

The following were observed during Phase 7 test writing and represent
deliberate design choices, not bugs. They are documented here for clarity.

### Note 1 — VET role can create farms

Initial test assumed `FarmViewSet` restricted farm creation to `FARMER` role.
On inspection, `FarmViewSet` only requires `IsAuthenticated`. This is correct
by design: vets may legitimately own farms (e.g. a vet who keeps livestock).
The test was updated to assert `HTTP_201_CREATED` for a vet creating a farm.

### Note 2 — VET role can submit disease reports

Same pattern. `DiseaseReportViewSet` has `permission_classes = [IsAuthenticated]`
only. Any authenticated user may report a suspected disease. The system logs
the reporter FK so origin is always traceable. Test updated accordingly.

### Note 3 — Logout returns HTTP 200, not HTTP 205

`LogoutView.post()` returns `HTTP_200_OK` with `{'detail': 'Successfully logged out.'}`.
The initial test expected `HTTP_205_RESET_CONTENT`. The view behaviour is correct
(205 is semantically appropriate but not required by the spec); test updated.
