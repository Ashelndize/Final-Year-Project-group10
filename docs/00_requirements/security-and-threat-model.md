# Security Requirements, Threat Model, and Privacy and GPS Policy

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-006 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard); privacy sections reviewed with Member B (mobile) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Related | DOC-REQ-002 (SRS), DOC-REQ-003 (BR), DOC-REQ-004 (data), DOC-REQ-005 (API), DOC-REQ-007 (AI safety, audit and suspicious activity), DOC-REQ-010 (access-control matrix), DOC-REQ-013 (risk register), DOC-REQ-014 (test plan) |

---

## 1. Scope and method

This document defines the security objectives, the asset inventory, the STRIDE threat model with
mitigations and owners, the OWASP-aligned control checklist, and the Privacy and GPS Policy
(`POL-PRIV-*`, `POL-GPS-*`). Audit and suspicious-activity rules live in DOC-REQ-007; AI safety lives
in DOC-REQ-007 as well. Threat IDs `THR-*` are assigned only here.

Method: for each asset, enumerate threats by STRIDE category, name the vulnerability or weakness that
makes the threat feasible, score likelihood and impact 1-5, state the mitigation, assign the enforcing
component from DOC-REQ-003/005, and name the owner role. Likelihood assumes an attacker with a legal
account (the realistic adversary for this system) plus network observation capability.

| Scale | Likelihood | Impact |
|---|---|---|
| 5 | Near certain on the default configuration without mitigation | Loss of official-information integrity, mass disclosure of location, or project acceptance failure |
| 4 | Likely within a normal pilot | Systematic disclosure of clinical or report data |
| 3 | Plausible with deliberate effort | Disclosure affecting one identifiable farmer or vet |
| 2 | Requires unusual access or a compounding bug | Limited, self-inflicted disclosure |
| 1 | Improbable in the deployment described | Nuisance or cosmetic |

Risk number = likelihood x impact. Bands: 1-6 Low, 8-12 Medium, 15-25 High. Any High risk must be
mitigated to Medium or lower before the Phase 7 gate, or formally accepted in writing by both members
with the supervisor informed.

---

## 2. Security objectives

| ID | Objective | Verifiable statement |
|---|---|---|
| SO-1 | Confidentiality of farm and clinical data | No role reads another farmer's SENSITIVE-FARM records except through the explicit BR-02/BR-08 paths |
| SO-2 | Integrity of the official-information channel | A `PUBLISHED` announcement always has an authenticated human officer actor who is not the draft author |
| SO-3 | Separation of unverified reports from official information | No report is ever serialised, aggregated or notified with confirmation wording |
| SO-4 | Accountability | Every sensitive mutation produces an append-only audit event with actor, action, target, timestamp, change summary |
| SO-5 | Privacy of location | Precise coordinates exist only where a consent record exists, and only in payloads the entitled party may receive |
| SO-6 | Availability of core recordkeeping | The mobile app can record observations offline and sync without duplication |
| SO-7 | Least privilege | Every default is deny; administrators do not gain clinical read access by virtue of their role |
| SO-8 | Safe AI assistance | Assistant output is disclaimed, cited or refused, and has no write capability |

---

## 3. Asset inventory

| ID | Asset | Classification | Where stored | Primary threat surface |
|---|---|---|---|---|
| AS-01 | Password hashes | SECRET/RESTRICTED | MySQL `accounts_user` | Credential attack, dump leakage |
| AS-02 | JWT signing key (`SECRET_KEY`) | SECRET | Environment file only | Signing forgery, source disclosure |
| AS-03 | MySQL credentials and URLs | SECRET | `.env` on host | Repository leakage, config dump |
| AS-04 | Personal identifiers (name, email, phone) | PRIVATE-USER | MySQL; cached subsets on device | Enumeration, disclosure |
| AS-05 | Farm identity and inventory | SENSITIVE-FARM | MySQL; device cache | IDOR, aggregation, dump |
| AS-06 | Animal health, vaccination and treatment records | SENSITIVE-FARM | MySQL; device cache | IDOR, tampering, bulk export |
| AS-07 | Precise farm coordinates | SENSITIVE-LOCATION | MySQL (consent-gated); device cache | Surveillance, metadata leakage via photos |
| AS-08 | Veterinarian licence numbers | RESTRICTED | MySQL | Impersonation, disclosure |
| AS-09 | Disease reports and reporter identity | RESTRICTED | MySQL | Retaliation risk, premature leak |
| AS-10 | Outbreak announcements (published and draft) | PUBLIC / RESTRICTED draft | MySQL | Forgery, premature publication, silent edit |
| AS-11 | Audit events | RESTRICTED | MySQL (append-only intent) | Alteration, deletion, exposure |
| AS-12 | Assistant knowledge base and prompts/answers | INTERNAL / RESTRICTED | MySQL; optional provider logs | Prompt injection, data exfiltration to provider |
| AS-13 | Attachment files (photos) | SENSITIVE | Object storage path outside static root | Direct URL guess, EXIF leak, malicious upload |
| AS-14 | Application source repository | INTERNAL | Git | Secret commits, history exposure |
| AS-15 | Device-resident tokens and local database | SECRET / SENSITIVE | Android keystore-backed storage, encrypted `sqflite` | Device loss, rooted device |
| AS-16 | Notification content | PRIVATE-USER | MySQL, device | Over-shoulder and shoulder-surfing disclosure |

