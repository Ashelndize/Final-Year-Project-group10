# Software Requirements Specification (SRS)

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-002 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard); requirement review with Member B (mobile) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Parent document | DOC-REQ-001 `project-charter.md` |
| Companion documents | DOC-REQ-003 business rules; DOC-REQ-004 data/ERD plan; DOC-REQ-005 API requirements; DOC-REQ-006 security/threat model + privacy/GPS policy; DOC-REQ-007 AI safety policy + audit/suspicious-activity policy |

---

## 1. Purpose and audience

This SRS specifies the functional and non-functional behaviour of the Smart Livestock Health and Farm
Management System with unique identifiers, MoSCoW priorities, dependencies and testable acceptance
criteria. It is the contract between the two developers, the supervisor, the backend implementation
(Django/DRF, MySQL, Django-template dashboard) and the mobile implementation (Flutter).

| Audience | Use |
|---|---|
| Member A | Implements FRs in `backend/` and the dashboard; owns the API contract |
| Member B | Implements FRs in `mobile/`; consumes the OpenAPI schema derived from DOC-REQ-005 |
| Supervisor | Approves scope, priorities and acceptance criteria at the Phase 0 gate |
| Tester / examiner | Derives test cases; each AC is a testable assertion |
| Final report | The requirements-analysis chapter is assembled from this document |

This document does not specify code. It specifies observable behaviour.

---

## 2. Conventions

### 2.1 Identifier scheme

| Prefix | Meaning | Home document |
|---|---|---|
| `FR-<MODULE>-<NN>` | Functional requirement | This document |
| `NF-<NN>` | Non-functional requirement | This document |
| `BR-<NN>` | Business rule | DOC-REQ-003 |
| `EP-<NN>` | Enforcement point (model / permission class / serializer / validator / viewset) | DOC-REQ-003, DOC-REQ-005 |
| `M-<NN>` | Data model / entity | DOC-REQ-004 |
| `API-<NN>` | API resource | DOC-REQ-005 |
| `THR-<NN>` | Threat | DOC-REQ-006 |
| `POL-*` | Policy clause (privacy/GPS, audit, AI safety) | DOC-REQ-006, DOC-REQ-007 |
| `AC` | Acceptance criterion, numbered inside a requirement | This document |
| `D-*` | Definition | §4 |

### 2.2 Priority (MoSCoW)

| Priority | Meaning | Release |
|---|---|---|
| Must | Without it the project objective is not met; the system cannot be demonstrated or accepted | MVP |
| Should | Important, painful to omit, but a documented manual workaround exists | MVP if capacity allows, otherwise Release 2 |
| Could | Valuable, clearly optional | Stretch |
| Won't (this release) | Explicitly deferred; recorded to prevent scope creep | Post-project |

### 2.3 Rule of precision

1. Every FR has at least one testable acceptance criterion. If a criterion cannot be executed or
   observed, it is reworded until it can.
2. Verbs are normative: **must** = required behaviour, **should** = expected unless justified,
   **may** = permitted.
3. Every Must requirement is reachable through the canonical 12-step end-to-end workflow of
   DOC-REQ-001 §8.2 or is a security/privacy control.
4. Where a requirement depends on location, the requirement states the consent state explicitly
   (DOC-REQ-006 Privacy and GPS Policy).

---

## 3. Product perspective

### 3.1 System context

| Element | Description | Mandatory? |
|---|---|---|
| Flutter mobile app | Farmer and Veterinarian client: accounts, farms, animals, health records, vet search, assistance requests, reports, announcements, notifications, offline, AI assistant | Yes |
| Django REST Framework API | Sole write path for business data; enforces authentication, RBAC, object-level permissions, validation, audit, rate limiting, sync and AI endpoints | Yes |
| MySQL 8.0.39 | Durable system of record | Yes |
| Authority dashboard | Django templates inside the same Django project; server-rendered, session-authenticated, CSRF-protected; shares models, permissions and audit with the API | Yes |
| Django admin | Configuration and privileged administration only; not a clinical data browser (BR-05) | Yes |
| OpenStreetMap raster tiles + Nominatim | Map display and reverse/forward geocoding, no API key, fair-use | Yes (with documented fallback) |
| Google Maps Platform | Alternative provider if a key is obtained | No |
| External LLM provider | Optional, behind `AssistantProvider` interface, disabled by default | No |
| Internal livestock-health knowledge base | Curated, cited, versioned reviewed sources; required | Yes |
| Email backend | Password reset delivery | Yes |
| Device secure storage | JWT and local-key storage | Yes |

```
[Farmer phone]--[GPS consent]--> [Flutter app]
        |  HTTPS/JSON /api/v1  (JWT)              \
        v                                          v
 [DRF API] --> [RBAC/permissions] --> [MySQL 8 (InnoDB)]
    |   ^                                    ^
    |   |                                    |
    | [AuditEvent + suspicious rules] [Django-template dashboard (Authority / Admin, session auth)]
    |
    +--> [Assistant provider interface] --> [KB retriever (default)] or [external LLM (optional)]
    +--> [Map/Nominatim proxied or client-side tiles]
```

### 3.2 Architectural principles binding the requirements

| ID | Principle | Consequence |
|---|---|---|
| ARC-1 | Server is the only policy enforcement point | Any client-side check is cosmetic; every FR that grants or restricts access is satisfied by a backend component listed in DOC-REQ-003 |
| ARC-2 | One identity, one role | Role is a property of `User`; profile objects hold role data; a user cannot hold two roles simultaneously |
| ARC-3 | Official information is human-issued | No automated path sets `OutbreakAnnouncement.status = published` (BR-04, BR-24) |
| ARC-4 | Reports are claims, never conclusions | `DiseaseReport` and `OutbreakAnnouncement` are separate resources; reports never mutate into announcements silently (BR-23) |
| ARC-5 | Every sensitive mutation is attributable | Mutation + `AuditEvent` written in the same transaction; failure rolls back both (BR-18) |
| ARC-6 | Data minimisation on device | Local database holds only approved tables/fields, encrypted, and is wiped on logout (BR-14) |
| ARC-7 | Deterministic, explainable behaviour | Conflict rule, thresholds and status machines are stated numerically so tests can assert them |
| ARC-8 | Abstractions at external boundaries | Map provider, assistant provider, notification transport each sit behind an interface so the optional/fallback paths are testable |
| ARC-9 | UTC storage, client-rendered local time | Schedules, SLAs and audit ordering compare correctly |

---

## 4. Definitions, abbreviations and data sensitivity

| ID | Term | Definition |
|---|---|---|
| D-01 | Actor | Authenticated `User` who performs an action; always recorded on an `AuditEvent` |
| D-02 | Access token | Short-lived JWT used as `Authorization: Bearer <token>` |
| D-03 | Refresh token | Long-lived JWT used only to obtain new access tokens; blacklistable |
| D-04 | Health record | Generic timestamped event on an animal: observation, symptom, note, weight, sample, or outcome |
| D-05 | Vaccination record | Proof that a vaccine dose was administered to an animal or group |
| D-06 | Vaccination schedule | Planned future vaccination obligation with due date |
| D-07 | Assistance request | Farmer-initiated request for veterinary attention against a farm/animal set |
| D-08 | Disease report | Veterinarian-authored structured claim of suspected disease, unverified by definition |
| D-09 | Outbreak announcement | Official, authority-published notice about a confirmed or officially declared situation |
| D-10 | Audit event | Append-only record of a security- or business-significant action with change summary |
| D-11 | Flagged activity | Rule-generated signal placed on the dashboard review list; never a finding of misconduct |
| D-12 | Idempotency key | Client-generated UUID identifying one mutation so replays cannot duplicate it |
| D-13 | Soft history | Mutating the current record while preserving old values as an audit change summary |
| D-14 | Jurisdiction | Geographic area an AuthorityProfile is responsible for; bounds report and announcement visibility |
| D-15 | Coarse location | Area name or administrative region, never a precise point |
| D-16 | Precise location | Latitude/longitude with more than ~1 km accuracy and a coordinate accuracy value |
| D-17 | Verified veterinarian | Veterinarian whose credentials an administrator has checked and recorded |
| D-18 | Knowledge base (KB) | Curated, cited, versioned internal livestock-health sources |
| D-19 | Pending queue | Client-side ordered list of unsynchronised mutations |
| D-20 | Sync item | Server-side bookkeeping row describing one processed client mutation |

### 4.1 Data classification (used by NF-SEC, NF-PRIV and DOC-REQ-006)

| Class | Examples | Handling |
|---|---|---|
| PUBLIC | Published outbreak announcements, public vet practice area, KB source metadata | Available to all authenticated users (and dashboard public view) |
| INTERNAL-ROLE | Aggregated report counts, pattern summaries | Authority role only; never presented as confirmation |
| PRIVATE-USER | Name, email, phone, role, verification status | Owner + administrators (limited) + authorities where a workflow requires it |
| SENSITIVE-FARM | Farm identity, animal inventory, health records, treatments, vaccinations | Owner farmer, explicitly authorised veterinarians, authority under workflow rules |
| SENSITIVE-LOCATION | Precise farm coordinates, farmer live position | Only with recorded consent; only to the specific counterparty of an accepted assistance request |
| RESTRICTED | Disease reports with reporter identity, audit contents, suspicious flags | Assigned authority reviewers/officers; administrators for audit purposes under BR-05 limits |
| SECRET | Database credentials, `SECRET_KEY`, LLM API key, JWT signing key | Environment only; never in code, logs or audit |

---

## 5. External actor definitions

| Actor | Interface | Volume assumption (MVP) | Notes |
|---|---|---|---|
| Farmer | Flutter app | 1-5 farms, 1-200 animals per farm, 1-20 health records/animal | Primary user; intermittently connected |
| Veterinarian | Flutter app | 5-50 active assistance requests, 1-10 reports/month | Must be verified by an administrator before authoring reports |
| Authority reviewer | Dashboard | 10-100 report reviews/week | Sees reports in jurisdiction; cannot publish |
| Authority officer | Dashboard | 2-10 announcements/month | Publishes, updates, withdraws, expires |
| System administrator | Dashboard + Django admin | Account operations only | No default clinical read access |
| Assistant provider | Internal service boundary | 5-30 questions/user/day | Read-only; never writes business data |
| Map/geocoding provider | Tile/Nominatim HTTP | A few hundred requests/day | Fair-use; manual fallback mandatory |

## 6. Functional requirements

Module index:

| Module | Prefix | Section | Requirement range |
|---|---|---|---|
| Authentication and accounts | `FR-AUTH` | 6.1 | 01-16 (+05a) |
| Farm management | `FR-FARM` | 6.2 | 01-08 |
| Animal management | `FR-ANIM` | 6.3 | 01-09 |
| Health, vaccination, treatment | `FR-HEALTH` | 6.4 | 01-13 |
| GPS and veterinary assistance | `FR-VET` | 6.5 | 01-14 |
| Disease reporting | `FR-REPORT` | 6.6 | 01-12 |
| Outbreak announcements | `FR-ANN` | 6.7 | 01-12 |
| Notifications | `FR-NOTIF` | 6.8 | 01-07 |
| Offline operation and sync | `FR-OFF` | 6.9 | 01-11 |
| AI health information assistant | `FR-AI` | 6.10 | 01-17 |

Legend for tables below: **P** = MoSCoW priority, **Dep** = dependencies (requirement IDs, models
`M-*` from DOC-REQ-004, business rules `BR-*` from DOC-REQ-003), **AC** = acceptance criteria.

