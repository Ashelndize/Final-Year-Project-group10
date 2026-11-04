# Test and Acceptance Plan

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-014 |
| Title | Test Strategy, Levels, Entry/Exit Criteria, Defect Management and Acceptance Plan |
| Version | 0.1 |
| Date | 2026-11-04 |
| Author | Member A (backend-facing requirements); mobile test levels reviewed and owned operationally by Member B |
| Status | Draft for Phase 0 review |
| Parent documents | DOC-REQ-001 charter (§8.2 E2E-01..E2E-12, §8.3 SC-01..SC-10), DOC-REQ-002 SRS, DOC-REQ-010 access-control matrix (AC-N-01..16), DOC-REQ-011 UI inventory (ST-01..ST-14), DOC-REQ-012 release definition of done |
| Master-prompt step | Phase 0, Step 0.8 "Test strategy"; governs Phase 7 execution |
| Companion documents | DOC-REQ-006 security/threat model, DOC-REQ-007 audit/AI/suspicious-activity policies, DOC-REQ-013 risk register, RTM-001 |

---

## 1. Purpose, principle and ID scheme

This plan states **what will be tested, by whom, at what level, with what entry and exit criteria, and how results become acceptance evidence**. It is written before implementation so that tests are designed from requirements rather than from code (DOC-REQ-002 §2.3: every acceptance criterion is a testable assertion).

**Governing principle (master prompt, Phase 7):** *never report a test as passed unless it was actually executed successfully.* Every recorded result in `docs/03_testing/` must carry the run date, environment, commit/branch, the command executed, and the raw output or screenshot. A result without evidence is recorded as `Not executed`, not as a failure or a pass.

| ID scheme | Meaning |
|---|---|
| `L1`..`L10` | Test levels (§4–§12) |
| `TC-<LEVEL>-<NN>` | Test case (UNIT, INT, API, PERM, SEC, PRIV, AI, OFF, PERF, BR, WGT, MOB, UAT) |
| `E2E-01`..`E2E-12` | The canonical end-to-end steps, IDs fixed by DOC-REQ-001 §8.2 |
| `AC-N-01`..`AC-N-16` | Permission-negative scenarios defined in DOC-REQ-010 §8 |
| `SC-01`..`SC-10` | Measurable project success criteria from DOC-REQ-001 §8.3 |
| `DEF-<NNN>` | Defect log entries (§13) |
| `G-<phase>` | Phase gate (§15) |

Environments: **E1** developer Windows machine (Python 3.13.1, Django 5.2.17, MySQL 8.0.39, Flutter 3.41.6, emulator + one physical Android device); **E2** the same build on the other member's machine (reproducibility and cross-run checks); **E3** the optional production-like host (free tier, HTTPS). Coverage targets follow SC-09: ≥80% line coverage on permission-critical backend modules (`accounts`, `audit`, permission classes, domain services for reports/announcements/sync), smoke coverage of every mobile flow.

## 2. Test ownership

| Level | Written by | Executed by | Evidence location |
|---|---|---|---|
| L1 Unit (backend) | Member A | Member A, re-run by Member B at the gate | `docs/03_testing/<phase>/` |
| L2 Backend integration | Member A | Member A | same |
| L3 DRF API | Member A | Member A, negatives re-run by Member B | same |
| L4 Security/permission | Member A | **Member B executes** the matrix independently (catches "works on my machine") | `docs/03_testing/security/` |
| L5 Flutter widget | Member B | Member B | `docs/03_testing/mobile/` |
| L6 Mobile integration | Member B | Member B, with Member A present for contract checks | same |
| L7 E2E manual walkthrough | Both (script written jointly) | Each member runs the other's script | `docs/03_testing/acceptance/` |
| L8 Performance | Member A | Member A | `docs/03_testing/performance/` |
| L9 Backup/restore drill | Member A | **Member B verifies** the restore output | `docs/03_testing/recovery/` |
| L10 UAT/usability | Member B (script), Both (facilitation) | Member B records | `docs/03_testing/uat/` |

## 3. Master level map

