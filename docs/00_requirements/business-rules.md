# Business Rules

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-003 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Related | DOC-REQ-002 (SRS), DOC-REQ-004 (data/ERD plan), DOC-REQ-005 (API), DOC-REQ-006 (security/threat + privacy/GPS), DOC-REQ-007 (AI safety + audit/suspicious activity) |

---

## 1. Purpose and conventions

A business rule (BR) is a statement that constrains system behaviour independently of any single
screen or endpoint. Every rule must be enforced at a named backend enforcement point (EP), and every
rule must have at least one negative test proving that the prohibited action fails.

| Column | Meaning |
|---|---|
| ID | Stable identifier; never reused |
| Rule | Normative statement (must / must not) |
| Rationale | Why the rule exists (objective, risk, policy) |
| Enforcement point | Where the rule is implemented: model/constraint (M), permission class (P), object permission (OP), serializer/validator (S), viewset/service (V), management command/job (J), middleware (MW), template/UI (U — never sole enforcement), provider abstraction (PA) |
| Verifying requirement | SRS requirement IDs that the rule supports |

Rule families:

| Range | Family |
|---|---|
| BR-01 to BR-10 | Data ownership, visibility and role boundaries |
| BR-11 to BR-14 | Security, audit and device rules |
| BR-15 to BR-20 | Data lifecycle, integrity and conflict rules |
| BR-21 to BR-30 | Workflow, official-information and AI rules |
| BR-31 to BR-38 | Dashboard, administrative and notification rules |

---

## 2. Data ownership, visibility and role boundaries