### 6.1 Authentication and account management (`FR-AUTH`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-AUTH-01 | The system shall provide user self-registration with email address (unique), display name, password, and role selection restricted to Farmer or Veterinarian. Registration creates exactly one `User`, one profile for the chosen role, and no Authority or Administrator account. | Must | BR-21, M-User, M-FarmerProfile, M-VetProfile | (1) Valid registration returns 201 and a persisted user with `role=FARMER` or `role=VETERINARIAN`. (2) Attempting to register with `role=AUTHORITY` or `role=ADMIN` returns 403 `ROLE_PROVISIONING_REQUIRED`. (3) Duplicate email returns 409 `EMAIL_ALREADY_REGISTERED` and creates no row. (4) Weak/rejected password returns 400 with `details.password` validator messages. (5) Exactly one profile row exists for the new user (asserted count in test). (6) Registration event is written to `AuditEvent` with actor = new user and action = `user.register`. |
| FR-AUTH-02 | The system shall authenticate users and issue a JWT access token plus refresh token pair on successful login. | Must | FR-AUTH-01, simplejwt | (1) Correct credentials return 200 with `access`, `refresh`, `expires_in`, and `role`. (2) Wrong password returns 401 `INVALID_CREDENTIALS` with no token and no indication of which field was wrong. (3) Inactive/deactivated account returns 403 `ACCOUNT_DISABLED`. (4) Access token payload contains `user_id`, `role`, `iat`, `exp` and no PII beyond identifiers. (5) Unauthenticated request to a protected endpoint returns 401; authenticated-but-unauthorised returns 403. |
| FR-AUTH-03 | The system shall blacklist the refresh token on logout using `token_blacklist`, so a logged-out token cannot mint new access tokens. | Must | FR-AUTH-02 | (1) POST `/api/v1/auth/logout/` with a valid refresh token returns 205/204 and creates a `BlacklistedRefreshToken` entry. (2) Reusing that refresh token at `/token/refresh/` returns 401 `TOKEN_BLACKLISTED`. (3) Logout of an already-blacklisted token is idempotent (no 500). (4) Logout is recorded in `AuditEvent` as `auth.logout`. |
| FR-AUTH-04 | The system shall allow refreshing an access token with a non-expired, non-blacklisted refresh token, and shall preserve the embedded role claim. | Must | FR-AUTH-02, FR-AUTH-03 | (1) Valid refresh returns a new access token with fresh `exp`. (2) Role claim after refresh equals the current DB role even if the token was issued before an admin role change (role re-read from DB at refresh time and audited). (3) Expired refresh returns 401 `TOKEN_EXPIRED`. |
| FR-AUTH-05 | The system shall hash passwords with Argon2 (`Argon2PasswordHasher` + `argon2-cffi`) using parameters memory=64 MiB, time=3, parallelism=4, and shall verify/rehash on login when parameters change. | Must | CON-06, NF-SEC-02 | (1) Stored password string begins `argon2`. (2) `django.contrib.auth.password_validation` rules enforced: min length 10, not common, not numeric-only, not entirely similar to email/name. (3) A password hashed with a weaker configured hasher is rehashed transparently on successful login (test asserts hash prefix change). (4) No plaintext password appears in any log, `AuditEvent`, or API response. |
| FR-AUTH-05a | The system shall reject a password reset or change that reuses the current password. | Should | FR-AUTH-06, FR-AUTH-12 | (1) Same old and new password returns 400 `PASSWORD_UNCHANGED`. (2) Change requires correct current password, else 400 and `auth.password_change_failed` audit event. |
| FR-AUTH-06 | The system shall provide email-based password reset: token request, single-use signed token, expiry 30 minutes, and password set. | Must | FR-AUTH-05, DEP-email | (1) Request for a registered email always returns the same generic response, whether or not the account exists (no account enumeration). (2) Reset token is valid for one use and for 30 minutes only; second use returns 400 `TOKEN_ALREADY_USED`; after 30 minutes returns 400 `TOKEN_EXPIRED`. (3) Token is not logged and not emailed in plaintext alongside the user record. (4) Successful reset blacklists all outstanding refresh tokens for that user and records `auth.password_reset` in `AuditEvent`. |
| FR-AUTH-07 | The system shall lock an account for a configured cool-off after 5 failed login attempts within 15 minutes (django-axes), return `423 ACCOUNT_LOCKED`, and write a security event plus a suspicious-activity flag for review. | Must | FR-AUTH-02, DOC-REQ-007 audit policy | (1) Attempt 6 within the window returns 423 with retry-after information and no token. (2) Successful login before the threshold resets the failure counter. (3) Lockout event is visible in the dashboard review list with reason `repeated_failed_logins`. (4) An administrator may manually reset the lockout; the reset is audited with actor and target. (5) Lockout does not disclose whether the account exists beyond the response the user already has. |
| FR-AUTH-08 | The system shall expose the current session identity: role, profile summary, verification status, consent state, and feature flags relevant to the caller. | Must | FR-AUTH-02 | (1) GET `/api/v1/auth/me/` returns 200 with `user_id`, `role`, `display_name`, `permissions_summary`, `profile_type`, `is_verified` where applicable, and `gps_consent` state. (2) The response never contains the password hash, tokens, or another user's data. (3) Returns 401 without a token. (4) A Farmer asking for authority-only fields does not receive them (field filtering by role in the serializer). |
| FR-AUTH-09 | The system shall enforce token lifetimes: access token 30 minutes, refresh token 7 days, with idle session invalidation at 30 days of inactivity. | Must | FR-AUTH-02, FR-AUTH-04 | (1) Access token `exp - iat` = 1800 s ±1 s. (2) Refresh token lifetime 7 days. (3) After 30 days without any authenticated request the user must re-authenticate with credentials; refresh fails with 401 `SESSION_IDLE_EXPIRED`. (4) Mobile client is able to refresh once transparently on a 401 `TOKEN_EXPIRED` and replay the original request exactly once (verified by mobile integration test). |
| FR-AUTH-10 | The system shall store a per-role profile: `FarmerProfile`, `VeterinarianProfile`, `AuthorityProfile`, each exactly one-to-one with `User`. | Must | FR-AUTH-01, M-User | (1) Creating a second profile for the same user raises `OneToOneConstraint` and returns 409. (2) Deleting a user is not permitted; deactivation only (FR-AUTH-11). (3) Each profile carries only fields relevant to that role; the API never exposes profile fields belonging to another role. |
| FR-AUTH-11 | The system shall allow an administrator to activate, deactivate, and restore a user account; deactivation revokes outstanding refresh tokens and blocks login. | Must | FR-AUTH-14, BR-21 | (1) Deactivation returns 200, sets `is_active=false`, blacklists all refresh tokens, and records `admin.user_deactivated` with reason text. (2) Subsequent login returns 403 `ACCOUNT_DISABLED`; existing access token stops working at expiry or immediately where the permission layer re-checks `is_active`. (3) Reactivation is audited. (4) An administrator cannot deactivate their own account through the API (403 `SELF_DEACTIVATION_FORBIDDEN`). |
| FR-AUTH-12 | The system shall allow an authenticated user to change their password with the current password and to update their own non-privileged profile fields. | Must | FR-AUTH-05, FR-AUTH-10 | (1) Change succeeds only with the correct current password and emits `auth.password_changed`; all other refresh tokens are blacklisted. (2) Users cannot change `role`, `is_verified`, `is_active`, or jurisdiction through the self-service endpoint (attempt returns 422 with `field_not_editable`). (3) Profile update for role-specific fields persists and is echoed by `/auth/me/`. |
| FR-AUTH-13 | The system shall require an administrator to provision Authority users and to assign a jurisdiction to each `AuthorityProfile`, with `authority_role` of REVIEWER or OFFICER. | Must | FR-AUTH-14, M-AuthorityProfile, BR-04 | (1) Only an administrator can create/update Authority profiles; a veterinarian or farmer attempt returns 403. (2) An Authority user with no jurisdiction cannot view reports (empty queryset, not an error). (3) `authority_role` change is audited with old and new values. (4) Officer and reviewer permissions differ exactly as the access-control matrix states. |
| FR-AUTH-14 | The system shall allow an administrator to verify veterinarian credentials (licence/registration number, issuing body, expiry date where supplied) and to store the verification decision. | Must | M-VetProfile, BR-03, BR-22 | (1) `is_verified` transitions false to true only through the administrator endpoint and records actor, timestamp and licence value. (2) Unverified veterinarians cannot create disease reports (403 `VET_NOT_VERIFIED`) but can browse their own profile. (3) Failed verification can be reversed; reversal immediately removes report-authoring capability on the next request. (4) Licence number is RESTRICTED: visible to administrators and assigned authority only. |
| FR-AUTH-15 | The system shall persist explicit consent records for location purposes: purpose, granularity (COARSE/PRECISE), grant time, revoke time, and app version. | Must | FR-VET-01, POL-GPS-02, M-ConsentRecord-like within profile/audit | (1) Granting precise location creates a consent record with purpose and granularity. (2) Revoking sets `revoked_at` and immediately stops new precise sharing; already-shared precise data on an accepted request remains until the request closes. (3) Consent records are listed to the owner on request (data subject access, NF-PRIV-06). (4) No consent record is created when the user declines; the manual area path is used instead. |
| FR-AUTH-16 | The system shall support account deletion requests: personal identifiers are erased or irreversibly anonymised while record integrity needed for audit and outbreak evidence is preserved. | Should | NF-PRIV-06, BR-18 | (1) Request places the account in `pending_deletion` with a 30-day grace period. (2) On completion, name, phone and precise coordinates are replaced by redaction markers; `user_id` remains as an audit actor reference. (3) Response includes what is retained and why. (4) Deletion is audited and cannot remove `AuditEvent` rows. |

### 6.2 Farm management (`FR-FARM`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-FARM-01 | A farmer shall create a farm with name, coarse area (region/district text chosen from the area list, mandatory), optional description, and optional species focus. | Must | M-Farm, BR-01, FR-VET-09 | (1) Valid POST returns 201 with server-assigned `id`, `owner` = authenticated user, and `created_at`. (2) Missing coarse area returns 422 `details.area`. (3) Farm name may repeat across farmers but must be unique per owner; duplicate under the same owner returns 409 `FARM_NAME_DUPLICATE`. (4) The created farm appears in the farmer's list immediately and in no other farmer's list. |
| FR-FARM-02 | A farmer shall list, retrieve, update and archive their own farms; no other user may read or modify a farm except under BR-02/BR-09 authorisation or authority workflow rules. | Must | FR-FARM-01, BR-01, NF-SEC-04 | (1) List returns only farms where `owner_id` = caller. (2) Retrieving another farmer's farm by guessing its id returns 404 (not 403, to avoid id enumeration). (3) Update of an unowned farm returns 404. (4) Archiving sets `status=ARCHIVED`, excludes the farm from default lists, and blocks new animal/health creation with 409 `FARM_ARCHIVED`. (5) Archived farms are restorable by the owner and the action is audited. |
| FR-FARM-03 | A farmer shall optionally store a precise farm location (latitude, longitude, accuracy in metres) only with recorded consent for that purpose. | Must | FR-AUTH-15, POL-GPS-04, BR-06 | (1) Without a consent record, a POST including `location_lat/location_lng` returns 403 `CONSENT_REQUIRED`. (2) With consent, the values persist and are never included in any list or public payload. (3) Serializer marks the fields write-only for the owner (`write_only=True`) except on the single-detail endpoint the owner reads. (4) Owner can delete precise coordinates independently of the farm record; deletion is audited. |
| FR-FARM-04 | The system shall expose per-farm summary counts: total live animals, animals by species, records pending vaccination, and outstanding assistance requests. | Must | FR-ANIM-01, FR-HEALTH-04 | (1) Summary numbers equal a direct count query for the same fixture data. (2) Only the farm owner (and authorised vets on detail) receive the summary. (3) Counts update after a create/archive without a full app restart (verified in mobile integration test). |
| FR-FARM-05 | The system shall validate the coarse area against a maintained area list so that jurisdiction matching and announcement targeting are consistent. | Must | M-Area, FR-ANN-07, BR-04 | (1) Unknown area name returns 422 with the accepted options or a suggestion endpoint. (2) Area records support parent/child (region/district) so authority jurisdiction can be expressed at either level. (3) Area list is served from the API and cached by the app. |
| FR-FARM-06 | A farmer shall be able to add a farm-level contact address and phone that may differ from the account phone, used for assistance dispatch. | Should | M-Farm, FR-VET-05 | (1) Fields validate phone format and length. (2) Contact details are revealed to a veterinarian only after that vet accepts an assistance request for the farm. (3) Change is audited. |
| FR-FARM-07 | The system shall support a farm identifier label chosen by the farmer (e.g. local plot or registration number) with free-text validation, and shall never imply official registration. | Should | M-Farm | (1) Value is stored and displayed with a neutral label. (2) The UI text does not claim government registration. (3) Max 60 characters, trimmed, HTML-escaped. |
| FR-FARM-08 | Farmers shall be able to authorise a specific verified veterinarian to access a named farm's animal and health data ahead of any visit. | Could | BR-02, FR-AUTH-14, M-FarmVetGrant | (1) Grant is listed, revocable, and time-stamped. (2) Revocation removes access immediately. (3) Both grant and revoke appear in `AuditEvent` with actor, target and reason. (4) Access-control matrix test proves a granted vet can read and a non-granted vet cannot. |

