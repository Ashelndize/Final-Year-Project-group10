# Requirements Traceability Matrix

**Project:** Smart Livestock Health and Farm Management System
**Phase:** Phase 7 — Integration, Testing, and Acceptance
**Date:** 2026-11-21

This matrix maps every Phase 7 acceptance requirement to its implementing
code and to the test(s) that provide evidence of compliance.

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Requirement met and verified by passing test |
| 🔧 | Requirement met after a defect was found and fixed |
| — | Not applicable |

---

## 1. End-to-end 12-step workflow

**Test file:** `backend/integration_tests/test_e2e_workflow.py`
**Test class:** `EndToEndWorkflowTest.test_full_12_step_workflow`

| Step | Requirement | Implementation | Test assertion | Status |
|---|---|---|---|---|
| 1 | Farmer can register via the API | `RegisterView` + `RegisterSerializer` | `assertEqual(HTTP_201_CREATED)` | ✅ |
| 2 | Registered farmer can create a farm | `FarmViewSet.create()` + `FarmSerializer` | `assertEqual(HTTP_201_CREATED)` | ✅ |
| 3 | Farmer can register an animal on their farm | `AnimalViewSet.create()` + `AnimalSerializer` | `assertEqual(HTTP_201_CREATED)` | ✅ |
| 4 | Farmer can record a health event | `HealthRecordViewSet.create()` | `assertEqual(HTTP_201_CREATED)` | ✅ |
| 5 | Vaccination schedule can be associated with an animal | `VaccinationSchedule` model + `VaccinationScheduleViewSet` | `assertIn(schedule.pk, ids)` | ✅ |
| 6 | Farmer can submit a veterinary assistance request | `VetAssistanceRequestViewSet.create()` | `assertEqual(HTTP_201_CREATED)`, `data['status'] == 'PENDING'` | ✅ |
| 7 | Vet can respond to assistance request; farmers cannot | `VetAssistanceRequestViewSet.respond()` + `IsVet` permission | `assertEqual(HTTP_200_OK)` for vet; `assertEqual(HTTP_403_FORBIDDEN)` for farmer | ✅ |
| 8 | Authenticated user can submit a disease report | `DiseaseReportViewSet.create()` | `assertEqual(HTTP_201_CREATED)`; outbreak not auto-confirmed | ✅ |
| 9 | AUTHORITY can review disease reports; farmers cannot | `DiseaseReportViewSet.review()` + `IsAuthority` | `assertEqual(HTTP_200_OK)` with `status == 'UNDER_REVIEW'`; farmer gets 403/404 | ✅ |
| 10 | AUTHORITY can create and publish announcements; farmers cannot publish | `OfficialAnnouncementViewSet.publish()` + `IsAuthority` | `assertEqual(HTTP_200_OK)` with `status == 'PUBLISHED'`; farmer gets 403/404 | ✅ |
| 11 | All FARMER and VET users receive in-app notification on publish | `announcements/signals.py` → `Notification.objects.bulk_create()` | `assertTrue(expected_recipients.issubset(notified_ids))` | ✅ |
| 12 | Sensitive actions appear in audit history | `AuditEvent.log()` called on create/update of key resources | `assertIn(CREATE, audit_actions)`, `assertIn(UPDATE, audit_actions)` | ✅ |

---

## 2. Authentication boundaries

**Test file:** `backend/integration_tests/test_permissions.py`
**Test class:** `AuthenticationBoundaryTests`

| Requirement | Endpoint(s) | Test | Status |
|---|---|---|---|
| Unauthenticated GET is rejected with 401 | 9 protected URLs | `test_all_protected_endpoints_require_authentication` (subTest) | ✅ |
| Unauthenticated POST is rejected with 401 | `/api/v1/farms/` | `test_post_without_token_returns_401` | ✅ |

---

## 3. Role-based access control — FARMER

**Test class:** `FarmerPermissionTests`

