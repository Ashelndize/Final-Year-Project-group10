# Access-Control Matrix

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-010 |
| Title | Role-Based and Object-Level Access-Control Matrix |
| Version | 0.1 |
| Date | 2026-11-04 |
| Author | Member A (backend/security-facing requirements); reviewed by Member B for mobile-surface consequences |
| Status | Draft for Phase 0 review |
| Parent documents | DOC-REQ-001 charter (§4.3), DOC-REQ-002 SRS (ARC-1..ARC-9, §4.1 data classes, `D-01`..`D-20`) |
| Companion documents | DOC-REQ-003 business rules, DOC-REQ-006 security/threat model, DOC-REQ-007 audit/suspicious-activity policy, DOC-REQ-008 user stories, DOC-REQ-009 architecture, DOC-REQ-014 test plan |
| Master-prompt step | Phase 0, Step 0.4 "Define user roles" and Step 0.7 "Access-control matrix" |

---

## 1. Purpose, rule of interpretation, and conventions

This matrix is the normative statement of who may do what to which data. It is the source for:

1. Backend permission classes and query-set scoping (DOC-REQ-009 §6, DOC-REQ-005).
2. The automated permission-matrix test suite (DOC-REQ-014 §5, `TC-PERM-*`) and the success criterion SC-02 ("0 privilege-escalation failures; every rule row has at least one automated test").
3. Mobile and dashboard UI gating — which is presentation only and never a control.

**Rules of interpretation**

1. **Default deny.** Anything not expressly granted is denied (CON-04, ARC-1). A blank cell means denied.
2. **Server-side only.** Every grant in this matrix must be implemented as a backend enforcement point (`EP-<NN>`, DOC-REQ-003/005). A client-side hide is not an enforcement.
3. **Two levels.** A role-level grant ("Veterinarian may read `HealthRecord`") never takes effect unless the object-level rule in §6 is also satisfied. Role-level allows AND object-level allows; both must pass.
4. **Sub-roles.** The Authority role has two sub-roles, recorded on `AuthorityProfile`: **reviewer** (assesses reports, cannot publish) and **officer** (may publish, update, withdraw, expire). They are shown as separate columns because their cells differ. A holder has one sub-role at a time unless the SRS later permits both; if both are ever granted, the officer rights dominate.
5. **Provisional links.** `FR-*`/`NF-*` numbers are provisional cross-references until DOC-REQ-002 §6 is final (see DOC-REQ-008 §1) and are resolved in RTM-001. `OR-<NN>` (object rule) and `LP-<NN>` (least-privilege default) identifiers are assigned by this document; if DOC-REQ-003 assigns authoritative `BR-<NN>` numbers to the same constraints, this matrix adopts them and keeps `OR-*` as the enforcement-facing label.
6. **Deletion.** No role holds unrestricted hard-delete rights on business data. `D` in this matrix means soft delete/archive unless the cell says "hard".

### 1.1 Legend

| Symbol | Operation | Meaning |
|---|---|---|
| `C` | Create | May cause a new row to exist |
| `R` | Read | May list/retrieve the object and the fields in scope |
| `R*` | Read restricted subset | May read only the listed fields/aggregates, not the full record |
| `U` | Update | May change permitted fields of an existing row |
| `D` | Delete | Soft delete/archivate; `D-hard` only where stated and only under the retention procedure |
| `A` | Approve | May change workflow state (verify, accept, review decision, role/jurisdiction assignment) |
| `P` | Publish | May set an announcement to `PUBLISHED`, or update/withdraw/expire one |
| `AR` | Archive/restore | May archive or restore without deleting history |
| `S` | System-only | Written by `SYSTEM` services; no human role may write directly |
| `—` | Deny | No access (default) |
| `(own)` `(assigned)` `(juris)` | Scope qualifiers | Owner-only, assigned-case-only, jurisdiction-scoped — see §6 |

## 2. Least-privilege defaults (normative)