### 6.3 Animal management (`FR-ANIM`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-ANIM-01 | A farmer shall register an animal with species (bounded vocabulary), breed (free text, validated length), sex, date of birth or an age estimate with an explicit estimate flag, tag/identification number, farm, and optional photo. | Must | M-Animal, FR-FARM-01, BR-01 | (1) Valid POST returns 201 and persists all supplied fields. (2) Species outside the vocabulary returns 422 `UNSUPPORTED_VALUE`. (3) Supplying neither `date_of_birth` nor `age_estimate_months` returns 422. (4) Supplying an impossible DOB (future date) returns 422. (5) Animal is visible to its owner only, and a cross-owner GET by guessed id returns 404. |
| FR-ANIM-02 | The system shall enforce tag uniqueness within a farm and allow the same tag on different farms. | Must | FR-ANIM-01 | (1) Duplicate tag under the same farm returns 409 `TAG_DUPLICATE_IN_FARM`. (2) Same tag on another farmer's farm succeeds. (3) A database unique constraint on `(farm_id, tag)` exists in the migration and is asserted by a test that bypasses the serializer. |
| FR-ANIM-03 | Farmers shall list and filter their animals by farm, species, sex, status (`LIVE`, `SOLD`, `DEAD`, `ARCHIVED`), tag search text, and health flag, with page size 20. | Must | FR-ANIM-01, NF-PERF-03 | (1) Each filter returns the exact expected subset for a seeded fixture. (2) Combining filters intersects them. (3) Response contains `page`, `page_size=20`, `count`, `next`, `previous`. (4) Default ordering is newest-created first; ordering is stable across pages. |
| FR-ANIM-04 | The system shall present an animal profile aggregating identity, current status, health-record timeline, vaccination records and next due date, treatments, visits, and related assistance requests. | Must | FR-HEALTH-01..06, FR-VET-05 | (1) Profile detail response includes each section's most recent 10 entries with links to full paginated collections. (2) Sections respect the caller's access rights (a vet sees only what BR-02 permits). (3) An animal with no records renders empty-state sections without error. |
| FR-ANIM-05 | A farmer shall be able to update animal details; species and farm ownership are immutable after creation, and a farm change requires the destination farm to be owned by the same farmer. | Must | FR-ANIM-01, BR-01 | (1) Attempting to change `species` returns 422 `field_not_editable`. (2) Moving to another farmer's farm returns 404/403 and is blocked. (3) Update of breed/tag/DOB is persisted and the old value appears in the `AuditEvent` change summary. |
| FR-ANIM-06 | A farmer shall record an animal outcome (sold, dead with reason category and date, or archived) as a status change; the system shall never hard-delete an animal that has health, vaccination or treatment history. | Must | FR-ANIM-01, BR-17, NF-PRIV-05 | (1) Status change to `DEAD` requires a reason category and date. (2) Hard delete of an animal with related records returns 409 `HISTORY_DEPENDENTS_EXIST`. (3) Historical records remain readable after a status change. (4) Status change is audited. |
| FR-ANIM-07 | The system shall maintain a computed health flag per animal (`NONE`, `UNDER_OBSERVATION`, `UNDER_TREATMENT`, `VACCINATION_OVERDUE`, `RESOLVED`) derived from open health records, treatments and schedules; the flag is derived, never hand-entered as clinical truth. | Should | FR-HEALTH-01, FR-HEALTH-05, FR-HEALTH-04 | (1) Flag recalculates after each related mutation without client action. (2) Flag changes are recorded in `AuditEvent` with `actor=system`. (3) No API accepts a client-supplied flag value (422 if attempted). (4) Unit tests cover each transition with dated fixtures. |
| FR-ANIM-08 | The system shall allow bulk registration of animals (up to 50 in one request) with per-row results, all-or-nothing choice surfaced to the client. | Should | FR-ANIM-01, FR-ANIM-02 | (1) Response reports `created`, `skipped`, and `errors` with row indexes. (2) Any row failing validation does not silently succeed; the client can retry only the failed rows. (3) Bulk request produces one `AuditEvent` per created animal. (4) Duplicate tags inside one request are detected. |
| FR-ANIM-09 | Farmers shall be able to search their animals by tag or name across farms, with partial matching and a maximum result window. | Must | FR-ANIM-03 | (1) Search returns matching animals the caller owns and nothing else. (2) Query is parameterised; a search string containing SQL metacharacters returns results or empty, never a server error. (3) Search length capped at 100 characters with 422 beyond. |

### 6.4 Animal health, vaccination and treatment (`FR-HEALTH`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-HEALTH-01 | Authorised users shall create a `HealthRecord` for an animal: event type (`OBSERVATION`, `SYMPTOM`, `WEIGHT`, `SAMPLE`, `OUTCOME`, `NOTE`), event date, free-text findings, severity (`MILD`, `MODERATE`, `SEVERE`), and optional photo evidence. | Must | M-HealthRecord, BR-01, BR-02 | (1) Valid POST returns 201 with `author` = caller and `author_role` = the caller's role at write time. (2) Event date in the future returns 422. (3) Findings length 1-2000 characters validated. (4) Unauthorised actor returns 404. (5) Record is readable by owner farmer and by veterinarians permitted under BR-02. |
| FR-HEALTH-02 | Authorised users shall be able to edit a health record; the system shall preserve the previous values as a change summary in `AuditEvent` (soft history) rather than an immutable event stream. | Must | FR-HEALTH-01, BR-18, POL-AUDIT-02 | (1) PUT/PATCH returns 200 and updates `updated_at`, `version` incremented by 1. (2) An `AuditEvent` row exists with action `health_record.update`, a change summary listing each changed field old and new value, actor, target and timestamp. (3) Editing an unchanged payload creates no audit row (no spam). (4) Farmer and veterinarian edit rights follow the access-control matrix; a farmer cannot alter a veterinarian-authored clinical finding, and vice versa (403). |
| FR-HEALTH-03 | A veterinarian shall be able to add a clinical assessment to an existing health record that is visibly distinct from farmer-authored observations, including differential notes and recommended action; the assessment must not be presented to farmers as a confirmed diagnosis. | Must | BR-02, BR-26, FR-AI-02 | (1) Assessment stored with `author_role=VETERINARIAN` and a distinct type label. (2) Farmer UI renders the clinical label and author identity. (3) The word `DIAGNOSIS` is never auto-populated for suspected assessments (test asserts the label enum). (4) Farmer cannot edit the veterinarian's assessment. |
| FR-HEALTH-04 | The system shall let a farmer or assigned veterinarian create a `VaccinationSchedule` per farm/species with vaccine name, due date, and optional recurrence, and shall generate a `VaccinationRecord` when the dose is logged. | Must | M-VaccSchedule, M-VaccRecord, FR-NOTIF-02 | (1) Schedule POST returns 201; due date must be today or future. (2) A schedule with a past due date and no record makes the animal/farm appear in the overdue set. (3) Logging a dose creates a `VaccinationRecord` and marks the schedule `COMPLETED`. (4) Repeat interval generates the next schedule row automatically when recurrence is set. |
| FR-HEALTH-05 | The system shall record `TreatmentRecord` entries containing medicine name, dosage text, route, start and end dates, withdrawing-period note, prescriber, and linked health record; only a veterinarian may create a treatment record whose prescriber is a veterinarian. | Must | M-Treatment, BR-02, BR-27 | (1) Farmer-created treatment record with `prescriber_role=VETERINARIAN` returns 403 `PRESCRIBER_MISMATCH`. (2) End date before start date returns 422. (3) Farmer may record an administered treatment that a veterinarian prescribed, referencing the prescription text, and the record is labelled as farmer-reported. (4) Treatment records appear on the animal profile and are audited on edit. |
| FR-HEALTH-06 | The system shall record a `VeterinaryVisit` with date, farm, animals covered, purpose, and outcome notes; a visit shall grant the visiting veterinarian read/write access to the animals covered, under BR-02. | Must | M-VetVisit, BR-02 | (1) POST returns 201 and the visit appears in the farm timeline. (2) After a visit, the veterinarian can read the covered animals' records; a veterinarian with no visit or accepted request cannot (access-control matrix test). (3) Only the visiting vet or an authority may edit the visit notes; farmer cannot edit. |
| FR-HEALTH-07 | The system shall provide a per-farm vaccination coverage summary: doses due in the next 30 days, overdue doses, and completion rate for a chosen period. | Should | FR-HEALTH-04, FR-REPORT-09 | (1) Numbers match a direct query on seeded data. (2) Period filter changes the result set correctly. (3) Visible to the farm owner and to authority aggregate views only in de-identified form. |
| FR-HEALTH-08 | The system shall attach optional photo evidence to health records, vaccination records, treatments, and disease reports, with server-side validation of MIME type, size (max 5 MB) and count (max 5 per record). | Should | NF-SEC-08, BR-30 | (1) Oversized upload returns 413; disallowed MIME returns 415/422. (2) Stored outside the web-served static root, served through an authorising endpoint that re-checks permissions. (3) EXIF GPS stripped server-side before storage. (4) Deletion of an attachment is audited and never orphaned by a record edit. |
| FR-HEALTH-09 | Users shall be able to soft-delete a health-related record with a reason; the record disappears from lists and profile timelines but remains available to authority reviewers and audit. | Must | BR-17, POL-AUDIT-02 | (1) DELETE returns 204 and sets `is_deleted=true`, `deleted_at`, `deleted_by`, `deletion_reason`. (2) Repeated GET of the detail returns 410 `RESOURCE_DELETED` for the owner and 404 for outsiders. (3) List and aggregate counts exclude deleted records. (4) Undelete is permitted for the owner (farmer-owned records) and audited. |
| FR-HEALTH-10 | The system shall generate vaccination and treatment reminders 3 days before a due date and daily while overdue, at most once per 24 hours per schedule, as in-app notifications. | Must | FR-NOTIF-02, FR-HEALTH-04, NF-REL-03 | (1) With a fixture due in 3 days, one notification exists with type `VACCINATION_DUE`. (2) Running the generator twice on the same day creates no duplicates (idempotent job). (3) Overdue schedule produces type `VACCINATION_OVERDUE`. (4) Completed schedule stops producing notifications. |
| FR-HEALTH-11 | Farmers shall be able to record weight and body-condition measurements with automatic plausibility checks by species. | Could | FR-HEALTH-01 | (1) Value outside the species plausibility range is rejected with 422 and a helpful message. (2) Weight series renders as a chart or table in the animal profile. |
| FR-HEALTH-12 | The system shall provide an editable, farm-level herd health note area (biosecurity measures, housing, feed changes) that is clearly separated from per-animal clinical records. | Could | M-Farm | (1) Note stored per farm with soft history. (2) Not included in animal-level timelines. (3) Never used as a source for outbreak confirmation. |
| FR-HEALTH-13 | The system shall expose a per-animal and per-farm health history export (CSV or PDF) to the farm owner, with redaction of other farmers' data and reporter identities. | Could | BR-01, NF-PRIV-05 | (1) Export contains only the requesting owner's records. (2) Export contains no reporter identity from disease reports. (3) Generation is audited as a read event (bulk read) because it is a data-disclosure operation. |

