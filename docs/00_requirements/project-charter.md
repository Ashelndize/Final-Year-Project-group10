# Project Charter — Smart Livestock Health and Farm Management System

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Full title | Design and Implementation of a Secure Smart Livestock Health and Farm Management System with GPS-Based Veterinary Assistance, AI-Powered Health Information, and Disease Outbreak Monitoring |
| Document ID | DOC-REQ-001 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard), Member B (mobile) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |

---

## 1. Purpose of this document

This charter authorises the project, fixes its scope boundaries, names the stakeholders and their
decision rights, records assumptions/constraints/dependencies/risks, and defines the measurable
criteria by which Phase 0 exit and final project success will be judged. It is the parent document
for `software-requirements-specification.md` (DOC-REQ-002). Where this charter and the SRS conflict,
the SRS governs requirement behaviour and this charter governs scope and governance.

---

## 2. Problem statement

Livestock farmers in the target context typically keep animal identity, treatment and vaccination
information on paper or in memory. The consequences documented in the project README and observed in
the problem description are:

| Problem | Who is harmed | Current cause |
|---|---|---|
| Incomplete or lost animal health history | Farmer, treating veterinarian | Paper records, no per-animal digital identity |
| Missed or untraceable vaccinations | Farmer, herd, disease-control programmes | No schedule or reminder mechanism |
| Difficulty finding an available, competent veterinarian quickly | Farmer | No shared, verified service directory or request channel |
| Delay between field observation of suspected disease and authority awareness | Authority, other farmers | Verbal/phone reporting, no structured report record |
| Rumour and misinformation about outbreaks | Farmers, markets, livestock economy | No channel that clearly separates unverified reports from confirmed official announcements |
| Unauthorised or deniable edits to health records | All parties | No audit trail or role-based access control |
| Poor connectivity in farming areas | Farmer | Existing tools assume continuous internet |

A secure digital platform is required that (a) supports farm and animal recordkeeping, (b) connects
farmers to veterinarians using location information without abusing it, (c) structures disease
reporting into a human-reviewed pipeline, (d) lets an authorised authority publish clearly
identifiable official announcements, and (e) provides safe, cited general health information that is
explicitly not a diagnosis.

---

## 3. Goal and objectives

### 3.1 General goal

To design, implement, test, deploy and evaluate a secure, role-based smart livestock health and farm
management system that demonstrably improves recordkeeping, veterinary accessibility, disease
reporting quality and information security for the target users.

### 3.2 Specific, measurable objectives

| ID | Objective | Success measure (evidence at Phase 7/9) |
|---|---|---|
| OBJ-1 | Mobile farm/animal recordkeeping for farmers | Farmer can complete the 12-step end-to-end workflow (see §8.2) with data persisted in MySQL |
| OBJ-2 | Digital health history with accountability | 100% of health-record create/edit/soft-delete operations produce an `AuditEvent` with actor, action, target, timestamp and change summary |
| OBJ-3 | Vaccination scheduling and reminders | Due-date reminders generated and surfaced in the app; verified by tests and dated demo data |
| OBJ-4 | Location-assisted veterinary search with consent | Nearby-vet search works with granted permission, with manual area entry when permission is denied/unavailable; consent state recorded |
| OBJ-5 | Structured veterinarian-authored disease reporting | Disease reports creatable only by users with the Veterinarian role; enforced server-side and proven by negative tests |
| OBJ-6 | Authority review workflow and official announcements | Status workflow transitions role-gated; only Authority (officer) can publish; draft-by-same-user publication blocked |
| OBJ-7 | Safe, cited AI health information | Every assistant response carries a disclaimer, source/citation metadata or an explicit no-answer fallback; assistant cannot write business data |
| OBJ-8 | Security controls | Access-control matrix implemented as executable tests with zero privilege-escalation failures; failed-login lockout and rule-based flags demonstrated |
| OBJ-9 | Offline entry with safe sync | Offline-recorded health event syncs on reconnect with no duplicate created when the same idempotency key is replayed |
| OBJ-10 | Academic evaluation | Final report chapters traceable to requirements, with real, non-fabricated test results |

### 3.3 Research questions (for the final report)

- RQ1: Does a role-based, audit-backed mobile recordkeeping system measurably improve the
  completeness and traceability of livestock health records compared with the manual baseline?
- RQ2: Can consent-controlled location features improve veterinarian discoverability without
  exposing precise farm coordinates to unauthorised parties?
