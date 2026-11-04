# API Requirements

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-005 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Related | DOC-REQ-002 (SRS), DOC-REQ-003 (business rules), DOC-REQ-004 (data), DOC-REQ-006 (security), DOC-REQ-007 (audit/AI) |

---

## 1. Purpose and status of this contract

This document specifies the API surface the backend must provide for the mobile app and the authority
dashboard, together with the conventions every resource obeys. It is the interface contract referenced
by the team rule "Member B never invents endpoints".

| Contract state | Meaning |
|---|---|
| Phase 0 (this document) | Required capability, conventions and shapes are specified; exact field lists may be refined |
| End of M2 (Phase 2 gate) | Contract freeze: the generated OpenAPI schema plus this document are signed by both members; changes afterwards require a changelog entry here and a schema regeneration |

The generated OpenAPI schema (drf-spectacular) is the source of truth for exact field names, types and
enums once implemented. This document is the source of truth for intent, permissions and conventions.

---

## 2. Global conventions

| ID | Convention | Specification |
|---|---|---|
| API-C1 | Base path and versioning | All resources under `/api/v1/`. Version in the path. Breaking change = new version namespace, never a silent redefinition (NF-CMP-04) |
| API-C2 | Format | JSON request and response, UTF-8. `multipart/form-data` only for attachment upload |
| API-C3 | Authentication | `Authorization: Bearer <access>` (SimpleJWT). Dashboard uses Django session auth and is not part of this contract |
| API-C4 | Content negotiation | `Accept: application/json` assumed; no HTML from the API |
| API-C5 | Timestamps | ISO-8601 UTC with microseconds, e.g. `2026-11-04T09:12:33.482115Z` |
| API-C6 | Identifiers | Numeric `id` in payloads; clients treat ids as opaque (IDOR defence is server-side, NF-SEC-04) |
| API-C7 | Pagination | Page-number pagination, default and maximum page size 20 for standard lists (sync batch is separately capped at 100). Envelope: `count`, `next`, `previous`, `page`, `page_size`, `results` |
| API-C8 | Filtering | django-filter query parameters declared per resource in §5; unknown filter parameters are ignored, invalid enum values return 422 |
| API-C9 | Search | `search=<string>` where declared, applied with `icontains` over the declared fields, max 100 characters |
| API-C10 | Ordering | `ordering=<field>` with `-` for descending; each resource declares an allow-list; default ordering stated in §5 |
| API-C11 | Partial update | `PATCH` for partial update, `PUT` for full replacement; both increment `version` |
| API-C12 | Idempotency | All mutation endpoints accept the `X-Idempotency-Key` header (client UUID). Sync endpoints require it. Replays return the original result with `X-Idempotent-Replayed: true` (BR-20) |
| API-C13 | Optimistic concurrency | Mutating requests may send `If-Match: <version>`; a stale version returns 409 `VERSION_CONFLICT`. Sync-path mutations use last-write-wins-with-audit instead (BR-19) |
| API-C14 | Errors | One envelope, §4, for 4xx and 5xx. Success responses are bare resources or the pagination envelope |
| API-C15 | Status codes | 200 read/update, 201 create, 204 delete/no content, 205 reset-content (logout), 400 malformed, 401 unauthenticated, 403 forbidden-by-role, 404 not visible to caller, 405 method not allowed, 409 conflict/state error, 410 gone (deleted resource), 413 payload too large, 415 unsupported media type, 422 validation, 423 locked (login lockout), 429 throttled, 500/503 server |
| API-C16 | Throttling | Declared per resource in §5 and §6; responses carry `Retry-After` |
| API-C17 | Correlation | Every response carries `X-Request-Id`; the same value is written to the log line and to any `AuditEvent` produced (NF-MNT-04) |
| API-C18 | Field-level sensitivity | Sensitive fields are omitted, not blanked, when the caller is not entitled: `location_lat`, `location_lng`, `licence_number`, `contact_phone`, reporter identity |
| API-C19 | Enum representation | Upper-case snake-case strings matching the model `TextChoices` |
| API-C20 | Documentation | Every endpoint annotated for drf-spectacular so the generated schema carries summaries, permission notes and error shapes |

---

## 3. Resource index

| ID | Resource | Path root | Requirement driver |
|---|---|---|---|
| API-01 | Health and metadata | `/api/v1/health/`, `/api/v1/config/` | NF-REL-01, FR-AI-16 |
| API-02 | Authentication | `/api/v1/auth/` | FR-AUTH-02..09 |
| API-03 | Account and profiles | `/api/v1/accounts/` | FR-AUTH-08/10/12/16 |
| API-04 | Areas | `/api/v1/areas/` | FR-FARM-05 |
| API-05 | Consents | `/api/v1/consents/` | FR-AUTH-03, BR-06 |
| API-06 | Farms | `/api/v1/farms/` | FR-FARM-01..07 |
| API-07 | Animals | `/api/v1/animals/` | FR-ANIM-01..09 |
| API-08 | Health records | `/api/v1/health-records/` | FR-HEALTH-01..03, 09 |
| API-09 | Vaccination schedules | `/api/v1/vaccination-schedules/` | FR-HEALTH-04 |
| API-10 | Vaccination records | `/api/v1/vaccination-records/` | FR-HEALTH-04 |
| API-11 | Treatment records | `/api/v1/treatment-records/` | FR-HEALTH-05 |
| API-12 | Veterinary visits | `/api/v1/vet-visits/` | FR-HEALTH-06 |
| API-13 | Veterinarians (directory) | `/api/v1/vets/` | FR-VET-04/11 |
| API-14 | Assistance requests | `/api/v1/assistance-requests/` | FR-VET-05..14 |
| API-15 | Geocoding proxy | `/api/v1/geo/` | FR-VET-03, THR-06 |
| API-16 | Disease reports | `/api/v1/disease-reports/` | FR-REPORT-01..12 |
| API-17 | Report reviews (dashboard-facing) | `/api/v1/disease-reports/{id}/review/` | FR-REPORT-03/04/10 |
| API-18 | Announcements | `/api/v1/announcements/` | FR-ANN-01..12 |
| API-19 | Notifications | `/api/v1/notifications/` | FR-NOTIF-01..06 |
| API-20 | Attachments | `/api/v1/attachments/` | FR-HEALTH-08 |
| API-21 | Sync | `/api/v1/sync/` | FR-OFF-03..05, 11 |
| API-22 | Assistant | `/api/v1/assistant/` | FR-AI-01..17 |
| API-23 | Audit and flags (restricted) | `/api/v1/audit/`, `/api/v1/suspicious-flags/` | BR-33/34, POL-AUDIT-06 |
| API-24 | Knowledge base administration | `/api/v1/kb-sources/` | FR-AI-03/16 |