| ID | Default |
|---|---|
| LP-01 | No authenticated user may read another user's private data unless an object rule in §6 explicitly grants it. |
| LP-02 | **System Administrator has no clinical read access by default**: no `HealthRecord`, `VaccinationRecord`, `TreatmentRecord`, `VeterinaryVisit`, animal clinical detail, or precise farm coordinates. Administration data only (identity, role, status, verification, jurisdiction, configuration). (BR-05, charter §4.3-3) |
| LP-03 | **Authority may read reports and publish announcements**; it may not create or edit farmer-owned farm/animal/health data, and it receives underlying clinical context only as limited by OR-03/OR-11 (open question Q8, DOC-REQ-008 §10). |
| LP-04 | Authority **reviewer** sub-role cannot publish, update, withdraw or expire announcements even though it can approve report status transitions. |
| LP-05 | **Veterinarian may read only the records of animals they are entitled to** — an accepted assistance request, a visit they recorded, or an explicit farmer grant under FR-FARM-08 — and only for the lifetime of that basis (OR-02, OR-08, BR-02/BR-02a). |
| LP-06 | Veterinarian clinical writes are limited to animals in an active assignment; they may not create Farms, and may not edit a farmer's own observation entries (they may add corrections). |
| LP-07 | Only an authenticated human authority officer holds `P`. No automated principal — management command, scheduler, rule engine, pattern summary, or the assistant — may hold or be granted `P`, and no API path accepts a non-human actor for publication (ARC-3, EXCL-01, BR-24). |
| LP-08 | The assistant (`ASSISTANT`) and all rule automation are read-only advisory surfaces: `C/U/D/A/P = —`. They may create a *flag* row only (SUS flag, OR-09). |
| LP-09 | `AuditEvent` is append-only (`S` write, `R` restricted, `U/D = —` for every role including Administrator). |
| LP-10 | Farmers may not author `DiseaseReport`; farmer input reaches reporting only through `HealthRecord` observations and `AssistanceRequest` escalation (`D-08`, ARC-4). |
| LP-11 | Role, sub-role and jurisdiction changes are exclusively Administrator actions and always audited with old/new values; self-assignment and self-elevation are impossible (OR-10). |
| LP-12 | Precise location (`D-16`) is released only to the counterparty of an accepted assistance request and only after recorded consent; everything else uses coarse area (`D-15`) (CON-11, BR-06). |
| LP-13 | Cross-farmer visibility is never granted, including for "nearby outbreak" context; farmers see official announcements and coarse aggregates only. |
| LP-14 | Every permission denial that targets an object identifier (not just an unauthenticated call) is recorded as an access-control `AuditEvent` (OR-12). |

## 3. Summary matrix (coarse)

Object-level scoping in §6 is mandatory; this table alone is insufficient for implementation.