---

## 4. STRIDE threat model

Legend for enforcement: BR = business rule from DOC-REQ-003, NF = non-functional requirement from
DOC-REQ-002 §7, EP = component named in DOC-REQ-005. Owner role is the accountable team member
(A = Member A backend/dashboard, B = Member B mobile, Both).

| ID | Asset | STRIDE | Threat | Vulnerability / weakness | L | I | Risk | Mitigation | Enforcement | Owner | Residual |
|---|---|---|---|---|---|---|---|---|---|---|---|
| THR-01 | AS-04 | Spoofing | Account takeover by password guessing | Weak or reused passwords; no lockout | 4 | 4 | 16 High | Argon2 hashing with validators, account lockout after 5 failures in 15 minutes (django-axes), throttled token endpoint, clear generic failures | FR-AUTH-05/07, NF-SEC-07, BR-11, `ObtainTokenView` throttle | A | Medium |
| THR-02 | AS-02 | Spoofing | Forged JWT if the signing key leaks | Key committed to the repo or printed in logs | 2 | 5 | 10 Medium | Key only in `.env`, excluded by `.gitignore`, secret scan in CI, never logged; short 30-minute access TTL and rotatable key with a documented re-issue runbook | NF-SEC-02/09/10, BR-15, TD-12 | A | Low |
| THR-03 | AS-15 | Spoofing | Stolen device used to open the app as the farmer | Device unlocked, tokens cached in plaintext | 3 | 4 | 12 Medium | OS credential gate on app open, tokens in keystore-backed secure storage, access token held in memory, remote account deactivation blacklists refresh tokens | FR-AUTH-03/11, NF-SEC-09, BR-14 | B | Medium |
| THR-04 | AS-05/AS-06 | Tampering | Farmer A edits Farmer B's animal or health record (IDOR) | Object-level access derived only from URL id | 4 | 4 | 16 High | Queryset scoping by ownership and derived vet access; foreign ids return 404; per-action permission classes; mutation re-checks ownership | NF-SEC-04, BR-01/02/16, `FarmAccessPermission`, `VetClinicalAccessPermission` | A | Low after tests |
| THR-05 | AS-06 | Tampering | Silent rewrite of a health or treatment record to hide a condition | Records mutable without history | 3 | 4 | 12 Medium | Soft history: change summary with before/after values plus full before-image in `AuditEvent` in the same transaction; edit rights role-split (farmer cannot edit vet text) | FR-HEALTH-02, BR-18, NF-SEC-05, `audit service` | A | Low |
| THR-06 | AS-12/AS-03 | Tampering (SSRF) | Backend geocoding proxy or LLM call induced to fetch internal or attacker URLs | Unvalidated URL passed to server-side HTTP client | 3 | 4 | 12 Medium | Geo endpoint accepts only a text query, never a URL; outbound requests restricted to the allow-listed provider hosts, redirects disabled, 5-second timeout, responses cached and coarse-only; LLM base URL is configuration, not user input | FR-VET-03, NF-SEC-06, EP `/api/v1/geo/search/` | A | Low |
| THR-07 | AS-06 | Repudiation | A user denies making a clinical edit or a report decision | Attribution not captured on mutations | 3 | 4 | 12 Medium | Actor and role snapshot stored on every sensitive action; audit write failure rolls the mutation back; decision endpoints require a reason | BR-18, NF-SEC-05, POL-AUDIT-01/02 | A | Low |
| THR-08 | AS-11 | Information disclosure | Audit contents (including other users' actions) read by an unauthorised role | Broad Django admin access | 3 | 4 | 12 Medium | Audit API restricted per POL-AUDIT-06, Django admin made read-only and limited, no mutation endpoints, BR-05 admin clinical denial, BR-34 read rights | BR-05/34, EP `/api/v1/audit/events/` | A | Low |
| THR-09 | AS-07 | Information disclosure | Precise coordinates leak in lists, notifications, announcements or photo EXIF | Coordinates serialised by default; EXIF untouched | 4 | 5 | 20 High | Field-level omission (not nulling) in all list and fan-out payloads, coordinates only in owner detail and entitled post-acceptance vet detail, EXIF stripped server-side before storage, coarse-only public features, deletion endpoint for coordinates | BR-06, NF-PRIV-07, POL-GPS-03/04, FR-HEALTH-08, FR-FARM-03 | Both | Medium |
| THR-10 | AS-09 | Information disclosure | Reporter identity or an unreviewed report leaks to farmers or peers | Aggregates carrying identifiers; shared notification text | 3 | 4 | 12 Medium | Serialiser field exclusion by role, reporter visible only to jurisdiction authority, aggregates de-identified with minimum-cell suppression under 3, notification payload allow-list | BR-08/09/23/36, FR-REPORT-08/09, NF-PRIV-03 | A | Low |
| THR-11 | AS-10 | Repudiation / Forgery | Fake "official" announcement circulated to farmers | Anyone able to create an announcement, or a draft rendered as official | 3 | 5 | 15 High | Officer-only publication, segregation of duties (non-author publication), immutable `classification` and `issuing_authority` fields, drafts invisible outside AUTHORITY, publication audited with the human actor | BR-04/10/24, FR-ANN-03/08, `IsAuthorityOfficer` | A | Low |
| THR-12 | AS-09/AS-10 | Denial of service | Report or assistance-request flooding overwhelms the review queue | Unbounded creation endpoints | 3 | 3 | 9 Medium | Per-user and per-day limits (10/day assistance, 3 emergency), throttles on auth and assistant, review-queue sorting by age rather than volume, sync batch caps | BR-29, FR-VET-13, NF-SEC-07, FR-OFF-04 | A | Low |
| THR-13 | AS-01/AS-14 | Elevation of privilege | Self-registration as AUTHORITY or ADMIN | Role accepted from the client | 4 | 5 | 20 High | Role whitelist at registration, authority/admin provisioning administrator-only, deny-by-default permission classes, router-walk test that every viewset declares permissions | BR-21, FR-AUTH-01/13, `RoleWhitelistValidator` | A | Low |
| THR-14 | AS-05 | Elevation of privilege | Veterinarian gains standing access to all clinical data through a broad filter | Derived-access query written without scope | 3 | 5 | 15 High | Narrow `Q`-union of the three grant paths, per-action re-check on detail reads, explicit test that a vet with no workflow link receives 404, optional grant records time-boxed and revocable | BR-02/02a, FR-FARM-08, `VetClinicalAccessPermission` | A | Low |
| THR-15 | AS-04 | Elevation of privilege | Administrator browses clinical records and reports as a matter of routine | Django superuser power applied to data | 3 | 4 | 12 Medium | BR-05 default-deny for ADMIN on clinical viewsets, break-glass requiring a second approver and generating a self-auditing event, dashboard separates configuration pages from clinical pages | BR-05, FR-REPORT-01 negative test, `AdminClinicalDenyPermission` | A | Medium |
| THR-16 | AS-13 | Tampering | Malicious or oversized upload (web shell, decompression bomb, double extension) | Naive upload handling, predictable storage path | 3 | 4 | 12 Medium | Type and size allow-list, image re-encode, random stored name, storage outside static root, serving via permission-checked endpoint with `no-store`, per-user upload throttle | BR-30, NF-SEC-08, FR-HEALTH-08 | A | Low |
| THR-17 | AS-06 | Information disclosure | SQL injection or ORM abuse through filter parameters | String-built queries, unvalidated filter fields | 2 | 5 | 10 Medium | Django ORM parameterisation only, django-filter declared fields with typed choices, search length capped, no raw SQL except reviewed parameterised cases | NF-SEC-06, API-C8/C9, DQ-06 | A | Low |
| THR-18 | AS-16 | Information disclosure | Stored XSS in the dashboard through free-text findings, notes or announcement bodies | Unescaped rendering of user content | 3 | 4 | 12 Medium | Django auto-escaping on templates, no raw-HTML safe filter, allow-listed markup if rich text is ever required, output escaping tests with crafted payloads, CSP header | NF-SEC-06, DQ-08, dashboard templates | A | Low |
| THR-19 | AS-12 | Information disclosure | Prompt injection through the question field steering the LLM into leaking system instructions or off-policy content | Untrusted user text concatenated with instructions | 3 | 3 | 9 Medium | Retrieval-restricted prompting, fixed instruction prefix, no tools or data-write capability, output validated against the safety rules before delivery, refusal on instruction-like requests, external content never fetched at request time | POL-AI-12, FR-AI-07/08/09, `AssistantProvider` | Both | Medium |
| THR-20 | AS-06 | Denial of service | Runaway client loop creating thousands of health records or sync requests | No per-user write budget | 3 | 3 | 9 Medium | Per-user write throttle (300/hour health records), batch caps, backoff on failure, POL-SUS-02 bulk-edit rule feeding the review list | BR-29, NF-SEC-07, FR-OFF-06 | Both | Low |
| THR-21 | AS-15 | Repudiation | Offline queue replay creates duplicate mutations after a partial network failure | Missing idempotency | 4 | 3 | 12 Medium | Client UUID per mutation, unique `(user_id, idempotency_key)` ledger, replay returns the original outcome, key reuse with a different payload rejected and flagged | BR-19/20, FR-OFF-03/04, `SyncItem` | Both | Low |
| THR-22 | AS-03 | Information disclosure | Secrets in repository history after a careless commit | `.env` tracked, key pasted into a commit | 3 | 5 | 15 High | `.gitignore`, `.env.example` placeholders only, pre-commit secret scan, review rule for shared files, documented rotation runbook if it happens | NF-SEC-02/10, TD-12, RSK-10, RSK-19 | Both | Medium |
| THR-23 | AS-10 | Tampering | Scheduled job or script publishes or edits an announcement without a human | A management command with publish capability | 2 | 5 | 10 Medium | BR-24 publish requires an interactive authenticated officer; `published_by` non-null human FK; test asserting no management command performs publication | BR-04/24, FR-ANN-10 | A | Low |
| THR-24 | AS-04/AS-05 | Denial of service | Credential stuffing against login causes an outage of trust or account lockout storm | No progressive backoff | 3 | 3 | 9 Medium | IP and account throttles, axes cool-off with a bounded duration, generic responses, self-view of failed attempts, security notifications | FR-AUTH-07, NF-SEC-07, POL-SUS-01 | A | Low |
| THR-25 | AS-11 | Tampering | An insider deletes audit rows to conceal edits | Update/delete rights on the audit table, model allows save | 2 | 5 | 10 Medium | Append-only model guards, DB user denied UPDATE/DELETE on `audit_event`, BR-33 no endpoint mutates audit, retention job may redact payload PII but never remove rows, daily dump with checksum | BR-33/34, POL-AUDIT-01, DB-11 | A | Low |
| THR-26 | AS-01 | Repudiation | Brute-force or offline attack on the hash store after a dump | Weak KDF | 2 | 4 | 8 Medium | Argon2id parameters 64 MiB / t=3 / p=4, minimum password length 10, transparent rehash on parameter change, least-privilege DB account limiting what a SQLi can read | FR-AUTH-05, NF-SEC-02/12 | A | Low |
| THR-27 | AS-08 | Information disclosure | Licence numbers exposed in a directory response | Over-broad serialiser | 2 | 3 | 6 Low | Field exclusion by role; masked display; RESTRICTED classification | FR-AUTH-14, API-C18 | A | Low |
| THR-28 | AS-13/AS-07 | Information disclosure | Attachment URL guessed or cached by a shared browser | Predictable path, cacheable response | 3 | 4 | 12 Medium | Random stored name, authorising download endpoint, `Cache-Control: private, no-store`, no signed public URLs in MVP | BR-30, NF-SEC-08, EP `/api/v1/attachments/{id}/` | A | Low |
| THR-29 | AS-09 | Spoofing | Unverified veterinarian files reports that enter the surveillance pipeline | Verification flag not checked on write | 3 | 4 | 12 Medium | `IsVerifiedVeterinarian` permission on create, re-read of the flag per request, reversal immediately removes rights | BR-22, FR-AUTH-14, FR-REPORT-01 | A | Low |
| THR-30 | AS-16 | Information disclosure | Backup dump or log file containing sensitive data is misplaced | Backups on shared storage, verbose logs | 3 | 4 | 12 Medium | Backups restricted to the DBA account, log redaction of tokens and coordinates, retention limits on `AuditEvent.ip_address`, restore drill performed in a controlled environment | NF-SEC-09, NF-REL-02, NF-MNT-04, POL-AUDIT-03 | A | Medium |

Threats scored High (15-25) — THR-01, THR-04, THR-09, THR-11, THR-13, THR-14, THR-22 — are the
Phase 1-to-6 controls that must be proven by tests before the Phase 7 gate. Each is carried into
DOC-REQ-013 as a tracked risk.

---

## 5. OWASP-aligned control checklist

Mapped to OWASP Top 10 (2021) and the OWASP API Security Top 10 (2019), the two catalogues most
relevant to a DRF-plus-mobile architecture.

| OWASP item | Where it applies here | Controls (IDs) | Evidence required at the gate |
|---|---|---|---|
| A01 Broken Access Control / API1 BOLA | Every object id in `/api/v1/`, dashboard pages, attachment downloads | BR-01/02/08/09/10, NF-SEC-03/04, BR-13 deny-by-default, 404-not-403 rule, `Access-Control-Matrix` tests | `TC-PERM-*` suite: 100% of DOC-REQ-010 rows executed, 0 privilege-escalation failures |
| A02 Cryptographic Failures | Password storage, tokens in transit and at rest, on-device database | NF-SEC-01/02/09/12, BR-14, BR-15, DB-11 | Hash-prefix assertions; TLS configuration review; device storage inspection |
| A03 Injection | Filter parameters, free text, ORM use, dashboard rendering | NF-SEC-06, BR-16, DQ-06/08, THR-17/18 | Stored-XSS payload test; SQL-metacharacter search test; code scan (Bandit) |
| A04 Insecure Design | Rumour risk, over-collection of location, admin over-privilege, offline conflict loss | BR-04/05/06/23/24/25, ARC-3/4/6, DOC-REQ-007 policy set | Design review against this document; STRIDE table completed and signed |
| A05 Security Misconfiguration | `DEBUG`, `ALLOWED_HOSTS`, CORS, Django admin exposure, error pages, default keys | NF-SEC-11/12, BR-13, TD-12 | Settings review checklist; 500-response body test; CORS allow-list documented |
| A06 Vulnerable and Outdated Components | Django, DRF, simplejwt, axes, django-filter, drf-spectacular, Flutter packages, MySQL | NF-SEC-10, NF-MNT-06 | `pip-audit` output; `flutter pub outdated` review recorded per release |
| A07 Identification and Authentication Failures | Login, reset, refresh, lockout, session idle, token revocation | FR-AUTH-02..09, BR-11/15, NF-SEC-07 | Lockout and replay tests; refresh-after-logout returns 401 |
| A08 Software and Data Integrity Failures | Dependency pinning, migration reproducibility, CI, unreviewed shared file edits, unverified AI content | NF-REL-07, NF-MNT-03/06, BR-25, POL-AI-03/12 | Migration from empty DB; pinned requirement files; KB review records |
| A09 Security Logging and Failures | Audit coverage, suspicious rules, redaction, correlation ids, review workflow | NF-SEC-05, POL-AUDIT-*, POL-SUS-*, NF-MNT-04 | Trigger table coverage test; log redaction test; dashboard flag review test |
| A10 Server-Side Request Forgery | Geocoding proxy, attachment fetching, optional LLM egress | THR-06, FR-VET-03, POL-AI-09 | Allow-listed host test proving internal addresses are refused |
| API2 Broken Authentication / API4 Insecure Consumption | Token TTLs, no tokens in URLs, OpenAPI schema exposure policy | BR-15, NF-SEC-09, API-C3 | Endpoint test asserting no token accepted from a query string |
| API3 Mass Assignment / API5 Broken Function Level Authorization | Serializer field whitelists; role-gated actions | BR-16/17, API-C18, `ROLE_NOT_PERMITTED` | Test asserting `role` and `is_verified` cannot be set by clients |
| API7 DoS | Rate limits, batch caps, pagination caps, indexes | BR-29, NF-SEC-07, API-C7, NF-PERF-03 | Throttle tests; `EXPLAIN` review for high-volume filters |
| API8 Bot and automated abuse | Bulk animal and record creation, script-driven report filing | BR-29, POL-SUS-02/04 | Threshold tests and review-list assertions |

Explicit note on rate limiting: the highest-value throttle points for this system are login/token
issuance (per IP and per account), password reset request, assistant question endpoint, geocoding
proxy, attachment upload, assistance-request creation and sync batch. All are declared in
DOC-REQ-005 §6 and implemented with DRF throttles plus django-axes for authentication.

---

## 6. Secure configuration baseline

| ID | Requirement | Verification |
|---|---|---|
| CFG-01 | `DEBUG = False` outside local development; `ALLOWED_HOSTS` from environment | Settings test; forced-500 body assertion |
| CFG-02 | `SECRET_KEY`, database credentials, email credentials, optional LLM key and provider base URL read from `.env`; `.env.example` contains keys with placeholder values only | Fresh clone setup by the other member (NF-MNT-06) |
| CFG-03 | `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`, `SECURE_SSL_REDIRECT` enabled in deployment; secure cookies for the dashboard | Deployment config review |
| CFG-04 | CORS restricted to the documented origins; the API never allows arbitrary origins with credentials | Negative CORS test |
| CFG-05 | Security headers on dashboard and API responses: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, CSP with no `unsafe-inline` for dashboard pages | Header assertions |
| CFG-06 | Django admin limited to configuration objects; clinical models read-only or excluded for ADMIN (BR-05); staff permission changes audited | Admin permission test |
| CFG-07 | OpenAPI schema exposure limited to authenticated developers in staging; never published to a public search index in production | Endpoint visibility test |
| CFG-08 | Database user least privilege (NF-SEC-12) with DDL rights held by a separate migration credential | `SHOW GRANTS` captured in the setup guide |
| CFG-09 | Uploads stored outside the static root, served only through the authorising endpoint | Storage-path assertion test |
| CFG-10 | Log levels exclude request bodies containing personal data in production; correlation ids retained 30 days | Log review |
| CFG-11 | Time zone UTC, `USE_TZ = True`, NTP-synchronised host so scheduled jobs and LWW ordering are reliable | Config check; job boundary tests |
| CFG-12 | The mobile build contains no hardcoded credentials or provider keys; any map/LLM key is supplied through configuration at deployment | Build inspection; secret scan of `mobile/` |

---

## 7. Privacy and GPS Policy

Applicability: this policy governs every collection, storage, disclosure and deletion of personal and
location data in the system. It is the authoritative text behind the in-app privacy summary screen
(DOC-REQ-011 SCR-M-43) and the dashboard privacy notice. Every clause is enforceable in code;
clauses with no implementation are marked documentation-only.

### 7.1 Privacy principles

| ID | Clause | Implementation |
|---|---|---|
| POL-PRIV-01 | Purpose limitation: personal and location data are collected only for the purposes listed in the purpose register (§7.2). No new field may be collected without adding a purpose row here and a requirement in DOC-REQ-002 | Schema-to-register cross-check (NF-PRIV-01); documented at each phase gate |
| POL-PRIV-02 | Data minimisation: only the fields needed by an approved requirement exist. Weight, photo, breed and contact details are optional; precise coordinates are optional and consent-gated | Serialiser optionality; DB-07 and §4 of DOC-REQ-004 |
| POL-PRIV-03 | Collection is transparent: each screen that collects data states why, who sees it, and for how long, in plain language | Screen text list in DOC-REQ-011; NF-USE-06 terminology rule |
| POL-PRIV-04 | Onward disclosure requires an entitlement check at request time, never a cached client decision | NF-SEC-04, BR-16, API-C18 field omission |
| POL-PRIV-05 | Aggregates are de-identified, and small cells (fewer than 3 reports) are suppressed for non-officers | FR-REPORT-09, BR-23 |
| POL-PRIV-06 | No third party receives personal data except: password-reset email delivery, optional LLM provider (question text only, POL-AI-09), and map/geocoding providers (query text or tiles only, no identifiers) | FR-AI-11, FR-VET-03, THR-06, provider terms recorded before enabling |
| POL-PRIV-07 | No advertising, analytics or tracking SDK is present; adding one requires a documented review and supervisor acknowledgement | NF-PRIV-08 |
| POL-PRIV-08 | Data subjects may access, correct, export, object to processing of optional fields, and request erasure or anonymisation, subject to the documented evidence-retention exceptions | BR-37, FR-AUTH-16, EP `/api/v1/accounts/me/data/` and `DELETE /api/v1/accounts/me/` |
| POL-PRIV-09 | Retention periods are published per data class (DOC-REQ-004 §8) and enforced by jobs; expired non-evidential data is deleted, evidential data is anonymised rather than deleted | POL-AUDIT-07, NF-PRIV-05 |
| POL-PRIV-10 | A personal or location data incident is recorded, its scope assessed, affected users notified when their data was exposed, and the event entered in the project risk register | POL-AUDIT-08; incident procedure documented in the administrator manual |

### 7.2 Purpose register

| Purpose | Data collected | Collected from | Disclosed to | Retention | Requirement |
|---|---|---|---|---|---|
| Account identity and login | Name, email, phone, hashed password | Farmer, vet self-registration | Self; administrator; authority for workflow contact | Account life plus 12 months | FR-AUTH-01/02 |
| Farm and animal recordkeeping | Farm name and area, animal identity, health events, vaccinations, treatments | Farmer, vet | Owner; entitled vets; authority under BR-08 | Owner life; 5 years after animal status change for evidential text | FR-FARM-*, FR-ANIM-*, FR-HEALTH-* |
| Veterinary assistance dispatch | Coarse area always; phone and precise coordinates only after acceptance with consent | Farmer device, farm record | The single accepted veterinarian for that request | Contact fields masked 30 days after closure | FR-VET-05/08 |
| Nearby-vet search | Coarse area (manual pick) or device position (precise only with consent) | Farmer device | Never sent onward as an identity; Nominatim receives free-text query only | Not stored unless the user saves it as a farm location | FR-VET-02/03/11 |
| Disease surveillance | Report content, affected area, reporter identity | Veterinarian | Jurisdiction authority only | 5 years (reporter anonymised after) | FR-REPORT-* |
| Official announcements | Affected areas, published content | Authority officer | All authenticated users in scope | Indefinite (official record) | FR-ANN-* |
| Notifications | Type, minimal body, target reference | Server | Recipient only | Read notifications 180 days | FR-NOTIF-* |
| Assistant questions | Question text plus up to 3 prior turns of that user's session | User | Optional LLM provider (question and retrieved KB text only) | 90 days, user-deletable | FR-AI-* |
| Audit | Action metadata, change summaries, hashed IP for security events | Server | Officers, designated reviewers, administrator for security purposes | 24 months online, then archived export | POL-AUDIT-* |
| Authentication security | Failed-attempt counts and timestamps, last activity | Server | Subject self-view; officers/administrators via the review list | 90 days | FR-AUTH-07, POL-SUS-01 |

### 7.3 GPS and location clauses

| ID | Clause | Enforcement | Status |
|---|---|---|---|
| POL-GPS-01 | Consent-based precise location: precise device location is requested only at the moment the user first invokes a location-dependent feature, after a plain-language purpose dialog, and never at first launch or in the background. Declining must never block any other feature | FR-VET-01; mobile permission handler; consent record on grant | Must |
| POL-GPS-02 | Consent is recorded per purpose and granularity, timestamped, versioned against the consent text shown, revocable at any time in the app's privacy screen, and revocation takes effect immediately for new operations | FR-AUTH-15, EP `/api/v1/consents/`, BR-06 | Must |
| POL-GPS-03 | Manual area fallback: when permission is denied, unavailable, imprecise, or the user chooses approximate precision, the system offers area search and an area picker and delivers functionally equivalent results (vet directory, distance-less ordering, report filing, announcement targeting) | FR-VET-02, FR-FARM-01 area mandatory, FR-VET-11 `distance_available` | Must |
| POL-GPS-04 | Coarse precision for public features: the vet directory, announcements, pattern summaries, notifications, aggregate views and every list payload use the `Area` vocabulary only. Latitude and longitude are omitted from these payloads, not blanked | NF-PRIV-07, API-C18, BR-06, serialiser field sets | Must |
| POL-GPS-05 | Device-side minimisation: the local cache stores the coarse area code for the user's own farms; precise coordinates are cached only when consent is active, are excluded from logs and crash context, and are cleared on logout | FR-OFF-01/08, BR-14, NF-PRIV-02 | Must |
| POL-GPS-06 | Third-party exposure: no external service receives farm coordinates or a farmer identifier. The tile provider receives only a tile bounding box; the geocoder receives only user-typed text; the external maps intent receives only the destination coordinates or label | FR-VET-12, FR-VET-03, POL-PRIV-06, THR-06 | Must |
| POL-GPS-07 | Photo metadata: all image EXIF, including GPS, is stripped server-side before storage, and stripping is asserted before the attachment becomes downloadable | BR-30, FR-HEALTH-08, `exif_stripped` flag | Must |
| POL-GPS-08 | Disclosure window is bounded: precise coordinates become visible to the accepted veterinarian only while the request is active, and the disclosure itself is recorded as an audit event naming who saw them and when | FR-VET-08, BR-18, `AuditEvent` action `assistance.location_disclosed` | Must |
| POL-GPS-09 | Accuracy honesty: coordinates are stored with an accuracy radius and a set-time; the UI states that accuracy may be poor and never claims a location is verified | FR-FARM-03 fields, NF-USE-06 | Must |
| POL-GPS-10 | Independent consent: granting farm-location consent is not a precondition for using recordkeeping features, and withdrawing it does not delete the farm or its history — only the coordinates | FR-FARM-03 delete endpoint, NF-USE-01 | Must |
| POL-GPS-11 | Retention: a consent record is kept as evidence for as long as any data collected under it is retained, even after withdrawal | POL-AUDIT-07, DOC-REQ-004 §8 | Must |
| POL-GPS-12 | No tracking: no continuous position reporting, no movement history, no background location collection, and no inference of a farmer's movements from other data | Requirement absence enforced: no such endpoint exists; the router-walk test (BR-13) covers the API surface | Must |
| POL-GPS-13 | Farm-coordinate access rules (the authoritative list): see §7.4 | Table below | Must |

### 7.4 Farm-coordinate access rules

| Caller | May read precise farm coordinates | Conditions | Denial behaviour |
|---|---|---|---|
| The owning farmer | Yes | Always; own records only | Own detail payload only |
| Another farmer | No | Never | 404 on the farm object |
| A veterinarian before accepting a request | No | Coarse `Area` only | Coarse-only payload; `location_available: false` |
| The assigned veterinarian on an accepted request | Yes | Farmer consent active for `SHARE_LOCATION_WITH_VET` at disclosure time | 403 `CONSENT_REQUIRED` at write, field omitted at read |
| The assigned veterinarian after completion | No | Coordinates removed from the payload after `COMPLETED` or `CANCELLED` | Field omitted |
| Authority reviewer or officer | Only when the report or announcement workflow includes that farm | Reason recorded in the audit entry; not shown in queues or aggregate maps | Omitted field |
| System administrator | No by default (BR-05); yes under recorded break-glass | Second-administrator approval, self-auditing event | 403 `ADMIN_CLINICAL_ACCESS_DENIED` |
| Anonymous or unauthenticated user | No | Public features use `Area` only | 401 or area-only list |
| Any third-party service | No | Only tile bounding boxes and user-typed geocoding text leave the system | Design exclusion, POL-GPS-06 |

### 7.5 Data-subject rights implementation map

| Right | How exercised | Limits |
|---|---|---|
| Access | `GET /api/v1/accounts/me/data/` returns the subject's own structured copy; the app also exposes a privacy summary screen | Excludes other users' data and reporter identities |
| Rectification | Profile, farm, animal and record edit endpoints with soft history | Authoritative fields such as `role` and `is_verified` are administrator-only |
| Erasure | `DELETE /api/v1/accounts/me/` with a 30-day grace period, then identifier anonymisation | `AuditEvent` rows and clinical narrative retained as evidence (BR-33, POL-AUDIT-07); reasons documented in the response |
| Restriction of location | Consent withdrawal plus coordinate deletion endpoint | Already-created coarse area references remain, as they are not precise location |
| Portability | JSON export; CSV animal export (Could) | Redacted for third-party identities |
| Objection to optional fields | Optional-by-design fields and mute preferences (FR-NOTIF-05) | Security notifications cannot be muted |

### 7.6 Privacy verification

| Check | Method | Gate |
|---|---|---|
| No coordinates in list, notification, announcement, directory or aggregate payloads | Serialiser field-set assertions per endpoint | Phase 2 |
| Consent precedes every precise write | Model and serializer tests, plus a no-consent negative test | Phase 2/4 |
| Denied-permission path equals the granted path in capability | Manual and automated walkthrough of FR-VET-02 | Phase 4 |
| EXIF GPS removed | Upload test with a geotagged fixture image | Phase 6 |
| Local cache empty after logout | Device/emulator inspection | Phase 6 |
| No personal data in logs | Redaction test over representative log lines | Phase 6 |
| Disclosure of precise location is auditable | `assistance.location_disclosed` event assertion | Phase 4/6 |

## 8. Trust boundaries and data-flow notes

| Boundary | Crossers | Trust assumption | Controls |
|---|---|---|---|
| Device to API | HTTPS JSON, JWT | The client is hostile: it may replay, tamper, or invent payloads | Server re-validates everything (BR-16); ids opaque; idempotency ledger |
| API to MySQL | Parameterised ORM | The database is trusted for integrity, not for authorization | FK constraints and unique constraints as defence in depth; least-privilege account |
| API to geocoding provider | Text query | External service is untrusted for content and can be slow or absent | Allow-listed host, timeouts, no redirects, cached coarse results, manual fallback |
| API to tile server | Bounding box only | Content untrusted, no identifiers sent | Attribution preserved; no query strings containing user data |
| API to optional LLM provider | Question text plus retrieved KB excerpts | Provider is untrusted for accuracy and may log inputs | Redaction filter (FR-AI-11), no identifiers, output validated against POL-AI rules, provider disabled by default |
| Dashboard to API layer | Django session cookies, same process | Browser may be a hostile network position | CSRF, secure cookies, session auth separate from JWT, no token in URL |
| Officer decision to public information | Publication action | Human judgement is the only gate to official status | BR-04/24, `published_by` human FK, segregation of duties |
| Device cache to device | Local encrypted database | Device may be lost | BR-14 minimisation, encryption, logout wipe |

### 8.1 Threat-relevant assumptions

| ID | Assumption | Consequence if false |
|---|---|---|
| SA-01 | The realistic adversary holds a legitimate account, not root on the server | Controls are access-control weighted rather than perimeter weighted |
| SA-02 | The deployment is HTTPS-only | Plaintext operation would invalidate token and password protection claims |
| SA-03 | Users keep their own device unlock secret | Device-loss mitigations (BR-14) assume an OS-level gate |
| SA-04 | The area vocabulary is stable enough that jurisdiction filtering is meaningful | Jurisdiction rules would need an area-mapping table |
| SA-05 | No statutory reporting obligation is automated by this project | Scope and ethics statements in DOC-REQ-001 §4.2 would need revision |

---

## 9. Residual risk and gate criteria

| ID | Criterion | Threshold |
|---|---|---|
| SG-01 | Every High-scored threat in §4 is mitigated to Medium or below, or formally accepted with a written justification | 7 of 7 addressed |
| SG-02 | Access-control matrix rows (DOC-REQ-010) all have passing negative tests | 100% |
| SG-03 | Audit coverage test on the sensitive-action list | 100% |
| SG-04 | Location privacy checks in §7.6 | All pass |
| SG-05 | Secret scan of the repository history at the acceptance gate | 0 findings |
| SG-06 | Dependency audit | 0 unaddressed critical advisories; medium advisories logged with a plan |
| SG-07 | Backup restore drill | 1 successful drill recorded |
| SG-08 | Throttle and lockout tests | All pass per DOC-REQ-005 §6 |
| SG-09 | Assistant safety suite (DOC-REQ-007 §6) | 0 responses without disclaimer; 0 write actions from the assistant path |
| SG-10 | Unresolved privacy or security defects at acceptance | 0 critical, 0 high unless formally accepted by both members with the supervisor informed |

---

## 10. Relationship to neighbouring documents

| Document | What it takes from this one |
|---|---|
| DOC-REQ-002 SRS | NF-SEC-* and NF-PRIV-* targets; threat IDs referenced as dependencies |
| DOC-REQ-003 BR | Enforcement points for BR-05, BR-06, BR-11 to BR-16, BR-30 |
| DOC-REQ-004 data | Classification map, DB-11 audit protection, retention table |
| DOC-REQ-005 API | Error codes `CONSENT_REQUIRED`, `ADMIN_CLINICAL_ACCESS_DENIED`, throttle table, attachment contract |
| DOC-REQ-007 | Audit and suspicious-activity policy detail; AI safety rules referenced by THR-19 |
| DOC-REQ-010 access-control matrix | Row-by-row enforcement of §4 mitigations that concern visibility |
| DOC-REQ-013 risk register | RSK rows corresponding to THR-01/04/09/11/13/14/22 |
| DOC-REQ-014 test plan | `TC-SEC-*` and `TC-PERM-*` test families, §9 gate criteria |

---

## 11. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial security objectives, 16-asset inventory, 30-item STRIDE threat table, OWASP Top 10 and API Top 10 mapping, configuration baseline, and the Privacy and GPS Policy (`POL-PRIV-01..10`, `POL-GPS-01..13`, farm-coordinate access rules) |