---

## 4. Error contract

### 4.1 Envelope

Every non-success response body has exactly this shape:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Two fields need attention.",
    "details": {
      "tag": ["An animal with this tag already exists on this farm."],
      "event_date": ["Date cannot be in the future."]
    },
    "request_id": "3f1c2a6e-9d0b-4c1a-8f2f-6b0c9a1d2e34",
    "http_status": 422
  }
}
```

| Field | Rule |
|---|---|
| `code` | Stable upper-case snake identifier from the catalogue in §4.2. Clients branch on this, never on `message` text |
| `message` | Short, human-readable, safe to display, non-technical, no stack traces, no internal names |
| `details` | Object mapping field name to list of messages for validation problems; empty object when not applicable; may carry structured items such as `sync.results` for batch endpoints |
| `request_id` | Echoes `X-Request-Id`; required on every error |
| `http_status` | Must equal the transport status code |

### 4.2 Error code catalogue

| Code | HTTP | Meaning and typical cause |
|---|---|---|
| `UNAUTHENTICATED` | 401 | Missing, malformed or expired access token |
| `TOKEN_EXPIRED` | 401 | Access or refresh token past `exp` |
| `TOKEN_BLACKLISTED` | 401 | Refresh token revoked by logout |
| `SESSION_IDLE_EXPIRED` | 401 | 30-day inactivity rule reached (FR-AUTH-09) |
| `INVALID_CREDENTIALS` | 401 | Wrong email or password; deliberately non-specific |
| `ROLE_NOT_PERMITTED` | 403 | Authenticated but the role may not perform the action |
| `VET_NOT_VERIFIED` | 403 | Veterinarian lacks credential verification (BR-22) |
| `CONSENT_REQUIRED` | 403 | Precise-location write without an active consent record (BR-06) |
| `ADMIN_CLINICAL_ACCESS_DENIED` | 403 | Administrator attempted clinical read without break-glass (BR-05) |
| `SELF_APPROVAL_FORBIDDEN` | 403 | Draft author attempted publication (FR-ANN-03) |
| `ROLE_PROVISIONING_REQUIRED` | 403 | Self-signup attempted for AUTHORITY or ADMIN (BR-21) |
| `ACCOUNT_DISABLED` | 403 | Deactivated account (FR-AUTH-11) |
| `NOT_FOUND` | 404 | Object invisible to this caller (IDOR-safe) |
| `METHOD_NOT_ALLOWED` | 405 | e.g. DELETE on reports or audit events |
| `STATE_CONFLICT` | 409 | Generic business-state conflict |
| `INVALID_STATUS_TRANSITION` | 409 | Transition not in the §8 state tables of the SRS |
| `REPORT_LOCKED` | 409 | Editing a report outside `SUBMITTED` |
| `VISIT_REQUIRED` | 409 | Completing an assistance request without a visit |
| `FARM_ARCHIVED` | 409 | Write against an archived farm |
| `FARM_NAME_DUPLICATE` | 409 | Owner already has that farm name |
| `TAG_DUPLICATE_IN_FARM` | 409 | Animal tag already used on the farm |
| `ANIMAL_FARM_MISMATCH` | 409 | Requested animals do not belong to the stated farm |
| `HISTORY_DEPENDENTS_EXIST` | 409 | Hard delete blocked by `PROTECT` dependants |
| `PROFILE_EXISTS` | 409 | Second profile for one user |
| `VERSION_CONFLICT` | 409 | Stale `If-Match` version |
| `RESOURCE_GONE` | 410 | Soft-deleted resource addressed directly |
| `PAYLOAD_TOO_LARGE` | 413 | Upload or sync batch beyond limits |
| `UNSUPPORTED_MEDIA_TYPE` | 415 | Disallowed upload type |
| `VALIDATION_FAILED` | 422 | Serializer validation failure |
| `UNSUPPORTED_VALUE` | 422 | Enum/vocabulary value not accepted |
| `INVALID_IDEMPOTENCY_KEY` | 422 | Missing or malformed key on sync |
| `ACCOUNT_LOCKED` | 423 | django-axes cool-off active (FR-AUTH-07) |
| `THROTTLED` | 429 | Rate limit exceeded |
| `ASSISTANT_DISABLED` | 503 | Assistant switched off by configuration (FR-AI-16) |
| `INTERNAL_ERROR` | 500 | Unexpected; generic message, `request_id` for diagnosis only |

### 4.3 Batch and sync error shape

Batch endpoints return 200 with per-item results; the transport status is 4xx/5xx only when the whole
request is unacceptable (auth failure, oversize, malformed envelope).

```json
{
  "batch_id": "b8c7...-1",
  "results": [
    {"key": "uuid-1", "status": "applied", "object_type": "health_record", "object_id": "9155", "version": 2, "server_received_at": "2026-11-04T09:12:33.482115Z"},
    {"key": "uuid-2", "status": "duplicate", "object_type": "health_record", "object_id": "9155", "version": 2},
    {"key": "uuid-3", "status": "conflict_applied_lww", "object_type": "health_record", "object_id": "9156", "version": 5, "audit_event_id": "77120"},
    {"key": "uuid-4", "status": "rejected_validation", "errors": {"event_date": ["Date cannot be in the future."]}},
    {"key": "uuid-5", "status": "forbidden", "code": "NOT_FOUND"}
  ],
  "applied": 2, "duplicates": 1, "conflicts": 1, "rejected": 1, "forbidden": 1
}
```

---

## 5. Resource specifications

Permission shorthand: `F` farmer, `V` veterinarian, `VR` authority reviewer, `VO` authority officer,
`A` administrator, `S` system job, `Any` = any authenticated user. Enforcement column names the
backend component that realises the rule, cross-referenced in DOC-REQ-003.

### 5.1 API-01 Health and configuration

| Method | Path | Auth | Permission | Purpose | Success | Errors |
|---|---|---|---|---|---|---|
| GET | `/api/v1/health/` | None | AllowAny (declared exception, BR-13) | Liveness and DB connectivity check; returns `status`, `database`, `version`, `time` | 200 | 500 `INTERNAL_ERROR` |
| GET | `/api/v1/config/` | Bearer | Any | Feature flags for the client: `assistant_enabled`, `assistant_provider`, `map_provider`, `page_size`, `sync_batch_max`, `announcement_public_read` | 200 | 401 |

The health endpoint must not disclose versions of internal libraries beyond the application release
tag, and must never be used as a readiness probe that leaks database credentials.

### 5.2 API-02 Authentication

| Method | Path | Auth | Permission | Request summary | Response summary | Errors | Requirements |
|---|---|---|---|---|---|---|---|
| POST | `/api/v1/auth/register/` | None | AllowAny | `email`, `display_name`, `password`, `password_confirm`, `role` in `FARMER`/`VETERINARIAN`, `phone?` | `user_id`, `role`, `profile_type` | 422 `VALIDATION_FAILED`, 403 `ROLE_PROVISIONING_REQUIRED`, 409 `EMAIL_ALREADY_REGISTERED` | FR-AUTH-01, BR-21 |
| POST | `/api/v1/auth/token/` | None | AllowAny + throttle 10/min/IP | `email`, `password` | `access`, `refresh`, `expires_in`, `role`, `display_name` | 401 `INVALID_CREDENTIALS`, 403 `ACCOUNT_DISABLED`, 423 `ACCOUNT_LOCKED`, 429 | FR-AUTH-02/07 |
| POST | `/api/v1/auth/token/refresh/` | None | AllowAny + throttle | `refresh` | new `access` | 401 `TOKEN_EXPIRED`, 401 `TOKEN_BLACKLISTED`, 401 `SESSION_IDLE_EXPIRED` | FR-AUTH-04/09 |
| POST | `/api/v1/auth/logout/` | Bearer | Own session | `refresh` (and optionally `all: true`) | no body | 401 | FR-AUTH-03 |
| POST | `/api/v1/auth/password/reset/request/` | None | AllowAny + throttle | `email` | generic `detail` message only | always 200 for registered and unregistered emails | FR-AUTH-06 |
| POST | `/api/v1/auth/password/reset/confirm/` | None | AllowAny | `email`, `token`, `new_password1`, `new_password2` | generic success | 400 `TOKEN_EXPIRED`/`TOKEN_ALREADY_USED`, 422 | FR-AUTH-06 |
| POST | `/api/v1/auth/password/change/` | Bearer | Own user | `current_password`, `new_password1`, `new_password2` | success plus refreshed token pair | 400 `INVALID_CREDENTIALS`, 422, 400 `PASSWORD_UNCHANGED` | FR-AUTH-05a, FR-AUTH-12 |

Notes: registration performs no auto-login; password strength is validated by Django validators and
the same rules are mirrored client-side for UX only (BR-16).

### 5.3 API-03 Accounts and profiles

| Method | Path | Permission | Request/response summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/auth/me/` | Any | Current user, role, profile summary, verification status, consent summary, feature flags, outstanding permissions | 401 | FR-AUTH-08 |
| PATCH | `/api/v1/accounts/me/profile/` | Own user, role-scoped fields | Updatable: display name, phone, preferred area, farming system, practice details (V), availability flags. Not updatable: `role`, `is_verified`, `authority_role`, `jurisdiction_area`, `is_active` | 422 `VALIDATION_FAILED`, 400 `field_not_editable` | FR-AUTH-12 |
| GET | `/api/v1/accounts/users/` | A only | Paginated account directory: id, name, role, active, verified, last login; filters `role`, `is_active`, `search` | 403 | FR-AUTH-11 |
| POST | `/api/v1/accounts/users/` | A only | Create authority or administrator account; email + name + role (+ subrole + jurisdiction) | 409 `EMAIL_ALREADY_REGISTERED` | FR-AUTH-13, BR-21 |
| PATCH | `/api/v1/accounts/users/{id}/role/` | A only | Change role or authority subrole; requires `reason` | 422, 403 `SELF_DEACTIVATION_FORBIDDEN` analogue for self-role change | FR-AUTH-13, BR-17 |
| POST | `/api/v1/accounts/users/{id}/activate/` and `/deactivate/` | A only | Requires `reason`; deactivation blacklists refresh tokens | 422, 403 | FR-AUTH-11 |
| POST | `/api/v1/accounts/vets/{id}/verify/` and `/unverify/` | A only | Records licence fields; `unverify` requires `reason` | 422, 403 | FR-AUTH-14, BR-22 |
| GET | `/api/v1/accounts/me/data/` | Own user | Full personal data export (JSON): profile, farms, animals, records, consents, notifications, assistant history | 401 | NF-PRIV-06, BR-37 |
| DELETE | `/api/v1/accounts/me/` | Own user | Requests erasure/anonymisation; `confirm: true` required; body explains retained evidence | 401, 409 `STATE_CONFLICT` when a pending deletion already exists | FR-AUTH-16, BR-37 |
| GET | `/api/v1/accounts/me/login-attempts/` | Own user | Recent failed attempts and lock state for self-transparency | 401 | FR-AUTH-07, POL-SUS-06 |

