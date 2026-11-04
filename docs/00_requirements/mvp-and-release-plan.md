# MVP and Release Plan

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-012 |
| Title | MVP Definition, Release Plan, Work Breakdown and 14-Week Timeline |
| Version | 0.1 |
| Date | 2026-11-04 |
| Author | Both members (compiled jointly; Member A owns backend estimates, Member B owns mobile estimates, gate criteria agreed) |
| Status | Draft for Phase 0 review |
| Parent documents | DOC-REQ-001 charter (§4 scope/exclusions, §6 deliverables, §8.1 milestones, §10 TD list), DOC-REQ-002 SRS (priorities), DOC-REQ-008 stories, DOC-REQ-010 permissions, DOC-REQ-011 screens, DOC-REQ-013 risks |
| Master-prompt step | Phase 0, Step 0.8 "WBS, timeline and milestones, MVP" |

---

## 1. Purpose

Define the minimum viable product, the release sequence R1..R4, what is deliberately **not** in each release, the exclusions that never enter the project, the work breakdown that produces each release, and the week-by-week schedule for a two-person team inside one 14-week teaching semester.

**Terminology mapping.** DOC-REQ-001 §4.1 calls its in-scope set "MVP unless stated" and uses milestones `M0`..`M9`; DOC-REQ-002 §2.2 maps MoSCoW priorities onto MVP / Release 2 / Stretch. This document's releases are the delivery vehicles for those: **R1 = MVP (Phases 1–3)**, **R2 (Phase 4)**, **R3 (Phase 5)**, **R4 (Phase 6)**, followed by the acceptance/deployment/report activities of Phases 7–9 which are not a feature release. `Must` requirements land in R1 unless the requirement itself is a Phase 4–6 concern; `Should` items land in R2/R3; `Could` items are stretch and may be dropped without failing acceptance.

**Schedule reconciliation (flagged for the supervisor).** CON-07 in DOC-REQ-001 states "two-person team, one academic year". This plan compresses **feature delivery (Phases 1–6) into 13 weeks and acceptance/deployment into week 14**, on the assumption that the assessment semester is ~14 weeks and that Phases 8–9 documentation/report work continues into the following examination period. If the supervisor confirms a full-year window, weeks 7–13 gains slack and the de-scope ladder (§7) is applied less aggressively. No scope is added if the window is longer; extra time buys testing, documentation quality and risk burn-down.

## 2. MVP definition (R1)

### 2.1 What the MVP must demonstrate

A farmer can install the app on an Android device, register, sign in, register a farm and animals, record health events, see a vaccination schedule with reminders, and have that data persist in MySQL with permissions enforced server-side. A reviewer can prove, by testing, that a second farmer cannot see any of it, and that an administrator cannot read the clinical data.

This is the master prompt's Phase 3 acceptance criterion, and it is the smallest set that satisfies the project's first two specific objectives while leaving the security story demonstrable from day one.

### 2.2 R1 in scope

| Area | Included in R1 | Phase | Story / screen refs | Requirement links (provisional) |
|---|---|---|---|---|
| Environment | Reproducible venv, Django project, MySQL DB + least-privilege user, `.env`/`.env.example`, health-check endpoint, Flutter scaffold, first app→API call, `.gitignore`, setup guide | 1 | — | NF-REL-01, NF-MNT-02 |
| Identity | Custom `User` + role, registration (Farmer/Vet), Argon2 hashing (TD-02), JWT access/refresh + logout blacklist (TD-01), password reset via email, profile update | 2, 3 | US-FARMER-01/02/03/17, US-VET-01, SCR-M-01..05 | FR-AUTH-01..13 |
| RBAC foundation | Role gate + object rules OR-01 (owner-only), OR-05, OR-06, OR-10, OR-12 implemented as `EP-*` classes/query-sets, default deny | 2 | DOC-REQ-010 §6 | FR-AUTH-13..16, NF-SEC-01..02 |
| Core models | `User`/profiles, `Area`, `Farm`, `Animal`, `HealthRecord`, `VaccinationRecord`, `VaccinationSchedule`, `VaccinationProtocol`, `Notification`, `AuditEvent`, `SyncItem` skeleton | 2 | UC-01..UC-04 | DOC-REQ-004 `M-*` |
| Farmer mobile CRUD | Farm create/read/update/archive, animal register/search/filter/list/detail, health record add/list, vaccination record add, schedule + reminders views | 3 | US-FARMER-04..09, SCR-M-07..19 | FR-FARM-01..05, FR-ANIM-01..09, FR-HEALTH-01..13, FR-NOTIF-01..03 |
| Reminder engine (minimal) | Management-command-driven due-dose notifications, pull-based inbox | 2, 3 | US-FARMER-09/16, UC-04 | FR-HEALTH-07..10, FR-NOTIF-01..03, EXCL-09 |
| Audit foundation | `AuditEvent` written in-transaction for auth, farm/animal/health mutations, permission denials | 2 | BR-18, UC-12 | NF-SEC-05, POL-AUDIT-01 |
| API contract | `/api/v1/` ViewSets, serializers + validation, standard error envelope (TD-05), pagination 20, filtering, drf-spectacular OpenAPI published | 2 | CON-09, DOC-REQ-005 | FR-* (all endpoints) |
| Test foundation | Model, permission and API tests; Flutter widget tests for R1 screens; synthetic fixtures | 1–3 | — | DOC-REQ-014 §4 |
| States | Loading/empty/error handling on all R1 screens (ST-01..ST-03, ST-05, ST-06) | 3 | DOC-REQ-011 §6 | NF-USE-01..04 |