- RQ3: Does a structured, human-reviewed reporting pipeline keep unverified reports clearly distinct
  from confirmed official announcements, and can that separation be enforced technically?
- RQ4: How effective is a curated, cited, retrieval-only AI assistant at answering general livestock
  health questions safely, compared with an uncited free-form model answer?

---

## 4. Scope

### 4.1 In scope (MVP unless stated)

| Area | In scope |
|---|---|
| Accounts | Self-registration (Farmer, Veterinarian), admin-provisioned Authority and Administrator accounts, Argon2 password hashing, JWT access/refresh with logout blacklisting, password reset, profile management |
| Roles | Farmer, Veterinarian, Authority (reviewer / officer sub-role), System Administrator |
| Farm management | Farm create/read/update/archive, farm area (coarse) + optional precise point behind consent |
| Animal management | Animal registration (species, breed, DOB or age estimate, tag/ID, sex), inventory, search/filter, status change (alive/sold/dead) without hard delete |
| Health | Generic `HealthRecord` events, `VaccinationRecord`, `VaccinationSchedule`, `TreatmentRecord`, `VeterinaryVisit`, change history via audit summaries |
| Veterinary assistance | Vet directory and search, map display (OpenStreetMap tiles + Nominatim), assistance-request workflow with statuses, GPS consent + manual area fallback |
| Disease reporting | Veterinarian-authored structured reports, authority review workflow with recorded decisions and reasons |
| Announcements | Draft → review → publish → update/expire/withdraw lifecycle, affected area, prevention guidance, expiry |
| Notifications | In-app notification centre, reminder and status-change notifications |
| Offline | Locally cached own farms/animals/records, pending-mutation queue with idempotency keys, last-write-wins-with-audit conflict handling |
| AI assistant | Curated versioned internal knowledge base, cited answers, provider abstraction with optional external LLM, KB-only fallback, safety rules |
| Dashboard | Django-template authority dashboard: report review queue, pattern summaries, announcement management, audit viewer, user/permission administration (admin) |
| Security | RBAC + object-level permissions, django-axes lockout, small explainable suspicious-activity rule set (review flags only), append-only audit events, least-privilege DB user, secrets in `.env` |
| Testing | Django unit/API/permission tests, Flutter widget/integration tests, security tests, offline scenario matrix, 12-step E2E walkthrough |
| Deployment | Documented staging/production configuration, HTTPS, backup/restore drill, APK distribution artefact, manuals |

### 4.2 Out of scope (exclusions)

Each exclusion is deliberate and must be re-approved by the supervisor before it is dropped.

| ID | Excluded | Reason |
|---|---|---|
| EXCL-01 | Automated outbreak confirmation or automated announcement publication | Violates the project's critical rule: only authorised humans publish official announcements. AI output, report counts and pattern detection are advisory only |
| EXCL-02 | AI diagnosis, prescribing, or dosage instructions beyond approved KB text | Safety and legal risk; assistant is general-information only |
| EXCL-03 | Integration with a national animal-movement or official notifiable-disease statutory system | No external interface available within project timeframe; documented as future work |
| EXCL-04 | Hardware IoT sensors, RFID gateways, GPS collars, weighbridges | Not part of the software study; ingestion would require vendor contracts |
| EXCL-05 | Payment, marketplace, or fee collection between farmers and veterinarians | Outside objectives; raises regulatory scope |
| EXCL-06 | Multi-tenant SaaS billing / organisation hierarchy | Final-year project scale |
| EXCL-07 | iOS release build | Android is the agreed target; iOS may be built if time permits but is not acceptance-tested |
| EXCL-08 | SMS/USSD channel and IVR voice | Requires paid gateway; documented as future work |
| EXCL-09 | Push notifications via FCM | Stretch goal (post-MVP); MVP delivers in-app pull notifications |
| EXCL-10 | Full event-sourcing / immutable event store | Explicitly replaced by timestamped soft-history + `AuditEvent` change summaries to control complexity |
| EXCL-11 | Real-time chat between farmer and vet | Assistance requests carry status notes only |
| EXCL-12 | Laboratory result management, sample chain-of-custody | Future work |
| EXCL-13 | Machine-learning epidemiological forecasting | Pattern views are count/area summaries, not prediction |

### 4.3 Explicit scope clarifications (guard against ambiguity)

1. "Unverified report" and "confirmed outbreak announcement" are different entities
   (`DiseaseReport` vs `OutbreakAnnouncement`), different API resources, and different UI surfaces.
   A report is never rendered or serialised as an announcement.
