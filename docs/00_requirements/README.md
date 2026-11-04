# Phase 0 Requirements Documentation — Index

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-000 (index) |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard) and Member B (mobile) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Governs | `MASTER_PROJECT_PROMPT.md` PHASE 0, Steps 0.1–0.8 and "Phase 0 deliverables" |

This folder is the Phase 0 deliverable set. No application code, configuration or tests belong here;
Phase 1 starts only after the gate in `phase-0-exit-checklist.md` is signed.

---

## 1. Document index

| # | File | Doc ID | Owner | What it contains |
|---|---|---|---|---|
| 1 | `project-charter.md` | DOC-REQ-001 | Member A + B | Problem statement, goal and 10 measurable objectives, scope with 13 exclusions, stakeholders and decision rights, deliverables, assumptions/constraints/dependencies, top risks, 14 fixed technical decisions (TD-01..TD-14), success criteria SC-01..SC-10 |
| 2 | `software-requirements-specification.md` | DOC-REQ-002 | Member A | The requirement contract: 120 `FR-*` requirements across 10 modules and 57 `NF-*` non-functional requirements, each with priority, dependencies and testable acceptance criteria; state machines; data summary; interface requirements; traceability skeleton; 7 open questions |
| 3 | `business-rules.md` | DOC-REQ-003 | Member A | `BR-01`..`BR-38` (plus `BR-02a`) with rationale, named backend enforcement point, and the requirement each rule blocks; coverage check listing the negative test required per rule |
| 4 | `data-requirements-and-erd-plan.md` | DOC-REQ-004 | Member A | 25-entity inventory (`M-01`..`M-25`), 39 relationships with cardinalities and `on_delete`, key fields and indexes per entity, Mermaid `erDiagram` plus a text fallback, MySQL/InnoDB decisions `DB-01`..`DB-14`, volume and retention maps, data-quality rules |
| 5 | `api-requirements.md` | DOC-REQ-005 | Member A | API conventions `API-C1`..`API-C20`, 24 resources (`API-01`..`API-24`) with methods, auth, permissions and request/response summaries, the single error envelope with an error-code catalogue, sync and duplicate-prevention contract, throttle table |
| 6 | `security-and-threat-model.md` | DOC-REQ-006 | Member A | Security objectives, 16-asset inventory, 30-item STRIDE threat table with scores and owners, OWASP Top 10 and API Security Top 10 control mapping, secure configuration baseline, and the **Privacy and GPS Policy** (`POL-PRIV-01..10`, `POL-GPS-01..13`, purpose register, farm-coordinate access rules) |
| 7 | `ai-safety-policy.md` | DOC-REQ-007 | Member A | **Part I — AI Safety Policy**: absolute boundaries, knowledge-base governance, provider abstraction and fallback, content-safety rules, cost and limitation transparency, and a 102-case safety test set (`POL-AI-01..12`). **Part II — Audit and Suspicious-Activity Policy**: audited-event inventory, the audit event schema and append-only protection (`POL-AUDIT-01..09`), reader rights, the 7 explainable detection rules with thresholds, review workflow and false-positive handling (`POL-SUS-01..10`) |
| 8 | `user-stories-and-use-cases.md` | DOC-REQ-008 | Member B | User stories and use cases per role, workflow narratives, activity/use-case diagrams and story-level acceptance criteria |
| 9 | `architecture-overview.md` | DOC-REQ-009 | Member A | Layers and components, request lifecycle, authentication and sync flows, module boundaries, deployment topology |
| 10 | `access-control-matrix.md` | DOC-REQ-010 | Member A | Role x resource x operation matrix with least-privilege defaults, object-level rules and the negative tests that prove them |
| 11 | `ui-screen-inventory.md` | DOC-REQ-011 | Member B | Mobile and dashboard screen inventory, navigation flow, states per screen, requirement links |
| 12 | `mvp-and-release-plan.md` | DOC-REQ-012 | Both | WBS, 14-week timeline, release slices R1..R4, de-scope ladder, change control |
| 13 | `risk-register.md` | DOC-REQ-013 | Both | `RSK-01`..`RSK-24` with categories, scores, responses, owners and contingency plans |
| 14 | `test-and-acceptance-plan.md` | DOC-REQ-014 | Member A | Test levels, entry and exit criteria, `TC-PERM-*`/`TC-SEC-*` families, offline scenario matrix, UAT, gate criteria |
| 15 | `phase-0-exit-checklist.md` | DOC-REQ-015 | Both | The artefact tracker, evidence pointers, governance items and the signature block for this gate |
| 16 | `requirements-traceability-matrix.md` | RTM-001 | Both | Requirement to design, implementation, test ID and result; skeleton at Phase 0, populated at every later gate |
| 17 | `team-work-division.md` | companion | Both | Ownership split by stack and phase; cross-cutting team rules |
| 18 | `README.md` | DOC-REQ-000 | Member A | This index |