| ID | Rule | Rationale | Enforcement point | Verifying requirement |
|---|---|---|---|---|
| BR-01 | A farmer can see, create, update and archive only the farms they own and the animals belonging to those farms. Requests concerning another farmer's objects return 404, not 403. | Ownership is the primary privacy boundary for SENSITIVE-FARM data; 404 prevents id enumeration | P: `IsAuthenticated`; OP: `FarmAccessPermission` / `AnimalAccessPermission` filtering `queryset` by `owner_id` and returning `Http404` on miss; S: nested writes validated against `owner` | FR-FARM-02, FR-ANIM-01/03/05, NF-SEC-04 |
| BR-02 | A veterinarian can read or write animal and health data only for animals covered by (a) an assistance request they are assigned to and not yet completed for the relevant access window, (b) a `VeterinaryVisit` they recorded, or (c) an explicit farmer grant (FR-FARM-08). No other animal is visible to them. | Least privilege; vets are external parties relative to the farm | OP: `VetClinicalAccessPermission` implemented as a queryset OR-filter of three conditions — `assistance_requests.veterinarian = user` with status in ACCEPTED/IN_PROGRESS/COMPLETED, OR `visits.veterinarian = user`, OR `farm.vet_grants.veterinarian = user` with `revoked_at` null; V: same filter applied on detail retrieval | FR-HEALTH-01/02/03/06, FR-VET-08/10, NF-SEC-04 |
| BR-02a | Access granted to a veterinarian by an accepted assistance request expires when the request becomes `CANCELLED`, and clinical read access granted by a visit does not expire but is never extended to the farmer's other farms. | Prevents open-ended third-party access through an abandoned workflow | OP filter status list; J: none required (state-derived) | FR-VET-08, BR-02 |
| BR-03 | Only a user with role VETERINARIAN and `is_verified = true` can create, or edit while `SUBMITTED`, a `DiseaseReport`. Farmers, authority users and administrators cannot. | Reports must be professional claims; unverified professionals must not enter the surveillance pipeline | P: `IsVerifiedVeterinarian` on the create action; V: author field forced to `request.user`; S: read-only `status`, `author` | FR-REPORT-01/07, BR-22 |
| BR-04 | Only a user with role AUTHORITY and `authority_role = OFFICER` can publish, update a published version, withdraw or expire-by-hand an `OutbreakAnnouncement`. Reviewers cannot publish. | Official communication is a legal-adjacent act reserved to accountable officers | P: `IsAuthorityOfficer`; V: `publish()` requires actor subrole check; M: `published_by` FK non-null on publication | FR-ANN-01/03/05, FR-ANN-10 |
| BR-05 | A System Administrator has configuration and account-management rights and does not receive read access to clinical records, animal health data, disease reports or precise farm coordinates by default. Break-glass access requires a second authorised administrator's recorded approval and generates a self-auditing elevated-access event. | Technical power must not silently become clinical surveillance power; supports ethics and least privilege | P: `NotAdminForClinicalData` deny rule on clinical viewsets for ADMIN role; OP: object filter excludes ADMIN; MW: break-glass decorator writing `AuditEvent` with `actor`, `reason`, `approver` | FR-REPORT-01, NF-SEC-03, NF-ETH-03 |
| BR-06 | Precise location (farm coordinates or device position) shall be collected, stored or shared only when an active consent record exists for that specific purpose. Public and directory features shall use coarse area only. | Location is proprietorial and personal data; purpose limitation | M: consent FK check in serializer validation; S: `LocationConsentValidator`; P: field-level exclusion in list serialisers; U: rationale dialog before OS permission | FR-AUTH-03, FR-FARM-03, FR-VET-01/02/08/11, NF-PRIV-04/07 |
| BR-07 | Status transitions of `AssistanceRequest`, `DiseaseReport` and `OutbreakAnnouncement` shall be role-gated exactly as the transition tables in DOC-REQ-002 §8. All other transitions shall be rejected with 409 and shall change nothing. | Workflows carry accountability; ad-hoc status edits destroy review integrity | V: `TransitionService.change(obj, to_status, actor)` with a declarative transition map; P: per-action permission; M: `status` field choices | FR-VET-06/07, FR-REPORT-03/04, FR-ANN-02 |
| BR-08 | A veterinarian shall see only the reports they authored. Authority users shall see reports whose affected area falls inside their jurisdiction (at their `Area` level or below). | Jurisdiction is the authority boundary; peer visibility is not a right | OP: queryset filter `affected_area__in=subtree(user.jurisdiction)`; `author=user` for vets; S: jurisdiction re-check on every transition | FR-REPORT-04/05/08, NF-SEC-04 |
| BR-09 | Farmers shall not receive, and shall not be able to query, other farmers' records, aggregate report counts, or reporter identities. Notifications shall not contain content the recipient could not read directly. | Prevents indirect leakage through messaging | S: notification payload builder with per-recipient field allow-list; OP: notification queryset filtered by `recipient=user` | FR-NOTIF-03, FR-REPORT-08 |
| BR-10 | Announcement drafts, review notes and internal recommendations shall be visible only to AUTHORITY users. Farmers shall see only `PUBLISHED` (and, with an explicit expired label, `EXPIRED`/`WITHDRAWN`) announcements. | Drafts are not official information and could mislead | P: `IsAuthenticated` plus OP status filter; S: status-filtered `get_queryset` | FR-ANN-02/07 |

---

## 3. Security, audit and device rules