### 2.3 R1 explicitly out of scope (deferred, not dropped)

| Deferred item | Target release | Why deferred |
|---|---|---|
| GPS, map, vet directory search | R2 | Phase 4 work; needs consent design and provider spike |
| Manual area fallback (as a tested path) | R2 | Paired with GPS so both are tested together |
| Assistance requests and veterinarian case workflow | R2 | Needs directory + assignment grants (OR-02) |
| Disease reports and review workflow | R2 (submit) / R3 (review) | Report authoring ships with the vet surface |
| Authority dashboard, announcement lifecycle | R3 | Phase 5 |
| Offline queue + sync + conflict UX | R4 | Phase 6; the local store exists in R1 only as cache |
| AI assistant, KB curation, refusal tests | R4 | Phase 6; KB-only fallback design decided in Phase 0 |
| django-axes tuning, suspicious-activity rules, backup drills | R4 | Phase 6/8 hardening |
| Precise-coordinate storage and consent release | R4 (behind opt-in) | R1/R2 persist coarse area only (LP-12) |
| Push transport (shipped), SMS, chat, payments, IoT | Never | EXCL-05, EXCL-08, EXCL-09, EXCL-11, EXCL-04 |

### 2.4 Project-wide exclusions (never in any release)

Carried from DOC-REQ-001 §4.2 with the numbering preserved, plus two additions proposed by this document.

| ID | Exclusion | Status |
|---|---|---|
| EXCL-01 | Automated outbreak confirmation or automated announcement publication | Hard rule (CON-05, ARC-3, BR-24) |
| EXCL-02 | AI diagnosis, prescribing, dosage instructions | Hard rule (BR-25) |
| EXCL-03 | National animal-movement / notifiable-disease statutory integration | Future work |
| EXCL-04 | IoT sensors, RFID gateways, GPS collars, weighbridges, any physical-device integration | Future work |
| EXCL-05 | Payments, marketplace, fee collection | Out |
| EXCL-06 | Multi-tenant SaaS billing / organisation hierarchy | Out |
| EXCL-07 | iOS release build and acceptance | Out (Android is the target) |
| EXCL-08 | SMS/USSD/IVR channels | Out |
| EXCL-09 | FCM/push notifications as a **shipped transport** (delivery is in-app pull, FR-NOTIF-01..06) | Out of every release; FR-NOTIF-07 (Could) is satisfied only by the `NotificationTransport` seam, which ships unimplemented — no Firebase dependency, no push credentials |
| EXCL-10 | Event-sourcing / immutable event store | Replaced by soft history + audit (TD-06) |
| EXCL-11 | Real-time farmer↔vet chat | Out |
| EXCL-12 | Laboratory results and sample chain of custody | Out |
| EXCL-13 | ML epidemiological forecasting | Out — summaries only |
| EXCL-14 | **Web portal for farmers — farmers are mobile-only** | Proposed here; the dashboard exists for Authority/Admin staff only |
| EXCL-15 | **Multi-country / multi-language scope — single-country focus** | Proposed here; area reference data is national-scope only, currency/locale variants out |
| EXCL-16 | Her-production analytics (yield, weight trends, economics) | Proposed here; not in the objectives |