| Requirement | Test | Status |
|---|---|---|
| Farmer cannot see another farmer's farm | `test_farmer_cannot_see_other_farmers_farm` (404) | ✅ |
| Farmer can see their own farm | `test_farmer_can_see_own_farm` (200) | ✅ |
| Farmer cannot create official announcements | `test_farmer_cannot_create_announcement` (403) | ✅ |
| Farmer cannot access the audit log | `test_farmer_cannot_access_audit_log` (403) | ✅ |
| Farmer cannot access suspicious-activity flags | `test_farmer_cannot_access_suspicious_flags` (403) | ✅ |
| Farm list returns only the authenticated farmer's farms | `test_farmer_list_farms_returns_only_own` | ✅ |
| Farmer cannot create assistance request using another farmer's farm | `test_farmer_cannot_create_assistance_request_for_others_farm` (400/403) | ✅ |

---

## 4. Role-based access control — VET

**Test class:** `VetPermissionTests`

| Requirement | Test | Status |
|---|---|---|
| Vet can create a farm (not role-restricted by design) | `test_vet_can_create_farm` (201) | ✅ |
| Vet can submit a disease report (not role-restricted by design) | `test_vet_can_submit_disease_report` (201) | ✅ |
| Vet cannot create an assistance request (serializer-level rejection) | `test_vet_cannot_create_assistance_request` (400/403) | ✅ |
| Vet cannot access the audit log | `test_vet_cannot_access_audit_log` (403) | ✅ |

---

## 5. Role-based access control — AUTHORITY

**Test class:** `AuthorityPermissionTests`

| Requirement | Test | Status |
|---|---|---|
| Authority can see all disease reports | `test_authority_can_see_all_disease_reports` | ✅ |
| Authority can review a report | `test_authority_can_review_report` (200) | ✅ |
| Authority can create and publish announcements | `test_authority_can_create_and_publish_announcement` | ✅ |
| Audit log is ADMIN-only (authority is excluded) | `test_authority_cannot_access_audit_log` (403) | ✅ |
| Authority can access suspicious-activity flags | `test_authority_can_access_suspicious_flags` (200) | ✅ |
| Farmer cannot confirm outbreak | `test_authority_cannot_confirm_outbreak_without_review` (403/404) | ✅ |

---

## 6. JWT security

**Test file:** `backend/integration_tests/test_security.py`
**Test class:** `JWTSecurityTests`

| Requirement | Test | Status |
|---|---|---|
| Invalid (nonsense) JWT token is rejected | `test_invalid_token_returns_401` | ✅ |
| Tampered JWT signature is rejected | `test_tampered_token_returns_401` | ✅ |
| Token without Bearer prefix is rejected | `test_missing_bearer_prefix_returns_401` | ✅ |
| Logout blacklists the refresh token (cannot be reused) | `test_logout_blacklists_refresh_token` | ✅ |

---

## 7. Location privacy

**Test class:** `LocationPrivacyTests`

| Requirement | Test | Status |
|---|---|---|
| GPS coordinates stripped from disease report when `location_consent=False` | `test_disease_report_strips_coords_without_consent` | ✅ |
| GPS coordinates stored in disease report when `location_consent=True` | `test_disease_report_stores_coords_with_consent` | ✅ |
| GPS coordinates stripped from assistance request when `location_consent=False` | `test_assistance_request_strips_coords_without_consent` | ✅ |

---

## 8. Audit log security

**Test class:** `AuditSecurityTests`

| Requirement | Test | Status |
|---|---|---|
| Audit event descriptions never contain plaintext passwords | `test_audit_events_never_contain_password` | ✅ |
| Audit event descriptions never contain JWT tokens | `test_audit_events_never_contain_token` | ✅ |
| Audit log endpoint requires ADMIN role | `test_audit_log_requires_admin` (403 for FARMER) | ✅ |

---

## 9. Cross-user resource isolation

**Test class:** `CrossUserAccessTests`

| Requirement | Test | Status |
|---|---|---|
| User B cannot read User A's farm | `test_user_b_cannot_read_user_a_farm` (404) | ✅ |
| User B cannot delete User A's farm | `test_user_b_cannot_delete_user_a_farm` (404/403) | ✅ |
| User B cannot read User A's animal | `test_user_b_cannot_read_user_a_animal` (404) | ✅ |
| User B cannot add an animal to User A's farm | `test_user_b_cannot_add_animal_to_user_a_farm` (400/403/404) | ✅ |

---

## 10. Audit trail completeness

**Test file:** `backend/integration_tests/test_audit_trail.py`