---

## 2. Two master-prompt artefacts are delivered as sections, not files

`MASTER_PROJECT_PROMPT.md` lists `privacy-and-gps-policy.md` and
`audit-and-suspicious-activity-policy.md` as separate filenames. This project delivers them as named
sections so that each policy sits with the controls it depends on:

| Master-prompt artefact | Delivered in | Section | Identifier families |
|---|---|---|---|
| Privacy and GPS policy | `security-and-threat-model.md` (DOC-REQ-006) | §7 Privacy and GPS Policy, including §7.4 farm-coordinate access rules | `POL-PRIV-*`, `POL-GPS-*` |
| Audit-trail and suspicious-activity policy | `ai-safety-policy.md` (DOC-REQ-007) | Part II — Audit and Suspicious-Activity Policy | `POL-AUDIT-*`, `POL-SUS-*` |

Consequence for the gate: rows 6, 7, 8 and 9 of the artefact tracker in `phase-0-exit-checklist.md` were
originally compiled before DOC-REQ-006 and DOC-REQ-007 were written and marked "Not started — gate
blocker". Those rows, the row-9 filename (now Part II of `ai-safety-policy.md`), the `BR-01`..`BR-34`
range (actually `BR-01`..`BR-38` plus `BR-02a`, 39 distinct rules) and Step 0.7 have all been corrected
in that document on 2026-11-04; B-1 and B-2 are recorded as resolved, and the remaining gate work is
reviewer comments plus consistency items C-3 (one note) and C-4..C-10.

---

## 3. Identifier registry (what is authoritative, and where)

| Prefix | Meaning | Assigned in |
|---|---|---|
| `FR-<MODULE>-<NN>` | Functional requirement | DOC-REQ-002 §6 |
| `NF-SEC/PRIV/PERF/USE/REL/MNT/CMP/ETH-nn` | Non-functional requirement | DOC-REQ-002 §7 |
| `BR-nn` | Business rule | DOC-REQ-003 (authoritative; DOC-REQ-010 `OR-*` labels map onto these) |
| `M-nn`, `R-nn`, `DB-nn`, `DQ-nn` | Entity, relationship, storage decision, data-quality rule | DOC-REQ-004 |
| `API-nn`, `API-Cnn` | API resource, API convention | DOC-REQ-005 |
| `THR-nn`, `SO-nn`, `CFG-nn`, `SA-nn` | Threat, security objective, configuration baseline, assumption | DOC-REQ-006 |
| `POL-PRIV-nn`, `POL-GPS-nn` | Privacy and location policy clauses | DOC-REQ-006 §7 |
| `POL-AI-nn`, `POL-AUDIT-nn`, `POL-SUS-nn` | AI safety and audit/suspicious-activity clauses | DOC-REQ-007 |
| `TD-nn`, `OBJ-n`, `SC-nn`, `EXCL-nn`, `CON-nn`, `AS-nn`, `DEP-n`, `RSK-nn` (charter set) | Charter-level identifiers | DOC-REQ-001 |
| `RSK-nn`, `ST-nn`, `Q-nn` | Risk register and release-plan items | DOC-REQ-012/013 (the register is authoritative for its own numbering) |
| `US-*`, `UC-*`, `SCR-*`, `OR-*`, `LP-*`, `TC-*`, `E2E-nn`, `G-*` | Stories, screens, object rules, least-privilege defaults, tests, gate criteria | DOC-REQ-008/010/011/014/015 |