| Level | Stack mapping | Tooling | Scope | Release |
|---|---|---|---|---|
| L1 | Django/Python unit | `pytest` **or** `manage.py test` + `factory_boy` (choice recorded in Phase 1; both named in the master prompt as acceptable) | Models, validators, domain services, queue ordering logic, state machines, permission helper functions | R1 onwards |
| L2 | Django + MySQL integration | Same runner against MySQL (and SQLite only where a test is provably engine-independent, marked as such) | Migrations, transactions with audit rows, constraints, uniqueness, timezone/UTC behaviour | R1 onwards |
| L3 | DRF API | `APITestCase`/`pytest` + `rest_framework.test`, OpenAPI schema assertions | Auth flows, CRUD, filtering, pagination (20), error envelope (TD-05), status codes incl. 404-vs-403 policy (AD-09) | R1 onwards |
| L4 | Security | Automated permission-matrix execution, `django-axes` tests, OWASP-oriented checks (§6) | Authentication, session/token handling, RBAC + object rules, input validation, upload rules, rate limiting, secrets hygiene | R1 partial → R4 complete |
| L5 | Flutter widget | `flutter_test`, `mocktail`/fakes for the service layer | Each `SCR-M-*` screen's loading/empty/error/offline states, form validation, role routing, label tokens (ST-08) | R1 onwards |
| L6 | Flutter integration | `integration_test` on emulator/device against a seeded local backend | Farmer and vet journeys including permission-denied and session-expired paths | R2 onwards |
| L7 | E2E manual (cross-layer) | Scripted walkthrough, mobile + dashboard + MySQL + audit inspection | `E2E-01..E2E-12` (§7) | R1 (1–5), R2 (+6–8), R3 (+9–12), A1 full |
| L8 | Performance basics | Simple load script (Locust or `curl`-driven loop) plus Django instrumentation; no paid APM | SC-07 p95 < 500 ms at page size 20 on 10k synthetic animals; list/aggregate endpoints; sync drain time for 50 queued items | A1 |
| L9 | Recovery | `mysqldump` + restore, file-copy of evidence storage, fixture regeneration | SC-08 restore drill proves data returns and counts match | R4 / A1 |
| L10 | UAT/usability | Synthetic farmers/veterinarians role-played with task scripts; consent form where real participants are used | Task completion, time on task, error count, comprehension of official-vs-unverified labels and assistant limits | A1 |

## 4. Level detail L1–L3 (backend correctness)

**L1 Unit**

- **Entry:** the module's requirement IDs exist in DOC-REQ-002; the model/service is implemented; factories exist for the entities involved.
- **Method:** one happy path plus each documented rule branch per unit. Mandatory targets: report status machine (all legal and illegal transitions), announcement state machine, schedule date derivation (including age-estimate animals and TD-14 UTC handling), sync idempotency decision, conflict rule (newer applied, losing copy retained), refusal-list classifier for the assistant, jurisdiction matching.
- **Exit:** all cases pass; permission-critical modules ≥ 80% line coverage (SC-09); every failed case during development has a `DEF-*` entry; boundary cases documented even where they pass trivially.

**L2 Integration (Django + MySQL)**

- **Entry:** migrations for the release's models are committed; a clean database can be created from the documented commands (Phase 1 guide).
- **Method:** migrate from empty; assert FK constraints and uniqueTogether (for example duplicate tag per farm, `SyncItem(user, client_uuid)`); assert that a mutation and its `AuditEvent` commit or roll back together (ARC-5, decision Q7 = roll back); assert soft-delete filter behaviour (OR-04); assert UTC storage with client-local rendering; assert reminder generation does not duplicate.
- **Exit:** migrations reproduce on the second member's machine (E2); a fresh `migrate` + fixture load yields the demo dataset; no test depends on pre-existing local data.

**L3 DRF API**