2. `OutbreakAnnouncement.status = published` is required before public visibility; a draft is visible
   only to the Authority role.
3. Administrators manage accounts and configuration; they do not receive clinical-data read access by
   default (see BR-05).
4. The Android device holds a reduced local copy only (BR-14, NF-PRIV-*); the server is the source of
   truth.

---

## 5. Stakeholders, responsibilities and decision rights

| Stakeholder | Interest | Responsibility | Decision right |
|---|---|---|---|
| Group 10 — Member A | Grade, working system | Backend (Django/DRF), MySQL, auth/RBAC, audit, authority dashboard, suspicious-activity rules, deployment | Technical decisions inside `backend/`, `dashboard/`; API contract |
| Group 10 — Member B | Grade, working system | Flutter app, navigation/state, GPS+maps, offline queue/sync, AI chat UI, notifications UI, device testing | Technical decisions inside `mobile/` |
| Project Supervisor (academic) | Methodological soundness | Reviews phases, ethics, evidence | Approves/rejects each phase gate; approves scope changes |
| Department / examination panel | Standards | Final assessment | Accepts final report and demo |
| Partner veterinary authority (intended dashboard users) | Operational fit | Validate report/announcement workflow, review KB sources, may supply policy wording | Sign-off on announcement fields and review workflow (if contact is available — see DEP-3) |
| Participating farmers/vets (usability testing) | Usability | Provide feedback under consent | None; feedback only |
| Future maintainers | Continuity | Consume documentation | N/A |

Governance rules (from `team-work-division.md`):

1. Neither member signs off their own phase-gate checklist; each runs the other's acceptance list.
2. API contract changes require both members' sign-off and a changelog entry in DOC-REQ-005 plus a
   regenerated OpenAPI schema.
3. Shared files (`settings`, `requirements.txt`, CI) change only via PR reviewed by the other member.
4. Human approval is required at every phase gate before substantial implementation begins.

---

## 6. Deliverables

| ID | Deliverable | Phase | Owner | Location |
|---|---|---|---|---|
| DEL-01 | Phase 0 requirements set (18 documents) | 0 | A + B | `docs/00_requirements/` |
| DEL-02 | Reproducible environment, `.env.example`, health-check endpoint, Flutter↔API call | 1 | A + B | `backend/`, `mobile/`, `docs/02_setup/` |
| DEL-03 | Migrations, models, JWT auth, RBAC, versioned `/api/v1/` endpoints, OpenAPI schema, backend tests, synthetic fixtures | 2 | A | `backend/` |
| DEL-04 | Farmer mobile app: auth, dashboard, farm/animal CRUD, health records, vaccination reminders | 3 | B | `mobile/` |
| DEL-05 | Vet directory/map, assistance requests, disease reports with jurisdiction rules | 4 | A + B | both |
| DEL-06 | Authority dashboard: review queue, announcement lifecycle, audit viewer | 5 | A | `backend/` (Django templates) |
| DEL-07 | Audit enforcement, django-axes + rules, offline sync, AI assistant with KB and fallback | 6 | A + B | both |
| DEL-08 | Test evidence: unit/API/widget/E2E/security/offline results, defect log, traceability matrix | 7 | A + B | `docs/03_testing/`, `tests/` |
| DEL-09 | Deployment, production config, backup/restore verification, user + admin manuals, handover package | 8 | A + B | `docs/04_deployment/` |
| DEL-10 | Final academic report, slides, demo script, limitations, maintenance plan | 9 | A + B | `docs/05_final_report/` |

---

## 7. Assumptions, constraints, dependencies

### 7.1 Assumptions