| Requirement | Test class | Test | Status |
|---|---|---|---|
| Successful JWT login creates `LOGIN_SUCCESS` audit event | `AuthAuditTests` | `test_successful_login_creates_audit_event` | 🔧 (DEF-001 fixed) |
| Failed login creates `LOGIN_FAIL` audit event | `AuthAuditTests` | `test_failed_login_creates_audit_event` | ✅ |
| Disease report review creates `UPDATE` audit event | `ReportAuditTests` | `test_report_review_creates_update_audit_event` | ✅ |
| Announcement publish creates `UPDATE` audit event | `AnnouncementAuditTests` | `test_announcement_publish_creates_audit_event` | ✅ |
| Announcement withdrawal creates `UPDATE` audit event | `AnnouncementAuditTests` | `test_announcement_withdraw_creates_audit_event` | ✅ |
| Assistance request creation creates `CREATE` audit event | `VetRequestAuditTests` | `test_assistance_request_creation_creates_audit_event` | ✅ |
| Vet response creates `UPDATE` audit event | `VetRequestAuditTests` | `test_vet_response_creates_audit_event` | ✅ |

---

## 11. Notification dispatch

**Test file:** `backend/integration_tests/test_notifications.py`
**Test class:** `AnnouncementNotificationTests`

| Requirement | Test | Status |
|---|---|---|
| All active FARMER users receive notification when announcement is published | `test_all_farmers_and_vets_notified_on_publish` | ✅ |
| All active VET users receive notification when announcement is published | `test_all_farmers_and_vets_notified_on_publish` | ✅ |
| The issuing AUTHORITY does not receive their own notification | `test_authority_not_notified_on_publish` | ✅ |
| Farmer can list their own notifications | `test_farmer_can_read_notifications` | ✅ |
| Farmer can mark a notification as read | `test_farmer_can_mark_notification_as_read` | ✅ |
| Farmer can mark all notifications as read | `test_farmer_can_mark_all_notifications_read` | ✅ |
| Farmer cannot mark another farmer's notification as read | `test_farmer_cannot_see_other_farmers_notifications` (404/403) | ✅ |

---

## 12. Mobile (Flutter) model correctness

**Test file:** `mobile/livestock_app/test/widget_test.dart`

| Requirement | Test group | Tests | Status |
|---|---|---|---|
| `User.fromJson` parses role and computed properties | `User model` | 1 | ✅ |
| `Farm.fromJson` parses status and type labels | `Farm model` | 1 | ✅ |
| `Animal.fromJson` parses species, sex, displayName fallback | `Animal model` | 2 | ✅ |
| `AuthProvider` starts unauthenticated | `AuthProvider initial state` | 1 | ✅ |
| `OfflineQueueItem` round-trips through SQLite map encoding | `OfflineQueueItem` | 3 | ✅ |
| `OfflineQueueException` carries user-friendly message | `OfflineQueueException` | 3 | ✅ |
| `HealthRecord.fromJson` parses all fields; status labels and colors correct | `HealthRecord model` | 6 | ✅ |
| `DiseaseReport.fromJson` parses all fields including optional GPS; status colors correct | `DiseaseReport model` | 4 | ✅ |
| `AssistantResponse.fromJson` parses all fields; computed boolean getters correct | `AssistantResponse model` | 6 | ✅ |

---

## Coverage summary

| Area | Requirements | Verified | Defects found | Defects fixed |
|---|---|---|---|---|
| E2E 12-step workflow | 12 | 12 | 0 | — |
| Authentication boundaries | 2 | 2 | 0 | — |
| FARMER permissions | 7 | 7 | 0 | — |
| VET permissions | 4 | 4 | 0 | — |
| AUTHORITY permissions | 6 | 6 | 0 | — |
| JWT security | 4 | 4 | 0 | — |
| Location privacy | 3 | 3 | 0 | — |
| Audit log security | 3 | 3 | 0 | — |
| Cross-user isolation | 4 | 4 | 0 | — |
| Audit trail completeness | 7 | 7 | 1 (DEF-001) | 1 |
| Notification dispatch | 7 | 7 | 0 | — |
| Mobile model correctness | 27 | 27 | 0 | — |
| **Total** | **86** | **86** | **1** | **1** |