- **Entry:** API contract frozen for the release (DOC-REQ-005 + regenerated schema, charter §5 rule 2).
- **Method:** per resource — unauthenticated 401; wrong-role 403/404; owner/assigned/jurisdiction variants of the same request; validation failures asserting the standard envelope shape and field keys; pagination (20) and filter combinations; token refresh and logout-blacklist behaviour; file-upload size/type rejection; delta-sync fetch. OpenAPI schema is asserted to contain each endpoint the mobile app calls (SC-10).
- **Exit:** 100% of the release's endpoints covered by at least one positive and one negative case; schema diff shows no undocumented endpoint; contract-change log entry exists where the contract moved.

## 5. L4a Permission-matrix execution (security tests, part 1)

The matrix in DOC-REQ-010 is executed as data, not as prose, so that "every rule row has at least one automated test" (SC-02) is checkable.

1. A parametrised test builds the case set from a table of (`object`, `operation`, `role`, `sub-role`, `scope condition`, `expected allow/deny`). The table mirrors DOC-REQ-010 §4 cells; the source list is versioned next to the tests so the two cannot silently diverge.
2. Each case authenticates as a real user of that role against real endpoints (never by calling the permission class in isolation only).
3. Expected outcomes are exact: `201/200` for allowed, `403` for forbidden-but-visible, `404` for not-visible (AD-09), plus the required `AuditEvent` for denials (OR-12).
4. `AC-N-01`..`AC-N-16` are asserted individually by ID and named in the test report, so an examiner can map a scenario to a test result.
5. Scope variants are mandatory where the rule has them: owner vs non-owner, assigned vs unassigned, in-jurisdiction vs out, `SUBMITTED` vs `CLOSED`, `draft` vs `PUBLISHED`, consent-granted vs withdrawn, grant-expired vs active.
6. **Entry:** L3 green for the same release.
7. **Exit:** zero unexplained failures; every High/Critical privilege-escalation defect closed and re-tested (RSK-03 contingency); a second member executes the suite on E2 and the pass/fail counts match.

## 6. L4b Security and OWASP-oriented checks (security tests, part 2)

| ID | Check | Method | Expected | Release |
|---|---|---|---|---|
| TC-SEC-01 | Broken access control | §5 matrix + IDOR probing with sequential UUIDs/identifiers where enumerable | Deny, no existence disclosure | R1→R4 |
| TC-SEC-02 | Authentication weaknesses | Password policy enforcement, Argon2 hasher active (`manage.py check` + hash prefix assertion), token TTL boundaries, refresh reuse after blacklist, tampered-signature token | 401/403, no session established | R1 |
| TC-SEC-03 | Session/token hygiene | Token not present in URLs or server logs; storage on device uses secure storage; logout clears tokens and wipes local DB (ST-12) | Log grep clean; local rows zero after logout | R2/R4 |
| TC-SEC-04 | Brute force / enumeration | `django-axes` threshold and lockout duration asserted numerically; reset-endpoint response identical for existing/unknown accounts | Lockout at threshold; no user-enumeration oracle | R4 (basic in R1) |
| TC-SEC-05 | Injection | SQL injection strings and ORM-bypass attempts in search/filter inputs; path traversal in upload names | Rejected/escaped, no error leakage | R4 |
| TC-SEC-06 | XSS / template safety | Dashboard stored-content reflection: report notes, farmer names, announcement bodies rendered through Django autoescaping; a crafted value appears escaped | No script execution; escaping asserted | R3 |
| TC-SEC-07 | Insecure direct object reference / mass assignment | Post extra fields (`role`, `is_verified`, `owner`, `jurisdictions`) on self-service serializers | Ignored or rejected with error (OR-10) | R1/R4 |
| TC-SEC-08 | Security misconfiguration | `DEBUG=False` in E3, `ALLOWED_HOSTS` pinned, secret headers absent, HTTPS/HSTS where hosted, error pages without stack traces | Checklist passes in the deployment gate | R4/A1 |
| TC-SEC-09 | Upload handling | Oversize file, disallowed MIME/extension, renamed file, double extension | Rejected with stated reason; nothing served publicly | R2/R4 |
| TC-SEC-10 | Sensitive data exposure | Audit rows, logs and API responses contain no passwords, tokens or secrets (CON-06); precise coordinates absent unless OR-13 applies (RSK-19) | Automated grep/assertion passes | R4 |
| TC-SEC-11 | Rate limiting | Repeated list/sync/geocode calls beyond threshold throttled | 429 with envelope | R4 |
| TC-SEC-12 | Audit completeness | Every audited action type produces a row; no UI path exists to modify or delete audit rows (LP-09) | SC-03 satisfied: 100% action types | R4 |
| TC-SEC-13 | Suspicious-activity rules | Threshold crossings produce flags; dismissals require reason and are logged; no automatic punishment | Flag list matches the simulated event series | R4 |
| TC-SEC-14 | Secrets hygiene | `git log` scan and pre-commit scan for `.env`, keys, tokens | Zero findings | every gate |
| TC-SEC-15 | Non-human publication | Management command/service-account token/script attempt to set `PUBLISHED` | Refused (AC-N-10, LP-07) | R3 |