| ID | Assumption | Validation |
|---|---|---|
| AS-01 | Users have an Android phone capable of running Flutter 3.41.6 builds (Android 8/API 26+) | Device matrix agreed in Phase 1 |
| AS-02 | Intended real users are literate enough for a text-first UI; icon+label pairs required for low-literacy tolerance | Usability walkthrough in Phase 7 |
| AS-03 | Farm network coverage is intermittent but not permanently absent, so queued sync eventually completes | Offline-first design; sync retry with backoff |
| AS-04 | One `User` holds exactly one role; role changes are administrative events | Enforced by model design + audit |
| AS-05 | A veterinarian's licence/credential can be verified by an administrator out-of-band before the vet is marked verified | Admin workflow, `VeterinarianProfile.is_verified` |
| AS-06 | Veterinary service location data supplied by verified vets is self-reported and is labelled as such | UI label + no "verified location" claim |
| AS-07 | OpenStreetMap tiles and Nominatim usage policy terms are acceptable for a low-volume academic deployment | Terms reviewed and recorded in Phase 1; documented Google Maps fallback exists |
| AS-08 | An external LLM may not be available or funded; the system must be fully functional with the KB-only provider | Default configuration `ASSISTANT_PROVIDER = kb_only`; `ASSISTANT_LLM_ENABLED = false` |
| AS-09 | Synthetic data is used for development and testing; no real farmer health data is ingested without approval | Phase 1/2 fixtures; ethics statement in final report |
| AS-10 | Django 5.2.17 supports Python 3.13.1 and required third-party packages publish compatible releases | Verified in Phase 1 (`pip install`, `manage.py check`, test run) |
| AS-11 | A `mysqlclient` (or documented PyMySQL) driver builds/installs on the Windows Python 3.13.1 environment | Phase 1 task; fallback recorded in RISK-08 |

### 7.2 Constraints

| ID | Constraint | Type |
|---|---|---|
| CON-01 | Stack fixed: Flutter/Dart mobile; Python/Django + Django REST Framework API; MySQL primary database; Django-templates authority dashboard | Mandated |
| CON-02 | Environment pinned: Python 3.13.1, Django 5.2.17, Flutter 3.41.6, MySQL 8.0.39, Windows development hosts | Mandated |
| CON-03 | Offline local storage: Flutter `sqflite` (encrypted variant if it installs cleanly on target API levels) | Mandated |
| CON-04 | Authorisation must be enforced on the backend; client-side checks are convenience only | Security rule |
| CON-05 | Only authorised humans publish official outbreak announcements | Hard rule |
| CON-06 | Secrets never committed; `.env.example` carries placeholders only; least-privilege MySQL app user | Security rule |
| CON-07 | Two-person team, one academic year: scope must fit MVP first | Resource |
| CON-08 | No paid third-party service may be required for acceptance | Budget |
| CON-09 | API versioned under `/api/v1/`, page size 20, consistent error envelope, OpenAPI via drf-spectacular | Technical standard |
| CON-10 | Data at rest in MySQL uses `utf8mb4`/InnoDB; timestamps stored in UTC | Technical standard |
| CON-11 | Precise location is not collected or shared without explicit per-purpose consent | Privacy rule |

### 7.3 Dependencies

| ID | Dependency | Owner | Mitigation if unavailable |
|---|---|---|---|
| DEP-1 | OpenStreetMap tile server + Nominatim availability and usage policy | External | Cache-free manual area search; documented Google Maps fallback with key |
| DEP-2 | Device location permission behaviour (Android 12+ precise/approximate toggle) | Platform | Manual area selection path tested independently |
| DEP-3 | Access to a cooperating veterinary authority reviewer for workflow validation and KB source review | Supervisor / team | Academic panel role-plays authority; KB sources restricted to published public-domain veterinary guidance with citations |
| DEP-4 | Optional external LLM API key/quota | Team | KB-only provider fallback (already mandatory path) |
| DEP-5 | Hosting capable of HTTPS for the deployed API/dashboard | Team | University server or free-tier host; local network deployment documented as fallback |
| DEP-6 | Test Android device/emulator with Google Play services optional | Team | Emulator matrix |
| DEP-7 | MySQL 8.0.39 server on development and deployment hosts | Team | Container or local install; documented setup guide |

---

## 8. Work breakdown, milestones and success criteria

### 8.1 Milestones

| Milestone | Content | Gate evidence |
|---|---|---|
| M0 (Phase 0) | Requirements frozen, MVP defined, critical design decisions documented | `phase-0-exit-checklist.md` signed by both members + supervisor |
| M1 | Reproducible environment, health check, app→API round trip | `docs/02_setup/` guide followed by the other member |
| M2 | Models, auth, RBAC, API, OpenAPI, backend tests green | Migration + permission test reports |
| M3 | Farmer app core flows usable | Manual walkthrough + Flutter tests |
| M4 | GPS assistance + disease reporting | Consent-denied and jurisdiction tests |
| M5 | Dashboard review + publication lifecycle | Negative publication tests pass |
| M6 | Audit, suspicious flags, offline sync, AI assistant | Offline scenario matrix, AI safety suite |
| M7 | Integration + acceptance | 12-step E2E + traceability matrix complete |
| M8 | Deployed + documented | Backup/restore drill evidence, manuals |
| M9 | Final report | Submitted report, slides, demo |

