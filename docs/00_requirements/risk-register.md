# Risk Register

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-013 |
| Title | Project and Technical Risk Register |
| Version | 0.1 |
| Date | 2026-11-04 |
| Author | Both members (charter §9 top risks `RSK-01`..`RSK-10` carried forward unchanged; `RSK-11`..`RSK-24` added here; Member A owns technical/security entries, Member B owns schedule/demo entries, jointly reviewed) |
| Status | Draft for Phase 0 review |
| Parent documents | DOC-REQ-001 charter (§7 assumptions/constraints/dependencies, §9 summary, §10 TD list), DOC-REQ-002 SRS (ARC/NF), DOC-REQ-012 release plan (§6 timeline, §7 de-scope ladder) |
| Companion documents | DOC-REQ-006 security/threat model, DOC-REQ-007 audit/AI policies, DOC-REQ-014 test plan |
| Master-prompt step | Phase 0, Step 0.2 "risks" and Step 0.8 "risk register" |

---

## 1. Scoring model and rules

**Likelihood (L)**: 1 rare (<10%), 2 unlikely (10–30%), 3 possible (30–50%), 4 likely (50–70%), 5 near-certain (>70%), assessed over the remaining project window.
**Impact (I)**: 1 negligible, 2 minor, 3 moderate (rework inside a gate), 4 major (gate slips or a Must requirement is at risk), 5 severe (acceptance failure, data breach, or academic penalty).
**Score = L × I.** Bands: **1–6 Low**, **8–12 Medium**, **15–25 High**. A score of 20–25 is treated as a stop condition that must be actively mitigated before the next gate.

Rules:

1. Every risk has one named owner (Member A backend, Member B mobile, Both) — "Both" only where the response genuinely requires both skill sets.
2. A risk scored High must have a mitigation **in progress** at the next gate, not planned.
3. Contingency is the fallback if the mitigation fails, and is written as an executable action.
4. Reviewed at every phase gate (weeks 6, 9, 11, 13, 14) and on any trigger event; closed risks are marked `Closed` with the date and evidence, never deleted, so the register shows the project's actual history.
5. `RSK-01`..`RSK-10` keep the identifiers, wording and intent of DOC-REQ-001 §9 so the two documents cannot diverge; the charter stays the summary view and this document the scored, owned view.

**Category codes**: TEC technical, ACD academic, SCH schedule, SEC security/privacy, DAT data, PRT partner/external.

## 2. Register