EXCL-14..16 must be added to DOC-REQ-001 §4.2 at Phase 0 sign-off so both documents agree; until then they are provisional and marked here.

## 3. Release plan

| Release | Master-prompt phase | Content | Milestone | Cut week | Demo evidence |
|---|---|---|---|---|---|
| **R1 — MVP** | Phase 1 + 2 + 3 | Environment, auth/RBAC, core models, farmer mobile CRUD, health records, vaccination schedule + reminders, OpenAPI contract, audit foundation, R1 tests | M1, M2, M3 | End of week 6 | E2E steps 1–5 (account → farm → animal → health event → vaccination schedule) run on a device against local MySQL; permission negatives AC-N-01, AC-N-05, AC-N-07 pass |
| **R2 — GPS + veterinary assistance + reporting** | Phase 4 | Consent-gated location, OSM map + Nominatim, manual area fallback, vet directory/search, assistance request workflow with assignment grants, vet clinical entry, veterinarian disease-report submission, notifications for case status | M4 | End of week 9 | E2E steps 6–8; consent-denied manual path works identically (SC-06); AC-N-02/03/04/16 pass |
| **R3 — Authority dashboard + announcements** | Phase 5 | Dashboard login/session/CSRF, review queue + status machine, clarification loop, monitoring summaries (signals only), announcement draft→approve→publish→update→expire→withdraw, targeted notifications, audit viewer, user management, reference data | M5 | End of week 11 | E2E steps 9–12; reviewer-cannot-publish (AC-N-06) and non-human-publish (AC-N-10) denied; jurisdiction isolation (AC-N-08) proven |
| **R4 — Security, offline, AI** | Phase 6 | Hardened permission matrix execution, django-axes + rule flags with review list, full append-only audit coverage, sqflite offline queue with idempotency replay and last-write-wins-with-audit conflict UX, assistant (KB-only default, citations, disclaimer, refusal paths, fallback), KB curation page, backup/retention operations | M6 | End of week 13 | Offline scenario matrix, `TC-PERM-*` suite green, AI safety suite green (SC-03/04/05), restore drill logged (SC-08) |
| **A1 — Acceptance & handover** (not a feature release) | Phase 7 + 8 + 9 | 12-step E2E walkthrough on a clean build, defect burn-down, traceability completion, deployment of the production-like option, manuals, handover package, final report and demo | M7, M8, M9 | Week 14 (+ examination period) | Test report with actual executed results, RTM fully populated, demo script, limitations list |

Release ordering rationale: R1 proves the data and permission spine before any integration risk is taken; R2 is the first release whose failure mode is external (map provider), so it is isolated; R3 is server-rendered staff work that can proceed against R2's data even if R2 slips; R4 (offline + AI) is the highest-complexity, lowest-foundation-risk bundle and is therefore last — and is the release where the de-scope ladder operates (§7).

## 4. Screen-to-release map (from DOC-REQ-011)

| Release | Mobile screens | Dashboard pages |
|---|---|---|
| R1 | SCR-M-01, 02, 03, 04, 05, 07, 08, 09, 10, 11, 12, 13, 14, 15, 17, 18, 19, 33 (reminders only), 39, 43-stub — 20 screens | none |
| R2 | SCR-M-06, 16, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 44 | none |
| R3 | SCR-M-31, 33 (announcements), 34, 35, 40 (consent state) | SCR-D-01..12, 14, 15, 18 |
| R4 | SCR-M-36, 37, 38, 40 (retention summary), 41, 42, 43-full | SCR-D-13, 16, 17 |

R1 has 20 mobile screens and no dashboard: the MVP is deliberately thin, and every screen in it is exercised by E2E steps 1–5.

## 5. Work breakdown structure

Work packages are sized in **person-days (PD)** of focused effort, assuming a two-person team (Member A backend/dashboard, Member B mobile) and joint gates. Estimates are Phase 0 planning figures to be re-planned at each gate, not commitments.