API contract freeze occurs at the end of M2 and blocks M3 mobile work until signed off.

### 8.2 Canonical end-to-end acceptance workflow

Numbered exactly as the master prompt requires; referenced by test IDs `E2E-01…E2E-12`:

1. Farmer creates an account.
2. Farmer creates a farm.
3. Farmer registers an animal.
4. Farmer records a health event.
5. System records a vaccination schedule.
6. Farmer requests veterinary assistance.
7. Veterinarian responds within their permissions.
8. A permitted user (veterinarian) submits a disease report.
9. Authorised reviewer assesses the report.
10. Authorised authority publishes an official notice when justified.
11. Relevant users receive the notification.
12. All sensitive actions appear in the audit history.

### 8.3 Measurable project success criteria

| ID | Criterion | Threshold | Verified by |
|---|---|---|---|
| SC-01 | All 12 E2E steps complete end-to-end on the deployed/localhost staging build | 12/12 pass | E2E walkthrough script |
| SC-02 | Access-control matrix implemented as tests | 0 privilege-escalation failures; every BR row has ≥1 automated test | Backend permission tests |
| SC-03 | Sensitive-operation auditing | 100% of audited action types produce an `AuditEvent` row | Model/API tests |
| SC-04 | Offline sync correctness | Duplicate replay of one idempotency key creates exactly 1 server mutation | Sync tests |
| SC-05 | AI safety | 100% of responses carry disclaimer + source/fallback metadata; 0 write operations from assistant path | AI safety suite |
| SC-06 | Location privacy | With permission denied, every location-dependent feature has a working manual path | Permission-denied tests |
| SC-07 | Performance | p95 read-only API response < 500 ms at page size 20 for core CRUD on 10k synthetic animals | Load script |
| SC-08 | Reliability | Daily backup + one successful restore drill | Restore log |
| SC-09 | Test coverage | ≥80% line coverage for permission-critical backend modules; smoke coverage for all mobile flows | Coverage reports |
| SC-10 | Documentation | OpenAPI schema matches implemented endpoints; setup guide reproducible by a third party | Review |

---

## 9. Risk register summary

Full register with scores and owners is `risk-register.md` (DOC-REQ-013, Member B). Charter-level
top risks:

| ID | Risk | Likelihood | Impact | Response |
|---|---|---|---|---|
| RSK-01 | Scope exceeds two-person capacity | High | High | MVP-first slicing; Stretch items explicitly deferred; phase gates |
| RSK-02 | Library incompatibility with Python 3.13.1 / Django 5.2.17 / MySQL driver on Windows | Medium | High | Phase 1 verification spike; documented driver fallback |
| RSK-03 | Permission bugs expose another user's records | Medium | Critical | Object-level permission classes, negative tests, code review checklist |
| RSK-04 | Map/Nominatim rate limiting or policy change breaks search | Medium | Medium | Manual area fallback, documented Google Maps switch, thin abstraction |
| RSK-05 | Offline conflict data loss | Medium | High | Last-write-wins-with-audit keeps rejected copy; user-visible conflict state |
| RSK-06 | AI assistant gives unsafe advice | Medium | Critical | KB-only default, curated sources, refusal lists, disclaimer, safety tests |
| RSK-07 | Rumour risk: reports mistaken for confirmed outbreaks | Medium | High | Separate entities/labels, no report counts presented as confirmation |
| RSK-08 | No real authority partner available | Medium | Medium | Simulated authority role using published guidance; documented limitation |
| RSK-09 | Ethics/consent issues in usability testing | Low | High | Consent form, synthetic data, no minors, supervisor approval before recruiting |
| RSK-10 | Secrets accidentally committed | Medium | High | `.gitignore`, pre-commit secret scan, `.env.example` placeholders |

---

## 10. Technical decisions recorded at Phase 0

These are fixed decisions for the project; rationale is expanded in the SRS, ERD plan and API docs.