### 5.4 API-04 Areas / API-05 Consents

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/areas/` | None (declared exception) or Any | Area vocabulary: `code`, `name`, `level`, `parent`; filters `level`, `parent`, `search`; cached by the app for offline area picking | 500 | FR-FARM-05, FR-VET-02 |
| GET | `/api/v1/areas/suggest/?text=` | Any | Normalised suggestion of the closest area names for free-text input | 422 | FR-FARM-05 |
| GET | `/api/v1/consents/` | Own user | Consent history: purpose, granularity, granted, revoked, text version | 401 | FR-AUTH-03 |
| POST | `/api/v1/consents/` | Own user | Grant consent: `purpose`, `granularity`, `consent_text_version` | 422 | FR-AUTH-03, BR-06 |
| POST | `/api/v1/consents/{id}/revoke/` | Own user | Sets `revoked_at`; immediate effect on new precise-location operations | 409 `STATE_CONFLICT` if already revoked | FR-AUTH-03, FR-VET-08 |

### 5.5 API-06 Farms

| Method | Path | Permission | Request summary | Response summary | Errors | Requirements |
|---|---|---|---|---|---|---|
| GET | `/api/v1/farms/` | F own rows (V sees farms it is entitled to per BR-02) | Filters `status`, `area`, `search`; ordering `name`, `created_at`; default `-created_at` | Paginated farm list, no coordinates | 401 | FR-FARM-02 |
| POST | `/api/v1/farms/` | F | `name`, `area` (required), `description?`, `species_focus?`, `farm_label?`, `contact_name?`, `contact_phone?`, `location_lat/lng?` with consent | Farm, `id`, `owner`, `status=ACTIVE`, `version=1` | 422, 409 `FARM_NAME_DUPLICATE`, 403 `CONSENT_REQUIRED` | FR-FARM-01/03/06/07 |
| GET | `/api/v1/farms/{id}/` | Owner; V under BR-02; VO within workflow scope | — | Farm detail incl. `summary` counts, and coordinates only for the owner or an entitled vet with active consent | 404, 403 | FR-FARM-02/04, FR-VET-08 |
| PATCH | `/api/v1/farms/{id}/` | Owner | Any editable field; `version` bump | Updated farm | 404, 409 `VERSION_CONFLICT`, 403 `CONSENT_REQUIRED` | FR-FARM-02 |
| POST | `/api/v1/farms/{id}/archive/` and `/restore/` | Owner | `reason?` | Farm with `status` | 404, 409 `STATE_CONFLICT` | FR-FARM-02 |
| GET | `/api/v1/farms/{id}/summary/` | Owner | — | Animal counts by species, records due, outstanding requests | 404 | FR-FARM-04 |
| POST | `/api/v1/farms/{id}/grants/` | Owner (Could) | `veterinarian_id`, `scope` | Grant record | 404, 422 | FR-FARM-08 |
| DELETE | `/api/v1/farms/{id}/location/` | Owner | Deletes precise coordinates only | 204 | 404 | FR-FARM-03 |

### 5.6 API-07 Animals

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/animals/` | Owner; entitled V | Filters `farm`, `species`, `sex`, `status`, `health_flag`, `search` (tag/breed); ordering `tag`, `created_at`, `date_of_birth` | 401 | FR-ANIM-03/09 |
| POST | `/api/v1/animals/` | Owner of the farm | `farm`, `tag`, `species`, `breed?`, `sex`, `date_of_birth` or `age_estimate_months`, `photo?` | 422, 409 `TAG_DUPLICATE_IN_FARM`, 409 `FARM_ARCHIVED` | FR-ANIM-01/02 |
| GET | `/api/v1/animals/{id}/` | Owner; entitled V | Aggregated profile: latest 10 health records, vaccination summary, treatments, visits, open requests | 404 | FR-ANIM-04 |
| PATCH | `/api/v1/animals/{id}/` | Owner | `species` and `farm` immutable | 404, 422 `UNSUPPORTED_VALUE` | FR-ANIM-05 |
| POST | `/api/v1/animals/{id}/status/` | Owner | `status`, `reason` (required for `DEAD`), `date` | 404, 422 | FR-ANIM-06 |
| POST | `/api/v1/animals/bulk/` | Owner | List of up to 50 animals plus `atomic` flag; per-row results | 413, 422 with row indexes | FR-ANIM-08 |
| DELETE | `/api/v1/animals/{id}/` | Owner | Soft archive; blocked when dependants exist | 409 `HISTORY_DEPENDENTS_EXIST` | FR-ANIM-06 |
| GET | `/api/v1/animals/{id}/history/` | Owner; entitled V | Merged timeline of all record kinds, paginated | 404 | FR-ANIM-04 |
| GET | `/api/v1/animals/{id}/export/` | Owner (Could) | CSV of the animal's records, redacted | 404, 429 | FR-HEALTH-13 |