| ID | Rule | Rationale | Enforcement point | Verifying requirement |
|---|---|---|---|---|
| BR-11 | Five failed login attempts from the same account/IP combination within 15 minutes shall lock authentication for that account for the configured cool-off and shall create a security `AuditEvent` plus a suspicious-activity flag on the review list. The lockout shall never be presented as an accusation. | Blocks credential stuffing and brute force while keeping review-based posture | MW/P: django-axes handler; J: flag writer; U: neutral lockout message | FR-AUTH-07, NF-SEC-07, POL-SUS-01 |
| BR-12 | Only Argon2-hashed passwords may be stored; passwords, tokens, licence numbers and precise coordinates must never appear in logs, audit change summaries, error payloads or analytics. | Hashing standard plus secret hygiene | M: Django hasher configuration; MW: log filter/redaction; S: audit payload allow-list | FR-AUTH-05, NF-SEC-02/09, POL-AUDIT-03 |
| BR-13 | The API surface shall be deny-by-default: every viewset must declare authentication and permission classes, and `AllowAny` is permitted only on the documented public area list, health check, and auth endpoints. | Prevents accidental exposure when new endpoints are added | MW: DRF `DEFAULT_PERMISSION_CLASSES = IsAuthenticated`; J: router-walk test asserting per-viewset permissions | NF-SEC-03, DOC-REQ-005 §4 |
| BR-14 | The device shall store only allow-listed offline tables, encrypted with a key held in platform secure storage, and shall clear cached business data, tokens and consented location on logout. Pending mutations are retained only under the same account key until synced or explicitly discarded. | Limits breach impact of a lost phone; keeps the server authoritative | U: mobile storage service with enforced schema; V: server unaffected; P: sync requires authentication | FR-OFF-01/07/08, NF-PRIV-02 |
| BR-15 | Every authentication token shall have a bounded lifetime (access 30 min, refresh 7 days, idle 30 days) and a refresh token shall be unusable after logout because it is blacklisted. | Limits the window of a stolen token | M: simplejwt blacklist app; V: logout view; MW: token TTL settings | FR-AUTH-03/09, NF-SEC-09 |
| BR-16 | All validation that affects authorization or data integrity shall run on the server. Client-side validation is a usability aid only and may never be the sole gate for any rule in this document. | Client code is attacker-controlled | V/S/P on every endpoint; U: mirrors server rules for UX only | NF-SEC-03/06, ARCH-1 |
| BR-17 | Roles and subroles are single-valued per user. An authority user holds exactly one of REVIEWER or OFFICER at a time; changes are administrator actions and are audited with old and new values. | Prevents privilege accumulation and unclear accountability | M: `OneToOne` profiles plus `TextChoices` field; S: admin-only serialiser field; J: audit hook | FR-AUTH-13, NF-SEC-05 |
| BR-18 | Every create, update, soft-delete and status transition of an audited object shall produce an `AuditEvent` in the same transaction as the mutation, containing actor, action, target type and id, timestamp, and a change summary of changed fields with old and new values. | Accountability and non-repudiation without a full event-sourcing system | V: `audit service` called inside `transaction.atomic()`; M: `AuditEvent` append-only model; MW: exception if audit fails | FR-HEALTH-02, FR-REPORT-03, FR-ANN-05, NF-SEC-05, POL-AUDIT-01 |
| BR-19 | Conflicting concurrent edits shall resolve by last-write-wins-with-audit: the later client timestamp (tie-broken by later server receipt) is applied and the rejected version is stored verbatim in the audit change summary. Silent discard of either version is prohibited. | Deterministic offline sync with full evidence retention | V: `SyncService.apply_mutation()` comparison logic; M: `AuditEvent.before_image/after_image`; S: version counter | FR-OFF-05, NF-REL-04, POL-AUDIT-04 |
| BR-20 | Each client mutation shall be identified by a client-generated UUID idempotency key that is unique per user; a replayed key shall return the original outcome and shall not create a second mutation. | Duplicate prevention across flaky mobile networks | M: unique constraint `(user_id, idempotency_key)` on `SyncItem`; V: lookup before applying | FR-OFF-03, NF-REL-04 |

---

## 4. Workflow, official information and AI rules

