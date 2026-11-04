# Phase 0 Exit Checklist

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-015 |
| Title | Phase 0 Exit Checklist and Requirements-Review Sign-off |
| Version | 0.1 |
| Date | 2026-11-04 |
| Author | Both members (Member B compiled the artefact tracker; Member A verified the backend-facing evidence entries) |
| Status | Draft for Phase 0 review |
| Governs | MASTER_PROJECT_PROMPT.md "PHASE 0" (Steps 0.1–0.8 and "Phase 0 deliverables"), DOC-REQ-001 §12 and milestone M0 |
| Companion documents | All documents in §2 below |

---

## 1. Gate rule (binding)

> **No substantial implementation starts until this checklist is complete and signed by Member A, Member B and the project supervisor.**

"Substantial implementation" means any application code beyond what Phase 0 evidence collection requires: no models, no migrations, no endpoints, no screens, no dependencies added to `requirements.txt`/`pubspec.yaml` other than what a Phase 0 spike needs to prove feasibility. Permitted before signature: repository hygiene (`.gitignore`, `.env.example` as placeholders, folder README stubs), documentation, diagram tooling checks, and environment *inspection* (recording installed versions) — not environment *build-out*.

This rule is inherited from the master prompt ("Do not proceed to substantial implementation until the requirements, MVP, critical design decisions, and acceptance criteria have been reviewed"; general rule 20 "Request human approval at phase gates") and from DOC-REQ-001 §5 governance rule 4.

Related governance rules that operate at this gate: neither member signs off their own work — each runs the other's review list (DOC-REQ-001 §5 rule 1, `team-work-division.md` rule 3); requirement changes after signature go through DOC-REQ-012 §9 change control; unresolved items in §5 below are Phase 0 defects, not Phase 1 tasks.

## 2. Phase 0 document register (deliverable tracker)

Status legend: **Drafted — ready for review** = content complete for Phase 0 purposes, awaiting reviewer comment; **Skeleton** = structure present, content deliberately deferred; **Not started** = required and missing; **N/A in Phase 0** = belongs to a later phase, listed here so it cannot be forgotten.

