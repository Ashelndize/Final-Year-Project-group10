# Project Progress Log

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Repository | Final-Year-Project-group10 |
| Team | Group 10 — 3 members |

---

## Session — 2026-11-18

### What was accomplished

#### 1. Full project analysis

A complete audit of the repository was performed before any changes were made. Key findings:

- The project is at the end of **Phase 0 (Requirements Assessment)** — documentation only, no application code exists yet.
- 19 requirements documents are drafted and stored in `docs/00_requirements/`.
- The tech stack is fully decided: Flutter (mobile), Django REST Framework (backend), MySQL (database), Django templates (authority dashboard).
- The architecture covers 25 database entities, 24 API resources, 4 user roles, and a 9-phase development plan.
- Phase 0 had been written for a **2-member team**. No code, no `.gitignore`, no dependency files existed.

---

#### 2. Team expanded from 2 to 3 members

The team was restructured from 2 members to 3. Responsibilities were split as follows:

| Member | Stack | Core responsibility |
|---|---|---|
| **Member A** | Backend Core | Django project, MySQL, models + migrations for accounts / farms / livestock / health_records / veterinary, JWT auth, RBAC, core DRF endpoints, backend tests, synthetic fixtures |
| **Member B** | Mobile | Flutter app (all 44+ screens), GPS/maps, offline sqflite + sync queue, AI assistant UI, notifications UI, APK build |
| **Member C** | Advanced Backend + Dashboard | Disease reports + announcements APIs, authority dashboard (Django templates), AI assistant backend (KB + provider interface), security/audit/suspicious-activity rules, rate limiting, drf-spectacular, deployment |

---

#### 3. Files changed

| File | Change | Commit |
|---|---|---|
| `docs/00_requirements/team-work-division.md` | Full rewrite — 2-member table replaced with 3-member table; 4-column phase ownership (A/B/C/Joint) across all 9 phases; updated cross-cutting rules; granular repo path ownership per app | `8465f40` |
| `docs/00_requirements/phase-0-exit-checklist.md` | Gate rule updated to require Member A, B, and C; Member C sign-off block added; supervisor sign-off block removed (team has full authority); doc register ownership redistributed to Member C for security/policy/architecture docs; all "Both" references updated to "All three"; supervisor removed from every governance item | `8465f40`, `d159adc` |
| `README.md` | Section 18 updated — 3-member group stated with a summary role table | `8465f40` |
| `docs/00_requirements/mvp-and-release-plan.md` | Full restructure for 3-member team: WP-03 added for Member C (Phase 1); all subsequent WPs renumbered WP-04..WP-40; new Member C work packages added across Phases 2–6; timeline expanded to 3 columns; capacity note updated to 210 available days; supervisor references removed from §8 and §9 | `7d3c94e` |
| `docs/00_requirements/phase-0-exit-checklist.md` | §11 updated to reference WP-01/WP-02/WP-03 | `7d3c94e` |
| `PROGRESS.md` | This file — created to log session work | — |

---

#### 4. Work packages restructure summary

The Work Breakdown Structure in `docs/00_requirements/mvp-and-release-plan.md` was restructured from 38 to 41 work packages:

| Phase | Member A WPs | Member B WPs | Member C WPs | Joint WPs |
|---|---|---|---|---|
| 0 | — | — | — | WP-00 |
| 1 | WP-01 | WP-02 | **WP-03** | — |
| 2 | WP-04, WP-05, WP-06, WP-09 | — | **WP-07, WP-08** | — |
| 3 | — | WP-10, WP-11, WP-12 | **WP-13** | WP-14 |
| 4 | WP-16, WP-17 | WP-15, WP-16, WP-18, WP-20 | **WP-19** | WP-21 |
| 5 | WP-26 | WP-28 | **WP-22, WP-23, WP-24, WP-25, WP-27** | WP-29 |
| 6 | WP-30 | WP-32, WP-35, WP-36 | **WP-31, WP-33, WP-34, WP-35** | WP-37 |
| 7 | — | — | — | WP-38 |
| 8 | — | — | — | WP-39 |
| 9 | — | — | — | WP-40 |

Capacity: 180 person-days needed / 210 available (86% utilisation — plan is no longer over-committed).

---

#### 5. Gate authority — supervisor removed

The project gate authority was transferred entirely to the three members. The supervisor no longer appears anywhere in the documentation. Specifically:

- Phase 0 gate rule: requires signatures from Member A, Member B, and Member C only.
- All open questions previously flagged as "supervisor decisions" are now "team decisions".
- Change control (§9 of mvp-and-release-plan.md) requires all three members to approve scope changes, not a supervisor.

---

### Current project state

| Item | Status |
|---|---|
| Phase 0 documents (19 total) | All drafted — awaiting sign-off |
| Team work division | Updated for 3 members |
| WBS and timeline | Updated for 3 members |
| Application code | None — gate not yet signed |
| `.gitignore` / `.env.example` | Not yet created (permitted after signature) |
| `backend/`, `mobile/` folders | Not yet created (permitted after signature) |
| Tests | None |
| Deployment config | None |