| ID | Rule | Rationale | Enforcement point | Verifying requirement |
|---|---|---|---|---|
| BR-21 | Self-registration shall be limited to Farmer and Veterinarian. Authority and Administrator accounts shall be created only by an administrator or a controlled provisioning command. | Role integrity is the foundation of all other access rules | P: register serialiser role whitelist; V: admin provisioning endpoint; S: 403 with `ROLE_PROVISIONING_REQUIRED` | FR-AUTH-01/13, NF-SEC-03 |
| BR-22 | A veterinarian's clinical authoring rights (assistance responses, health-record clinical entries, disease reports) require successful credential verification by an administrator; unverified veterinarians have directory-read access only. | Prevents unqualified claims entering the surveillance record | M: `VeterinarianProfile.is_verified`; P: `IsVerifiedVeterinarian`; J: audit on verification change | FR-AUTH-14, FR-REPORT-01, FR-VET-07 |
| BR-23 | `DiseaseReport` and `OutbreakAnnouncement` shall be distinct records, endpoints, and UI surfaces. Report data shall never be labelled, aggregated, serialised or notified as a confirmed outbreak. Report counts shall carry `is_confirmed_data: false` and hide groups with fewer than 3 reports from non-officers. | Core research and safety constraint: unverified reports are not official information | S: separate serialisers with fixed `classification` constants; V: no report-to-announcement mutation, only linking (BR-28); U: label guard test; V: cell suppression | FR-REPORT-06/09, FR-ANN-08, NF-PRIV-03, NF-ETH-03 |
| BR-24 | No automated mechanism shall set an announcement to `PUBLISHED`. Publication shall require an interactive, authenticated authority officer who is not the draft author; AI output, report counts and pattern summaries may only inform a human recommendation. | Legal and safety requirement; the project's critical rule | V: `publish()` requires `request.user`; P: `IsAuthorityOfficer`; M: `published_by` non-null human FK; J: test that no management command performs publication | FR-ANN-03/04/10, FR-AI-10, BR-04 |
| BR-25 | Every AI assistant response shall carry the disclaimer `General information — not a diagnosis.`, its `answer_source`, `kb_version`, and either citations or an explicit no-answer state. | Transparency and safety of AI output | S: `AssistantAnswerSerializer` non-optional fields; V: response builder cannot complete without them; U: always-visible banner | FR-AI-04/17, POL-AI-04 |
| BR-26 | The assistant shall not diagnose a named animal, and veterinarian-authored suspicions shall be presented as clinical assessments rather than confirmed diagnoses. | Avoids false certainty in both automated and human content | V: assistant refusal rules; S: label enum without `DIAGNOSIS` for assessments; U: wording guard | FR-AI-02, FR-HEALTH-03 |
| BR-27 | A `TreatmentRecord` may name a veterinarian as prescriber only when created by a veterinarian or when it references an existing veterinarian prescription; farmers may not create prescriptions. | Medication safety and accountability | S: cross-role validator; P: create-permission branch on `prescriber_role` | FR-HEALTH-05 |
| BR-28 | Officers may link source reports to an announcement only while that announcement is `DRAFT` or `IN_REVIEW`; linking shall be audited on both objects, and shall never change a report's status automatically. | Keeps evidential linkage explicit and reversible | V: `link_report()` guarded by status; J: audit writes on both sides | FR-REPORT-11, FR-ANN-01 |
| BR-29 | Rate limits shall apply to assistance-request creation (default 10 per farmer per 24 h, 3 emergency), assistant questions (20 per user per hour), login attempts, and sync batch size (max 100 items, 512 KB). Limits are configuration values. | Abuse and cost control; protects optional paid integrations | MW: DRF throttles; V: service-level counters; J: none | FR-VET-13, FR-AI-12, FR-OFF-04, NF-SEC-07 |
| BR-30 | Attachments shall be type- and size-validated, re-encoded where images, stripped of EXIF GPS, stored outside the static root, and served only through a permission-checking endpoint. | Upload abuse and location leakage through photo metadata | V: attachment service; S: validator; MW: storage configuration | FR-HEALTH-08, NF-SEC-08 |

---

## 5. Dashboard, administration and notification rules