| # | Deliverable | File path | Doc ID | Author per header | Status |
|---|---|---|---|---|---|
| 1 | Project charter (problem, objectives, scope, stakeholders, assumptions, constraints, dependencies, risks, deliverables, success criteria, technical decisions) | `docs/00_requirements/project-charter.md` | DOC-REQ-001 | Member A | Drafted — ready for review |
| 2 | Software Requirements Specification (FR/NF with IDs, priorities, dependencies, acceptance criteria) | `docs/00_requirements/software-requirements-specification.md` | DOC-REQ-002 | Member A | Drafted — ready for review (§13 open questions pending) |
| 3 | Business rules | `docs/00_requirements/business-rules.md` | DOC-REQ-003 | Member A | Drafted — ready for review (`BR-01`..`BR-38` plus `BR-02a`) |
| 4 | Data requirements, ERD plan and data dictionary | `docs/00_requirements/data-requirements-and-erd-plan.md` | DOC-REQ-004 | Member A | Drafted — ready for review (entity inventory, cardinalities, fields/indexes, Mermaid ERD, retention map, §10 open data questions) |
| 5 | API requirements / design (resource index, error contract, per-resource specs, throttle classes) | `docs/00_requirements/api-requirements.md` | DOC-REQ-005 | Member A | Drafted — ready for review (contract freeze planned at end of week 4, DOC-REQ-012 §6) |
| 6 | Security requirements and threat model | `docs/00_requirements/security-and-threat-model.md` | DOC-REQ-006 | Member A | Drafted — ready for review (`THR-*` threat table, OWASP/API mapping, secure-configuration baseline) |
| 7 | Privacy and GPS policy | §7 of `docs/00_requirements/security-and-threat-model.md` (folded in per DOC-REQ-000 §2) | DOC-REQ-006 | Member A | Drafted — ready for review (`POL-PRIV-01..10`, `POL-GPS-01..13`, purpose register, coordinate access rules) |
| 8 | AI safety policy | `docs/00_requirements/ai-safety-policy.md` | DOC-REQ-007 | Member A | Drafted — ready for review (Part I, `POL-AI-01..12`, KB governance, 102-case safety set) |
| 9 | Audit-trail and suspicious-activity policy | Part II of `docs/00_requirements/ai-safety-policy.md` (folded in per DOC-REQ-000 §2; not a standalone file) | DOC-REQ-007 | Member A | Drafted — ready for review (`POL-AUDIT-01..09`, `POL-SUS-01..10`, seven explainable rules, review workflow) |
| 10 | User stories and use cases (workflows, diagrams, acceptance criteria) | `docs/00_requirements/user-stories-and-use-cases.md` | DOC-REQ-008 | Member B | Drafted — ready for review |
| 11 | Architecture overview (layers, components, request lifecycle, auth/sync flows, deployment topology) | `docs/00_requirements/architecture-overview.md` | DOC-REQ-009 | Member A | Drafted — ready for review |
| 12 | Access-control matrix (roles, operations, least privilege, object-level rules, negative tests) | `docs/00_requirements/access-control-matrix.md` | DOC-REQ-010 | Member A | Drafted — ready for review |
| 13 | UI screen inventory and navigation flow | `docs/00_requirements/ui-screen-inventory.md` | DOC-REQ-011 | Member B | Drafted — ready for review |
| 14 | MVP and release plan (incl. WBS, 14-week timeline, de-scope ladder, change control) | `docs/00_requirements/mvp-and-release-plan.md` | DOC-REQ-012 | Both | Drafted — ready for review |
| 15 | Risk register | `docs/00_requirements/risk-register.md` | DOC-REQ-013 | Both | Drafted — ready for review (`RSK-01`..`RSK-24`) |
| 16 | Test and acceptance plan (levels, entry/exit, defect log, UAT, gates) | `docs/00_requirements/test-and-acceptance-plan.md` | DOC-REQ-014 | Member A | Drafted — ready for review |
| 17 | Phase 0 exit checklist (this document) | `docs/00_requirements/phase-0-exit-checklist.md` | DOC-REQ-015 | Both | Drafted — awaiting signature |
| 18 | Requirements traceability matrix | `docs/00_requirements/requirements-traceability-matrix.md` | RTM-001 | Both | Skeleton — acceptable at Phase 0; populated per gate from week 2 (rule: no Implemented/Verified without an executed test) |
| 19 | Team work division | `docs/00_requirements/team-work-division.md` | companion (no DOC-REQ ID) | Both | Done — see §6 item G-2 for the authorship reconciliation |

DOC-REQ-006 and DOC-REQ-007 are now written and verified present (threat model `THR-*`, `POL-PRIV-01..10`, `POL-GPS-01..13`; `POL-AI-*`, `POL-AUDIT-01..09`, `POL-SUS-01..10`), so they are no longer content blockers; the two documents deliberately fold the privacy/GPS and audit/suspicious-activity policies in as sections (DOC-REQ-000 §2). Items N/A in Phase 0 but tracked here so they are not lost: use-case diagram and low-fidelity wireframes (`docs/01_design/`, Phase 1, from DOC-REQ-011 §7), environment setup guide (`docs/02_setup/`, Phase 1, master prompt Step 0.8), deployment architecture finalisation (Phase 8), user/administrator manuals, test report, backup/restore guide, handover checklist (Phase 8), final report (Phase 9).

## 3. Step-by-step Phase 0 completion check