### 6.5 GPS-based veterinary assistance (`FR-VET`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-VET-01 | The app shall request device location permission only when the user first invokes a location-dependent feature, shall explain the purpose in plain language, shall record consent (FR-AUTH-15), and shall never request permission at first launch. | Must | POL-GPS-01, FR-AUTH-15 | (1) Fresh install + login shows no location prompt until the user taps Find vets or Add precise farm location. (2) The rationale dialog is shown before the OS dialog and its text is version-controlled. (3) Denying permission does not break any other feature. (4) Consent record created on allow; no record created on deny. |
| FR-VET-02 | When permission is denied, unavailable, or the user chooses approximate precision, the system shall provide manual area selection (search + area picker from the maintained area list) that delivers the same veterinary results as the map path. | Must | FR-VET-01, FR-FARM-05, BR-06 | (1) With permission denied, the vet search UI offers area selection and returns results. (2) Results from manual area selection are identical to a server query filtered by that area for the same fixture. (3) No error state is shown when location is unavailable — an explanatory offline banner instead. |
| FR-VET-03 | The system shall display verified veterinarians on a map using OpenStreetMap raster tiles and shall geocode queries through Nominatim, behind a `MapProvider` interface so a Google Maps implementation can be substituted by configuration only. | Must | TD-08, DEP-1 | (1) Map renders tiles without an API key in the default configuration. (2) Swapping `MAP_PROVIDER=google_maps` requires no code change outside the provider adapter (asserted by config-driven test with a stub). (3) Provider failure shows tiles-unavailable message and keeps list results usable. |
| FR-VET-04 | The system shall return veterinarian directory entries as: display name, practice name, coarse practice area, species expertise, languages if supplied, availability summary, and verified badge; precise practice coordinates are excluded from list payloads. | Must | FR-AUTH-14, M-VetProfile, POL-GPS-04 | (1) List response contains no `lat`/`lng` fields. (2) Unverified veterinarians appear only where the field is explicitly `is_verified=false` and are visually distinguished. (3) A profile detail request from an unauthenticated user returns 401. (4) Personal mobile number is not in the list payload. |
| FR-VET-05 | A farmer shall create an assistance request against one farm, optionally referencing specific animals, with issue category, urgency (`ROUTINE`, `URGENT`, `EMERGENCY`), description, and a location reference that is either the farm's coarse area or a consented precise point. | Must | FR-FARM-01, FR-ANIM-01, BR-06 | (1) POST returns 201 with status `PENDING` and a reference code. (2) Animals referenced must belong to the stated farm; otherwise 422 `ANIMAL_FARM_MISMATCH`. (3) Urgency outside the enum returns 422. (4) Description 10-2000 characters validated. (5) Creation is audited. |
| FR-VET-06 | The system shall implement the assistance-request status workflow from `PENDING` to `ACCEPTED`, `DECLINED` or `CANCELLED`, `ACCEPTED -> IN_PROGRESS -> COMPLETED`, with `CANCELLED` reachable from `PENDING` and `ACCEPTED`, and every other transition rejected. | Must | BR-07, M-AssistanceRequest | (1) Each allowed transition succeeds for the correct actor. (2) Each disallowed transition returns 409 `INVALID_STATUS_TRANSITION` and changes nothing. (3) A transition table test iterates all 6x6 pairs and asserts allowed/forbidden exactly as specified. (4) Every transition writes an `AuditEvent` with old and new status. |
| FR-VET-07 | Only the veterinarian named on the request may change veterinarian-side statuses, and only the requesting farmer may cancel; authority and administrators cannot change these statuses. | Must | BR-07, NF-SEC-04 | (1) A second verified vet attempting to accept an assigned request receives 403. (2) Farmer accept/complete attempts receive 403. (3) Authority attempt receives 403. (4) Attempt by a non-verified veterinarian returns 403 `VET_NOT_VERIFIED`. |
| FR-VET-08 | The system shall reveal the farmer's contact details and, where consented, the precise farm location to the accepted veterinarian only, and shall remove that visibility when the request reaches `COMPLETED` or `CANCELLED`. | Must | POL-GPS-03, BR-06, FR-VET-06 | (1) Before acceptance the vet sees coarse area only. (2) After acceptance the detail response includes phone and precise coordinates when consent is active. (3) After completion the same fields are absent. (4) Each disclosure event is audited (who saw precise location, when, under which request). |
| FR-VET-09 | Veterinarians shall accept or decline an assistance request within a configured response window (default 4 hours) and shall be able to attach a status note to each action; a declined request must carry a reason category. | Must | FR-VET-06 | (1) Decline without reason returns 422. (2) Note max 1000 characters, persisted with author and timestamp. (3) A request older than the window is displayed as `OVERDUE_FOR_RESPONSE` in the vet list without changing its stored status. |
| FR-VET-10 | The system shall let a veterinarian log the visit that resolves a request, creating a `VeterinaryVisit` linked to the request, and completing the request only when that visit exists. | Must | FR-HEALTH-06, FR-VET-06 | (1) Complete without a linked visit returns 409 `VISIT_REQUIRED`. (2) Completing creates the visit and sets request `COMPLETED` in one transaction. (3) Both objects appear in the farm timeline. |
| FR-VET-11 | Farmers shall be able to search and sort veterinarians by area, species expertise, and distance from their own consented coarse or precise location. | Must | FR-VET-04, FR-AUTH-15 | (1) Sorting by distance uses precise coordinates only when consent exists; otherwise ordering falls back to area match and the response states `distance_available=false`. (2) Filter by species returns only vets declaring that species. (3) Empty result set returns 200 with an empty list and a suggestion message, not 404. |
| FR-VET-12 | The app shall offer to open the selected practice location in an external maps application via URI intent, without transmitting any farmer identifier or farm coordinate to the external app. | Should | POL-GPS-06 | (1) Generated URI contains only the destination coordinates/label. (2) No query parameter includes the farmer's id, farm name or origin coordinates. (3) Absence of an external maps app is handled gracefully with a message. |
| FR-VET-13 | The system shall limit assistance-request creation to a configured rate per farmer (default 10 per 24 hours, 3 with `EMERGENCY` urgency per 24 hours) and return 429 with retry information beyond it. | Must | NF-SEC-07, BR-29 | (1) 11th request in 24 h returns 429 with `Retry-After`. (2) Counting resets correctly at the rolling window boundary. (3) The limit is configuration, not hard-coded, and the test overrides it. |
| FR-VET-14 | Both parties shall see request status history, and the farmer shall receive a notification on every status change. | Must | FR-NOTIF-02, FR-VET-06 | (1) History lists each status, actor, timestamp and note. (2) Each transition creates exactly one notification for the counterparty. (3) No notification contains the veterinarian's personal phone number. |

### 6.6 Disease reporting (`FR-REPORT`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-REPORT-01 | Only a verified veterinarian shall be able to create a `DiseaseReport`. Farmers, authority users and administrators shall receive 403 on the create endpoint. | Must | FR-AUTH-14, BR-03, BR-05 | (1) Verified vet POST returns 201 with status `SUBMITTED`. (2) Unverified vet returns 403 `VET_NOT_VERIFIED`. (3) Farmer, authority and admin POST each return 403 `ROLE_NOT_PERMITTED`. (4) The permission is enforced in a DRF permission class, not only in the serializer, and a test asserts 403 before any DB row exists. |
| FR-REPORT-02 | A disease report shall contain: suspected disease (free text, optional), species, estimated affected animal count, observation date, affected area (from the area list), observed clinical signs (structured multi-select plus notes), biosecurity measures taken, farm reference (mandatory when the reporting vet has visited it, otherwise optional), onset date, deaths count, and optional evidence attachments. | Must | M-DiseaseReport, FR-FARM-05, FR-HEALTH-08 | (1) Missing area, species or observation date returns 422 with per-field messages. (2) Observation date in the future returns 422. (3) Counts must be non-negative integers; deaths may not exceed affected count (422). (4) Structured sign options come from a maintained vocabulary. (5) A report may be created without a farm reference for area-level suspicion, and the UI labels it accordingly. |
| FR-REPORT-03 | The system shall implement the report review workflow `SUBMITTED -> UNDER_REVIEW -> CLARIFICATION_REQUESTED -> ACCEPTED_FOR_ASSESSMENT or REJECTED`, plus `UNDER_REVIEW -> ACCEPTED_FOR_ASSESSMENT or REJECTED`, and `ACCEPTED_FOR_ASSESSMENT`, `REJECTED` or `CLARIFICATION_REQUESTED -> CLOSED`, with all other transitions forbidden. | Must | BR-07, DOC-REQ-001 | (1) A transition-matrix test asserts allowed and forbidden pairs exhaustively. (2) Forbidden transitions return 409 `INVALID_STATUS_TRANSITION` and do not persist. (3) Every allowed transition records a `ReviewDecision` audit entry with actor, target, old/new status, reason text and timestamp. (4) `CLOSED` is terminal. |
| FR-REPORT-04 | Only an authority user whose jurisdiction contains the report's affected area may transition that report; reviewers may transition to `UNDER_REVIEW`, `CLARIFICATION_REQUESTED` and `CLOSED`, while only officers may set `ACCEPTED_FOR_ASSESSMENT` or `REJECTED`. | Must | BR-04, BR-07, FR-AUTH-13, D-14 | (1) Reviewer attempt at `ACCEPTED_FOR_ASSESSMENT` returns 403. (2) Officer outside the jurisdiction returns 404 for that report (not listed, not retrievable). (3) Officer inside jurisdiction succeeds. (4) Access is re-checked on every transition, including when jurisdiction was changed after submission. |
| FR-REPORT-05 | The dashboard shall present a review queue with filters (status, area, species, suspected disease, date range, urgency of cluster), sorting by oldest-unreviewed first, and page size 20. | Must | FR-REPORT-03, NF-PERF-04 | (1) Each filter returns the expected subset against a seeded fixture. (2) Queue excludes reports outside the reviewer's jurisdiction. (3) Pagination metadata present and total count accurate. |
| FR-REPORT-06 | The system shall present and serialise every report with the explicit qualifier that it is an unverified report and shall never use the words outbreak, confirmed or case-confirmed in report context. | Must | BR-23, POL-AI-06 | (1) Serialised report contains `classification: SUSPECTED_UNVERIFIED` and never `confirmed`. (2) The report list UI shows the unverified label in all states. (3) A wording-guard test scans report templates and serialiser fields for forbidden terms. |
| FR-REPORT-07 | A reporting veterinarian shall be able to view, and edit only while the report status is `SUBMITTED`, their own reports; after that, corrections must be requested through clarification or a new report. | Must | BR-03, BR-18, FR-REPORT-03 | (1) Edit succeeds while `SUBMITTED`; the old values are stored as an audit change summary. (2) Edit at `UNDER_REVIEW` or later returns 409 `REPORT_LOCKED`. (3) Another vet cannot read or edit the report (404). (4) Reporter can withdraw a `SUBMITTED` report, which sets status `CLOSED` with reason and is audited. |
| FR-REPORT-08 | The system shall keep the reporter's identity confidential from farmers and from other veterinarians, and shall reveal it only to jurisdiction authority users and to the administrator audit view. | Must | D-14, POL-AUDIT-06, BR-22 | (1) Vet list/detail responses contain no reporter identity for non-authority callers. (2) Authority reviewer sees reporter name, licence-masked contact and timestamp. (3) Farmer sees nothing about reports at all, other than official announcements. (4) Field-level exclusion is asserted in serialiser tests, not only UI tests. |
| FR-REPORT-09 | The dashboard shall provide informational pattern summaries: report counts grouped by area, species, suspected disease and week, with a clear statement that counts are unverified reports and not confirmed outbreak numbers. | Must | BR-23, NF-PRIV-03 | (1) Aggregation output matches a direct query for the same fixture. (2) Response contains `is_confirmed_data: false` and the advisory sentence. (3) Aggregates are de-identified (no farm, no reporter, no animal identifiers). (4) Minimum-cell suppression hides any group with fewer than 3 reports from non-officer viewers. |
| FR-REPORT-10 | When a reviewer requests clarification, the system shall notify the reporter, require a question text, and record the reporter's answer with a timestamp without reopening edit rights on locked fields. | Must | FR-REPORT-03, FR-NOTIF-02 | (1) Clarification request without question text returns 422. (2) Reporter receives a notification and can submit an answer of 5-2000 characters. (3) Answer is stored append-only and shown in the review timeline. (4) Report fields remain read-only during clarification. |
| FR-REPORT-11 | The system shall allow an officer creating an announcement to link source reports, and shall record that linkage on both sides with an audit entry. | Must | FR-ANN-01, BR-24 | (1) Link created only when the announcement is in `DRAFT` or `IN_REVIEW`. (2) Announcement detail for authority users lists linked report references; farmers never see report ids. (3) Unlinking is audited. (4) Reports linked to a `PUBLISHED` announcement get status transition suggestion text but are not auto-closed. |
| FR-REPORT-12 | The system shall retain reports and their decision history for a configurable period (default 5 years) and shall not allow hard deletion by any role; retention expiry anonymises reporter identity while keeping the clinical narrative. | Should | NF-PRIV-05, POL-AUDIT-07 | (1) Attempting DELETE returns 405 for every role. (2) A retention job replaces reporter name with an anonymised token after the configured period and is audited. (3) Retention value read from configuration and asserted by a test that overrides it. |