| ID | Risk | Cat. | L | I | Score | Band | Mitigation (in progress) | Owner | Contingency if it happens |
|---|---|---|---|---|---|---|---|---|---|
| RSK-01 | Scope exceeds two-person capacity; feature requests creep in after Phase 0 (scope creep) | ACD/SCH | 4 | 4 | 16 | High | MVP-first slicing (DOC-REQ-012 §2); `Must/Should/Could` fixed at sign-off; new requests need supervisor approval + a release target (§9 change control); de-scope ladder pre-agreed (DOC-REQ-012 §7); gate stops at week 6/9/11/13 | Both | Apply the ladder in order; ship R4-lite; state the cut and its reason in the report limitations instead of pretending completion |
| RSK-02 | Library incompatibility with Python 3.13.1 / Django 5.2.17 / MySQL driver / key packages on Windows (AS-10, AS-11) | TEC | 3 | 4 | 12 | Medium | Week-1 verification spike: `pip install`, `manage.py check`, test run, migration against MySQL; pins recorded in `requirements.txt`; documented driver fallback (`mysqlclient` → PyMySQL); minimal dependency list | Member A | Pin a slightly older compatible Django/Python pair with a recorded decision, or switch driver; if `mysqlclient` will not build, standardise on PyMySQL before the contract freeze |
| RSK-03 | Permission bug exposes another user's records (privacy failure, acceptance blocker) | SEC | 3 | 5 | 15 | High | DOC-REQ-010 as the normative matrix; object-permission classes + query-set scoping, default deny; `TC-PERM-*` and the AC-N-01..16 negative suite run in CI/locally at every gate; cross-member review of any permission diff; deny logging (OR-12) | Member A | Treat as Critical defect: stop feature work, fix, re-run the whole permission suite, add a regression test per found hole, document honestly in the security chapter |
| RSK-04 | Map/Nominatim rate limits, policy change or outage breaks vet search (DEP-1) | PRT/TEC | 3 | 3 | 9 | Medium | Provider abstraction (`MapProvider`, AD-07); coarse-area queries cached; per-call throttling; manual area selection is a first-class path (FR-VET-02) not an error path; documented Google Maps fallback if a key exists; Nominatim fair-use terms recorded in Phase 1 (AS-07) | Member B | Demo the manual-area path as the primary route; disable tiles and show the list view; state the provider limitation in the report |
| RSK-05 | Offline conflict causes data loss (TD-09 last-write-wins) | DAT/TEC | 3 | 4 | 12 | Medium | Conflict rule fixed and numeric (newer wins, losing copy retained in `AuditEvent` summary); user-visible `CONFLICT_RESOLVED` state (ST-07) with re-apply action; offline scenario matrix in DOC-REQ-014 §6; idempotency ledger `SyncItem` prevents duplicate mutation | Both | Restrict offline scope to health observations only (ladder step 3); require explicit user confirmation for queue items older than the configured max age |
| RSK-06 | AI assistant gives unsafe advice (dosage, treatment, diagnosis) | SEC/ACD | 2 | 5 | 10 | Medium | KB-only default (AS-08); curated, versioned, cited entries; refusal list for diagnosis/dosage topics; mandatory disclaimer on every answer; no write capability (OR-09); AI safety test suite as a release blocker for R4; source review by Member A + supervisor (DEP-3) | Both | Widen the refusal list, ship without the LLM path entirely (already default), and if curation is not ready, replace the assistant with a static referenced-guidance page and document the reduction |
| RSK-07 | Rumour / fake-news-style misreporting: an unverified report is perceived or shared as a confirmed outbreak | ACD/SEC | 3 | 5 | 15 | High | `DiseaseReport` and `OutbreakAnnouncement` are separate entities, endpoints and surfaces (ARC-4); persistent `UNVERIFIED REPORT` label (ST-08); pattern views worded as signals with no publish control (EXCL-01/EXCL-13); human-only publication with audit (BR-24); no share-to-image of raw reports in the UI; withdrawal path with reason | Both | Immediately withdraw/expiry the notice with a logged reason, publish a corrective official update, and present the incident in the final report as evidence the control worked rather than hiding it |
| RSK-08 | No cooperating veterinary-authority partner available (DEP-3) | PRT/ACD | 3 | 3 | 9 | Medium | Role-play the authority workflow with the supervisor/panel; source KB text from published public-domain veterinary guidance with citations; keep the dashboard workflow realistic and reviewable without real staff | Both | Report as a validation limitation; substitute an expert walkthrough by the supervisor and label evaluation results as simulated-user |
| RSK-09 | Ethics/consent problems in usability testing with real farmers/vets | ACD | 2 | 4 | 8 | Medium | Consent form, synthetic data first (AS-09), no minors, no real animal-health data without approval, supervisor approval before recruiting, right to stop | Both | Run testing on the team and classmates acting out roles; report only task-completion metrics, no personal data |
| RSK-10 | Secrets accidentally committed (DB password, `SECRET_KEY`, LLM key) | SEC | 3 | 4 | 12 | Medium | `.gitignore` for `.env`/local DB; `.env.example` placeholders only (TD-12, CON-06); pre-commit secret scan; no secret values in logs or audit rows; branch protection if hosting allows | Member A | Rotate the credential immediately, purge from history (`filter-repo`) with team consent, record the incident and the rotation in the security chapter |
| RSK-11 | Teammate unavailability (illness, work, other modules, exam clashes) — single points of knowledge | SCH | 4 | 4 | 16 | High | Docs-as-you-go rule (each feature updates its doc section); cross-documentation of setup so the other member can run it (M1 test); weekly handover note in the PR description; each member runs the other's acceptance checklist; no irreversible single-owner module (AD-01 keeps the stack simple) | Both | Re-plan at the next gate using the de-scope ladder; the surviving member takes the Critical-path items only (R1/R2 core, permission tests) and defers R4 features |
| RSK-12 | Flutter/Android SDK and emulator friction: Gradle/AGP version conflicts, long first builds, device-driver problems, plugin AndroidX mismatches | TEC/SCH | 4 | 3 | 12 | Medium | Week-1 toolchain checkpoint with a fixed versions table (Flutter 3.41.6, Android API 26+ target, AGP/Gradle pins recorded once they work); `flutter doctor` output captured as evidence; emulator image chosen once and documented; one physical device confirmed working before R1 features start; avoid plugins that require Google Play services | Member B | Move development to the confirmed physical device only, or a documented emulator image; if Android builds become unworkable, keep the API/dashboard as the demonstrable core and present the mobile build status honestly |
| RSK-13 | MySQL configuration problems on Windows: service not starting, `utf8mb4`/collation mismatches, timezone/UTC handling, reserved words, migration reproducibility (CON-10, TD-11) | TEC | 3 | 3 | 9 | Medium | Week-1 checklist: create dedicated database + least-privilege user, `utf8mb4_innoDB` defaults, `USE_TZ=True` (TD-14), FK constraints verified, migrations from a clean database, mysqldump/restore path tested early rather than in Phase 8 | Member A | Fall back to a containerised MySQL 8.0.39 for development with the same credentials model, documented as an approved environment variant; never silently switch the DBMS for the app |
| RSK-14 | Offline-sync implementation complexity (queue ordering, idempotency, sqflite/SQLCipher plugin behaviour on target API levels, conflict UX) overruns weeks 12–13 (CON-03) | TEC/SCH | 3 | 4 | 12 | Medium | Queue + ledger design fixed before coding (DOC-REQ-009 §7, AD-06); a one-entity vertical slice (health observation only) built first in week 12 to prove the mechanism; Dart unit tests for queue ordering and dedup run without a device; encryption plugin evaluated early and treated as optional (unencrypted reduced copy is an accepted documented fallback) | Member B | Ship the reduced offline scope (ladder step 3), document exactly which operations are offline-capable and which are not, and state it in the test report |
| RSK-15 | Documentation debt: code advances while docs lag, so the required Phase 0/8 artefacts and the final report are incomplete at submission — **direct grade risk** (master prompt general rule 10, Phase 8 required-documentation list) | ACD | 4 | 5 | 20 | High | Every release's definition of done includes documentation (§8 DOC-REQ-012); RTM-001 updated at each gate; docs are merged in the same PR as the feature; the Phase 9 report is assembled from existing sections rather than written at the end (team rule 5); this register and DOC-REQ-015 track all 18 Phase 0 artefacts by path | Both | Freeze features at the week-13 gate and spend week 14 plus the submission period on documentation only; a smaller system with complete documentation scores better than a larger one with gaps |
| RSK-16 | Data loss: untested backups, a bad migration, dropped schema, wiped device with an unsynchronised queue, or accidental `git` destructive operation | DAT/SCH | 2 | 5 | 10 | Medium | Automated `mysqldump` schedule from Phase 1 with a restore drill in R4 (SC-08); migrations reviewed before merge; local queue warns and attempts a final sync before logout wipe (ST-12, Q6); no force-push/`reset --hard` on shared branches; fixtures let a new database be rebuilt in one command | Both | Restore from the most recent verified dump; if unrecoverable, regenerate synthetic fixtures and record the loss window as a test finding, not a hidden incident |
| RSK-17 | Free-tier hosting (Render/Railway) cold starts, sleep, or lack of a free MySQL make the hosted demo slow or unavailable at assessment time (DEP-5, DE-7) | PRT/SCH | 4 | 3 | 12 | Medium | The academic demonstration target is the **local** topology (DOC-REQ-009 §10.1); hosted deployment is supplementary evidence, warmed up with a health-check call before the demo; deployment steps scripted; a LAN-hosted fallback documented | Both | Demo on the local build with the hosted URL offered as an extra; state hosting-tier limits in the deployment guide |
| RSK-18 | External LLM provider cost, quota, outage or policy change (DEP-4) | PRT/TEC | 3 | 2 | 6 | Low | Assistant must be fully functional without an LLM (AS-08, `ASSISTANT_LLM_ENABLED = false`, TD-10); provider sits behind `AssistantProvider`; no paid dependency is required for acceptance (CON-08); cost/limits documented before enabling | Both | Remain on KB-only mode permanently and describe the LLM integration as an optional, tested-but-unrelied-upon path |
| RSK-19 | Location privacy breach: precise coordinates collected or retained beyond consent, or exposed in logs/exports/API responses | SEC | 2 | 5 | 10 | Medium | Consent gate before any location request (BR-06); coarse area is the default persisted value (`D-15`); precise coordinate released only per OR-13; consent grant/withdrawal audited; `TC-PRIV-*` tests including "permission denied" and "withdrawn consent" runs; no coordinates in logs (CON-06) | Both | Disable precise-location code path, purge the affected field via an authorised retention operation with an audit row, and report the incident and the fix in the privacy chapter |
| RSK-20 | Demo-day failure: device not ready, emulator dead, database empty, API unreachable, presenter sick | SCH | 3 | 4 | 12 | Medium | Rehearsed script (DOC-REQ-014 §7 E2E list) run on the assessment hardware at least twice before submission; seeded demo database committed as a fixture; pre-recorded walkthrough video as backup; both members able to present either half (RSK-11 mitigation doubles here) | Both | Switch to the recorded walkthrough and the dashboard on the laptop; keep the API walkthrough live where possible so the audit trail is genuinely produced |
| RSK-21 | Supervisor or institutional requirements change mid-semester (report format, evaluation weighting, added deliverable) | ACD | 2 | 4 | 8 | Medium | Written requirement record from each supervision meeting; explicit Phase 0 sign-off baseline; every requirement change enters the change-control table in DOC-REQ-012 §9 before work starts | Both | Re-plan at the next gate and use the ladder; do not absorb changes by silently working longer hours |
| RSK-22 | Synthetic data produces a thin evaluation: results cannot support the "improves recordkeeping/accessibility" claims | ACD/DAT | 3 | 3 | 9 | Medium | Objectives restated as measurable system properties (SC-01..SC-10) rather than real-world outcome claims; task-completion timing and error counts captured during the usability walkthrough (RSK-09 approved path); fixtures sized realistically (10k animals for SC-07) | Both | Report the study as a technical/demonstrative evaluation with the limitation stated, and avoid any invented user-outcome finding |
| RSK-23 | Key-person knowledge asymmetry: only Member A understands the backend, only Member B the mobile app (compounds RSK-11) | SCH/TEC | 3 | 4 | 12 | Medium | API contract freeze reviewed by both (charter §5 rule 2); each member runs the other's acceptance checklist at gates; one cross-stack task per release (Member B adds a serializer test; Member A fixes a mobile UI state) | Both | Surviving member works the Critical path only; escalate to the supervisor early rather than hiding the gap |
| RSK-24 | Repository process failure: merge conflicts in shared files, work overwritten, `main` broken, commit history that does not evidence both members' contributions | TEC/ACD | 2 | 4 | 8 | Medium | Branch-per-feature with the other member reviewing; shared files (`settings`, `requirements.txt`, CI) changed only by PR (team rule 2); path-based ownership (`backend/`+`dashboard/` vs `mobile/`) keeps diffs separable; no direct pushes to `main` once CI exists | Both | Restore from the last green commit, re-apply lost work from the PR branch, and record the process fix in the setup guide |