### 5.7 API-08 to API-12 Health, vaccination, treatment, visits

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/health-records/` | Owner; entitled V | Filters `animal`, `kind`, `severity`, `author_role`, `date_from`, `date_to` | — | FR-HEALTH-01 |
| POST | `/api/v1/health-records/` | Owner; entitled V | `animal`, `kind`, `event_date`, `findings`, `severity?`, `weight_kg?`, `attachment_ids?`; server sets `author`, `author_role` | 422 `DQ-01`, 404 | FR-HEALTH-01 |
| GET/PATCH | `/api/v1/health-records/{id}/` | Owner for own records; V for vet-authored clinical entries; audit-visible to authority on workflow scope | PATCH writes an audit change summary | 404, 409 `VERSION_CONFLICT`, 403 `ROLE_NOT_PERMITTED` | FR-HEALTH-02 |
| DELETE | `/api/v1/health-records/{id}/` | Owner or author | Soft delete with `reason` | 422, 410 on later direct read | FR-HEALTH-09 |
| GET | `/api/v1/health-records/{id}/history/` | Same as read | List of audit change summaries for that record | 404 | FR-HEALTH-02 |
| POST | `/api/v1/health-records/{id}/assessment/` | V (entitled) | Adds a clinical assessment entry, kind `CLINICAL_ASSESSMENT`, `recommended_action`; label never `DIAGNOSIS` | 404, 422 | FR-HEALTH-03, BR-26 |
| GET/POST | `/api/v1/vaccination-schedules/` | Owner; entitled V | `farm` or `animal` (exactly one), `vaccine_name`, `due_date`, `recurrence_days?` | 422, 409 `STATE_CONFLICT` | FR-HEALTH-04 |
| GET/PATCH | `/api/v1/vaccination-schedules/{id}/` | Owner; entitled V | Cancel or reschedule; `status` transitions from `PLANNED` to `COMPLETED`, `OVERDUE` or `SKIPPED` | 409 `INVALID_STATUS_TRANSITION` | FR-HEALTH-04 |
| GET/POST | `/api/v1/vaccination-records/` | Owner; entitled V; vet-administered flag | `animal`, `vaccine_name`, `batch_number?`, `dose_number?`, `administered_at`, `schedule?` | 422, 404 | FR-HEALTH-04 |
| GET/POST | `/api/v1/treatment-records/` | Owner (as `FARMER_REPORTED`); V (as `VETERINARIAN`) | `animal`, `medicine_name`, `dosage_text`, `route`, `start_date`, `end_date?`, `prescriber_role`, `linked_health_record?` | 403 `ROLE_NOT_PERMITTED` (farmer claiming a vet prescription, BR-27), 422 | FR-HEALTH-05 |
| GET/POST | `/api/v1/vet-visits/` | V; owner may read | `farm`, `animal_ids[]`, `visit_date`, `purpose`, `outcome_notes`, `completed_request?` | 422, 404, 409 `ANIMAL_FARM_MISMATCH` | FR-HEALTH-06 |
| GET | `/api/v1/vaccination-coverage/?farm=` | Owner | Due-in-30, overdue, completion rate | 404 | FR-HEALTH-07 |

### 5.8 API-13 Veterinarians and API-15 Geocoding

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/vets/` | Any | Directory; filters `area`, `species`, `search`; `near_lat`/`near_lng` accepted only for callers with active consent, otherwise `distance_available: false`; list never contains coordinates or phone numbers | 422 | FR-VET-04/11 |
| GET | `/api/v1/vets/{id}/` | Any | Practice name, coarse area, species expertise, verified flag, availability note; `contact_phone` only for a farmer with an accepted request involving that vet | 404 | FR-VET-04, BR-06 |
| GET | `/api/v1/vets/{id}/availability/` | Any | Latest status summary of whether the vet accepts new requests | 404 | FR-VET-11 |
| GET | `/api/v1/geo/search/?text=` | Any, throttled | Server-side Nominatim proxy: forward geocoding to coarse areas only; caches results 24 h; rejects URLs and non-text input | 422, 429, 503 `INTERNAL_ERROR` mapping to provider outage | FR-VET-03, THR-06 |
| GET | `/api/v1/geo/tiles-config/` | Any | Tile URL template, attribution string, usage limits for the client map widget | 503 | FR-VET-03 |