| WP | Work package | Phase | Owner | Est. PD | Produces |
|---|---|---|---|---|---|
| WP-00 | Phase 0 completion, sign-off, repo hygiene (`.gitignore`, `.env.example`) | 0 | Both | 3 | DOC-REQ-008..015, M0 |
| WP-01 | Python/Django/MySQL/Flutter/Android toolchain verification, venv, health-check endpoint | 1 | A | 3 | M1 |
| WP-02 | Flutter scaffold, theme, navigation shell, API service layer, env config | 1 | B | 3 | M1 |
| WP-03 | Models + migrations + MySQL config (`utf8mb4`, least-privilege user), synthetic fixtures | 2 | A | 5 | M2 |
| WP-04 | Auth (JWT, Argon2, reset), RBAC + object permission classes, audit writer | 2 | A | 6 | M2 |
| WP-05 | Core CRUD APIs (farm, animal, health, vaccination, notifications) + validation + error envelope + pagination | 2 | A | 6 | M2 |
| WP-06 | OpenAPI (drf-spectacular) publication + API contract freeze + change log | 2 | A | 2 | M2 gate blocker |
| WP-07 | Backend unit/API/permission tests for R1 scope | 2 | A | 5 | M2 evidence |
| WP-08 | Auth screens + session handling + profile in Flutter | 3 | B | 4 | M3 |
| WP-09 | Farm + animal screens, list/search/filter, forms with validation | 3 | B | 6 | M3 |
| WP-10 | Health/vaccination/schedule/reminder screens + states | 3 | B | 5 | M3 |
| WP-11 | R1 integration walkthrough, widget tests, gate report | 3 | Both | 3 | R1 cut |
| WP-12 | Map/geocoding spike + provider abstraction + consent design decision record | 4 | B | 3 | R2 |
| WP-13 | Vet directory, area reference search, manual fallback API + UI | 4 | A+B | 5 | R2 |
| WP-14 | Assistance request API, status machine, access grants (OR-02/OR-08) | 4 | A | 5 | R2 |
| WP-15 | Assistance UI: request form, status timeline, vet case intake/work view | 4 | B | 6 | R2 |
| WP-16 | Disease report model/API, jurisdiction rules (OR-03), evidence upload rules | 4 | A | 4 | R2 |
| WP-17 | Report form + my-reports screens, escalation confirmation flow | 4 | B | 4 | R2 |
| WP-18 | R2 gate: consent-denied matrix, permission tests, walkthrough | 4 | Both | 2 | R2 cut |
| WP-19 | Dashboard scaffolding: templates, session auth, CSRF, base layout, staff login | 5 | A | 3 | R3 |
| WP-20 | Review queue + review actions + status history | 5 | A | 5 | R3 |
| WP-21 | Monitoring summaries (signals only, framing text) | 5 | A | 2 | R3 |
| WP-22 | Announcement lifecycle: composer, four-eyes approve, publish/update/expire/withdraw, versioning | 5 | A | 6 | R3 |
| WP-23 | Notification targeting fan-out + dispatch summary | 5 | A | 3 | R3 |
| WP-24 | Audit viewer + user management + reference-data pages | 5 | A | 4 | R3 |
| WP-25 | Mobile announcement surfaces (detail, list), report status detail, consent state in settings | 5 | B | 4 | R3 |
| WP-26 | R3 gate: negative publication tests, jurisdiction isolation | 5 | Both | 2 | R3 cut |
| WP-27 | Security hardening pass: rate limiting, input validation audit, secret scan, HTTPS config | 6 | A | 4 | R4 |
| WP-28 | django-axes configuration + explainable rule engine + flags review page | 6 | A | 4 | R4 |
| WP-29 | Offline local store, queue, idempotency keys, replay, conflict UX (ST-07) | 6 | B | 8 | R4 |
| WP-30 | `SyncItem` ledger, replay dedup, conflict rule server-side (TD-09) | 6 | A | 5 | R4 |
| WP-31 | Assistant service, KB seed + retrieval, provider interface, fallback, refusal list | 6 | A | 6 | R4 |
| WP-32 | Assistant chat UI, citations, disclaimer, source viewer, KB curation page | 6 | B+A | 5 | R4 |
| WP-33 | Notification surfaces completed, connection banner, queue screen | 6 | B | 3 | R4 |
| WP-34 | R4 gate: offline matrix, AI safety suite, permission suite re-run | 6 | Both | 3 | R4 cut |
| WP-35 | Phase 7: 12-step E2E, defect log burn-down, RTM completion, performance script, restore drill | 7 | Both | 8 | A1 |
| WP-36 | Phase 8: production-like deployment, backups, manuals, handover package | 8 | Both | 6 | A1 |
| WP-37 | Phase 9: final report chapters, slides, demo script, limitations | 9 | Both | 8 | M9 |