| Step | Master-prompt requirement | Evidence | Status |
|---|---|---|---|
| 0.1 | Inspect repository: structure, README, existing code, dependencies, tests; record environment problems; preserve useful code | Findings in §4 below | **Done** |
| 0.2 | Define the project: problem statement, goals/objectives, scope and exclusions, stakeholders, assumptions/constraints/dependencies/risks, deliverables, measurable success criteria | DOC-REQ-001 §2, §3, §4 (EXCL-01..13 + proposed EXCL-14..16), §5, §6, §7, §9, §8.3 SC-01..10; DOC-REQ-013 | **Done** |
| 0.3 | SRS with unique IDs, priorities, dependencies, acceptance criteria, covering all modules | DOC-REQ-002 §6 (FR-AUTH, FR-FARM, FR-ANIM, FR-HEALTH, FR-VET, FR-REPORT, FR-ANN, FR-NOTIF, FR-OFF, FR-AI) and §7 (NF-SEC, NF-PRIV, NF-PERF, NF-REL, NF-USE, NF-ETH, NF-CMP, NF-MNT) | **Done pending reviewer comments** |
| 0.4 | Define user roles and which data each role can create, read, update, approve, publish, archive, or delete; least privilege; backend enforcement | DOC-REQ-010 (per-object tables §4, LP-01..LP-14, OR-01..OR-14, AC-N-01..16); DOC-REQ-008 §2 actor tokens | **Done** — needs the BR/ID reconciliation in §5 (items C-1..C-6) |
| 0.5 | Workflows: user stories, use cases, business rules, activity diagrams, acceptance criteria | DOC-REQ-008 (US-* with Given/When/Then; UC-01..UC-12; three Mermaid workflow diagrams); DOC-REQ-003; DOC-REQ-002 §8 state machines | **Done** — activity-diagram coverage is Mermaid flowchart/sequence form, not UML swim-lane (see §6 item G-3) |
| 0.6 | Design documents: architecture diagram, use-case diagram, ERD, data dictionary, API design, UI inventory and wireframes, navigation flow, preliminary deployment architecture | DOC-REQ-009 (components, auth, sync, GPS/AI/notification flows, deployment topology); DOC-REQ-004 (ERD + dictionary); DOC-REQ-005; DOC-REQ-011 (inventory + 3 navigation flows) | **Partial** — missing: standalone use-case diagram, wireframes (both Phase 1); the rest is complete |
| 0.7 | Security and privacy requirements: threat model, access-control matrix, data inventory/classification, GPS consent and privacy policy, audit-trail policy, AI safety policy, suspicious-activity policy, retention/backup, research ethics | Access-control matrix **done** (DOC-REQ-010); classification done (DOC-REQ-002 §4.1, DOC-REQ-004 §8); ethics constraints present (NF-ETH-01..05, DOC-REQ-013 RSK-09); threat model + privacy/GPS policy done (DOC-REQ-006 §1–§7); AI safety + audit/suspicious-activity policy done (DOC-REQ-007 Parts I and II) | **Done pending reviewer comments** — Step 0.7 artefacts all present; retention/backup figures are marked tunable defaults, not spec |
| 0.8 | Delivery planning: WBS, timeline and milestones, risk register, MVP, test strategy, RTM, environment setup guide, phase approval checklist | DOC-REQ-012 §5/§6 (WP-00..WP-37, weeks 1–14), §2 (MVP), §7 (ladder), §8 (DoD), §9 (change control); DOC-REQ-013; DOC-REQ-014; RTM-001 skeleton; this checklist | **Done** except the environment setup guide, which is a Phase 1 artefact |
| — | Store documentation under `docs/00_requirements/` | All 19 rows of §2 live in that directory | **Done** |

## 4. Repository inspection record (Step 0.1 evidence)

| Item | Observation at Phase 0 (2026-11-04) |
|---|---|
| Contents | `README.md`, `MASTER_PROJECT_PROMPT.md`, `.git/`, `docs/00_requirements/` (in progress). **No code, no configuration, no tests, no dependency manifests.** |
| Git | Two commits: "Initial commit" and "Added project README and master development prompt"; all `docs/` files untracked at the time of writing; no tags, no branches beyond the default |
| Existing components to preserve | None in code. The README's proposed structure and the master prompt's target structure are the baseline; DOC-REQ-009 §4.1 adopts the README app list and records that the dashboard lives inside the Django project (TD-13), so no separate `web/` directory will be created |
| Missing components expected before Phase 1 | `.gitignore`, `.env.example`, `backend/`, `mobile/`, `docs/01_design/`, `docs/02_setup/`, `docs/03_testing/`, `docs/04_deployment/`, `docs/05_final_report/`, `tests/` |
| Environment risks identified | Library/toolchain compatibility on Windows (DOC-REQ-013 RSK-02), MySQL driver and configuration (RSK-13), Flutter/Android SDK and emulator friction (RSK-12) — all verified in week 1, not assumed |
| Documentation drift found during inspection | `README.md` §8 proposes a `docs/requirements/` layout while the master prompt mandates `docs/00_requirements/`; the master prompt layout is used and README §8 should be corrected (item G-1 in §6) |
| Placeholder-feature risk noted | README §5 lists features as proposals; §17 already states they are not implemented. Every Phase 0 document keeps that distinction, and DOC-REQ-014 §1 forbids claiming an executed test that was not executed |

## 5. Cross-document consistency items to close before signature