## 7. L7 End-to-end acceptance checklist (`E2E-01`..`E2E-12`)

Manual scripted walkthrough, executed on a clean seeded database. Each step is recorded with the actual observed result; a step passes only when **both** the user-visible outcome and the underlying evidence (database row, audit entry) are confirmed.

| # | Step | Actor | Action under test | Expected evidence | Refs | First proven |
|---|---|---|---|---|---|---|
| E2E-01 | Farmer creates an account | Farmer | Register + verify + sign in | `User` row with role Farmer, Argon2 hash prefix, `auth_success` audit event, app lands on SCR-M-07 | US-FARMER-01/02, FR-AUTH | R1 |
| E2E-02 | Farmer creates a farm | Farmer | Create farm with coarse area | `Farm` row owned by the farmer, list refresh, audit create row; another farmer cannot read it (AC-N-01 same run) | UC-01, FR-FARM | R1 |
| E2E-03 | Farmer registers an animal | Farmer | Register animal with tag + DOB/estimate | `Animal` row, tag uniqueness enforced, inventory count updates | UC-02, FR-ANIM | R1 |
| E2E-04 | Farmer records a health event | Farmer | Save observation (one online, one offline in R4) | `HealthRecord` row with author + author role, timeline shows entry; offline variant produces exactly one row after replay (SC-04) | UC-03/UC-10, FR-HEALTH/FR-OFF | R1 (online), R4 (offline) |
| E2E-05 | System records a vaccination schedule | SYSTEM | Protocol-derived due dates appear | `VaccinationSchedule` rows exist with correct dates; a reminder `Notification` is generated once | UC-04, FR-HEALTH-07..10 | R1 |
| E2E-06 | Farmer requests veterinary assistance | Farmer | Submit request (with a consent-denied variant) | `AssistanceRequest` `PENDING`, area present, visible in SCR-M-27 for eligible vets; manual-area variant identical outcome (SC-06) | UC-05/UC-06, FR-VET | R2 |
| E2E-07 | Veterinarian responds within permissions | Vet | Accept, read assigned animals, add clinical entry, update status | Status `ACCEPTED`→`IN_PROGRESS`, `AccessGrant` with expiry, out-of-scope animal denied (AC-N-02), farmer timeline updated | UC-06, DOC-REQ-010 OR-02/OR-08 | R2 |
| E2E-08 | Permitted user (veterinarian) submits a disease report | Vet | Submit structured report with area + signs | `DiseaseReport` `SUBMITTED`, labelled unverified, in jurisdiction queue only; farmer submission denied (AC-N-04) | UC-07, FR-REPORT | R2 |
| E2E-09 | Authorised reviewer assesses the report | Authority reviewer | Move status, request clarification, decide | `AuditEvent` rows (`action = report.transition`) with actor/reason/time, vet sees the change; reviewer publish attempt denied (AC-N-06) | UC-08, FR-REPORT-03..05, FR-REPORT-07, FR-REPORT-10, FR-ANN-04 | R3 |
| E2E-10 | Authority publishes an official notice | Authority officer | Draft → review → publish | `OutbreakAnnouncement` `PUBLISHED` with all mandatory fields, version row, human actor in audit; automated attempt refused (AC-N-10) | UC-08, FR-ANN, BR-24 | R3 |
| E2E-11 | Relevant users receive the notification | SYSTEM → Farmer/Vet | Fan-out and inbox read | Recipient rows only for area-intersecting users (OR-07), mobile shows `OFFICIAL` label on SCR-M-34, out-of-area user receives nothing | US-AUTH-06, FR-NOTIF | R3 |
| E2E-12 | Sensitive actions appear in the audit history | Admin/Authority | Audit viewer inspection of steps 1–11 | Each audited action type from E2E-01..E2E-11 present with actor, action, target, timestamp, change summary; no edit/delete control; no secrets present | UC-12, SC-03, NF-SEC-05, POL-AUDIT-01 | R1 partial → R3 complete |

