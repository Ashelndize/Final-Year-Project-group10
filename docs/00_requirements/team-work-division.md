# Team Work Division — Group 10 (3 members)

| Member | Stack | Primary ownership |
|---|---|---|
| **Member A** | Backend Core | Django project setup, MySQL, models and migrations for accounts / farms / livestock / health_records / veterinary, JWT authentication, RBAC permission classes, core DRF endpoints, backend unit and API tests, synthetic data fixtures |
| **Member B** | Mobile | Flutter app, state management and navigation, all mobile screens, GPS/maps integration, offline storage (sqflite) and sync queue, AI assistant UI with disclaimers, notifications UI, device testing, APK build |
| **Member C** | Advanced Backend + Dashboard | Disease-report and announcement APIs, authority web dashboard (Django templates), AI assistant backend (knowledge base, provider interface, fallback), security controls (audit enforcement, django-axes, rate limiting, suspicious-activity rules), notifications backend, drf-spectacular API docs, deployment |

No member signs off their own phase-gate checklist item — each runs at least one other member's review list.

## Ownership by phase

| Phase | Member A | Member B | Member C | Joint |
|---|---|---|---|---|
| 0 — Requirements | Backend/data docs: charter (DOC-REQ-001), SRS (DOC-REQ-002), business rules (DOC-REQ-003), ERD plan (DOC-REQ-004), API reqs (DOC-REQ-005) | UX/planning docs: user stories (DOC-REQ-008), screen inventory (DOC-REQ-011), MVP plan (DOC-REQ-012), risk register (DOC-REQ-013) | Security/policy docs: threat model (DOC-REQ-006), AI/audit policy (DOC-REQ-007), architecture overview (DOC-REQ-009), access-control matrix (DOC-REQ-010), test plan (DOC-REQ-014), exit checklist (DOC-REQ-015) | Review + sign-off on all docs; RTM skeleton (RTM-001) |
| 1 — Environment | Django project scaffold, MySQL database and least-privilege user, `.env`, health-check endpoint | Flutter project scaffold, emulator/device setup, first API call from app | `.gitignore`, `.env.example`, repo folder layout, setup guide (`docs/02_setup/`), architecture diagram (`docs/01_design/`) | Setup guide peer-review; confirm full E2E toolchain works |
| 2 — Backend core | accounts / farms / livestock / health_records / veterinary models + migrations; JWT auth; RBAC permission classes; DRF endpoints for those five apps; backend unit and API tests; synthetic data fixtures | Consumes OpenAPI schema to plan Flutter service layer | disease_reports / announcements / notifications / audit / sync / assistant models + endpoints; drf-spectacular schema setup; API contract merge | API contract freeze (end of week 4) |
| 3 — Farmer app | API support: filtering, pagination, any gaps on farms / livestock / health endpoints | Full Flutter app: auth screens, farmer dashboard, farm and animal CRUD, health records, vaccination reminders, API service layer | Notifications API; veterinary-submission endpoint support | Phase 3 acceptance test (E2E-01..E2E-05) |
| 4 — GPS + reporting | Veterinary directory and assistance-request APIs, jurisdiction restrictions, request status workflow | Map provider integration, GPS consent and manual fallback, assistance request UI, disease report submission UI | Disease report API and status workflow, report access restrictions, report-related notification dispatch | Permission-testing of report access (AC-N-*) |
| 5 — Authority dashboard | Announcement API backend and notification dispatch | Notification surfaces in app (outbreak alerts), announcement reading view | Entire authority dashboard: review queue, report statuses, announcement lifecycle, audit viewer, user management | Unauthorized-publication tests |
| 6 — Security / offline / AI | Audit enforcement at model level, django-axes config, API rate limiting | sqflite offline queue, idempotency UUIDs, sync and conflict UX, AI chat UI with disclaimers | AI knowledge base and provider interface and fallback, all seven suspicious-activity detection rules | Security test round; offline scenario matrix |
| 7 — Integration / UAT | Backend + API + security tests | Flutter widget and integration tests | 12-step E2E walkthrough coordination, defect log management, RTM column updates | End-to-end walkthrough (E2E-01..E2E-12); permission-matrix suite |
| 8 — Deployment / docs | Production Django settings, HTTPS/TLS config, DB backup and restore test, backend API deployment | APK build and distribution, mobile user manual | Authority dashboard deployment, admin manual, handover package, install and troubleshooting guides | Handover package sign-off; production smoke test |
| 9 — Report | Backend implementation chapter, database design chapter, security chapter | Mobile and UX chapter, demo script, screenshots | Testing results chapter, AI and advanced-features chapter, limitations and future work, presentation slides | Final report assembly; maintenance plan; demo rehearsal |

## Cross-cutting rules

1. **Interface contracts:** No member invents endpoints unilaterally — all three sign off on API contract changes. The versioned `docs/00_requirements/api-requirements.md` changelog and the OpenAPI schema (regenerated at the week-4 freeze) are the source of truth.
2. **Shared files** (`settings.py`, `requirements.txt`, `pubspec.yaml`, CI configuration) change only via PR reviewed by at least one other member.
3. **Testing:** each member writes tests for their own code; each runs at least one other member's acceptance checklist at phase gates (prevents "works on my machine").
4. **Docs as you go:** every merged feature updates its doc section — the Phase 9 report is assembled, not written from scratch.
5. **Equal academic weight:** all three members present at the demo; commit history should reflect each member owning their primary paths (enforced by the path ownership below).

## Suggested repo path ownership

```text
backend/apps/accounts/        → Member A
backend/apps/farms/           → Member A
backend/apps/livestock/       → Member A
backend/apps/health_records/  → Member A
backend/apps/veterinary/      → Member A
backend/apps/disease_reports/ → Member C
backend/apps/announcements/   → Member C
backend/apps/notifications/   → Member C
backend/apps/audit/           → Member C
backend/apps/sync/            → Member C (backend ledger) / Member B (mobile queue)
backend/apps/assistant/       → Member C
backend/config/ (settings)    → shared — PR review by at least one other member required
backend/dashboard/            → Member C
mobile/                       → Member B
docs/                         → shared — see per-doc authorship in Phase 0 row above
tests/                        → shared — E2E scripts are joint
```