### 5.9 API-14 Assistance requests

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/assistance-requests/` | Farmer own; veterinarian assigned; filters `status`, `farm`, `area`, `urgency`, and `role_view` taking `inbox` or `mine` | Paginated, default `-created_at` | 401 | FR-VET-14 |
| POST | `/api/v1/assistance-requests/` | F | `farm`, `animal_ids?`, `category`, `urgency`, `description`, `area`, optional consented precise point, optional `preferred_vet` | 422, 409 `ANIMAL_FARM_MISMATCH`, 429 `THROTTLED`, 403 `CONSENT_REQUIRED` | FR-VET-05/13 |
| GET | `/api/v1/assistance-requests/{id}/` | Farmer owner; assigned vet | Includes `status_history`; vet-only fields `contact_phone` and precise location appear only post-acceptance with active consent | 404, 403 | FR-VET-07/08/14 |
| POST | `/api/v1/assistance-requests/{id}/accept/` | V selected/eligible | `note?`; sets `ACCEPTED`, `accepted_at` | 409 `INVALID_STATUS_TRANSITION`, 403 `VET_NOT_VERIFIED` | FR-VET-06/07/09 |
| POST | `/api/v1/assistance-requests/{id}/decline/` | V | `reason_category` required | 422, 409 | FR-VET-06/09 |
| POST | `/api/v1/assistance-requests/{id}/start/` | Assigned V | `note?` | 409, 403 | FR-VET-06 |
| POST | `/api/v1/assistance-requests/{id}/complete/` | Assigned V | `visit` payload or `visit_id` of an existing visit; atomic creation of visit plus completion | 409 `VISIT_REQUIRED`, 409 `INVALID_STATUS_TRANSITION` | FR-VET-10 |
| POST | `/api/v1/assistance-requests/{id}/cancel/` | F | `reason?` | 409 | FR-VET-06 |
| POST | `/api/v1/assistance-requests/{id}/notes/` | Farmer or assigned vet | Append-only status note (max 1000 characters) | 422, 404 | FR-VET-09/14 |

### 5.10 API-16/17 Disease reports

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/disease-reports/` | V own rows; VR/VO jurisdiction rows | Filters `status`, `area`, `species`, `suspected_disease`, `date_from`, `date_to`, `observation_after`; default `oldest_unreviewed` for authority views | 403 for F and A | FR-REPORT-05/08 |
| POST | `/api/v1/disease-reports/` | V verified only | `species`, `affected_area`, `observation_date`, `affected_count`, `deaths_count?`, `clinical_signs[]`, `signs_notes?`, `suspected_disease?`, `farm?`, `biosecurity_measures?`, `attachment_ids?` | 403 `VET_NOT_VERIFIED`, 403 `ROLE_NOT_PERMITTED`, 422, 409 | FR-REPORT-01/02 |
| GET | `/api/v1/disease-reports/{id}/` | Author; jurisdiction VR/VO | Reporter identity included only for authority; `classification: SUSPECTED_UNVERIFIED` always present | 404 | FR-REPORT-06/08 |
| PATCH | `/api/v1/disease-reports/{id}/` | Author while `SUBMITTED` | Field edits audited as change summaries | 409 `REPORT_LOCKED`, 404 | FR-REPORT-07 |
| POST | `/api/v1/disease-reports/{id}/transition/` | VR/VO per jurisdiction and subrole | `to_status`, `note`, `reason` when required by the target status | 403 `ROLE_NOT_PERMITTED`, 404, 409 `INVALID_STATUS_TRANSITION` | FR-REPORT-03/04 |
| POST | `/api/v1/disease-reports/{id}/clarify/` | VR/VO | `question` required; notifies reporter | 422, 409 | FR-REPORT-10 |
| POST | `/api/v1/disease-reports/{id}/respond/` | Author vet | `answer` required; append-only | 409 `REPORT_LOCKED` (allowed only in `CLARIFICATION_REQUESTED`), 422 | FR-REPORT-10 |
| GET | `/api/v1/disease-reports/patterns/` | VR/VO | Aggregates by area/species/disease/week; `is_confirmed_data: false`; cell suppression under 3 for non-officers | 403 | FR-REPORT-09, BR-23 |
| GET | `/api/v1/disease-reports/{id}/audit/` | Author; jurisdiction VR/VO | Decision and edit history | 404 | BR-31 |
| DELETE | any | — | Not offered | 405 `METHOD_NOT_ALLOWED` | FR-REPORT-12 |