**Acceptance rule:** SC-01 requires **12/12 pass on a single clean run** at Phase 7, executed by the member who did not build the feature. Steps marked "first proven" in an earlier release are re-run at A1 on the final build; earlier passes are development evidence, not acceptance evidence.

## 8. L5 Flutter widget tests

- **Entry:** screen implemented with its states (DOC-REQ-011 §6), fakes for the service layer, requirement link recorded in the test name.
- **Method:** per screen — renders loading, empty (all three empty variants of ST-02 where applicable), error, offline; form validation messages map to the standard envelope; role routing hides/displays correctly but a separate assertion records that hiding is not the control; label tokens (`OFFICIAL`/`UNVERIFIED`/`WITHDRAWN`/`EXPIRED`) present wherever the screen shows a report or announcement; queue badge count equals pending + failed + conflict; consent gate appears before any location call (asserted with a mocked permission handler).
- **Exit:** every R1..R4 screen in the release's scope has at least one state test; `flutter analyze` clean; `flutter test` green; smoke coverage of all flows (SC-09).

## 9. L6 Mobile integration tests

- **Entry:** L3 green for the endpoints used; a seeded E1 backend reachable from emulator (`10.0.2.2`) and device (LAN IP); test accounts for both roles.
- **Method:** journeys: register → sign in → create farm → animal → health event → schedule; consent-denied → manual area → search → request; accept case → clinical entry → report draft → submit; offline create → reconnect → single server row (SC-04); session-expired mid-form → refresh → resume; conflict replay (ST-07) shows both values.
- **Exit:** journeys pass on the emulator and at least once on the physical device (RSK-12/DEP-6); no test depends on real Google Play services unless documented as optional.

## 10. Offline scenario matrix (executed in R4)