### 6.7 Official outbreak announcements (`FR-ANN`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-ANN-01 | An authority officer shall create an `OutbreakAnnouncement` draft with title, disease name, affected area(s), risk level (`WATCH`, `WARNING`, `CRITICAL`), summary, prevention guidance, effective-from date, review-by date and expiry date, plus issuing authority name. | Must | M-Announcement, FR-AUTH-13, BR-04 | (1) POST returns 201 with status `DRAFT` and `created_by` set. (2) Missing title, disease, area, prevention guidance, or expiry date returns 422. (3) Expiry before effective-from returns 422. (4) Farmer, veterinarian and administrator create attempts return 403. (5) Draft is invisible outside the Authority role. |
| FR-ANN-02 | The system shall enforce the announcement lifecycle `DRAFT -> IN_REVIEW -> PUBLISHED -> EXPIRED or WITHDRAWN`, with `IN_REVIEW -> DRAFT` for revision, and shall forbid any other transition. | Must | BR-07, BR-24 | (1) Exhaustive transition-matrix test passes. (2) Forbidden transition returns 409 `INVALID_STATUS_TRANSITION`. (3) Each transition writes `AuditEvent` with actor, old/new status, reason (required for `WITHDRAWN`). |
| FR-ANN-03 | Publication shall require an authority officer who is not the author of the draft (segregation of duties), and publication shall be the only way an announcement becomes visible to farmers. | Must | BR-04, FR-AUTH-13 | (1) Author-attempted publication returns 403 `SELF_APPROVAL_FORBIDDEN`. (2) Reviewer-attempted publication returns 403 `ROLE_NOT_PERMITTED`. (3) Non-author officer publication returns 200, sets `published_at`, `published_by`, and creates notifications. (4) The rule holds even if the author's role is later changed to officer within the same request cycle. |
| FR-ANN-04 | A reviewer shall be able to record a recommendation (`RECOMMEND_PUBLISH`, `RECOMMEND_REVISE`, `RECOMMEND_REJECT`) with free-text justification; recommendations shall inform but never auto-publish. | Must | BR-24, POL-AI-06 analogue | (1) Recommendation stored with actor and timestamp and shown to officers. (2) No code path or test fixture can set status `PUBLISHED` from a recommendation alone. (3) A management command or scheduled job that publishes must not exist; asserted by a grep-style test on the publish service signature being human-request-bound only. |
| FR-ANN-05 | Editing a `PUBLISHED` announcement shall create a new version with full previous content retained in audit history, and shall require an officer; farmers shall always see the latest published version. | Must | BR-18, FR-ANN-03 | (1) Update returns 200, increments `version`, and writes an `AuditEvent` change summary containing old and new values of every changed field. (2) Prior versions remain retrievable by authority users for evidence. (3) Farmer list never shows an unpublished version. (4) Editing a `DRAFT` does not require re-review but is still audited. |
| FR-ANN-06 | The system shall automatically move a `PUBLISHED` announcement to `EXPIRED` when its expiry date passes, using a scheduled management command at least daily, and shall record the actor as `system`. | Must | FR-ANN-01, NF-REL-03 | (1) Command execution with an expired fixture changes status to `EXPIRED` and writes `AuditEvent` with `actor=system`. (2) Non-expired announcements are untouched. (3) Expired announcements remain readable with an explicit expired label. (4) Running the command twice is idempotent. |
| FR-ANN-07 | The system shall allow farmers to see published announcements relevant to them: globally published, or matching the area of any farm they own, or their profile area. | Must | FR-FARM-05, FR-ANN-03 | (1) A farmer in area A sees announcements targeting area A and any marked `scope=GLOBAL`. (2) A farmer does not see drafts, withdrawn, or area-B announcements. (3) Serialised response always includes `is_official: true` and `issuing_authority`. (4) Response excludes reporter identities and report ids. |
| FR-ANN-08 | The system shall distinguish, in both API and UI, unverified reports from official announcements: separate endpoints, separate list types, and a distinct visual treatment for official notices. | Must | BR-23, API-ANN, API-REPORT | (1) `GET /api/v1/announcements/` never returns report objects and vice versa. (2) Announcement payload contains `classification: OFFICIAL_PUBLISHED`; report payload contains `classification: SUSPECTED_UNVERIFIED`. (3) Mobile announcement card displays an official badge, issuing authority, publication date and expiry; report views (authority-only) display the unverified label. (4) A test asserts no template or serialiser mixes the two labels. |
| FR-ANN-09 | Publishing, updating or withdrawing an announcement shall notify farmers whose area matches the affected area, and shall record the notification batch identifier. | Must | FR-NOTIF-02, FR-ANN-07 | (1) Publication to area A creates notifications for all farmers with a farm in area A (and profile area A), exactly once each. (2) Withdrawal notification states withdrawal and reason summary. (3) Notification volume is capped and paginated; no notification includes reporter identity or farm-level detail. |
| FR-ANN-10 | No AI component, rule, aggregate or scheduled job shall create, modify, publish or withdraw an announcement; write access shall be limited to interactive authority-officer requests. | Must | BR-04, BR-24, POL-AI-05 | (1) The assistant service has no write permission on the announcement model (unit test asserts a denied attempt). (2) `AuditEvent` for publication always has an authenticated human actor. (3) Test verifying that a management command cannot publish without a `published_by` user id. |
| FR-ANN-11 | Users shall be able to search and filter announcements by area, disease name, risk level and date range, with page size 20. | Must | FR-ANN-07 | (1) Each filter returns the expected subset on a seeded fixture. (2) Search by disease name is partial and case-insensitive. (3) Results are ordered newest published first. |
| FR-ANN-12 | The dashboard shall show an announcement editorial view listing drafts, pending-review items, published items with days-to-expiry, and withdrawn/expired archive, with per-item audit trail. | Should | FR-ANN-02, FR-ANN-06 | (1) Each bucket contains the correct items for the fixture set. (2) Days-to-expiry computed against server time, not client time. (3) Audit trail per announcement shows every transition with actor and reason. |

### 6.8 Notifications (`FR-NOTIF`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-NOTIF-01 | The system shall maintain an in-app notification per user with type, title, body, target object reference, created timestamp and read flag, and shall expose list, unread count and mark-as-read operations. | Must | M-Notification | (1) List returns only the caller's notifications, newest first, page size 20. (2) Unread count matches the list. (3) Mark-read is idempotent. (4) Marking another user's notification returns 404. |
| FR-NOTIF-02 | The system shall generate notifications for: vaccination due/overdue, assistance request created/accepted/declined/status change/completed, report status change and clarification request, announcement published/updated/withdrawn/expired, and account security events. | Must | FR-HEALTH-10, FR-VET-14, FR-REPORT-10, FR-ANN-09, FR-AUTH-07 | (1) Each trigger produces exactly one notification for the correct recipient(s) in a test. (2) The actor of an action does not receive a self-notification. (3) Trigger table in DOC-REQ-007 matches the implementation set. |
| FR-NOTIF-03 | Notification bodies shall contain no more information than the recipient is entitled to see: no reporter identity, no other farmer's name, no clinical detail beyond the recipient's own records. | Must | POL-PRIV, BR-08 | (1) Serialiser-level test asserts forbidden fields absent for each notification type. (2) A recipient without record access receiving a related notification still sees only generic text plus a link that itself is permission-checked. |
| FR-NOTIF-04 | The app shall poll notifications on launch, on resume, and at least every 5 minutes while foregrounded, and shall show an unread badge. | Must | FR-NOTIF-01, NF-PERF-05 | (1) A notification created server-side appears in the app within one poll interval. (2) Polling stops when the app is backgrounded beyond the configured interval. (3) Badge count equals server unread count. |
| FR-NOTIF-05 | Users shall be able to mute non-security notification categories, and security and account notifications shall not be mutable. | Could | FR-NOTIF-01 | (1) Muted category generates no notification rows for that user. (2) Security category remains delivered even with all muting on. (3) Preference persisted per user and re-applied after reinstall via server data. |
| FR-NOTIF-06 | The system shall delete read notifications older than 180 days in a scheduled job, leaving audit history untouched. | Should | NF-PRIV-05, FR-NOTIF-01 | (1) Job deletes only read, older-than-180-day rows. (2) Count of remaining rows asserted in a test. (3) Deletion is not an audit-covered business action (no audit row) and this is documented. |
| FR-NOTIF-07 | The system may deliver notifications through an external push transport behind an interface; MVP shall function fully without it. | Could (stretch) | EXCL-09, ARC-8 | (1) With push disabled by configuration, all notification FRs still pass. (2) Transport adapter is injected, not hard-coded at call sites. (3) Device-token storage requires consent and is deleted on logout. |

### 6.9 Offline operation and synchronisation (`FR-OFF`)

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-OFF-01 | The app shall cache, in an encrypted local `sqflite` database, only the data required for offline use: the signed-in user's farms, animals, recent health/vaccination/treatment records, published announcements and unread notifications. | Must | TD-09, BR-14, NF-PRIV-02 | (1) Local schema contains no other farmer's rows (asserted in a device/emulator test). (2) Database file is encrypted at rest with a device-key-held key; plaintext file scan of the DB path finds no animal tag values. (3) Cache can be inspected and cleared from the app's privacy screen. |
| FR-OFF-02 | The app shall allow offline creation and editing of: animals, health records, vaccination records, treatment records and disease-report drafts, and shall queue each as a pending mutation. | Must | FR-ANIM-01, FR-HEALTH-01/04/05, FR-REPORT-02 | (1) In airplane mode, creating a health record succeeds locally and the animal timeline shows it with a pending indicator. (2) The mutation appears in the pending queue with type, target id, client timestamp and status `QUEUED`. (3) The same operations are blocked offline where listed in FR-OFF-09. |
| FR-OFF-03 | Every queued mutation shall carry a client-generated UUID idempotency key that is stable across retries, and the server shall persist processed keys per user. | Must | TD-09, NF-REL-04 | (1) Two submissions of the same key result in exactly one server-side mutation; the second returns the original result with `X-Idempotent-Replayed: true`. (2) Key uniqueness enforced by a DB constraint on `(user_id, idempotency_key)`. (3) A malformed key returns 422 `INVALID_IDEMPOTENCY_KEY` and no mutation occurs. (4) Same key used by a different user is independent. |
| FR-OFF-04 | The system shall expose a batch sync endpoint that accepts an ordered list of mutations, processes them sequentially with the same validation and permission rules as the online API, and returns a per-item result. | Must | API-SYNC, NF-PERF-02 | (1) Batch of 50 valid mutations returns 50 item results, all `applied`, in one request. (2) A batch containing one permission-violating item applies the valid ones and returns `forbidden` for that item; no partial application of a single item. (3) Response includes server id, server `version`, and `server_received_at` per item. (4) Request payload size and item count capped (max 100 items, max 512 KB) with 413 beyond. |
| FR-OFF-05 | The system shall resolve write conflicts by last-write-wins-with-audit: the incoming mutation with the later `client_timestamp` (tie-broken by later `server_received_at`) is applied, the rejected copy is stored in `AuditEvent` in full, and the client is told a conflict occurred. | Must | TD-09, BR-18, POL-AUDIT-04 | (1) Two clients editing the same record with different timestamps: the later value wins, the earlier rejected copy is retrievable from the audit change summary. (2) Sync response marks the losing item `conflict_applied_lww`. (3) The winner's `version` increments by exactly 1. (4) Equal timestamps resolve deterministically by `server_received_at` (repeated test yields the same winner). |
| FR-OFF-06 | The app shall display per-item sync state (`QUEUED`, `SYNCING`, `SYNCED`, `FAILED_RETRYABLE`, `FAILED_PERMANENT`, `CONFLICT`) and shall retry failed retries with exponential backoff (base 30 s, factor 2, cap 30 min, max 8 attempts). | Must | FR-OFF-02, NF-REL-04 | (1) Airplane-mode-to-online transition moves items to `SYNCED`. (2) A 5xx response leaves the item `FAILED_RETRYABLE` and schedules backoff; a 4xx validation response leaves it `FAILED_PERMANENT` and surfaces an editable error. (3) After 8 attempts the item is `FAILED_PERMANENT` with a user-visible action. (4) Unit-testable backoff schedule asserted numerically. |
| FR-OFF-07 | The app shall never lose a queued mutation on logout: it shall warn the user, offer sync-then-logout, and on forced logout keep the queue encrypted under the account key until the user logs in again or explicitly discards it. | Must | FR-AUTH-02, BR-14 | (1) Logout with 1 queued item shows the warning dialog with counts. (2) Forced logout leaves the queue readable only after re-authentication as the same user. (3) Discarding the queue is confirmed twice and then deletes rows (asserted count 0). (4) A different user logging in on the same device sees an empty queue. |
| FR-OFF-08 | Logging out shall clear the user's cached business data, tokens and consent-derived location from the device, retaining only non-identifying app settings. | Must | BR-14, NF-PRIV-02 | (1) After logout, local tables for farms/animals/records/notifications are empty. (2) Tokens absent from secure storage. (3) Cached precise location absent. (4) Re-login repopulates from the server with correct counts. |
| FR-OFF-09 | The system shall clearly mark features that require connectivity: AI assistant, veterinarian search/geocoding, assistance request status submission beyond creation, announcement publication, and login refresh. Offline attempts shall return a distinct in-app message rather than a silent failure. | Must | FR-AI-01, FR-VET-03, FR-ANN-03 | (1) With no network, tapping the AI assistant shows the specified unavailable message and no queued mutation is created. (2) Map area picker falls back to cached area list. (3) Message strings centralised so the offline capability list is single-sourced. |
| FR-OFF-10 | The app shall present a persistent offline indicator and label any displayed record whose state is not yet confirmed by the server. | Must | FR-OFF-06 | (1) Indicator visible in airplane mode on every screen. (2) Pending records show the pending chip; synced records do not. (3) Indicator disappears within 2 s of reconnect and successful sync. |
| FR-OFF-11 | The server shall provide a change-delta endpoint so the client can resynchronise only records modified after a supplied cursor/timestamp per entity type. | Should | FR-OFF-01, NF-PERF-02 | (1) Second call with the returned cursor yields an empty or reduced set. (2) Deleted (soft) records are included so the client can remove them locally. (3) Permission filters apply to the delta exactly as to the list endpoints. |

### 6.10 AI health information assistant (`FR-AI`)

Governing policy: DOC-REQ-007 (AI Safety Policy). The assistant answers general livestock-health
questions only. It never diagnoses, never writes business data, and never publishes announcements.