| ID | Decision | Choice | Rationale |
|---|---|---|---|
| TD-01 | Authentication | Django custom `User` model + DRF SimpleJWT (access + refresh), refresh blacklisting on logout via `rest_framework_simplejwt.token_blacklist`; optional `django-allauth` for email verification | Standard, testable, stateless mobile auth with revocable refresh |
| TD-02 | Password hashing | Argon2 via Django's `Argon2PasswordHasher` with the `argon2-cffi` package | Memory-hard, current best practice; no custom KDF |
| TD-03 | Identity model | One `User`, one role; per-role profile objects `FarmerProfile`, `VeterinarianProfile`, `AuthorityProfile` | Single source of identity, role data isolated, easy to audit |
| TD-04 | API style | DRF ViewSets + routers, `/api/v1/` prefix, page size 20, `django-filter`, `drf-spectacular` OpenAPI | Consistency, generated docs for the mobile contract |
| TD-05 | Error contract | `{"error": {"code", "message", "details"}}` for all API failures | Single client-side handling path |
| TD-06 | History | Timestamped soft-history: mutable records + `AuditEvent` change summaries (no event-sourcing system) | Accountability with acceptable complexity |
| TD-07 | Suspicious activity | `django-axes` for failed logins + small custom rule set (e.g. >N health-record edits by one actor in M minutes) feeding a dashboard review list | Explainable, no automatic punishment |
| TD-08 | Maps | OpenStreetMap tiles + Nominatim (no key, free, privacy-friendly) as default; documented fallback to Google Maps if a key is obtained | Cost and privacy constraints; no vendor lock-in via provider abstraction |
| TD-09 | Offline storage | Flutter `sqflite` + pending-sync queue; client-generated UUID idempotency key per mutation; conflict rule last-write-wins-with-audit (rejected copy retained in audit) | Deterministic, testable, no lost evidence |
| TD-10 | AI assistant | Curated, cited, versioned internal knowledge base of reviewed livestock-health sources; optional external LLM behind an abstracted provider interface; mandatory no-LLM fallback answering from the KB only; disclaimer on every answer; no publish capability | Safety, cost independence, auditability |
| TD-11 | Database | MySQL 8.0.39, InnoDB, `utf8mb4`, FK constraints, dedicated least-privilege application DB user | Referential integrity with mandated engine |
| TD-12 | Configuration | `.env` (e.g. `django-environ`-style read at settings import), secrets excluded from Git; `.env.example` placeholders only | Reproducible and secret-safe |
| TD-13 | Dashboard | Django templates inside the same Django project, server-rendered, session-authenticated (CSRF protected), sharing models/permissions with the API | Avoids a second auth stack and duplicated rules |
| TD-14 | Time zone | Store UTC in DB; render local time in clients; `USE_TZ = True` | Unambiguous scheduling, audit ordering and sync comparisons |

Documented correction to source wording: the master prompt's `argon2-cvh` / `django-argon2` spelling is
interpreted as `argon2-cffi` plus Django's built-in Argon2 hasher, which is the supported combination.

---

## 11. Feasibility summary

| Dimension | Assessment |
|---|---|
| Technical | Feasible. All components use mainstream, documented frameworks. Highest technical risk is offline conflict handling and AI safety, both reduced by conservative rules (LWW-with-audit; KB-only default). |
| Operational | Feasible with synthetic + pilot data; real deployment requires authority cooperation (DEP-3) which is treated as optional for validation but desirable. |
| Legal/ethical | Livestock data is not personal health data, but farm coordinates and phone numbers are personal/proprietorial. Requires consent, minimisation, retention limits and a documented privacy policy (DOC-REQ-006 §Privacy and GPS Policy). Usability testing needs institutional consent procedures. |
| Schedule | Two members, nine phases in one academic year. Feasible only under MVP-first scope control; Stretch items are explicitly deferrable. |
| Economic | No mandatory paid services: OSM/Nominatim free within fair use, KB-only assistant avoids LLM cost, free-tier deployment. |

---

## 12. Phase 0 exit criteria for this charter

| # | Criterion | Status |
|---|---|---|
| 1 | Problem statement, general goal and specific measurable objectives present | Drafted (§2, §3) |
| 2 | Scope with explicit exclusions | Drafted (§4) |
| 3 | Stakeholders with decision rights and governance rules | Drafted (§5) |
| 4 | Deliverables mapped to phases and owners | Drafted (§6) |
| 5 | Assumptions, constraints, dependencies, risks recorded | Drafted (§7, §9) |
| 6 | Measurable success criteria with thresholds | Drafted (§8.3) |
| 7 | Fixed technical decisions recorded consistently | Drafted (§10) |
| 8 | Feasibility stated | Drafted (§11) |
| 9 | Reviewed by both members and supervisor | **Pending — Phase 0 gate** |