### 5.11 API-18 Announcements

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/announcements/` | Any | Published plus, with explicit labels, expired and withdrawn; filters `area`, `disease`, `risk_level`, `published_after`; default `-published_at`; drafts excluded | 401 | FR-ANN-07/11 |
| POST | `/api/v1/announcements/` | VO | `title`, `disease_name`, `risk_level`, `summary`, `prevention_guidance`, `affected_areas[]`, `scope`, `issuing_authority`, `effective_from`, `review_by_date`, `expires_at`, optional `source_report_ids[]` | 403 `ROLE_NOT_PERMITTED`, 422 `DQ-04` | FR-ANN-01 |
| GET | `/api/v1/announcements/{id}/` | Any if published; VR/VO for any status | `classification: OFFICIAL_PUBLISHED`, `version`, `published_at`, `expires_at`, `source_report_count` for authority only | 404 | FR-ANN-08 |
| PATCH | `/api/v1/announcements/{id}/` | VO (own-draft edits allowed for author; published edits require an officer) | Version bump, full change summary retained | 403 `SELF_APPROVAL_FORBIDDEN` on publish attempts, 409 `INVALID_STATUS_TRANSITION` | FR-ANN-05 |
| POST | `/api/v1/announcements/{id}/submit-for-review/` | VO author | Moves `DRAFT -> IN_REVIEW` | 409 | FR-ANN-02 |
| POST | `/api/v1/announcements/{id}/recommend/` | VR | `recommendation`, `note`; never publishes | 403 for F/V/A, 409 if not `IN_REVIEW` | FR-ANN-04 |
| POST | `/api/v1/announcements/{id}/publish/` | VO, not the author, interactive request only | Sets `published_at`, `published_by`, fans out notifications | 403 `SELF_APPROVAL_FORBIDDEN`, 403 `ROLE_NOT_PERMITTED`, 409 | FR-ANN-03/09/10 |
| POST | `/api/v1/announcements/{id}/withdraw/` | VO | `reason` required; notifies | 422, 409 | FR-ANN-02 |
| POST | `/api/v1/announcements/{id}/sources/` and `DELETE .../sources/{report_id}/` | VO while draft or in review | Link/unlink reports | 409 `STATE_CONFLICT` after publication | FR-REPORT-11, BR-28 |
| GET | `/api/v1/announcements/{id}/versions/` | VR/VO | Version history from audit rows | 404 | FR-ANN-05/12 |

### 5.12 API-19 Notifications

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/notifications/` | Own rows | Filters `is_read`, `type`; default `-created_at` | 401 | FR-NOTIF-01 |
| GET | `/api/v1/notifications/unread-count/` | Own rows | `{"count": n}` | 401 | FR-NOTIF-01 |
| POST | `/api/v1/notifications/{id}/read/` | Own rows | Idempotent | 404 | FR-NOTIF-01 |
| POST | `/api/v1/notifications/read-all/` | Own rows | `{"updated": n}` | 401 | FR-NOTIF-01 |
| GET/PUT | `/api/v1/notifications/preferences/` | Own user | Per-category mute flags; security category immutable | 422 | FR-NOTIF-05 |