These were found while writing DOC-REQ-008..015 against Member A's documents. Each is an editing task in this phase, not deferred work.

| ID | Item | Documents affected | Action | Owner | Status |
|---|---|---|---|---|---|
| C-1 | DOC-REQ-008 originally used local `WB-<NN>` labels for workflow constraints; the authoritative labels are `BR-01`..`BR-38` plus `BR-02a` in DOC-REQ-003 | DOC-REQ-008, DOC-REQ-010, DOC-REQ-009, DOC-REQ-011, DOC-REQ-012, DOC-REQ-014 | Replace every `WB-*` reference with the matching `BR-*` ID | Member B | **Closed (verified 2026-11-04)** — zero `WB-*` tokens remain in the folder |
| C-2 | Assistance-request status names: DOC-REQ-008/010/011 used `SUBMITTED/ASSIGNED/ATTENDED/CLOSED`; the SRS (FR-VET-06) uses `PENDING → ACCEPTED \| DECLINED \| CANCELLED`, `ACCEPTED → IN_PROGRESS → COMPLETED` | DOC-REQ-008 (UC-06, US-FARMER-12, US-VET-03), DOC-REQ-010 §4.6, DOC-REQ-011 SCR-M-25/28 | Align to the SRS state names; the SRS is authoritative | Member B | **Closed (verified 2026-11-04)** — UC-06 main flow, alternates and the Mermaid sequence diagram rewritten to SRS §8.1; `ASSIGNED`/`ATTENDED`/`NEEDS_FOLLOW_UP` no longer appear, and UC-06 now states completion requires a linked `VeterinaryVisit` (409 `VISIT_REQUIRED`, FR-VET-10) and that no `CLOSED` state exists for assistance requests |
| C-3 | Report decision name: `ACCEPTED_FOR_ASSESSMENT` (master prompt wording) vs `ACCEPTED_FOR_ASSESSMENT` (FR-REPORT-03) | DOC-REQ-008, DOC-REQ-010, DOC-REQ-014 | Use `ACCEPTED_FOR_ASSESSMENT`; record that it is the master prompt's "accepted for assessment" state so an examiner can see the equivalence | Member A | **Partially closed** — the single spelling `ACCEPTED_FOR_ASSESSMENT` is now used in all 16 occurrences folder-wide (verified 2026-11-04), but the examiner-facing equivalence note has not yet been added to DOC-REQ-002 §8.2; item stays open for that one line |
| C-4 | Announcement lifecycle labels `DRAFT → IN_REVIEW → PUBLISHED → EXPIRED \| WITHDRAWN` (FR-ANN-02) not used consistently in DOC-REQ-010 §4.8 and DOC-REQ-011 §3 | as listed | Align labels; keep `WITHDRAWN` and `EXPIRED` visible as separate UI tokens (ST-08) | Member A / B | Open |
| C-5 | Four-eyes publication: DOC-REQ-010 §7 Q-A assumed "reviewer approval required"; FR-ANN-03 already settles it as **the publishing officer must not be the draft author** (segregation of duties) | DOC-REQ-010 §4.8, §7 | Replace Q-A with the FR-ANN-03 rule and cite BR-04/BR-24 | Member A | Open |
| C-6 | Offline logout: DOC-REQ-008 §10 Q6 assumed "wipe on logout destroys the queue"; FR-OFF-07/08 require warn + sync-then-logout and an encrypted retained queue on forced logout | DOC-REQ-008 (US-FARMER-14, UC-10 alt 4e), DOC-REQ-011 ST-12, DOC-REQ-014 OFF-06 | Rewrite to FR-OFF-07 behaviour; note BR-14 covers the wipe of *cached business data*, not the retained queue | Member B | Open |
| C-7 | Requirement-link ranges written before the SRS list was complete (e.g. FR-VET/FR-ANN/FR-NOTIF/FR-AI numbering) | DOC-REQ-008, 009, 010, 011, 012, 014 | Re-point each link to the final FR/NF IDs; record any link with no SRS counterpart as a missing requirement for DOC-REQ-002 rather than deleting it | Both | Open |
| C-8 | Unverified-vet case acceptance: BR-22 states clinical authoring rights (including assistance responses) require administrator verification | DOC-REQ-008 Q1, DOC-REQ-010 §4.6 | Close Q1 with BR-22 and cite it in the matrix | Member A | Open |
| C-9 | FR-AUTH-08 allows a farmer to authorise a specific verified veterinarian to access a named farm (farmer-granted, not request-derived) — a second access path this matrix must state | DOC-REQ-010 §4/§6 (new OR row) | Add the explicit-farm-authorisation rule and its revocation path, plus a negative test | Member A | Open |
| C-10 | FR-NOTIF-07 permits an optional external push transport behind an interface, while EXCL-09 defers push | DOC-REQ-012 §2.3, DOC-REQ-009 §8.3 | State clearly: interface present, transport in-app only for acceptance; push is stretch | Both | Open |