| ID | Rule | Rationale | Enforcement point | Verifying requirement |
|---|---|---|---|---|
| BR-31 | Every review decision shall record actor, timestamp, previous and new status, and a reason or note; a decision without a reason shall be rejected. Reviewers shall be able to see, but not overwrite, earlier decisions. | Decisions must be defensible in an evidence review | V: transition service requires `reason`; M: audit change summary; U: dashboard form validation | FR-REPORT-03/10, FR-ANN-04 |
| BR-32 | The dashboard shall present suspicious-activity flags as a review list with an outcome field (`reviewed_ok`, `escalated`, `false_positive`, `action_taken`) and shall take no automatic action against a user. | Flags are signals, not findings; prevents automated harm | V: flag status transitions; U: dashboard; J: no auto-block job may exist | POL-SUS-05, NF-ETH-04 |
| BR-33 | Audit events shall be append-only. No role shall be able to update or delete an `AuditEvent` through the API or the dashboard; retention anonymisation may alter only personal identifiers inside the payload, never the record's existence. | Integrity of the evidence trail | M: `AuditEvent` with `save()`/`delete()` guards plus DB revoke; P: no viewset exposing mutation actions; J: anonymiser limited to payload PII | POL-AUDIT-01/07, NF-SEC-05 |
| BR-34 | Audit and flag data shall be readable by authority officers (workflow scope), designated reviewers for their jurisdiction's reports, and administrators for security purposes only. Django admin access to `AuditEvent` shall be restricted to a read-only listing. | Audit data is itself sensitive | OP: audit queryset filters; P: `CanReadAudit`; U: admin `has_change_permission=False` | POL-AUDIT-06, BR-05 |
| BR-35 | Announcements shall expire automatically at their expiry date via a daily scheduled job recording `actor = system`, and expired or withdrawn announcements shall remain readable with an explicit status label. | Stale official guidance is a hazard; history is still evidence | J: `expire_announcements` command, idempotent; M: status field; S: status label | FR-ANN-06, NF-REL-03 |
| BR-36 | Notification content shall be the minimum necessary: type, short title, generic body, and a target reference whose own permission check protects the detail. | Notifications are an uncontrolled disclosure channel | S: per-type payload allow-list builder; OP: target permission re-check on open | FR-NOTIF-03, BR-09 |
| BR-37 | Farmers shall be able to obtain a copy of their own data (farms, animals, records, announcements they were shown, consent records, and their assistant history) and to request erasure or anonymisation, subject to BR-18 and BR-33 evidence retention. | Data subject rights | V: export service; J: anonymisation job; S: redaction rules | FR-AUTH-16, NF-PRIV-05/06 |
| BR-38 | Development, demonstration and testing shall use synthetic data; real personal or farm data shall not be loaded without supervisor approval and participant consent. | Research ethics and privacy by default | J: fixture factories only; M: seeded demo data; U: demo build flag; documentation gate | NF-ETH-01, NF-MNT-07 |

---

## 6. Rule-to-requirement coverage check

| Rule | Must-have requirement(s) it blocks if unenforced | Negative test required |
|---|---|---|
| BR-01 | FR-FARM-02, FR-ANIM-03 | Cross-owner GET/PUT returns 404 |
| BR-02 | FR-HEALTH-01, FR-VET-08 | Vet without grant/visit/request cannot read |
| BR-03 | FR-REPORT-01 | Farmer/admin create attempt returns 403 |
| BR-04 | FR-ANN-03 | Reviewer publish attempt returns 403 |
| BR-05 | NF-SEC-03 | Admin GET on clinical collection returns 403/404 |
| BR-06 | FR-AUTH-03, FR-VET-02 | No-consent coordinate write returns 403 |
| BR-07 | FR-VET-06, FR-REPORT-03, FR-ANN-02 | Every forbidden transition pair returns 409 |
| BR-11 | FR-AUTH-07 | 6th failed login returns 423 and a flag exists |
| BR-13 | NF-SEC-03 | Router-walk test finds a permission class everywhere |
| BR-18 | FR-HEALTH-02 | Rollback leaves no orphan audit row and no orphan mutation |
| BR-19 | FR-OFF-05 | Losing version retrievable from audit |
| BR-20 | FR-OFF-03 | Duplicate key replay creates 1 mutation |
| BR-23 | FR-ANN-08, FR-REPORT-06 | No report payload contains `confirmed`; no announcement derived from a report alone |
| BR-24 | FR-ANN-10 | No command path publishes |
| BR-25 | FR-AI-04 | Response without disclaimer is impossible to serialise |
| BR-29 | FR-AI-12, FR-VET-13 | Exceeding limit returns 429 |
| BR-33 | POL-AUDIT-01 | DELETE/PATCH on audit endpoint returns 405 |

Rules BR-02a, BR-08 to BR-10, BR-12, BR-14 to BR-17, BR-21, BR-22, BR-26 to BR-28, BR-30 to BR-32 and
BR-34 to BR-38 follow the same pattern: each is enforced in a named backend component and each is
paired with at least one negative test recorded in RTM-001.

---

## 7. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial business rule set: 38 rules plus BR-02a, with rationale, enforcement points and coverage check |