### 5.13 API-20 Attachments

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| POST | `/api/v1/attachments/` | Any who may write the parent object | `multipart/form-data`, `file`, `object_type`, `object_id` (optional on create-then-attach flows) | 413, 415, 422, 404 | FR-HEALTH-08, BR-30 |
| GET | `/api/v1/attachments/{id}/` | Entitled reader of the parent | Streams bytes through the permission check; `Cache-Control: private, no-store` | 404, 403 | FR-HEALTH-08 |
| DELETE | `/api/v1/attachments/{id}/` | Parent writer | Soft delete, audited | 404, 409 | FR-HEALTH-08 |

### 5.14 API-21 Sync (duplicate prevention and offline)

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| POST | `/api/v1/sync/batch/` | Any authenticated; user scope | Body: `{"batch_id": uuid, "mutations": [{"key": client uuid, "entity_type", "entity_id", "operation", "client_timestamp", "base_version", "payload"}]}`. Sequential per-item processing with full online validation and permissions; response per §4.3 | 401, 413 `PAYLOAD_TOO_LARGE`, 422 `INVALID_IDEMPOTENCY_KEY`, 429 | FR-OFF-03/04/05 |
| GET | `/api/v1/sync/state/?cursor=` | Any | Pending/processed status per key for the caller, so the client can reconcile after an interrupted batch | 401 | FR-OFF-06 |
| GET | `/api/v1/sync/delta/?entity=&lt;farms or animals or health_records or announcements&gt;&amp;since=` | Any, permission-filtered | Changed and soft-deleted rows since the cursor; response returns a new `cursor` | 401, 422 | FR-OFF-11 |
| GET | `/api/v1/sync/conflicts/?object_id=` | Owner; entitled V; authority on workflow scope | Conflict evidence items (rejected before-images) referencing audit events | 404 | FR-OFF-05, BR-19 |

Duplicate-prevention rules for the sync contract:

1. `key` must be a UUID v4 string; missing or malformed yields 422 `INVALID_IDEMPOTENCY_KEY` and the
   whole item is rejected without side effects.
2. Uniqueness is `(user_id, key)`; a replay returns `status: duplicate` with the original object id
   and version, and the header `X-Idempotent-Replayed: true`.
3. A key may not be reused for a different payload: mismatch yields 409 `STATE_CONFLICT` and is
   audited as a suspicious pattern candidate (POL-SUS-04).
4. `client_timestamp` older than 30 days is rejected with 422 unless the item is flagged
   `late_replay_ok` by the client after user confirmation.
5. Batch limits: 100 mutations, 512 KB request body; oversize yields 413 and the client must split.
6. No mutation is partially applied; each item runs in its own transaction with its audit row.

### 5.15 API-22 Assistant

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| POST | `/api/v1/assistant/ask/` | Any; throttle 20/hour/user | `{"question": "1-500 chars", "session_id": uuid?, "context_turns": 0-3}`. Response: `answer_text`, `answer_source` in `KB`/`LLM_RETRIEVAL`/`FALLBACK_KB`/`FALLBACK_NONE`/`REFUSED`, `disclaimer`, `citations[]` (`source_id`, `title`, `publisher`, `version`), `kb_version`, `escalation`, `safety_flags[]`, `latency_ms` | 422, 429, 503 `ASSISTANT_DISABLED` | FR-AI-01..14 |
| GET | `/api/v1/assistant/history/` | Own rows | Paginated interactions; `answer_source` and citations included | 401 | FR-AI-13 |
| DELETE | `/api/v1/assistant/history/{id}/` | Own row | Anonymises the interaction | 404 | FR-AI-13, BR-37 |
| POST | `/api/v1/assistant/feedback/` | Any | `{"interaction_id", "problem_type", "comment"}` for safety review | 404, 422 | FR-AI-17 |
| GET | `/api/v1/assistant/capabilities/` | Any | Provider id, enabled flag, KB version, rate limit values | 401 | FR-AI-16 |

Contract guarantees: the endpoint is read-only with respect to business data; it never accepts an
`animal_id`, `farm_id`, coordinate or report reference as input (FR-AI-11); a response without
`disclaimer` is impossible to serialise (BR-25); provider failure is reported as a fallback
`answer_source`, never as a 5xx.