Gate condition: **items C-4..C-10 must be closed (or explicitly accepted by the supervisor) before signature.** C-1 and C-2 are closed with evidence; C-3 is partially closed (one note outstanding). The former B-1/B-2 blockers are resolved: DOC-REQ-006 and DOC-REQ-007 now exist and carry the threat model, GPS/privacy policy, AI-safety policy and audit/suspicious-activity policy that the other documents cite.

## 6. Governance and follow-up items

| ID | Item | Why it matters at this gate | Action |
|---|---|---|---|
| G-1 | README §8 document tree vs the master prompt's `docs/00_requirements/` structure | Two structures in one repo invites misfiled evidence | Update README §8 to the as-built tree at Phase 0 close |
| G-2 | `team-work-division.md` (Phase 0 row) assigns the access matrix, architecture overview and test plan to Member B, while this document set records them as Member A-authored (backend-facing) | Ownership claims must be defensible in the commit history and the final report | Reconcile the row: Member A authors backend-facing documents, Member B authors mobile/UX-facing documents, both review — DOC-REQ-012 §2 ownership and DOC-REQ-014 §2 already assume this |
| G-3 | Master prompt Step 0.5 names "activity diagrams"; DOC-REQ-008 supplies Mermaid flowchart/sequence diagrams | An examiner may look for UML swim-lanes | Either add UML activity diagrams in `docs/01_design/` for UC-05/06/08/10 or record in the report that Mermaid diagrams are the project's notation |
| G-4 | Schedule window: DOC-REQ-001 CON-07 says one academic year; DOC-REQ-012 §1 plans 14 weeks | Scope and de-scope decisions differ | Supervisor confirms the window at signature (DOC-REQ-012 §1 reconciliation note) |
| G-5 | Wireframes and use-case diagram not yet produced | Step 0.6 partially open | Scheduled in Phase 1 (DOC-REQ-011 §7); acceptable because inventory + navigation flows already fix scope |
| G-6 | Environment setup guide not yet produced | Listed under Step 0.8 | Produced in Phase 1 (WP-01/WP-02); Phase 0 evidence is that the guide's acceptance criterion — reproducibility by the other member — is already written into DOC-REQ-014 gate G-1 |
| G-7 | `.gitignore` and `.env.example` do not exist | Required before any code exists (CON-06, RSK-10) | Created as the first action after signature; permitted earlier as repo hygiene |
| G-8 | RTM-001 has placeholder rows only | Step 0.8 asks for a traceability matrix | Skeleton + population rule accepted at Phase 0; rows added as each FR is implemented |

## 7. Phase 0 acceptance criteria and their evidence