## 3. Top risks by score (response priority)

| Rank | ID | Score | Band | Primary response owner | Immediate action before the week-6 gate |
|---|---|---|---|---|---|
| 1 | RSK-15 | 20 | High | Both | Documentation-in-the-PR rule adopted; DOC-REQ-015 tracker in use; RTM populated per gate |
| 2 | RSK-01 | 16 | High | Both | Supervisor sign-off of Must/Should/Could list; ladder agreed in writing |
| 3 | RSK-11 | 16 | High | Both | Week-1 cross-install test (each member installs the other's stack from the guide only) |
| 4 | RSK-03 | 15 | High | Member A | Permission-negative test skeleton exists in week 3, not week 14 |
| 5 | RSK-07 | 15 | High | Both | Label tokens (`UNVERIFIED`/`OFFICIAL`) specified in DOC-REQ-011 ST-08 before UI work starts |
| 6 | RSK-12 | 12 | Medium | Member B | `flutter doctor` + emulator + physical-device proof captured in week 1 |
| 7 | RSK-02 | 12 | Medium | Member A | Dependency pin spike completed week 1 with fallback recorded |
| 8 | RSK-14 | 12 | Medium | Member B | One-entity offline slice designed (not built) in Phase 0/1 notes |
| 9 | RSK-10 | 12 | Medium | Member A | Secret scan added to the commit flow in week 1 |
| 10 | RSK-17 | 12 | Medium | Both | Local topology declared the demo target; hosted is optional evidence |
| 11 | RSK-20 | 12 | Medium | Both | Rehearsal dates written into the week-14 plan |
| 12 | RSK-23 | 12 | Medium | Both | One cross-stack task per release scheduled |

## 4. Risk response summary

| Strategy used | Risks addressed |
|---|---|
| Avoid (scope/features never built) | RSK-01, RSK-06 (no diagnosis feature), RSK-07 (no auto-publish), RSK-19 (no precise tracking), RSK-18 (no paid dependency required) |
| Reduce (design/test controls) | RSK-03, RSK-04, RSK-05, RSK-10, RSK-12, RSK-13, RSK-14, RSK-16, RSK-19, RSK-22, RSK-24 |
| Transfer / share | RSK-08, RSK-21 (supervisor holds decision rights), RSK-17 (external host — limits accepted rather than transferred) |
| Accept with contingency (documented, no avoidance cost) | RSK-17 cold starts, RSK-18 provider quota, RSK-09 limited real-user access, RSK-11 residual availability risk |

Residual-risk statement: after the mitigations above, the project still cannot guarantee (a) a live hosted demo independent of free-tier behaviour, (b) real-world outcome evidence beyond simulated-user evaluation, and (c) zero schedule risk in weeks 12–13 where two of the hardest features (offline sync, assistant) sit together. These three are the named reasons the de-scope ladder and the week-6/9/11/13 gates exist.

## 5. External-dependency risks mapped to the charter

| Dependency (DOC-REQ-001 §7.3) | Linked risks | If unavailable |
|---|---|---|
| DEP-1 OSM/Nominatim | RSK-04 | Manual area path + documented Google fallback |
| DEP-3 authority partner | RSK-08, RSK-09 | Supervisor/panel role-play, published guidance for the KB |
| DEP-4 LLM key/quota | RSK-18, RSK-06 | KB-only mode (already the default) |
| DEP-5 HTTPS host | RSK-17 | Local/LAN deployment documented as the demo target |
| DEP-6 test device/emulator | RSK-12, RSK-20 | Confirmed physical device as primary; emulator secondary |
| DEP-7 MySQL 8 availability | RSK-13, RSK-16 | Containerised MySQL variant, fixtures for rebuild |

## 6. Review and escalation procedure

1. At each gate, the outgoing member updates L/I for every open risk and records the change; scores that increase are reported to the supervisor in the gate note.
2. A risk reaching score ≥ 15 with no in-progress mitigation stops new feature work until a mitigation exists (derived from master-prompt rule 20, "request human approval at phase gates").
3. New risks discovered during implementation are added here with the next free `RSK-<NN>`; if they change scope, the DOC-REQ-012 §9 change-control table is used.
4. Security and privacy risks (RSK-03, RSK-07, RSK-10, RSK-19) are additionally reviewed against DOC-REQ-006 and DOC-REQ-007 at the R4 gate.
5. Closed risks keep their row with the closure evidence link, so the register doubles as a project decision history for the final report.