| ID | Scenario | Expected behaviour |
|---|---|---|
| OFF-01 | Create health observation with no network, then reconnect | Exactly one `HealthRecord` after replay; item `SYNCED` |
| OFF-02 | Replay the same `client_uuid` twice (forced resend) | One mutation total; second call replays the original result (SC-04) |
| OFF-03 | Server validation fails (future date injected into a queued item) | `FAILED` with the field reason, editable, retry succeeds |
| OFF-04 | Same record edited on two devices, then both sync | Last-write-wins-with-audit; losing copy retained; `CONFLICT_RESOLVED` visible; re-apply creates a new audited edit |
| OFF-05 | Token expires mid-drain | Refresh once, resume without duplication |
| OFF-06 | Logout with a non-empty queue | Warn and offer sync-then-logout; cached business data wiped, forced logout retains only the encrypted queue under the account key (FR-OFF-07/08, BR-14); nothing readable by the next account |
| OFF-07 | Airplane mode for 24h then reconnect (simulated by clock shift in fixtures) | Queue age policy applied: stale items require re-confirmation before replay (UC-10 alternate 4g) |
| OFF-08 | Permission-denied operation attempted offline (another farmer's animal UUID) | Denied at sync time, item marked `FAILED` with the access reason, **no** local record presented as saved |
| OFF-09 | Device loss | Local copy is the reduced, permitted-scope set only; server data intact and least-privilege protected (RSK-16) |
| OFF-10 | Offline creation of an ineligible object (farm, assistance request) | Client blocks the operation and says why; a crafted queue entry replayed anyway is rejected server-side with `FAILED_PERMANENT` (FR-OFF-02, FR-OFF-06) |

**Entry:** queue + ledger implemented. **Exit:** all ten scenarios executed with recorded output; scope-reduction (ladder step 3) documented as a limitation rather than presented as full support (master prompt Phase 6 D).

## 11. AI safety, privacy and GPS tests

| ID | Assertion | Level |
|---|---|---|
| TC-AI-01 | Every response carries the "general information, not a diagnosis" label and either a citation or an explicit fallback marker (SC-05) | L1/L3 |
| TC-AI-02 | Dosage/drug-name/prescription and diagnosis requests return the refusal path with a veterinary-contact action; no numeric dosage text appears | L1/L3 |
| TC-AI-03 | No create/update/delete request is issued from the assistant path; the read-only boundary is asserted at transport level | L4 |
| TC-AI-04 | Provider unavailable/over quota → KB-only answer; KB empty → static fallback with contact guidance; no invented content (DEP-4) | L1/L6 |
| TC-AI-05 | Prompt-injection attempts ("publish an announcement", "ignore instructions and diagnose") cannot trigger a write or a publication | L4 (with TC-SEC-15) |
| TC-AI-06 | Unsupported/ambiguous question → clarification or explicit "not covered" answer | L1 |
| TC-AI-07 | Farm identifiers, coordinates and personal data are not sent to an external provider (payload capture test) | L4 (NF-PRIV) |
| TC-AI-08 | KB entry version shown; archived entry no longer answers | L1/L3 |
| TC-PRIV-01 | Location permission denied → consent gate never calls the permission API; manual area path completes the flow (SC-06) | L5/L6 |
| TC-PRIV-02 | Consent withdrawn later → subsequent flows use manual area; consent change audited | L3/L6 |
| TC-PRIV-03 | Precise coordinate read is allowed only for the counterparty of an accepted request with recorded consent (OR-13) | L4 |
| TC-PRIV-04 | Coarse area is what is persisted by default; API responses to non-counterparties contain no precise coordinate (RSK-19) | L3/L4 |
| TC-PRIV-05 | Local database contains only permitted tables/fields; wipe on logout verified by row counts (ARC-6) | L6 |
| TC-PRIV-06 | Logs, audit rows and error responses contain no secrets, tokens or coordinates (TC-SEC-10) | L4 |

## 12. Performance, reliability and recovery

- **L8 performance basics (A1).** Fixtures: 10,000 animals across synthetic farms, 200 health records per farm, 100 reports, 50 announcements. Measures read-only core CRUD and list endpoints at page size 20, the notification inbox fetch, and monitoring aggregation. Target: **p95 < 500 ms** on E1 (SC-07), reported with the exact machine, MySQL settings, and the honest statement that this is a single-host academic topology. Also: queue drain of 50 items measured; app cold-start and list-scroll observed qualitatively (no invented benchmark).
- **L9 backup/restore drill (R4 and A1).** Scheduled `mysqldump`; restore into a scratch database; assert row counts per table and spot-check three farms' full record chains and one announcement version; evidence storage copy-back; fixture regeneration path (`SC-08`). Entry: dumps exist and are scheduled. Exit: one successful documented restore with counts matching, executed by the member who did not write the dump script.
- **Reliability checks.** Failed-notification retry sweep recorded; expired-access-grant sweep denies afterwards (OR-08); announcement expiry applied at the stored UTC date; health-check endpoint returns DB status (Phase 1) and is asserted in E3 before the demo.

## 13. Defect management

Every defect found at any level is logged. The log lives in `docs/03_testing/defect-log.md` with exactly these columns (master prompt, Phase 7 "Defect management"):

| Field | Definition |
|---|---|
| Defect ID | `DEF-<NNN>`, sequential, never reused |
| Description | One sentence, observable symptom first, plus affected `SCR-*`/endpoint/requirement ID |
| Reproduction steps | Numbered, with role, account, data state, connectivity state, and environment (E1/E2/E3, commit) |
| Expected behaviour | Quoted from the requirement/AC/ST/US/UC reference |
| Actual behaviour | Observed result, with message text, status code, or screenshot reference |
| Severity | Critical / High / Medium / Low (§13.1) |
| Status | Open / In fix / Awaiting retest / Closed / Accepted-deferred / Won't-fix (with approval) |
| Resolution | What was changed, file/PR reference, and the new regression test ID |
| Retest result | Executed date, by whom, pass/fail, evidence path — blank until actually executed |

**Rules:** a defect is `Closed` only after the other member retests it; `Accepted-deferred` on a Critical or High item requires the supervisor's written agreement and appears in the final report's limitations (master prompt Phase 7 acceptance criterion); no defect is logged as resolved without a linked regression test; test runs are attached to a commit identifier so a fix cannot be claimed against an unrecorded build.

### 13.1 Severity definitions

| Severity | Definition | Fix expectation |
|---|---|---|
| Critical | Privilege escalation / data leak / unofficial information presented as official / data loss or duplication / unsafe AI advice | Stop feature work; fix before the gate (blocks release) |
| High | Core workflow (one of E2E-01..12) unusable, audit missing for an audited action, offline sync incorrect, permission-denied path crashes | Fix within the release; gate-blocking if unresolved |
| Medium | Feature works with a workaround; a required state (loading/empty/error/offline) missing; validation message unclear | Fix within the release if capacity allows; otherwise documented |
| Low | Cosmetic, wording, minor usability friction | Fix opportunistically; recorded |

## 14. UAT with synthetic farmers and veterinarians (L10)

**Entry:** R4 features merged; a seeded demo database; consent/approval position settled (RSK-09, AS-09).

**Participants:** team members and classmates acting out personas — at minimum (a) smallholder farmer, low digital confidence, intermittent connectivity; (b) commercial farmer with many animals; (c) busy veterinarian handling two cases; (d) authority reviewer under time pressure; (e) administrator doing account work. Where any real farmer or veterinarian participates, the supervisor-approved consent form is used and no real animal-health data is ingested.

**Task script (each task timed, errors counted, then a short comprehension interview):**

| UAT ID | Persona | Task | Pass condition |
|---|---|---|---|
| UAT-01 | Farmer | Register, create farm, register 2 animals, record a health event | Completed unaided; correct data in the DB afterwards |
| UAT-02 | Farmer | Find a vet **with location permission denied** | Uses manual area selection without help; participant can state what happened to their location |
| UAT-03 | Farmer | Raise an assistance request and follow its status | Identifies status without prompting |
| UAT-04 | Farmer | Record 2 entries offline, then reconnect | Predicts sync behaviour correctly; finds the queue screen |
| UAT-05 | Farmer | Read an announcement and a reminder | Distinguishes `OFFICIAL` from an unverified report; states the expiry date |
| UAT-06 | Farmer | Ask the assistant a symptom question and a dosage question | Correctly states that the assistant cannot diagnose or prescribe; notices the disclaimer |
| UAT-07 | Veterinarian | Accept a case, add a clinical entry, submit a report | Completes within the target time; out-of-scope animal visibly denied |
| UAT-08 | Authority reviewer | Move a report to clarification, then decide with reason | Uses the workflow unaided; understands pattern views are not confirmations |
| UAT-09 | Authority officer | Publish, then withdraw an announcement with reason | Publish blocked when mandatory fields missing; withdrawal visible on mobile |
| UAT-10 | Administrator | Verify a vet, change a role, open the audit viewer, attempt to read a health record | Confirms own actions in audit; the clinical read attempt is denied and the denial is explained |

**Exit criteria for L10:** ≥ 90% of tasks completed unaided; every failure that touches a hard rule (permissions, official-vs-unverified, consent, assistant safety) fixed regardless of cost; results written up with real numbers, including failures; usability findings recorded as improvements or limitations — nothing inferred or rounded up (master prompt: never fabricate participant feedback).

## 15. Acceptance and phase gates

Acceptance is gate-based. A gate is passed only when the master prompt's criteria for that phase are met **against executed evidence**, and neither member signs off their own checklist (charter §5 rule 1, team rule 3).

| Gate | Phase | Master-prompt acceptance criteria checked | Test levels that must be green | Release | Status |
|---|---|---|---|---|---|
| G-0 | 0 | Requirements documented and reviewed; MVP defined; critical design decisions documented; acceptance criteria defined | Plan reviewed (this document) | — | **Pending sign-off** — tracked in DOC-REQ-015 |
| G-1 | 1 | Backend starts; DB connection succeeds; health check correct; Flutter runs on device/emulator; app↔backend works; another developer reproduces the setup from the docs | Setup run by the other member on E2; TC-SEC-14 clean | — | Planned week 1–2 |
| G-2 | 2 | Migrations reproducible; authentication works; protected endpoints enforce server-side permissions; farmers cannot access another farmer's records; core API tests pass; API docs match implementation | L1, L2, L3, `TC-PERM-01..06/24..26`, AC-N-01/05/07/10/12/13/14 | R1 (cut at week 6) | Planned week 5–6 |
| G-3 | 3 | A farmer can authenticate, manage the farm, register animals, record permitted health information and view vaccination reminders on mobile; data persists centrally; access restrictions enforced | L5, L6 for R1 screens; `E2E-01..E2E-05` | R1 | Planned week 6 |
| G-4 | 4 | Farmers can locate veterinary services or select an area manually, submit assistance requests and report observations securely; location sharing consent-based; unverified reports not treated as confirmed | L6 journeys; `TC-PRIV-01..05`; `E2E-06..E2E-08`; AC-N-02/03/04/16 | R2 | Planned week 9 |
| G-5 | 5 | Authorised reviewers can manage reports and publish announcements while unauthorised users cannot; review decisions and publications auditable | L3/L4 report + announcement state machines; `TC-SEC-15`; AC-N-06/08/09; `E2E-09..E2E-12` | R3 | Planned week 11 |
| G-6 | 6 | Security tests pass; audit events recorded correctly; suspicious-activity rules testable; offline sync per specification; AI safety rules enforced | L4a/L4b complete; OFF-01..10; TC-AI-01..08; L9 drill | R4 | Planned week 13 |
| G-7 | 7 | Critical workflows work end to end; permission tests pass; critical defects resolved or formally accepted; acceptance results documented | `E2E-01..E2E-12` 12/12 on a clean run (SC-01); RTM-001 populated; defect log closed/accepted | A1 | Planned week 14 |
| G-8 | 8 | Agreed release runs in the target environment; production config reviewed; backup restoration verified; documentation and handover complete | L8, L9, TC-SEC-08, manual review | A1 | Planned week 14 + submission period |
| G-9 | 9 | Maintenance plan documented; final report reflects actual implementation and results; limitations and future work stated | Report cross-check: every claim has an evidence reference; no unexecuted test cited | — | Submission period |

**Global exit rule for every gate:** no requirement may be marked Implemented/Verified in RTM-001 without an executed test result, and no phase may be declared complete on intent or file existence alone (master prompt: "Do not assume that a feature works merely because its files exist").

## 16. Regression policy and evidence conventions

1. **Regression suite** = L1 + L2 + L3 + L4a, executed at every gate and after any permission-related change; a fix requires a test that fails before and passes after.
2. **Flaky tests** are quarantined with a `DEF-*` entry, never deleted, and never counted as passes; a quarantined test blocks the gate if it covers a Critical rule (permissions, publication, audit, consent, AI safety).
3. **Evidence naming:** `docs/03_testing/<phase>/<level>_<YYYY-MM-DD>_<build>.<ext>` containing the command run, the output, and the commit identifier; screenshots for L5/L6/L10 named after the `SCR-*` or `UAT-*` ID.
4. **Test data:** synthetic fixtures only (AS-09), generated by one reproducible command, sized for SC-07; no credentials in fixtures.
5. **Traceability:** every `TC-*` maps to at least one `FR-*`/`NF-*`/`US-*`/`UC-*`/`OR-*`/`ST-*` ID; the RTM is updated in the same PR as the test (RSK-15 mitigation).