| # | Criterion | Measurable condition | Evidence location | Status |
|---|---|---|---|---|
| A-1 | **Requirements documented and reviewed** | (a) every module in DOC-REQ-002 has at least one FR with an acceptance criterion; (b) all four roles have stories with Given/When/Then; (c) each of DOC-REQ-001..015 exists with version, date, author, status headers; (d) both members have performed the cross-review and their comments are resolved or recorded | The 19-row register in §2 plus review comments logged in §8 | **Criteria (a)–(c) met; (d) in progress** — the review itself happens at the signature meeting, and §5 C-items are open review findings |
| A-2 | **MVP defined** | (a) R1 scope table lists included items with phase, story, screen and requirement references; (b) deferred items have a named target release; (c) permanent exclusions are enumerated; (d) R1 has a definition of done and a demo script | DOC-REQ-012 §2 (in/deferred/exclusions), §4 (screen map), §8 (DoD), §3 (R1 demo = E2E-01..05) | **Met**, subject to C-10 and supervisor confirmation of EXCL-14..16 |
| A-3 | **Critical design decisions documented** | (a) `TD-01`..`TD-14` recorded with rationale; (b) architecture supplements `AD-01`..`AD-10` with alternatives and revisit triggers; (c) each external dependency has a fallback; (d) the permission model, conflict rule, publication rule and consent rule are stated numerically/testably | DOC-REQ-001 §10; DOC-REQ-009 §2, §6, §7, §9; DOC-REQ-001 §7.3 + DOC-REQ-013 §5; DOC-REQ-010 §2/§6, BR-19/FR-OFF-05, BR-04/BR-24, BR-06/NF-PRIV-04 | **Met** |
| A-4 | Acceptance criteria defined for every phase gate | G-0..G-9 rows with the master-prompt criteria and the test levels that must be green | DOC-REQ-014 §15 | **Met** |
| A-5 | Risks identified, scored and owned | ≥ 20 scored risks, each with mitigation, owner and contingency; charter summary consistent with the register | DOC-REQ-013 §2/§3; DOC-REQ-001 §9 | **Met** |
| A-6 | Testability preserved (no unverifiable requirement) | Every Must requirement reachable via `E2E-01..E2E-12` or a named test; every business rule has a negative test; nothing is asserted as passed in advance | DOC-REQ-014 §7, §5, §16; DOC-REQ-010 §8 | **Met** |
| A-7 | No placeholder or invented completeness | Absent documents listed as **Not started** here; unexecuted tests listed as such; open questions enumerated instead of silently answered | §2, §5, §9 below | **Met** |
| A-8 | Documentation quality standard met | Precise, testable statements; tables and diagrams used; no requirement text duplicated where an ID link suffices | Independent supervisor review | **Pending review** |

## 8. Outstanding items blocking signature (single actionable list)

| Blocker | Description | Owner | Target |
|---|---|---|---|
| B-1 | ~~DOC-REQ-006 security/threat model **and** privacy/GPS policy missing~~ **Resolved 2026-11-04** — `security-and-threat-model.md` present with `THR-*` table, OWASP/API mapping, CFG baseline and §7 Privacy/GPS policy (`POL-PRIV-01..10`, `POL-GPS-01..13`) | Member A | Closed — reviewer comments only |
| B-2 | ~~DOC-REQ-007 AI safety policy **and** audit/suspicious-activity policy missing~~ **Resolved 2026-11-04** — `ai-safety-policy.md` Part I (`POL-AI-*`, KB governance, 102-case safety set) and Part II (`POL-AUDIT-01..09`, `POL-SUS-01..10`, review workflow) | Member A | Closed — reviewer comments only |
| B-3 | Cross-document consistency items: C-1, C-2 closed; C-3 one note outstanding; **C-4..C-10 still open** | Member B (C-2 done, C-6, C-7-mobile, C-10), Member A (C-3 residue, C-4, C-5, C-7-backend, C-8, C-9, C-10) | Before signature |
| B-4 | Supervisor decisions: Q-A/Q-C/Q-E in DOC-REQ-010 §7, DOC-REQ-008 §10 residue (Q2, Q3, Q4, Q5, Q9), DOC-REQ-004 §10, DOC-REQ-002 §14, G-4 schedule window, EXCL-14..16 approval | Supervisor + both members | At the review meeting |
| B-5 | Governance reconciliation G-1 (README tree) and G-2 (authorship row in `team-work-division.md`) | Both | At signature |
| B-6 | RTM-001 population rule accepted: every `US-*`/`UC-*`/`OR-*`/`AC-N-*`/`ST-*` referenced in this set must map to an FR/NF or be added to DOC-REQ-002 | Both | Before Phase 1 start |

Items that are **not** blockers (recorded so they are not mistaken for one): wireframes and use-case/activity diagrams (Phase 1), environment setup guide (Phase 1), RTM content rows (progressive), deployment finalisation (Phase 8).

## 9. Decisions taken at this gate (to be confirmed in §10)

