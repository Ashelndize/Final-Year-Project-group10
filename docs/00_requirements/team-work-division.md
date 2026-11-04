# Team Work Division — Group 10 (2 members)

| Member | Stack | Primary ownership |
|---|---|---|
| **Member A** | Backend / Dashboard | Django REST Framework API, MySQL, authentication & RBAC, audit trail, authority dashboard (Django templates), suspicious-activity rules, deployment |
| **Member B** | Mobile | Flutter app, state & navigation, GPS/maps, offline storage + sync queue, AI assistant UI, notifications UI, device testing |

Both members review each other's pull requests at phase gates. Neither "approves" their own phase-gate checklist.

## Ownership by phase

| Phase | Member A | Member B | Joint |
|---|---|---|---|
| 0 — Requirements | Backend/data/security docs (charter, SRS, ERD plan, API reqs, threat model, AI/audit policies, business rules) | UX/planning docs (user stories, access matrix, architecture overview, screen inventory, MVP plan, risk register, test plan, exit checklist) | Review + sign-off on all docs |
| 1 — Environment | venv, Django project, MySQL db + least-privilege user, `.env`, health-check endpoint, `.gitignore` | Flutter project scaffold, emulator/device setup, first API call from app | Repo layout, setup guide (`docs/02_setup/`) |
| 2 — Backend core | All models, migrations, JWT auth, RBAC permissions, DRF endpoints, drf-spectacular docs, backend tests, synthetic data fixtures | — (consumes OpenAPI schema to plan services) | API contract freeze before Phase 3 |
| 3 — Farmer app | Support on API gaps (e.g., filtering, endpoints) | Full Flutter app: auth screens, dashboard, farm/animal CRUD, health records, vaccination reminders, API service layer | Phase 3 acceptance test (E2E) |
| 4 — GPS + reporting | Vet/assistance/report APIs, jurisdiction restrictions, report status workflow | Map provider integration, location consent + manual fallback, assistance request UI, report submission support | Permission-testing of report access |
| 5 — Authority dashboard | Entire dashboard: review queue, statuses, announcement lifecycle, audit viewer, user management | Notification surfaces in app (outbreak alerts), announcement reading view | Unauthorized-publication tests |
| 6 — Security/offline/AI | Audit enforcement, django-axes + rules, AI knowledge base + provider interface + fallback, rate limiting | sqflite offline queue, idempotency UUIDs, sync + conflict UX, AI chat UI with disclaimers | Security test round, offline scenario matrix |
| 7 — Integration/UAT | Backend/API/security tests | Flutter widget/integration tests | 12-step end-to-end walkthrough, defect log, traceability updates |
| 8 — Deployment/docs | Production settings, HTTPS, backups, API deployment, admin manual | App build (APK), user manual (mobile) | Handover package, install/troubleshooting guides |
| 9 — Report | Implementation + backend/testing chapters | Mobile/UX chapters + demo script | Final report, limitations, maintenance plan, slides |

## Cross-cutting rules

1. **Interface contracts:** Member B never invents endpoints — both sign off when the API contract changes (versioned `docs/00_requirements/api-requirements.md` changelog + OpenAPI schema is the source of truth).
2. **Shared files** (settings, requirements.txt, CI) change only via PR reviewed by the other member.
3. **Testing:** each member writes tests for their own code; each runs the *other's* acceptance checklist at phase gates (catches "works on my machine").
4. **Docs as you go:** every merged feature updates its doc section — Phase 9 report is assembled, not written from scratch.
5. **Equal academic weight:** both members present at the demo; commit history should show each owning their stack (split by `backend/`+`dashboard/` vs `mobile/` paths).

## Suggested repo path ownership

```text
backend/     → Member A
dashboard/   → Member A (if separate; may live inside Django)
mobile/      → Member B
docs/        → shared (see per-doc authorship headers)
tests/       → shared (E2E scripts joint)
```