| Data object | Farmer | Veterinarian | Authority reviewer | Authority officer | System Administrator |
|---|---|---|---|---|---|
| `User` (own account) | C R U AR | C R U AR | R* (own) U (own) | R* (own) U (own) | C R U AR D (LP-02) |
| `User` (others) | — | R* (assigned counterpart) | R* (jurisdiction workflow) | R* (jurisdiction workflow) | R* (identity/role/status only) |
| `Farm` | C R U AR (own) | R (assigned animals' parent farm, minimal) | R* (juris, aggregate + report context) | R* (juris) | — |
| `Animal` | C R U AR (own) | C? no — R/U clinical fields (assigned) | R* (juris, report context) | R* (juris) | — |
| `HealthRecord` | C R U (own, observations) | C R U-corrections (assigned) | R* (limited case context, Q8) | R* (limited) | — |
| `VaccinationRecord` | C R (own) | C R U (assigned) | R* (aggregate) | R* (aggregate) | — |
| `VaccinationSchedule` | R (own) | R (assigned) | — | — | — (protocol config only) |
| `TreatmentRecord` | R (own) C (administered-by-farmer entry) | C R U (assigned) | R* (limited) | R* (limited) | — |
| `VeterinaryVisit` | R (own) | C R (assigned) | R* (report context) | R* | — |
| `AssistanceRequest` | C R U-cancel (own) | R A-accept/U-status (assigned) | — | — | — |
| `DiseaseReport` | — | C R U-withdraw (own authored) | R A-status (juris) | R A-status P-adjacent (juris) | — |
| `OutbreakAnnouncement` | R (published, own area) | R (published, own area) | C-draft R U (juris) | C R U **P** (juris) | — |
| `Notification` | R U-read/dismiss (own) | R U-read (own) | R (own) + trigger via publication | R (own) + trigger | R* (delivery failures, monitoring) |
| `AuditEvent` | — | — (own actions only, if surfaced) | R (juris, read-only) | R (juris, read-only) | R (security/admin scope, read-only) |
| `Area` / `VaccinationProtocol` reference data | R | R | R | R | C R U AR |
| `SyncItem` / idempotency ledger | — | — | — | — | R* (operational) ; `S` writes |
| Suspicious-activity flag | — | — | R (juris) | R (juris) | R A-dismiss |
| Assistant KB entry | R (via answers) | R | R | R | C R U AR (KB curation, no clinical data) |

## 4. Detailed matrix per object

Notation in cells: symbol + scope qualifier + note key (`N-<n>`, explained under each table).

### 4.1 `User` and role/profile data

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create self (self-registration) | C | C | — | — | C (staff accounts) |
| Read self | R | R | R | R | R |
| Read others | — | R* N-1 | R* N-2 | R* N-2 | R* N-3 |
| Update self (name, phone, area) | U | U | U | U | U N-4 |
| Update credentials (password, email) | U | U | U | U | C-reset N-5 |
| Update role / sub-role / jurisdiction | — | — | — | — | U A N-6 |
| Verify veterinarian credentials | — | — | — | — | A N-7 |
| Deactivate / restore | — (may request) | — | — | — | U AR N-8 |
| Archive (retention) | — | — | — | — | D N-9 |

- N-1 A veterinarian may read the counterparty's contact identity only while a case is open (OR-02).
- N-2 Authority may read the identity of a report's author, the requesting farmer of an in-scope case, and nothing else (OR-03).
- N-3 Administrator sees identity, role, sub-role, jurisdiction, verification, account status, last-login. Never clinical content or precise coordinates (LP-02).
- N-4 Users may not change their own role, verification status or account status; role-bearing fields are absent from self-update serializers (OR-10).
- N-5 Administrator may trigger a reset, not read or set a plaintext password (LP-09, CON-06).
- N-6 Audited with old/new values (US-ADMIN-01, OR-10).
- N-7 Sets `VeterinarianProfile.is_verified` (BR-22) and unlocks report authoring; audited.
- N-8 Deactivation blocks authentication with a generic message; data retained (FR-HEALTH-09, FR-REPORT-12).
- N-9 Hard deletion only via the documented retention procedure, always with an audit row (DOC-REQ-007).

### 4.2 `Farm`

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | C (own) | — | — | — | — |
| List/read own | R | — | — | — | — |
| Read another farmer's farm | — | R* N-10 | R* N-11 | R* N-11 | — |
| Update identity/contact/area | U (own) | — | — | — | — |
| Update coarse area with consent | U (own) | U N-12 | — | — | — |
| Archive / restore | AR (own) | — | — | — | AR N-13 |
| Delete (hard) | — | — | — | — | D N-13 |
| Approve/publish | — | — | — | — | — |

- N-10 Minimal read of the farm containing an assigned animal: name, coarse area, species present, contact route (OR-02).
- N-11 Report/case context and jurisdiction aggregates only; no browsing of farms in the area (OR-03, LP-13).
- N-12 A veterinarian may correct a coarse area observed during a visit; the change is audited and never writes precise coordinates (LP-12).
- N-13 Administrator may archive on account closure under the retention procedure; the farm's clinical data is not readable by them (LP-02).

### 4.3 `Animal`

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | C (own farm) | — | — | — | — |
| Read own inventory | R | — | — | — | — |
| Read assigned animal | — | R N-14 | R* N-15 | R* N-15 | — |
| Update identity/species/tag | U (own) | — | — | — | — |
| Update clinical/veterinary fields | — | U N-16 | — | — | — |
| Change status (alive/sold/dead) | U (own) | U N-16 | — | — | — |
| Archive | AR (own) | — | — | — | — |
| Delete (hard) | — | — | — | — | D (retention only) |

- N-14 Only animals named in an active assignment; access ends with the assignment window (OR-02/OR-08).
- N-15 Identification, species, age band, status and the report-relevant record subset (Q8). No herd-wide browsing.
- N-16 Treatment/vaccination/observation-derived fields and status; a veterinarian may not change farmer-owned identity fields (LP-06).

### 4.4 `HealthRecord` (farmer observation + clinical entry, `D-04`)

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create observation (own animals) | C N-17 | — | — | — | — |
| Create clinical entry | — | C N-18 | — | — | — |
| Read own animal's records | R | — | — | — | — |
| Read assigned animals' records | — | R N-18 | R* N-19 | R* N-19 | — |
| Update | U N-20 (own observations) | U-correction N-21 | — | — | — |
| Delete | AR N-22 (own, recent) | AR N-22 | — | — | — |
| Approve / publish | — | — | — | — | — |

- N-17 Author + author role recorded; reportable-sign flags may be set (BR-23).
- N-18 Active assignment required (OR-02).
- N-19 Limited to the records referenced by the report under review, for the review duration; the read is audited (OR-03/OR-11, Q8).
- N-20 A farmer may edit their own observation while it is unmodified by a clinical process; edits after a veterinarian has relied on them create an audited amendment, not a silent overwrite (BR-18).
- N-21 A veterinarian may not edit a farmer's observation text; they add a correction entry, and only their own clinical entries are updatable (LP-06).
- N-22 Nothing is hard-deleted from clinical history; archival keeps the row and its audit chain (FR-HEALTH-09, FR-REPORT-12, OR-04).

### 4.5 `VaccinationRecord`, `VaccinationSchedule`, `TreatmentRecord`, `VeterinaryVisit`

| Object / operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| `VaccinationRecord` C | C N-23 | C N-18 | — | — | — |
| `VaccinationRecord` R | R (own) | R (assigned) | R* aggregate (juris) | R* aggregate | — |
| `VaccinationRecord` U / AR | U (own farmer-administered only) | U (own entries) | — | — | — |
| `VaccinationSchedule` R | R (own) | R (assigned) | — | — | — |
| `VaccinationSchedule` C/U/S | S (derived) N-24 | — | — | — | Protocol config U N-25 |
| `TreatmentRecord` C | C N-26 | C N-18 | — | — | — |
| `TreatmentRecord` R | R (own) | R (assigned) | R* (report context) | R* | — |
| `TreatmentRecord` U / AR | U (own entries) | U (own entries) | — | — | — |
| `VeterinaryVisit` C | — | C N-18 | — | — | — |
| `VeterinaryVisit` R | R (own animals) | R (own visits + assigned) | R* (report context) | R* | — |
| `VeterinaryVisit` U | — | U (own, before close) | — | — | — |
| Any archive/delete above | AR only per §1.1 rule 6 | AR (own entries) | — | — | Retention only |

- N-23 Farmer-recorded vaccinations are labelled "farmer-reported" and are not treated as proof in authority views (AS-06).
- N-24 Derived by `SYSTEM` from protocols + DOB/age; a user cannot insert arbitrary schedule rows (prevents reminder gaming).
- N-25 `ADMIN` edits the protocol catalogue (doses, intervals, species) — configuration, not clinical data (LP-02).
- N-26 Farmer treatment entries are permitted only where the SRS admits farmer-administered treatments; they never override a veterinarian's prescription record and are always labelled by author role.

### 4.6 `AssistanceRequest`

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | C (own farm/animals) | — | — | — | — |
| Read | R (own requests) | R (eligible before accept, full after accept) N-27 | — | — | — |
| Update content (animals, urgency) | U while `PENDING` only | — | — | — | — |
| Accept / decline | — | A N-28 | — | — | — |
| Status update (`PENDING`→`ACCEPTED`→`IN_PROGRESS`→`COMPLETED`; `DECLINED`/`CANCELLED` terminal) | U-cancel / confirm N-29 | U N-30 | — | — | — |
| Withdraw / archive | AR | AR (own closed cases) | — | — | — |
| Delete | — | — | — | — | — |
| Grant read access to animal records | S (on accept, time-bounded) N-31 | — | — | — | — |

- N-27 Before acceptance: species, urgency, coarse area, problem summary only. After: animals named in the request (OR-02).
- N-28 Requires verified status (BR-22, FR-VET-07); only one accept succeeds — concurrent accepts return a state conflict (UC-06 alternate 4a).
- N-29 Farmer may cancel with reason at any time before `COMPLETED` or `CANCELLED`; structural edits lock at `ACCEPTED`.
- N-30 A veterinarian may not close a case the farmer has not confirmed where the SRS requires confirmation, and may not modify the request's farmer/animal identity.
- N-31 Grant rows are written by `SYSTEM` with an expiry; administrators cannot create grants manually (OR-08).

### 4.7 `DiseaseReport` (`D-08`, veterinarian-authored, unverified)

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | — N-32 | C (verified, own case, mandatory area) | — | — | — |
| Read | — (sees nothing; escalation flag only) | R (own authored) | R (jurisdiction) N-33 | R (jurisdiction) | — |
| Update | — | U-withdraw/append (own, while `SUBMITTED`) | U-review-notes | U-review-notes | — |
| Status transitions (`SUBMITTED`→`UNDER_REVIEW`→`CLARIFICATION_REQUESTED`/`ACCEPTED_FOR_ASSESSMENT`/`REJECTED`→`CLOSED`) | — | — | A N-34 | A N-34 | — |
| Publish | — | — | — N-35 | — (publication happens on `OutbreakAnnouncement`, not the report) | — |
| Archive / delete | — | AR (own) | AR (juris) | AR | Retention only |

- N-32 LP-10: farmers never author reports; the farmer-originated path is `HealthRecord` + `AssistanceRequest` escalation (US-FARMER-13).
- N-33 Report visible only to reviewers/officers whose jurisdiction covers the report's area (OR-03, BR-08); out-of-scope requests are denied and audited.
- N-34 Illegal transitions (for example `CLOSED`→`UNDER_REVIEW`) are refused by the state machine; reasons are mandatory for `REJECTED` (US-AUTH-03).
- N-35 A reviewer holds no `P` anywhere (LP-04). An officer's publication right is exercised only on `OutbreakAnnouncement` (§4.8) — a report can never be mutated into an announcement (ARC-4).

### 4.8 `OutbreakAnnouncement`

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator | Automated principal |
|---|---|---|---|---|---|---|
| Create draft | — | — | C-draft N-36 | C-draft | — N-37 |
| Read | R (`PUBLISHED` + own area) | R (`PUBLISHED` + own area) | R (jurisdiction, all statuses) | R | — |
| Update | — | — | U (own draft) | U (draft/edit) | — |
| Approve (internal review of a draft) | — | — | A N-38 | A | — |
| **Publish** | — | — | **—** | **P (human session only)** | — |
| Update published version | — | — | — | P-update N-39 | — |
| Expire | — | — | — | P-expire / `S` at date N-40 | — |
| Withdraw | — | — | — | P-withdraw N-41 | — |
| Archive / delete | — | — | — | AR | Retention only |

- N-36 Drafts are visible only to the Authority role until published (charter §4.3-2).
- N-37 LP-07/ARC-3: no management command, scheduler, rule, pattern summary, report count or assistant path may hold `P`; the publish view requires an authenticated human officer session, rejects service-account tokens, and is audited (SC-02, EXCL-01).
- N-38 Whether a reviewer's approval is a mandatory precondition for an officer's publication (four-eyes) is a Phase 0 decision (§7 Q-A); default here: **required for publication of a new announcement, not for expiry**.
- N-39 Each published update is a new audited version; prior versions remain retrievable.
- N-40 `EXPIRED` may be applied by `SYSTEM` at the stored review/expiry date (UTC, TD-14) and is audited as a system event; it is not a human act and cannot introduce new official claims (text change requires an officer).
- N-41 Withdrawal requires a reason and immediately changes the label on every surface (US-FARMER-16, US-AUTH-08).

### 4.9 `Notification`

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | — N-42 | — | — (triggered by publication) | — (triggered) | — |
| Read | R (own) | R (own) | R (own) | R (own) | R* delivery-failure aggregates |
| Update (`read`/`dismissed`) | U (own) | U | U | U | — |
| Archive / delete | AR (own, older than retention) | AR | AR | AR | Retention only |
| Approve / publish | — | — | — | — | — |

- N-42 Rows are written by `SYSTEM` (reminder job, status-change, publication fan-out). No human authors another user's notification; an officer's publication triggers recipients via the targeting rule in OR-07 (area intersection), which is asserted in tests rather than hand-entered (US-AUTH-06).
- MVP delivery is pull-based in-app retrieval; SMS/email/FCC-style push are out of scope (EXCL-08, EXCL-09).

### 4.10 `AuditEvent` (`D-10`)

| Operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| Create | — (all writes are `SYSTEM`/model-layer, in-transaction) | — | — | — | — |
| Read | — | R* (own actions, if surfaced) | R (jurisdiction, read-only) | R (jurisdiction) | R (security/admin scope: auth events, role changes, permission denials, sync/admin ops — not clinical payload) N-43 |
| Update / Delete / Archive | — | — | — | — | — N-44 |
| Export | — | — | R (jurisdiction) | R | R (admin scope) |

- N-43 Audit content is itself sensitive (`RESTRICTED`, SRS §4.1). Administrator audit read covers security and administration events; a row whose payload is clinical change detail is rendered as change-summary metadata only, never full clinical text (LP-02, BR-34, POL-AUDIT-06).
- N-44 Append-only (LP-09): no role may mutate or remove audit rows; retention/expiry is a documented offline procedure, and password, token or secret values may never appear in any field (CON-06).

### 4.11 Reference, sync, flag and assistant objects

| Object / operation | Farmer | Veterinarian | Auth. reviewer | Auth. officer | Administrator |
|---|---|---|---|---|---|
| `Area` R | R | R | R (own jurisdiction for filtering) | R | R |
| `Area` C/U/AR | — | — | — | — | C U AR |
| `VaccinationProtocol` R | R | R | R | R | R |
| `VaccinationProtocol` C/U/AR | — | — | — | — | C U AR N-45 |
| `SyncItem` / idempotency ledger R | — | — | — | — | R* operational |
| `SyncItem` C/U | S (on replay) | — | — | — | — N-46 |
| Suspicious-activity flag R | — | — | R (jurisdiction) | R | R N-47 |
| Flag A (dismiss with reason) | — | — | A (with reason) | A | A |
| Assistant KB entry R | R (via answers) | R | R | R | R |
| KB entry C/U/AR (curation) | — | — | — (source approval comment) | — | C U AR N-48 |
| Assistant question/answer log R | R (own) | R (own) | R* (aggregate, no farm identifiers) | R* | R* operational |
| Assistant write operations | — | — | — | — | — N-49 |

- N-45 Protocol edits are audited and must not retroactively rewrite completed vaccination records.
- N-46 `SyncItem` (`D-20`) is server bookkeeping for replayed client mutations; humans do not edit it (SC-04 depends on its integrity).
- N-47 Flags are signals for human review only (D-11, TD-07); no automatic enforcement action follows from a flag.
- N-48 KB curation touches published general-information sources only, never user data (BR-25).
- N-49 The assistant endpoint exposes no create/update/delete capability on business objects; this is enforced by using a read-only service boundary (ARC-8) and asserted by test `TC-SEC-*` (SC-05).

## 5. Operation-availability summary (approve / publish / archive)

| Operation | Holders | Scope | Notes |
|---|---|---|---|
| Approve (verify vet) | Administrator | Global | Audited old/new values |
| Approve (report status) | Authority reviewer + officer | Jurisdiction | State-machine constrained, reason mandatory where stated |
| Approve (draft before publication) | Authority reviewer (§7 Q-A) | Jurisdiction | Four-eyes default |
| Publish / update / withdraw | Authority **officer only**, human session | Jurisdiction | LP-07, ARC-3, EXCL-01 |
| Archive | Owner role per object; Administrator for retention | Own / jurisdiction / retention | Never destroys history (FR-HEALTH-09, FR-REPORT-12) |
| Hard delete | Nobody by UI; retention procedure only | Documented, audited | DOC-REQ-007 retention policy |
| Role/jurisdiction change | Administrator | Global | Self-change forbidden (OR-10) |

## 6. Object-level rules (`OR-<NN>`)

| ID | Rule | Enforcement point (provisional `EP-<NN>`) | Test ID |
|---|---|---|---|
| OR-01 | **Owner-only**: `Farm`, `Animal`, `HealthRecord`, `VaccinationRecord`, `TreatmentRecord`, `VeterinaryVisit`, `AssistanceRequest` are visible and mutable only to the farmer who owns the chain farm → animal → record. | Object permission class + `queryset` filtering by `owner=request.user` on every viewset; ownership re-checked on nested writes | `TC-PERM-01..06` |
| OR-02 | **Vet-clinical-access-only**: a veterinarian reads or writes an animal's records only through one of the three bases in BR-02 — (a) an `AssistanceRequest` naming that animal that is `ACCEPTED`/`IN_PROGRESS`, (b) a `VeterinaryVisit` they recorded on that animal, or (c) an explicit farmer authorisation under FR-FARM-08 that has not been revoked. No other animal is visible to them. | `VetClinicalAccessPermission` queryset OR-filter of the three conditions; `AccessGrant` rows created on accept or on grant, expired on close/cancel/revocation | `TC-PERM-07..10`, AC-N-02, AC-N-17 |
| OR-03 | **Jurisdiction-scoped**: `DiseaseReport`, announcements, pattern summaries and audit views are limited to areas in `AuthorityProfile.jurisdictions`. | Area-set filter in the manager/queryset; denial logged | `TC-PERM-11..14` |
| OR-04 | **Soft-delete visibility**: archived rows are excluded from default listings and included only by an explicit, permitted `?archived=true` query. | Default manager filter + permission gate on the parameter | `TC-PERM-15` |
| OR-05 | **Published-only visibility**: `OutbreakAnnouncement` is readable outside the Authority role only when `status = published` and the reader's area intersects the affected areas. | Read-only serializer + status/area filter | `TC-PERM-16..18` |
| OR-06 | **Append-only audit**: no write endpoint exists for `AuditEvent`; ORM-level protection and permission denial. | Model-level guards, no write viewset | `TC-PERM-19`, `TC-SEC-*` |
| OR-07 | **Notification targeting**: a recipient row is created only for users whose area set intersects the announcement's affected areas. | Fan-out service with asserted recipient rule | `TC-PERM-20` |
| OR-08 | **Time-bounded grant expiry**: access grants carry an expiry (`UTC`, TD-14) and are revoked on close, cancellation, lapse or account deactivation; a revocation test must show the previously granted read now denied. | Expiry evaluated at request time + scheduled sweep | `TC-PERM-21..23` |
| OR-09 | **Automation is read-only**: scheduler, rule engine, pattern views and the assistant may write only their own artefacts (`Notification` fan-out rows, `AuditEvent`, flags, KB answers) and no business object. | Separate service interfaces, no request-scoped human token reuse | `TC-SEC-*` (LP-07/LP-08 assertions) |
| OR-10 | **No self-elevation**: role, sub-role, jurisdiction, verification and account-status fields are absent from every self-service serializer and rejected if posted. | Serializer field exclusion + allowlist input validation | `TC-PERM-24..26` |
| OR-11 | **Purpose-limited authority read**: underlying clinical data is readable by Authority only for the rows referenced by a report under active review, and the read is audited. | Permission check on review state + audit on read | `TC-PERM-27` |
| OR-12 | **Denial logging**: an object-scoped denial (identifier present) writes an access-control `AuditEvent`; unauthenticated collection requests are rate-limited instead of logged per row. | Middleware/permission deny hook | `TC-SEC-*` |
| OR-13 | **Consent-gated precise location**: precise coordinates are readable only by the counterparty of an accepted request with recorded consent; every other path returns the coarse area only. | Consent flag checked in serializer field selection | `TC-PRIV-01..04` |
| OR-14 | **Cross-farmer blackout**: no path allows farmer A to see farmer B's data, including search, aggregations and announcement context (LP-13). | Aggregation endpoints expose area-level values only | `TC-PERM-28` |

## 7. Decisions this matrix needs before Phase 2 (permission model freeze)

| ID | Question | Default adopted here | Owner |
|---|---|---|---|
| Q-A | Is reviewer approval mandatory before an officer publishes (four-eyes)? | Yes for new announcements; no for expiry/withdrawal by the publishing officer | Both + supervisor |
| Q-B | May an unverified veterinarian accept assistance requests (DOC-REQ-008 Q1)? | No | Member A |
| Q-C | Depth of Authority's clinical read (`D-19` scope) — report-referenced rows only, or full animal history? | Report-referenced rows only (OR-11) | Both |
| Q-D | May farmers create `TreatmentRecord` rows (N-26)? | Yes, labelled farmer-administered, never overriding vet prescription | Member A |
| Q-E | Should the Administrator be able to read the full audit text including clinical change summaries for support purposes? | Metadata-only view; full text requires an authority reader (N-43) | Both + supervisor |
| Q-F | Is `Assistant` question log retention on by default? | On, without farm identifiers, per retention policy | Member A |

## 8. Negative-test expectations (minimum set)

These are the assertions that make SC-02 verifiable. Full procedure in DOC-REQ-014 §5.

| ID | Scenario | Expected result |
|---|---|---|
| AC-N-01 | Farmer B retrieves Farmer A's farm/animal/health record by guessed UUID | 403/404, no data leaked, denial audited |
| AC-N-02 | Veterinarian reads an animal with no active grant | Deny, audited |
| AC-N-03 | Veterinarian writes a clinical record after the case closed and grant expired | Deny |
| AC-N-04 | Farmer posts a `DiseaseReport` creation request | Deny (LP-10) |
| AC-N-05 | Farmer posts `role=ADMIN` in a profile-update payload | Field rejected (OR-10) |
| AC-N-06 | Authority reviewer calls the publish endpoint | Deny (LP-04) |
| AC-N-07 | Administrator calls the `HealthRecord` collection endpoint | Deny (LP-02) |
| AC-N-08 | Officer from jurisdiction X reads a report in jurisdiction Y | Deny + audited |
| AC-N-09 | Draft announcement requested by a farmer session | Not present / deny (OR-05) |
| AC-N-10 | Any API token or management command attempts publication as a non-human principal | Deny by design, assertion in test (LP-07) |
| AC-N-11 | Authenticated user attempts to update or delete an `AuditEvent` | No endpoint exists; direct ORM attempt blocked (OR-06) |
| AC-N-12 | Unauthenticated request to any protected collection | 401 with the standard error envelope |
| AC-N-13 | Logged-out session replayed against protected endpoint after refresh blacklist | 401 |
| AC-N-14 | Client-side hidden admin action reached directly via URL | Deny — proves hiding is not the control |
| AC-N-15 | Farmer searches "nearby reports" to infer another farm | Only official/aggregate data returned (OR-14) |
| AC-N-16 | Location read with consent withdrawn | Coarse area only (OR-13) |
| AC-N-17 | Veterinarian reads an animal whose FR-FARM-08 grant the farmer has revoked (and no open request or visit exists) | Deny, audited; grant revocation takes effect on the next request (OR-02, BR-02/BR-02a) |

## 9. Non-goals of this matrix

- It does not define API paths or payload shapes (DOC-REQ-005, TD-04).
- It does not define the threat model, rate limits or lockout thresholds (DOC-REQ-006, TD-07).
- It does not define retention durations or export rights (DOC-REQ-007).
- It does not replace the ERD; cardinalities that determine ownership are in DOC-REQ-004.