1. Scope: R1 = Phases 1–3 (environment, auth + RBAC, core models, farmer mobile CRUD, health records, reminders); R2 = Phase 4; R3 = Phase 5; R4 = Phase 6; Phases 7–9 = acceptance/handover activity A1 (DOC-REQ-012 §3).
2. Exclusions EXCL-01..13 confirmed, plus EXCL-14 (no farmer web portal — mobile only), EXCL-15 (single-country focus), EXCL-16 (no herd-production analytics) pending supervisor approval.
3. Technical baseline `TD-01`..`TD-14` unchanged; architecture supplements `AD-01`..`AD-10` adopted (DOC-REQ-009 §9); AD-05 (Flutter state management) is a proposal to be confirmed by a week-2 spike.
4. Permission model is default-deny with role gate **and** object rule; administrators hold no clinical read right; publication requires a human authority officer who is not the draft author (DOC-REQ-010 §1/§2, FR-ANN-03, BR-04/BR-24).
5. Conflict rule for offline sync is last-write-wins-with-audit with a user-visible conflict state (BR-19, FR-OFF-05, ST-07); logout never silently loses a queued mutation (FR-OFF-07).
6. Location is consent-gated, coarse-by-default, with a functionally equivalent manual path (BR-06, FR-VET-01/02, NF-PRIV-04, SC-06).
7. The assistant is KB-first, cited, disclaimed, read-only, and safe without any external LLM (TD-10, BR-25/BR-26, FR-AI-05/06/10, AS-08).
8. Demonstration target topology is the local Windows environment; free-tier hosting is supplementary evidence (DOC-REQ-009 §10, RSK-17).
9. Testing is executed-and-evidenced only; acceptance requires 12/12 on the E2E checklist at Phase 7 with the permission-matrix suite green (DOC-REQ-014 §1, §7, §15).

## 10. Sign-off

Pre-condition for signing: §8 items B-3 (C-3 residue and C-4..C-10) and B-4 closed or formally waived by the supervisor; B-1 and B-2 are resolved and need only reviewer comments; §5 consistency edits reflected in the documents at the versions listed in §2.

**Member A — backend/dashboard**

I confirm that the backend-facing requirements (DOC-REQ-001..006 as applicable, DOC-REQ-009, DOC-REQ-010, DOC-REQ-014) describe a system I am able to build within the agreed scope, that the permission model and the hard rules (server-side enforcement, human-only publication, audit on sensitive actions, consent-based location) are stated testably, and that the open items assigned to me are recorded.

| Field | Entry |
|---|---|
| Name | ______________________________ |
| Signature | ______________________________ |
| Date | ______________________________ |
| Conditions or reservations | ______________________________ |

**Member B — mobile**

I confirm that the user stories, screen inventory, release plan and risk register reflect what the mobile application can realistically deliver in the planned weeks, that each screen's required states are specified, and that the open items assigned to me are recorded.

| Field | Entry |
|---|---|
| Name | ______________________________ |
| Signature | ______________________________ |
| Date | ______________________________ |
| Conditions or reservations | ______________________________ |

**Project supervisor**

I have reviewed the Phase 0 requirements set, the MVP definition, the critical design decisions and the acceptance criteria. I approve progression to **Phase 1: Development environment and repository setup** and no substantial implementation beyond the gate rule in §1.

| Field | Entry |
|---|---|
| Name | ______________________________ |
| Signature | ______________________________ |
| Date | ______________________________ |
| Approved scope / conditions (including EXCL-14..16 and the schedule window, G-4) | ______________________________ |

If the supervisor requests changes: record them as requirement deltas through DOC-REQ-012 §9 change control, update the affected documents to version 0.2, and re-sign. Phase 1 does not begin on verbal approval.

## 11. Actions immediately after signature

1. Commit this document set with a tag `phase-0-exit` and note the version numbers of all 19 artefacts in the commit message.
2. Create repo hygiene files: `.gitignore`, `.env.example` (placeholders only), and the `docs/01_design/`, `docs/02_setup/`, `docs/03_testing/`, `docs/04_deployment/`, `docs/05_final_report/`, `backend/`, `mobile/`, `tests/` folders with one-line purpose stubs (no application code).
3. Correct README §8 to the as-built tree (G-1) and reconcile `team-work-division.md` Phase 0 authorship row (G-2).
4. Start WP-01/WP-02 (DOC-REQ-012 §5) and record toolchain evidence for RSK-02, RSK-12, RSK-13 in week 1 — these three risks retire only on executed proof, not on plan.
5. Register RTM-001 rows for every requirement implemented from week 2 onward.
6. Schedule the week-4 API contract freeze (DOC-REQ-005 + regenerated OpenAPI schema) and put it on the calendar now, because mobile API work is blocked behind it.