---

### What must happen before Phase 1 starts

**Step 1 — Close remaining consistency items (B-3)**

Each item is documented in `docs/00_requirements/phase-0-exit-checklist.md` §5:

| Item | Owner | What to fix |
|---|---|---|
| C-3 | Member A | Add one equivalence note in DOC-REQ-002 §8.2 for `ACCEPTED_FOR_ASSESSMENT` |
| C-4 | Member A / C | Align announcement lifecycle labels across DOC-REQ-010 §4.8 and DOC-REQ-011 §3 |
| C-5 | Member A | Replace Q-A in DOC-REQ-010 §7 with the FR-ANN-03 four-eyes rule |
| C-6 | Member B | Rewrite offline logout behaviour in DOC-REQ-008 and DOC-REQ-011 to match FR-OFF-07 |
| C-7 | All three | Re-point FR/NF link ranges to final IDs in DOC-REQ-008/009/010/011/012/014 |
| C-8 | Member A | Add BR-22 unverified-vet rule to DOC-REQ-010 §4.6 |
| C-9 | Member A | Add FR-AUTH-08 farmer-granted farm access path to DOC-REQ-010 §4/§6 |
| C-10 | All three | Clarify FR-NOTIF-07 vs EXCL-09 push-interface status in DOC-REQ-012 and DOC-REQ-009 |

**Step 2 — Close team decisions (B-4)**

Hold a short team meeting to agree on:
- Open questions Q-A/Q-C/Q-E (DOC-REQ-010 §7)
- Open questions Q2, Q3, Q4, Q5, Q9 (DOC-REQ-008 §10)
- Schedule window G-4 (1 academic year vs 14 weeks — confirm which applies)

**Step 3 — Fix README §8 tree (B-5 / G-1)**

Update `README.md` §8 to show the actual as-built directory tree (currently shows an older proposed structure).

**Step 4 — Sign the exit checklist**

All three members fill in and sign `docs/00_requirements/phase-0-exit-checklist.md` §10.

**Step 5 — Start Phase 1**

After signature, each member begins their Phase 1 work package:

| Member | Task | Documented in |
|---|---|---|
| Member A | WP-01: Django project + MySQL + health-check endpoint | [MASTER_PROJECT_PROMPT.md Phase 1](MASTER_PROJECT_PROMPT.md) + [WP-01](docs/00_requirements/mvp-and-release-plan.md) |
| Member B | WP-02: Flutter scaffold + emulator + first API call | [MASTER_PROJECT_PROMPT.md Phase 1](MASTER_PROJECT_PROMPT.md) + [WP-02](docs/00_requirements/mvp-and-release-plan.md) |
| Member C | WP-03: `.gitignore`, `.env.example`, folder layout, setup guide | [MASTER_PROJECT_PROMPT.md Phase 1](MASTER_PROJECT_PROMPT.md) + [WP-03](docs/00_requirements/mvp-and-release-plan.md) |

---

### Commits made this session

| Commit | Message | Files |
|---|---|---|
| `8465f40` | Expand team work division from 2 to 3 members | `team-work-division.md`, `phase-0-exit-checklist.md`, `README.md` |
| `d159adc` | Remove supervisor from gate authority — full control to 3 members | `phase-0-exit-checklist.md` |
| `7d3c94e` | Add Member C to WBS and timeline; renumber WP-03 onwards | `mvp-and-release-plan.md`, `phase-0-exit-checklist.md` |

All commits pushed to `origin/main` on branch `main`.

---

### Key documents reference

| Document | Path | Purpose |
|---|---|---|
| Master development guide | `MASTER_PROJECT_PROMPT.md` | Phase-by-phase instructions for the entire project |
| Project overview | `README.md` | High-level summary, tech stack, setup commands |
| Team work division | `docs/00_requirements/team-work-division.md` | Per-phase ownership for all 3 members |
| Phase 0 exit checklist | `docs/00_requirements/phase-0-exit-checklist.md` | Gate conditions and sign-off |
| MVP and release plan | `docs/00_requirements/mvp-and-release-plan.md` | WBS (WP-00..WP-40), 3-column timeline, release plan |
| Software requirements | `docs/00_requirements/software-requirements-specification.md` | 120 functional + 57 non-functional requirements |
| Architecture overview | `docs/00_requirements/architecture-overview.md` | System layers, component diagram, request flows |
| ERD plan | `docs/00_requirements/data-requirements-and-erd-plan.md` | 25 entities, relationships, MySQL decisions |
| API requirements | `docs/00_requirements/api-requirements.md` | 24 API resources, conventions, error contract |
| Access control matrix | `docs/00_requirements/access-control-matrix.md` | Role × resource × operation, negative tests |