| ID | Requirement | P | Dep | Acceptance criteria |
|---|---|---|---|---|
| FR-AI-01 | Authenticated users shall ask a free-text livestock health or farm management question (1-500 characters) and receive an answer drawn from the curated knowledge base. | Must | POL-AI-01, M-KBSource | (1) POST returns 200 with `answer_text`, `citations`, `disclaimer`, `answer_source`, `kb_version`. (2) Empty or >500-character question returns 422. (3) Unauthenticated request returns 401. (4) Response time p95 < 4 s with the KB-only provider on the test dataset. |
| FR-AI-02 | The assistant shall answer general information questions only and shall refuse to diagnose a named animal, interpret a photo as a diagnosis, or replace examination. | Must | POL-AI-02, FR-HEALTH-03 | (1) A question of the form `diagnose my cow with these signs` returns the refusal template with a veterinary-contact prompt and `answer_source=REFUSED`. (2) Refusal responses contain no disease-name assertion for that animal. (3) Refusal path returns 200 (a valid, safe answer), not 4xx. |
| FR-AI-03 | The system shall maintain a curated, versioned knowledge base of reviewed livestock-health sources, each with title, publisher, URL or citation text, review date, reviewer, applicability tags (species, topic, region) and a version number. | Must | POL-AI-03, TD-10 | (1) KB records are read-only to all roles except administrator. (2) A question returns citation entries whose `source_id` exists in the KB. (3) Changing the KB version changes the `kb_version` echoed in responses. (4) Unreviewed or expired-review sources are excluded from retrieval (test with a fixture source dated past its review). |
| FR-AI-04 | Every assistant answer shall display its supporting citations and shall display the disclaimer text `General information — not a diagnosis.` verbatim. | Must | POL-AI-04 | (1) Disclaimer present in 100% of responses including refusals and fallbacks (serialiser-level test). (2) Citations render as source title plus publisher. (3) If no source supports the answer, the system returns the no-answer fallback rather than an uncited answer. |
| FR-AI-05 | The assistant shall obtain answers through an abstracted provider interface with at least two implementations: `kb_only` (retrieval and extractive answer from the KB) and `llm_retrieval` (optional external model restricted to retrieved context). The active provider shall be selectable by configuration and default to `kb_only`. | Must | TD-10, ARC-8 | (1) With `ASSISTANT_PROVIDER=kb_only` and no API key, all FR-AI Must requirements pass. (2) Adding the LLM adapter requires no change to the endpoint contract. (3) An unknown provider value fails closed at configuration validation, not at request time. |
| FR-AI-06 | The system shall fall back safely when the selected provider is unavailable, times out (8 s), returns an error, or returns content failing safety validation: the answer must be regenerated from the KB only, or the no-answer fallback returned. | Must | POL-AI-07, NF-REL-05 | (1) With a stubbed provider raising a timeout, the response is `answer_source=FALLBACK_KB` or `FALLBACK_NONE` and HTTP 200. (2) No stack trace or provider error text reaches the client. (3) The failure is logged server-side and counted in the assistant health metric. (4) The user sees the connectivity explanation plus a contact-a-veterinarian prompt where relevant. |
| FR-AI-07 | The assistant shall detect sensitive or urgent symptom patterns (e.g. sudden multiple deaths, neurological signs, abortion storms, haemorrhagic signs, rapid spread across species, suspected notifiable disease) and respond with a prompt to contact a veterinarian, prioritising the local vet directory and assistance-request path. | Must | POL-AI-02, FR-VET-04 | (1) Each pattern in the published trigger list produces the escalation response with `escalation=true`. (2) Escalation response contains no speculative disease list. (3) Response includes an in-app action to open the vet-assistance flow. (4) Trigger list is data-driven and unit-tested per entry. |
| FR-AI-08 | The assistant shall refuse out-of-scope topics: human medicine, veterinary legal or regulatory determinations, drug purchase or supply sourcing, dosages not present in the KB, financial valuation, and any request to confirm an outbreak. | Must | POL-AI-02, POL-AI-06 | (1) Each out-of-scope category in the fixture prompt set returns a refusal with a short reason and an appropriate referral. (2) Refusal text never includes requested prohibited content. (3) Out-of-scope detection is rule-based and covered by an adversarial prompt test suite of at least 25 cases. |
| FR-AI-09 | The assistant shall not provide treatment instructions that carry animal, human or food-safety risk: no unauthorized drug dosing, no antimicrobial dosing beyond KB-approved general guidance, no withdrawal-period claims not present in the KB, no dangerous physical procedures. | Must | POL-AI-08, FR-HEALTH-05 | (1) A prompt asking for an antibiotic dose for a named animal returns a refusal pointing to veterinarian-prescribed treatment records. (2) Withdrawal-period questions return KB text only with `answer_source` indicating citation, else refusal. (3) Safety suite asserts the absence of dosage numerics in refusal responses. |
| FR-AI-10 | The assistant shall be read-only: it shall have no capability to create, update, delete or publish any business object, in particular `DiseaseReport` and `OutbreakAnnouncement`. | Must | BR-04, FR-ANN-10, POL-AI-05 | (1) No write permission is granted to the assistant service identity, asserted by a permission test. (2) Code-path test proves the assistant module imports no model write APIs. (3) Attempting to send a write intent through the assistant endpoint is ignored and logged. |
| FR-AI-11 | The system shall send to an external LLM provider only the user question text plus non-identifying retrieved KB context; it shall never send farm identifiers, animal identifiers, owner identity, coordinates, contact details, disease-report content, or health-record content. | Must | POL-AI-09, NF-PRIV-03 | (1) Outbound payload constructed by a redaction filter; test asserts a forbidden-content scan (regex over ids, coordinates, phone patterns, names from fixture) finds nothing. (2) Configuration flag `ASSISTANT_INCLUDE_CONTEXT=kb_only` cannot be overridden per request. (3) Data-processing terms of the provider are recorded in the deployment document before enabling it. |
| FR-AI-12 | The system shall rate-limit assistant requests per authenticated user to 20 requests per hour and shall return 429 with `Retry-After` beyond it; unauthenticated access is denied outright. | Must | NF-SEC-07, cost control | (1) 21st request within an hour returns 429. (2) Limit is configuration-driven and unit-tested with an override. (3) Rate-limit counters are per user, not per device only. (4) A dashboard metric exposes current throttle state for the administrator. |
| FR-AI-13 | The system shall retain each assistant interaction (question text, answer, citations, `answer_source`, provider id, latency, safety flags) for a configurable period (default 90 days) and shall treat it as a RESTRICTED audit-adjacent record accessible to the asking user and to reviewers for safety review. | Must | POL-AUDIT-03, NF-PRIV-05 | (1) Asking user can list and delete their own assistant history. (2) Retention job purges after the configured period. (3) Assistant logs contain no tokens, passwords or precise location values. (4) Access to another user's interaction history returns 404. |
| FR-AI-14 | The assistant shall maintain short conversational context (last 3 turns of the same session, retained 24 hours) and shall state when context is being used. | Should | FR-AI-13 | (1) Turn 4 no longer references turn 1. (2) Context is per user and not shared across accounts. (3) Deleting history clears context immediately. |
| FR-AI-15 | The system shall record a safety flag whenever a response is a refusal, an escalation, a fallback, or is generated while the provider is degraded, and shall surface the counts in the dashboard review list for KB improvement. | Must | POL-AI-10, POL-AUDIT-05 | (1) Each flagged category increments the correct counter. (2) Reviewer can see the flagged question text with the asking user anonymised. (3) Flag does not trigger any automatic user sanction (asserted: no lockout path from assistant flags). |
| FR-AI-16 | An administrator shall be able to disable the assistant entirely, or force `kb_only`, by configuration change and restart, with a user-visible unavailable message. | Must | POL-AI-11 | (1) `ASSISTANT_ENABLED=false` makes the endpoint return 503 `ASSISTANT_DISABLED` with the standard error envelope. (2) App hides the assistant entry point when the flag from `/auth/me/` says disabled. (3) Change is audited. |
| FR-AI-17 | The app shall display, permanently on the assistant screen, the general-information disclaimer, the source-of-answer label, and a one-tap path to report a problematic answer. | Must | POL-AI-04 | (1) Disclaimer is visible without scrolling on the reference device size. (2) Answer-report submission creates a `Notification`-free safety record visible to administrators. (3) Reporting a problem does not delete the original record. |

### 6.11 Requirement priority summary

| Module | Must | Should | Could | Won't (this release) | Total |
|---|---|---|---|---|---|
| FR-AUTH | 15 | 2 | 0 | 0 | 17 |
| FR-FARM | 5 | 2 | 1 | 0 | 8 |
| FR-ANIM | 7 | 2 | 0 | 0 | 9 |
| FR-HEALTH | 8 | 2 | 3 | 0 | 13 |
| FR-VET | 13 | 1 | 0 | 0 | 14 |
| FR-REPORT | 11 | 1 | 0 | 0 | 12 |
| FR-ANN | 11 | 1 | 0 | 0 | 12 |
| FR-NOTIF | 4 | 1 | 2 | 0 | 7 |
| FR-OFF | 10 | 1 | 0 | 0 | 11 |
| FR-AI | 16 | 1 | 0 | 0 | 17 |
| **Functional total** | **100** | **14** | **6** | **0** | **120** |

Non-functional totals are in §7.8. The MVP cut line is all Must items plus the Should items that the
`mvp-and-release-plan.md` schedule admits; nothing in Could is scheduled before M7.

## 7. Non-functional requirements

Format: ID, requirement, MoSCoW priority, measurable target, verification method. IDs referenced by
functional requirements above are used consistently here.

### 7.1 Security (`NF-SEC`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-SEC-01 | All client-server and dashboard traffic shall use HTTPS/TLS in any deployed environment; HTTP shall redirect to HTTPS with HSTS enabled. | Must | TLS 1.2 minimum, 1.3 preferred; 0 plaintext endpoints in the deployment manifest | Deployment config review; external scan report; redirect test |
| NF-SEC-02 | Credentials and secrets shall be stored safely: Argon2 password hashing (64 MiB / t=3 / p=4), database credentials and signing keys only in environment configuration, never in code, logs, audit rows or version control. | Must | 100% of stored passwords hashed `argon2`; 0 secret strings found by a repository secret scan | Hash-prefix assertions; `git-secrets`/equivalent pre-commit scan; log inspection test |
| NF-SEC-03 | Authorization shall be enforced by the backend for every request, with a deny-by-default posture: any endpoint without an explicit permission class fails closed at review. | Must | 0 endpoints with `AllowAny` except the documented public-area list, health check and auth endpoints | Automated test that walks the router and asserts a permission class per viewset |
| NF-SEC-04 | Object-level access control shall prevent IDOR: requests for objects the caller may not see shall return 404 rather than 403, and no listing shall leak foreign object ids. | Must | 100% of the access-control-matrix rows implemented as passing tests; 0 privilege-escalation failures | Negative permission tests per resource; fuzzed-id test per endpoint |
| NF-SEC-05 | Sensitive operations shall write an audit event in the same database transaction as the mutation, with no credentials or tokens recorded. | Must | 100% of actions in the audit trigger table produce an `AuditEvent` | Transaction test asserting rollback removes both; content assertions on audit rows |
| NF-SEC-06 | All input shall be validated server-side and all output encoded; raw SQL shall only appear in Django ORM parameterised queries. | Must | 0 dynamic SQL string concatenations; injection test set passes; XSS payload stored safely and escaped on render | Bandit/`manage.py check` plus dedicated injection and stored-XSS tests |
| NF-SEC-07 | Throttling shall apply to login/token endpoints (per IP and per account), assistant questions (20/hour/user), assistance-request creation (10/day) and sync batches. | Must | Documented limits enforced with 429 and `Retry-After` | Throttle tests per endpoint with an overridden rate |
| NF-SEC-08 | File uploads shall be validated by MIME type, extension allow-list, maximum 5 MB, image re-encoding, and EXIF stripping; attachments shall be served only through an authorising endpoint. | Must | 0 uploads of disallowed types; 0 raw-EXIF-GPS retention | Upload tests with crafted files (double extension, SVG, oversized) |
| NF-SEC-09 | Tokens shall never appear in URLs, logs, analytics, audit rows or error messages; refresh tokens shall be stored in platform secure storage; access tokens in memory only where feasible. | Must | 0 occurrences of token substrings in log fixtures | Log redaction test; storage inspection test on device/emulator |
| NF-SEC-10 | Dependencies shall be pinned, reviewed and scanned; the dashboard shall be CSRF-protected and separate from token-based mobile auth. | Must | 0 known critical vulnerabilities unaddressed at acceptance; CSRF enabled on all mutating dashboard forms | `pip-audit`/`flutter outdated` review log; CSRF negative test |
| NF-SEC-11 | Error responses shall not leak stack traces, SQL, file paths or configuration; production `DEBUG` shall be False and 500 responses generic. | Must | 0 stack traces in API responses under forced-error tests | Fault-injection tests; response body assertions |
| NF-SEC-12 | The MySQL application user shall have least privilege: DML on the application schema only, no `DROP`/`FILE`/`SUPER`, no access to other schemas; administrative migrations use a separately credentialed account. | Must | Grant script reviewed and asserted by `SHOW GRANTS` output stored in setup docs | Phase 1 verification, rechecked at deployment |