### 5.16 API-23 Audit and suspicious flags (restricted)

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/audit/events/` | VO (workflow scope), designated VR (own jurisdiction), A (security purpose only) | Filters `actor`, `action`, `target_type`, `target_id`, `date_from`, `date_to` | 403 `ROLE_NOT_PERMITTED` | POL-AUDIT-06, BR-34 |
| GET | `/api/v1/audit/events/?target_type=health_record&target_id=9155` | As above, plus record owner entitled to their own record history | Record-level history | 404 | BR-18 |
| GET | `/api/v1/suspicious-flags/` | VO, A for security purpose | OPEN and in-review flags with rule, explanation and evidence counts; no accusations | 403 | POL-SUS-05 |
| POST | `/api/v1/suspicious-flags/{id}/outcome/` | VO | `outcome` in `REVIEWED_OK`, `ESCALATED`, `FALSE_POSITIVE`, `ACTION_TAKEN`; `note` required for `FALSE_POSITIVE` | 422, 409 | POL-SUS-05/06 |
| PATCH/PUT/DELETE | any audit path | — | Not offered | 405 `METHOD_NOT_ALLOWED` | BR-33, POL-AUDIT-01 |

### 5.17 API-24 Knowledge base administration

| Method | Path | Permission | Summary | Errors | Requirements |
|---|---|---|---|---|---|
| GET | `/api/v1/kb-sources/` | Any authenticated (metadata only) | Title, publisher, version, tags, review date; excerpt text only for authority/administrator | 401 | FR-AI-03 |
| POST/PATCH | `/api/v1/kb-sources/` | A, or VR with content-review rights | Curate sources; `reviewed_by`, `review_due_at`, `is_active` | 403, 422 | FR-AI-03/16 |
| POST | `/api/v1/kb-sources/{id}/deprecate/` | A | Removes from retrieval while preserving citation history | 409 | FR-AI-03 |

---

## 6. Cross-cutting limits and throttle classes

| Endpoint group | Throttle | Notes |
|---|---|---|
| `auth/token`, `auth/register`, password reset request | 10/min per IP, 5/hour per account | django-axes applies the account lockout independently (FR-AUTH-07) |
| Assistant ask | 20/hour per user | FR-AI-12; disabled outright by `ASSISTANT_ENABLED=false` |
| Assistance request create | 10/day per farmer, 3/day emergency | FR-VET-13 |
| Geo search | 30/min per user, server-side cache 24 h | Protects Nominatim fair use (THR-06) |
| Attachment upload | 60/hour per user, 5 MB per file, 5 per record | FR-HEALTH-08 |
| Sync batch | 20/hour per user; 100 items and 512 KB per batch | FR-OFF-04 |
| Health-record create | 300/hour per user | Detects runaway client loops; feeds POL-SUS-02 |
| All list endpoints | max page size 100 | Standard is 20 (API-C7) |

## 7. Contract coverage and verification requirements

### 7.1 Module to endpoint coverage

| Module (DOC-REQ-002) | Requirements | Resources that must exist |
|---|---|---|
| FR-AUTH-01..16 | Registration, login, refresh, logout, reset, change password, me, profiles, provisioning, verification, consents, deletion | API-02, API-03, API-05 |
| FR-FARM-01..08 | Farm CRUD, archive, summary, area vocabulary, coordinate deletion, grants | API-04, API-06 |
| FR-ANIM-01..09 | Animal CRUD, filters, search, status, bulk, history, export | API-07 |
| FR-HEALTH-01..13 | Health records, assessments, schedules, doses, treatments, visits, coverage, attachments, reminders | API-08..API-12, API-20, API-19 |
| FR-VET-01..14 | Directory, distance search, geo, request workflow, notes, completion by visit | API-13, API-14, API-15 |
| FR-REPORT-01..12 | Report authoring, review transitions, clarification, patterns, audit read | API-16, API-17, API-23 |
| FR-ANN-01..12 | Draft, review, recommendation, publish, versioning, withdraw, targeting, search | API-18, API-19 |
| FR-NOTIF-01..07 | List, unread count, read, preferences | API-19 |
| FR-OFF-01..11 | Batch sync, state, delta, conflict evidence | API-21 |
| FR-AI-01..17 | Ask, history, feedback, capabilities, KB administration | API-22, API-24 |

Coverage rule: every Must requirement in DOC-REQ-002 §6 maps to at least one endpoint or to an
explicitly documented absence (for example FR-OFF-09 is a client-side capability statement with no
endpoint). The mapping is recorded in RTM-001 at contract freeze.

### 7.2 API-level acceptance tests required before contract freeze

| Test ID | Assertion |
|---|---|
| `TC-API-01` | Router walk: every registered viewset declares authentication and permission classes; `AllowAny` appears only on the three documented endpoints (BR-13) |
| `TC-API-02` | Every endpoint that is not documented in this file returns 404, and every documented endpoint exists in the generated OpenAPI schema |
| `TC-API-03` | Error envelope conformance: a forced validation error, a forced permission error, a forced throttle and a forced 500 all produce the §4.1 shape with a populated `request_id` |
| `TC-API-04` | Pagination conformance: all list endpoints return `count`, `next`, `previous`, `page`, `page_size`, `results` with default page size 20 |
| `TC-API-05` | Sensitivity conformance: `location_lat`, `location_lng`, `licence_number`, `contact_phone` and reporter identity are absent from every list and fan-out payload for every role |
| `TC-API-06` | Idempotency conformance: replaying a sync key returns the original result, sets `X-Idempotent-Replayed`, and creates no second mutation (BR-20) |
| `TC-API-07` | State-machine conformance: the transition tables of DOC-REQ-002 §8 are exercised pair-by-pair through the API, asserting 200 or 409 exactly as specified (BR-07) |
| `TC-API-08` | Throttle conformance for the table in §6 |
| `TC-API-09` | Assistant read-only conformance: no row of any business model changes during an assistant call, and every response carries `disclaimer` and `answer_source` (BR-25, FR-AI-10) |
| `TC-API-10` | Announcement/announcement separation: no response of the report endpoints contains announcement fields and vice versa (BR-23) |

### 7.3 Mobile consumption notes (for Member B)

1. Treat `id` values as opaque; never encode meaning into them.
2. Branch on `error.code`, never on `error.message`.
3. Persist `X-Request-Id` with a failed request so a support report can be matched to the server log.
4. The offline queue must generate the idempotency key at mutation time, not at sync time, and must
   reuse it on every retry (FR-OFF-03).
5. Do not cache list payloads containing other users' data; cache only the allow-listed offline tables
   (BR-14).
6. On 401 `TOKEN_EXPIRED`, refresh once and replay the original request once; on a second 401 send the
   user to login (FR-AUTH-09).
7. Read `GET /api/v1/config/` at login to obtain feature flags and limits rather than hardcoding them.

---

## 8. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial API requirements: conventions `API-C1..C20`, error envelope and 37-code catalogue, 24 resource specifications, sync and duplicate-prevention contract, throttle table, contract-freeze test set |

Contract change log (to be extended after freeze):

| Date | Change | Approved by |
|---|---|---|
| 2026-11-04 | Baseline draft issued for Phase 0 review | Pending both members' sign-off at the end of week 4 |