Totals: ≈ 152 person-days of effort across 14 weeks. Capacity ≈ 2 members × 5 days × 14 weeks = 140 available days **before** meetings, lectures, and other modules. The plan is therefore already over-committed on paper, which is the reason for §7's ladder rather than added scope; WP-12, WP-06 and WP-07 are the early warning items — if the geocoding spike or the contract freeze slips, the ladder is applied at the week 9 gate.

## 6. Timeline (14 weeks, two-person team)

| Week | Member A (backend/dashboard) | Member B (mobile) | Gate / output |
|---|---|---|---|
| 1 | WP-00 sign-off, WP-01 toolchain, MySQL db + user, health check | WP-00 review, WP-02 Flutter scaffold, emulator | **M1** environment reproducible (each member installs from the other's guide) |
| 2 | WP-03 models/migrations, WP-04 auth start | WP-02 API service layer, navigation shell, theme | — |
| 3 | WP-04 RBAC + permission classes + audit writer | WP-08 auth screens, session handling | — |
| 4 | WP-05 core CRUD APIs, WP-06 OpenAPI + **contract freeze** | WP-09 farm + animal screens against the frozen contract | Contract freeze blocks mobile API work (charter §8.1) |
| 5 | WP-05 health/vaccination/notifications APIs, WP-07 backend tests | WP-10 health/vaccination/schedule/reminders screens, states | — |
| 6 | WP-11 joint integration + fixes | WP-11 widget tests + walkthrough | **M2/M3 gate, R1 cut (MVP demo).** Buffer used if consumed in weeks 2–5 |
| 7 | WP-13 directory/search API, WP-14 assistance API start | WP-12 geocoding/consent spike, WP-15 request form | — |
| 8 | WP-14 grants + status machine, WP-16 report API | WP-13/15 area selection, map + list, case intake | — |
| 9 | WP-16 evidence + jurisdiction rules | WP-17 report screens, escalation flow, WP-18 tests | **M4 gate, R2 cut** (ladder decision point) |
| 10 | WP-19 dashboard shell, WP-20 review queue + actions, WP-21 | WP-25 announcement surfaces, consent-state settings, report status screens | — |
| 11 | WP-22 announcement lifecycle, WP-23 fan-out, WP-24 audit/user pages | WP-25 completion + dashboard UI review support | **M5 gate, R3 cut** |
| 12 | WP-27 hardening, WP-28 axes + rules, WP-30 sync ledger | WP-29 offline queue + sync + conflict UX | — |
| 13 | WP-31 assistant + KB, WP-32 curation page | WP-32 chat UI, WP-33 banner/queue screens, WP-34 tests | **M6 gate, R4 cut** |
| 14 | WP-35 E2E + defect burn-down + restore drill, WP-36 deploy prep | WP-35 Flutter/integration/E2E support, WP-36 APK build + manuals | **M7 acceptance; M8 deployment evidence** |
| after week 14 | WP-37 report chapters (backend/testing), maintenance plan | WP-37 report chapters (mobile/UX), demo script, slides | **M9 final report, demo, handover** |

Assumptions behind the schedule: ~5 working days per member per week available for the project, minus university commitments; weeks 6, 9, 11 and 13 end on a gate, and a failed gate stops the next phase from starting (master prompt rule 20). Only week 6 carries a declared buffer; everything else is fully consumed — which is stated plainly rather than presented as comfortable.

## 7. De-scope ladder (applied in this order when a week is lost)

| Step | Action | Consequence accepted |
|---|---|---|
| 1 | Drop `Could` items: assistant chat history browsing, KB-curation UI polish, dashboard printable export | SC-05 still provable with KB-only answers |
| 2 | Reduce the assistant to **KB-only with no external LLM integration** (already the default, AS-08/DEP-4) and drop the provider-interface demo | Saves ~4 PD; documented in limitations |
| 3 | Reduce offline scope to **health observations only** (no offline animal creation, no offline reports) | FR-OFF partially met; explicitly reported, not claimed (master prompt Phase 6 D: "do not claim that all features work offline") |
| 4 | Replace the map widget with a list-only vet search over areas (no tiles), keeping consent + manual fallback behaviour | Loses the "GPS-based" visual element; keeps the privacy workflow |
| 5 | Shrink announcement versioning to update-in-place plus audited history rows (no side-by-side compare UI) | Saves ~2 PD |
| 6 | Freeze R4 features at the week-12 status and spend weeks 13–14 on acceptance quality | R4 shipped as "R4-lite" with honest documentation |
| Never | Do **not** de-scope: server-side permission enforcement, human-only publication, audit on sensitive actions, consent-based location with a manual path, AI no-diagnosis rule, or the 12-step E2E | These are the project's hard rules (CON-04, CON-05, CON-11) |

## 8. Definition of done (per release)

A release is cut only when all of the following are true and evidenced:

1. Its scope table (§2.2 / §3) items are implemented — or the gap is recorded as a limitation with the reason.
2. Its gate acceptance criteria from the master prompt are checked against **actual executed** evidence (test output, screenshots, walkthrough notes) in `docs/03_testing/` — never asserted from intent.
3. Permission-negative tests for that release's objects pass (DOC-REQ-010 §8 subset).
4. Every screen in the release has loading/empty/error/offline states implemented (DOC-REQ-011 §6).
5. OpenAPI schema regenerated and matching (MVP+ releases), with the changelog entry if the contract moved (charter §5 rule 2).
6. RTM-001 rows for the release's requirement links filled with real test IDs and results.
7. Defects at severity Critical/High are closed or formally accepted by the supervisor with rationale.
8. No secrets in the repo (secret scan clean), `.env.example` updated if configuration changed.
9. The other member has executed the acceptance checklist (cross-run rule in `team-work-division.md`).
10. Demo artefacts for the release (script, device build, seeded synthetic data) committed or archived.

## 9. Change control

| Situation | Required action |
|---|---|
| New feature request mid-semester | Written into DOC-REQ-002/008 with a priority and release target, then approved by the supervisor before implementation. No silent additions |
| API contract change | Both members sign off; DOC-REQ-005 changelog + regenerated schema (charter §5 rule 2) |
| Permission change | DOC-REQ-010 row updated **first**, then code, then the `TC-PERM-*` test; the matrix is the contract |
| Scope cut | Apply §7 ladder, record which step was used and why, note it in the final report's limitations |
| Schedule slip > 1 week | Re-plan at the next gate, do not add hours to the estimate silently |
| New dependency | Justification note (master prompt Phase 1) + supervisor approval + risk-register entry if it adds availability/cost risk |

## 10. Success criteria inherited for this plan

| Source criterion | Release where it becomes provable | Test vehicle |
|---|---|---|
| SC-01 (12/12 E2E) | A1, steps 1–5 from R1, 6–8 from R2, 9–12 from R3 | DOC-REQ-014 §7 checklist |
| SC-02 (permission matrix as tests) | R1 partial, R2/R3 extended, R4 complete | `TC-PERM-*` |
| SC-03 (100% audited action types) | R1 core events; R3 review/publish events; R4 complete | audit tests |
| SC-04 (one mutation per idempotency key) | R4 | replay tests |
| SC-05 (AI disclaimer + zero writes) | R4 | assistant safety suite |
| SC-06 (manual path works when permission denied) | R2 | consent-denied matrix |
| SC-07 (p95 < 500 ms at page size 20, 10k animals) | A1 | load script on the dev topology |
| SC-08 (backup + restore drill) | R4/A1 | restore log |
| SC-09 (≥80% coverage on permission-critical modules; smoke on mobile flows) | progressive | coverage reports |
| SC-10 (schema matches endpoints; setup reproducible) | R1 (setup) / every release (schema) | gate checks |

## 11. Risks that specifically threaten this plan

Cross-references to DOC-REQ-013: `RSK-01` scope exceeds capacity, `RSK-11` teammate availability, `RSK-02`/`RSK-12` toolchain and library incompatibility, `RSK-05`/`RSK-14` offline conflict complexity, `RSK-04` map provider, `RSK-06` AI safety, `RSK-15` documentation/grade risk, `RSK-17` free-tier cold starts. The two highest-consequence schedule items are the week-4 API contract freeze (blocks all mobile API work) and the week-12–13 offline bundle; both have named mitigations in DOC-REQ-013 and §7 above.