### 7.2 Privacy (`NF-PRIV`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-PRIV-01 | Personal and location data shall be collected only for documented purposes listed in DOC-REQ-006; no collection without a corresponding requirement. | Must | Purpose register covers 100% of persisted personal/location fields | Schema-to-register cross-check table in the final report |
| NF-PRIV-02 | On-device data shall be minimised, encrypted, and cleared at logout, holding only what offline features require. | Must | Local tables limited to the allow-list in FR-OFF-01; 0 rows after logout | Device/emulator inspection, file encryption check |
| NF-PRIV-03 | Aggregates and outbound third-party calls shall be de-identified: no farm id, reporter identity, coordinates, names or phone numbers. | Must | 0 forbidden tokens detected in aggregate/payload scans | Regex/fixture-based payload tests |
| NF-PRIV-04 | Consent for location shall be explicit, per purpose, revocable, recorded with timestamp and granularity, and honoured immediately for new requests. | Must | 100% of precise-location operations preceded by a consent record | Model tests plus FR-AUTH-15/FR-VET-01/02/08/11 checks |
| NF-PRIV-05 | Retention and deletion shall be configured per data class and enforced by documented jobs, with hard deletion impossible for records that carry clinical or outbreak evidence. | Must | Retention table published; job tests pass at boundary dates | Boundary-date unit tests; audit of job runs |
| NF-PRIV-06 | Data subjects shall be able to access, correct, export, and request erasure or anonymisation of their own personal data, subject to the documented audit/evidence exceptions. | Must | Request endpoints/jobs exist for each right with 30-day completion record | Manual + automated test of each right |
| NF-PRIV-07 | Public-facing features shall use coarse location only; precise coordinates shall never be serialised in list, aggregate, announcement or notification payloads. | Must | 0 coordinate fields in those payloads | Serialiser field-set assertions per endpoint |
| NF-PRIV-08 | No analytics, advertising or crash SDK shall transmit location, farm identifiers or health content; any SDK added later requires a documented review. | Must | SDK inventory approved and version-controlled | `pubspec.yaml`/settings review at each phase gate |

### 7.3 Performance (`NF-PERF`)

Targets are for the acceptance dataset: 2,000 users, 3,000 farms, 10,000 animals, 50,000 health
records, 2,000 reports, 200 announcements, single MySQL instance.

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-PERF-01 | API read latency shall meet: p95 < 500 ms for core list/detail CRUD; p95 < 800 ms for aggregated views; p95 < 4 s for assistant KB answers. | Must | Measured on the acceptance dataset over ≥200 requests per endpoint | Load script + timing report |
| NF-PERF-02 | Batch sync of 50 mutations shall complete in < 5 s server-side; the delta endpoint shall transfer only changed rows. | Must | Measured with the seeded fixture | Sync benchmark test |
| NF-PERF-03 | List endpoints shall return in bounded time regardless of data volume via pagination (page size 20, maximum 100) plus the documented indexes. | Must | Query plans use the declared indexes for the four highest-volume collections | `EXPLAIN` review recorded in setup docs; SQL-log inspection in tests |
| NF-PERF-04 | Dashboard review queue shall render within 1.5 s p95 with 2,000 reports and active filters. | Should | Timed page render | Measured on staging with fixture data |
| NF-PERF-05 | Mobile notification polling shall not exceed 2 requests per minute while foregrounded and shall stop when backgrounded; cold start < 3 s on the reference device. | Should | Instrumented counts on the reference device | Profiled run recorded in the mobile test report |
| NF-PERF-06 | The system shall support 15 concurrent authenticated users on the acceptance hardware with no error rate above 1%. | Should | Load run at 15 users for 10 minutes | Locust/equivalent report |

### 7.4 Usability (`NF-USE`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-USE-01 | Each role's core task set shall be completable by a first-time user with only in-app guidance and a one-page quick guide. | Must | Farmer core tasks in ≤5 taps; ≥80% task completion in a 3-participant walkthrough | Usability walkthrough log (approved participants) |
| NF-USE-02 | Every mutating form shall show field-level validation with actionable messages before submission fails server-side. | Must | 100% of Must-have forms have client-side validators matching server rules | Widget tests + manual checklist |
| NF-USE-03 | Every list and detail screen shall implement loading, empty, error and pending-sync states. | Must | 4 states present on all MVP screens | Widget tests per screen (screen inventory cross-check) |
| NF-USE-04 | Touch targets ≥48 dp, minimum 16 sp body text, scalable font support, and no colour-only status signalling. | Must | Audited against the screen inventory | Accessibility audit checklist; Flutter semantics test |
| NF-USE-05 | Offline and sync status shall always be visible where data is not server-confirmed. | Must | Pending chip present on every unconfirmed record | Widget test |
| NF-USE-06 | Terminology shall be consistent: `official announcement` vs `unverified report` and `general information — not a diagnosis`. | Must | 0 forbidden synonyms in strings for those concepts | String-lint guard test over ARB/strings file |
| NF-USE-07 | Dashboard shall be operable in the two most recent stable desktop browsers at 1366x768 and above. | Must | Documented pass on both | Manual compatibility sheet |

### 7.5 Reliability and availability (`NF-REL`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-REL-01 | The deployed system shall be available during scheduled demonstration and acceptance windows; unplanned downtime shall be logged with cause. | Must | ≥99% availability within measured windows | Uptime log during Phase 7/8 |
| NF-REL-02 | Database backups shall run daily with a verified restore; RPO ≤ 24 h, RTO ≤ 4 h. | Must | One documented successful restore drill per release candidate | Restore drill log and checksum |
| NF-REL-03 | Scheduled jobs (reminders, expiry, retention) shall be idempotent and safe to re-run; re-running twice shall not duplicate notifications or change statuses twice. | Must | Idempotency assertions in tests | Job tests run twice |
| NF-REL-04 | Mutations shall be duplicate-resistant via idempotency keys, and clients shall not create duplicates after a network interruption mid-request. | Must | Replay test creates exactly one mutation | FR-OFF-03 sync tests |
| NF-REL-05 | External dependency failure shall degrade gracefully: map tiles, geocoding, LLM provider and email each have a documented fallback and never a hard stop for core recordkeeping. | Must | Core 12-step E2E passes with LLM and map provider stubbed as failing | Forced-failure integration run |
| NF-REL-06 | Multi-step business operations shall be atomic: status transition + audit + notification either all commit or none. | Must | Fault-injection test proves rollback | Transaction tests |
| NF-REL-07 | Migrations shall be forward-and-backward safe where feasible and reproducible from an empty database. | Must | `migrate` from empty DB succeeds; rollback documented for each release | CI/migration run log |

### 7.6 Maintainability and testability (`NF-MNT`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-MNT-01 | Backend automated tests shall cover ≥80% line coverage for permission, model and workflow modules, and 100% of the access-control-matrix rows. | Must | Coverage report at phase gates | Coverage tooling output |
| NF-MNT-02 | An OpenAPI schema generated by drf-spectacular shall be published and shall match the implemented endpoints; the schema is the mobile contract. | Must | 0 undocumented endpoints; schema regeneration in CI | Schema diff check at contract freeze |
| NF-MNT-03 | Static analysis shall pass with zero errors: `ruff` + `black` on backend, `flutter analyze` on mobile. | Must | CI or pre-commit gate | Tool runs |
| NF-MNT-04 | Structured logging with a request correlation id, actor id and duration; no PII, token or coordinate values in log lines. | Must | Redaction test over representative log fixtures | Log assertions in tests |
| NF-MNT-05 | Significant technical decisions shall be recorded as short decision records with context, choice, alternatives and consequences. | Must | ≥1 record for each TD-01..TD-14 | `docs/` decision-log review |
| NF-MNT-06 | Configuration shall be environment-driven with no per-developer code edits; `.env.example` shall contain every required key with placeholder values. | Must | Fresh clone + `.env` from example starts successfully | Setup reproducibility run by the other member |
| NF-MNT-07 | Synthetic data factories shall generate a deterministic dataset for tests and demos, seeded and documented. | Must | Fixed seed produces identical counts; 0 production-like real data | Fixture test |
| NF-MNT-08 | Each business rule shall be traceable to at least one test and each requirement to at least one test in the traceability matrix. | Must | 0 orphan Must requirements at Phase 7 | RTM completeness check |

### 7.7 Compatibility and portability (`NF-CMP`)

| ID | Requirement | P | Measurable target | Verification |
|---|---|---|---|---|
| NF-CMP-01 | Mobile application shall support Android 8.0 (API 26) and later; target the phone size band 360x640 to 412x915 logical pixels. | Must | Core flows pass on at least 2 device/emulator profiles | Device matrix in test report |
| NF-CMP-02 | Backend shall run on Python 3.13.1 with Django 5.2.17 and MySQL 8.0.39 using `utf8mb4`; no feature may depend on an undocumented engine extension. | Must | Pinned versions installed from the setup guide; migrations succeed | Phase 1 verification |
| NF-CMP-03 | Map provider shall be switchable by configuration only (`mapzen`-style provider key in settings), keeping the client contract stable. | Must | Provider swap requires no API change | FR-VET-03 test |
| NF-CMP-04 | API contract shall remain backward compatible within `/api/v1/`; breaking changes require a version bump and a documented changelog. | Must | 0 unannounced breaking changes before Phase 7 | Changelog review |

### 7.8 Non-functional totals

| Category | Must | Should | Could | Total |
|---|---|---|---|---|
| NF-SEC | 12 | 0 | 0 | 12 |
| NF-PRIV | 8 | 0 | 0 | 8 |
| NF-PERF | 3 | 3 | 0 | 6 |
| NF-USE | 7 | 0 | 0 | 7 |
| NF-REL | 7 | 0 | 0 | 7 |
| NF-MNT | 8 | 0 | 0 | 8 |
| NF-CMP | 4 | 0 | 0 | 4 |
| NF-ETH | 4 | 1 | 0 | 5 |
| **Total** | **53** | **4** | **0** | **57** |

### 7.9 Compliance and ethics (`NF-ETH`)

| ID | Requirement | P |
|---|---|---|
| NF-ETH-01 | Development and testing shall use synthetic data. Any use of real user data requires supervisor approval and participant consent recorded before collection. | Must |
| NF-ETH-02 | Usability testing participants shall receive an information sheet and consent form, may withdraw, and shall not be exposed to real outbreak claims. | Must |
| NF-ETH-03 | The system shall not make or imply legal determinations about disease status; official status flows only through authority humans. | Must |
| NF-ETH-04 | Automated suspicion shall be review-only; the system shall take no automatic punitive action against a user based on a flag. | Must |
| NF-ETH-05 | The knowledge base shall cite sources and shall not reproduce copyrighted full text; short attributed excerpts only. | Should |

## 8. Key workflows and state machines

Status vocabularies are normative. Every transition must be validated in a service layer, never by
the client alone, and must produce an audit event.

### 8.1 Assistance request

| From | To | Actor | Preconditions | Audit action |
|---|---|---|---|---|
| — | `PENDING` | Farmer | Farm owned by caller; animals (if any) belong to the farm; rate limit not exceeded | `assistance.create` |
| `PENDING` | `ACCEPTED` | Assigned/selected veterinarian (verified) | Request still open; vet not already assigned to another open request for the same slot (soft rule, warning only) | `assistance.accept` |
| `PENDING` | `DECLINED` | Veterinarian | Reason category supplied | `assistance.decline` |
| `PENDING` | `CANCELLED` | Farmer | — | `assistance.cancel` |
| `ACCEPTED` | `IN_PROGRESS` | Assigned veterinarian | — | `assistance.start` |
| `ACCEPTED` | `CANCELLED` | Farmer | Notification to vet | `assistance.cancel` |
| `IN_PROGRESS` | `COMPLETED` | Assigned veterinarian | Linked `VeterinaryVisit` exists | `assistance.complete` |
| any other pair | — | — | — | rejected with 409 |

### 8.2 Disease report