Where two documents assign the same identifier for the same concept, the document named above is
authoritative and the other adopts it.

### 3.1 Provisional link resolution (for RTM-001 at sign-off)

DOC-REQ-008, DOC-REQ-010 and DOC-REQ-011 were compiled before `software-requirements-specification.md`
§6 was final, so a small number of their links point at identifiers this set does not use. They
resolve as follows; no behaviour is lost, only numbering:

| Provisional link (sibling docs) | Resolves to (authoritative) |
|---|---|
| `FR-REPORT-14..19` (review queue, transitions, action panel) | FR-REPORT-03, FR-REPORT-04, FR-REPORT-05, FR-REPORT-07, FR-REPORT-10, FR-ANN-04 |
| `FR-REPORT-20..22` (monitoring summaries) | FR-REPORT-09 (with BR-23 suppression rules) |
| `FR-HEALTH-15..16` (veterinarian clinical entry, prescription, follow-up) | FR-HEALTH-03, FR-HEALTH-05, FR-HEALTH-06 |
| `FR-VET-17` (vet response and status notes) | FR-VET-09, FR-VET-14 |
| `NF-AUDIT-01..05` | NF-SEC-05 plus `POL-AUDIT-01..07` (mapping also recorded in DOC-REQ-007 §6.1) |
| `NF-AVAIL-01..03` | NF-REL-01, NF-REL-02, NF-REL-03, NF-REL-05 |
| `NF-OFF-01..03` | FR-OFF-01, FR-OFF-02, FR-OFF-06, FR-OFF-10 plus NF-PRIV-02 |
| `NF-AI-01..04` | FR-AI-04, FR-AI-17, FR-AI-02, FR-AI-09 plus `POL-AI-04` |
| `ReportStatusEvent` rows (DOC-REQ-014 `E2E-09`) | `AuditEvent` with `action = report.transition` — no separate table, per DOC-REQ-004 §2 note 2 |
| `OR-*` / `LP-*` object and least-privilege rules (DOC-REQ-010) | Adopted as enforcement labels for `BR-01..BR-10` and `BR-13` |

---

## 4. Reading order

1. `project-charter.md` — why and what, and the exclusions.
2. `software-requirements-specification.md` — the behavioural contract (largest document; read §2 for
   conventions first).
3. `business-rules.md` — the constraints that cut across every module.
4. `access-control-matrix.md` then `security-and-threat-model.md` — who may do what, and why those
   choices exist.
5. `data-requirements-and-erd-plan.md` then `api-requirements.md` — the shape of data and its contract.
6. `ai-safety-policy.md` — the AI and audit rules that the API and data designs implement.
7. `user-stories-and-use-cases.md`, `architecture-overview.md`, `ui-screen-inventory.md` — the flows
   and surfaces.
8. `mvp-and-release-plan.md`, `risk-register.md`, `test-and-acceptance-plan.md` — delivery and proof.
9. `requirements-traceability-matrix.md`, `phase-0-exit-checklist.md` — the gate.

---

## 5. Status summary at 2026-11-04

| Item | Status |
|---|---|
| Documents drafted | 18 of 18 (this index included); none implemented as code |
| Requirements defined | 120 `FR` (100 Must), 57 `NF`, 39 `BR`, 30 threats, 24 API resources |
| Open questions carried to the gate | SRS §14 (`OQ-01..07`), ERD plan §10 (`DQ-OQ-1..5`), DOC-REQ-007 §11 (`Q-01..05`), checklist governance items (`G-1`, `G-2`) |
| Blockers for Phase 0 sign-off | Supervisor review of the MVP cut, answers to `OQ-01` (area vocabulary) and `OQ-06` (announcement visibility without login), and the governance corrections listed in §2 above |
| Rule | No substantial implementation before this set is reviewed and the gate is signed |

---

## 6. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial index of the Phase 0 document set with the identifier registry and the two section-folding decisions recorded |