| From | To | Actor | Notes |
|---|---|---|---|
| — | `SUBMITTED` | Verified veterinarian (author) | Reporter may withdraw while `SUBMITTED` |
| `SUBMITTED` | `UNDER_REVIEW` | Authority reviewer or officer in jurisdiction | First touch; SLA clock starts |
| `UNDER_REVIEW` | `CLARIFICATION_REQUESTED` | Reviewer or officer | Question text mandatory |
| `CLARIFICATION_REQUESTED` | `UNDER_REVIEW` | Reviewer or officer | On reporter answer |
| `UNDER_REVIEW` | `ACCEPTED_FOR_ASSESSMENT` | Officer only | Records assessment note |
| `UNDER_REVIEW` | `REJECTED` | Officer only | Mandatory reason |
| `CLARIFICATION_REQUESTED` | `ACCEPTED_FOR_ASSESSMENT` / `REJECTED` | Officer only | Direct escalation permitted |
| `ACCEPTED_FOR_ASSESSMENT` / `REJECTED` / `CLARIFICATION_REQUESTED` / `SUBMITTED` | `CLOSED` | Reviewer or officer | Terminal; reporter notified |

Rules: the reporter cannot set any of these statuses; a report is never re-opened after `CLOSED` —
a new report is filed instead (BR-07, BR-23).

### 8.3 Outbreak announcement

| From | To | Actor | Notes |
|---|---|---|---|
| — | `DRAFT` | Officer | Author recorded |
| `DRAFT` | `IN_REVIEW` | Officer | Submission for review |
| `IN_REVIEW` | `DRAFT` | Officer | Return for revision with note |
| `IN_REVIEW` | `PUBLISHED` | Officer, not the author | Sets `published_at`, `published_by`, notifies, starts expiry |
| `PUBLISHED` | `PUBLISHED` (new version) | Officer | Version increments; prior content retained in audit |
| `PUBLISHED` | `EXPIRED` | `system` (scheduled job) | Expiry date passed |
| `PUBLISHED` | `WITHDRAWN` | Officer | Mandatory reason; farmers notified |

### 8.4 Verification and account states

`User.is_active` true/false, `VeterinarianProfile.is_verified` true/false,
`User.deletion_state` `ACTIVE | PENDING_DELETION | ANONYMISED`, plus `AUTHORITY_SUBROLE`
`REVIEWER | OFFICER`. All transitions in this group are administrator-only and audited.

### 8.5 Notification trigger table (single source of truth for FR-NOTIF-02)

| Trigger | Recipient | Type |
|---|---|---|
| Vaccination due within 3 days | Farm owner | `VACCINATION_DUE` |
| Vaccination overdue | Farm owner | `VACCINATION_OVERDUE` |
| Assistance request created | Selected/available vets | `ASSISTANCE_NEW` |
| Assistance accepted/declined/status change/complete | Farmer | `ASSISTANCE_STATUS` |
| Report status change or clarification request | Reporting vet | `REPORT_STATUS` |
| Announcement published/updated | Farmers in affected area | `ANNOUNCEMENT_PUBLISHED` |
| Announcement withdrawn/expired | Previously notified farmers | `ANNOUNCEMENT_WITHDRAWN`, `ANNOUNCEMENT_EXPIRED` |
| Failed logins threshold reached | Target user (generic security notice) + dashboard review list | `SECURITY_LOGIN` |
| Account deactivated / credentials changed | Target user | `SECURITY_ACCOUNT` |

---

## 9. Data requirements (summary; full specification in DOC-REQ-004)

| Entity group | Entities | Owner-visible | Notes |
|---|---|---|---|
| Identity | `User`, `FarmerProfile`, `VeterinarianProfile`, `AuthorityProfile`, `Area`, `ConsentRecord` | Self | One role per user; one profile each |
| Farm and animal | `Farm`, `Animal` | Farmer | Soft-archive only; tag unique per farm |
| Health | `HealthRecord`, `VaccinationRecord`, `VaccinationSchedule`, `TreatmentRecord`, `VeterinaryVisit`, `Attachment` | Farmer + authorised vets | Soft history via audit summaries |
| Assistance | `AssistanceRequest` | Farmer + assigned vet | Status machine §8.1 |
| Reporting | `DiseaseReport` | Reporter + jurisdiction authority | Status machine §8.2 |
| Official information | `OutbreakAnnouncement` | Public once published | Status machine §8.3 |
| Messaging | `Notification` | Recipient | Pull model in MVP |
| Security | `AuditEvent`, `SuspiciousActivityFlag`, `SyncItem`, `AssistantInteraction`, `KBSource` | Restricted | Append-only intent; admin/officer read rights |

Constraints carried by the requirements: `utf8mb4`, InnoDB, real foreign keys, UTC timestamps, unique
natural keys where stated (email; per-farm tag; per-owner farm name; per-user idempotency key), and
no hard deletion of clinically or legally relevant rows.

---

## 10. External interface requirements

### 10.1 User interfaces

Screen-level detail is Member B's `ui-screen-inventory.md`. Constraint from this SRS: every screen
listed there must map to at least one FR/NF identifier, and each Must FR must be reachable from at
least one screen or dashboard page. Screens must render the four states of NF-USE-03 and honour the
terminology rule of NF-USE-06.

### 10.2 APIs

DOC-REQ-005 is the API requirements contract; the generated OpenAPI schema is the implementation
truth. Conventions fixed here: `/api/v1/` prefix, JWT bearer auth, page size 20, django-filter query
parameters, the standard error envelope, and idempotency-key support on all mutating sync paths.

### 10.3 Device and platform interfaces

| Interface | Requirement |
|---|---|
| Location | Android permission handling for `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`, rationale dialog first, approximate fallback honoured, no background location collection |
| Secure storage | Tokens and local-database key stored in Android Keystore-backed secure storage |
| Local database | `sqflite` (encrypted variant preferred); allow-listed tables only |
| Camera/gallery | Permission requested at first use; image compressed client-side to ≤5 MB before upload |
| Network | Explicit handling for offline, timeout, 401 refresh-then-replay-once, and 429 backoff |
| External maps | URI intent only; no data other than destination coordinates/label |
| Email | Django email backend for password reset; no marketing mail |

### 10.4 Software interfaces

| Interface | Contract |
|---|---|
| MapProvider | `tilesUrl(template)`, `search(query) -> coarse area`, `reverse(point)`; OSM/Nominatim implementation default, Google implementation optional |
| AssistantProvider | `answer(question, kb_context) -> AnswerDraft`; implementations `kb_only`, `llm_retrieval`; timeouts and errors surface as fallbacks (FR-AI-06) |
| KnowledgeBase | `search(question, filters) -> ranked source excerpts with citations`; versioned corpus |
| NotificationTransport | MVP no-op/pull implementation; push adapter is a stretch plug-in |
| Audit sink | Write-only API from services; no update/delete methods exposed |

---

## 11. Traceability

### 11.1 Objective to requirement

| Objective (DOC-REQ-001 §3.2) | Requirements |
|---|---|
| OBJ-1 recordkeeping | FR-FARM-01..08, FR-ANIM-01..09, FR-HEALTH-01..06, NF-CMP-01 |
| OBJ-2 vaccination and reminders | FR-HEALTH-04, FR-HEALTH-07, FR-HEALTH-10, FR-NOTIF-02 |
| OBJ-3 GPS assistance with manual alternative | FR-VET-01..14, FR-AUTH-15, NF-PRIV-04, NF-PRIV-07 |
| OBJ-4 structured disease reporting | FR-REPORT-01..12 |
| OBJ-5 dashboard and announcements | FR-ANN-01..12, FR-REPORT-04/05/09, NF-PERF-04 |
| OBJ-6 safe AI information | FR-AI-01..17, NF-ETH-03 |
| OBJ-7 security, RBAC, audit, suspicious activity | NF-SEC-01..12, NF-SEC-05, FR-AUTH-07, §8.5, DOC-REQ-006/007 |
| OBJ-8 offline and sync | FR-OFF-01..11, NF-REL-04 |
| OBJ-9 testing and evaluation | NF-MNT-01..08, §12 |

### 11.2 Requirement to business rule to screen to test (illustrative rows for RTM-001)

| FR | BR | Screen / dashboard page | Test IDs (indicative) |
|---|---|---|---|
| FR-AUTH-07 | BR-11 | Login screen; dashboard review list | `test_axes_lockout`, `TEST-SEC-03` |
| FR-FARM-02 | BR-01 | Farm list/detail | `test_farm_idor_returns_404` |
| FR-HEALTH-02 | BR-18 | Animal timeline; record edit | `test_health_edit_audit_diff` |
| FR-REPORT-01 | BR-03 | Report create (vet); dashboard queue | `test_report_create_forbidden_for_farmer` |
| FR-ANN-03 | BR-04, BR-24 | Announcement editor | `test_self_approval_blocked` |
| FR-VET-02 | BR-06 | Vet search with area picker | `test_manual_area_path_equivalent` |
| FR-OFF-05 | BR-14, BR-19 | Sync status screen | `test_lww_keeps_rejected_copy` |
| FR-AI-04 | BR-25 | Assistant screen | `test_disclaimer_always_present` |

### 11.3 Requirement coverage of the canonical E2E workflow

| E2E step | Requirements |
|---|---|
| 1 farmer registers | FR-AUTH-01, FR-AUTH-05 |
| 2 creates farm | FR-FARM-01 |
| 3 registers animal | FR-ANIM-01, FR-ANIM-02 |
| 4 records health event | FR-HEALTH-01, FR-HEALTH-02 |
| 5 vaccination schedule recorded | FR-HEALTH-04, FR-HEALTH-10 |
| 6 requests veterinary assistance | FR-VET-05 (with FR-VET-01/02 consent path) |
| 7 vet responds | FR-VET-06, FR-VET-07, FR-VET-09, FR-HEALTH-06 |
| 8 permitted user submits disease report | FR-REPORT-01, FR-REPORT-02 |
| 9 reviewer assesses | FR-REPORT-03, FR-REPORT-04 |
| 10 authority publishes | FR-ANN-01, FR-ANN-02, FR-ANN-03 |
| 11 users notified | FR-NOTIF-02, FR-ANN-09 |
| 12 audit trail | NF-SEC-05, FR-HEALTH-02, BR-18 |

---

## 12. Verification and acceptance

1. Each AC is mapped to at least one automated or scripted test in `test-and-acceptance-plan.md`
   (DOC-REQ-014) and recorded in RTM-001.
2. Priority-1 security requirements (NF-SEC-03, NF-SEC-04, NF-SEC-05, BR-01..BR-10) require negative
   tests — proving the forbidden action fails — not only positive tests.
3. No requirement is marked satisfied by inspection of files; only by execution evidence.
4. Acceptance data set and thresholds are as stated in §7.3.
5. The 12-step E2E walkthrough is executed against the deployed build and recorded.

---

## 13. Ambiguities resolved in this SRS

| Common ambiguous phrasing | Resolution adopted |
|---|---|
| Vets can see animal records | Only animals they are assigned to via an accepted assistance request, a recorded visit, or a farmer grant (BR-02) |
| Farmers report disease | Farmers submit observations and assistance requests; only veterinarians author `DiseaseReport` (BR-03) |
| Reports count indicates an outbreak | Counts are informational, unverified, and cell-suppressed; only announcements are official (BR-23) |
| Location is shared with vets | Coarse area pre-acceptance; precise only with consent and only to the accepted counterpart, revoked at completion (BR-06) |
| Admin can access everything | Admins get configuration and account rights, not clinical read by default (BR-05) |
| Offline means full functionality | An explicit allow-list (FR-OFF-02) and deny-list (FR-OFF-09) |
| History means event sourcing | Soft history with audit change summaries (TD-06) |
| AI answers health questions | General information only, cited, disclaimed, never diagnosis, never publishing (FR-AI-*) |

---

## 14. Open questions for the Phase 0 gate

| ID | Question | Blocks which requirement | Proposed default if unanswered |
|---|---|---|---|
| OQ-01 | Is there a real veterinary-area vocabulary available from the cooperating authority, or do we define one? | FR-FARM-05, FR-AUTH-13 | Define a curated `Area` list in code fixtures |
| OQ-02 | Are vets allowed to set fees or is any fee information displayed? | EXCL-05 | Do not display fees |
| OQ-03 | Minimum-cell suppression threshold: is 3 acceptable for academic demo data? | FR-REPORT-09 | Use 3 |
| OQ-04 | Is an external LLM available at no cost for the demonstration? | FR-AI-05 | Ship `kb_only`, keep the adapter |
| OQ-05 | Retention period for disease reports (5 years proposed)? | FR-REPORT-12 | 5 years, configurable |
| OQ-06 | Should announcements be readable without login (public web page)? | FR-ANN-07 | Require authentication in MVP |
| OQ-07 | Multi-user farms (farm workers) in scope? | FR-FARM-08 | Out of MVP |

---

## 15. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial SRS for Phase 0 review: 120 functional and 57 non-functional requirements, state machines, traceability skeleton |

