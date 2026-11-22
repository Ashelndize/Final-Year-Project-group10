# Known Limitations

**Project:** Smart Livestock Health and Farm Management System
**Phase:** 8 — Deployment, Documentation, and Handover
**Date:** 2026-11-22

This document records the known limitations of the system at the time of academic submission. Each limitation explains what is not implemented, why it was deferred or excluded, and what the impact is.

---

## 1. AI health assistant — knowledge base not populated

**Status:** Deferred
**Applies to:** `assistant` app, KB-only provider
**Impact:** The AI assistant endpoint is functional (returns structured responses) but the knowledge base contains no articles. All queries return the "no matching KB entry" fallback response with a referral to contact a veterinarian.

**Why deferred:** The knowledge base requires curated, reviewed livestock health content from authoritative sources. The team did not have access to a reviewed content set within the project timeline. The database schema, API, and fallback behaviour are all implemented and ready.

**Future work:** Populate `KnowledgeBaseEntry` records via the Django admin or the seed command with reviewed livestock health articles from sources such as the FAO Animal Production and Health Guidelines.

---

## 2. External LLM integration not implemented

**Status:** Excluded by design ladder
**Applies to:** `assistant` app
**Impact:** The `ASSISTANT_PROVIDER` setting accepts `openai` and `anthropic` as values but the provider-specific code paths are not implemented. Only `kb_only` is functional.

**Why excluded:** External LLM integration requires API credentials, cost management, and additional safety testing that were not feasible within the academic timeline. DOC-REQ-012 §7 de-scope ladder step 2 explicitly covers this.

**Future work:** Implement the `OpenAIProvider` and `AnthropicProvider` classes in `backend/assistant/providers/`; wire them in `ASSISTANT_PROVIDER`; add the AI safety test suite (TC-AI-01..TC-AI-08).

---

## 3. Push notifications not implemented

**Status:** Excluded (EXCL-09)
**Applies to:** `notifications` app
**Impact:** Notifications are in-app pull only. The user must open the app to see new notifications; there is no background push to the device lock screen.

**Why excluded:** FCM/push transport was excluded from scope in DOC-REQ-001 §4.2 (EXCL-09). The `NotificationTransport` interface seam is implemented in `notifications/models.py` but the Firebase integration is not.

**Future work:** Integrate Firebase Cloud Messaging; implement `FCMTransport`; handle device token registration and renewal.

---

## 4. Performance testing not executed on production hardware

**Status:** Partial
**Applies to:** SC-07 — p95 < 500 ms
**Impact:** Performance was tested on the developer's Windows machine (E1) with the seed dataset (~20 animals, ~10 farms). The 10,000-animal load test specified in DOC-REQ-014 §12 (L8) was not executed.

**Why:** The project ran on a single developer machine throughout. Load-testing requires a stable server environment.

**What is known:** Response times on E1 with the seed dataset were well under 100 ms for all endpoints. The bottleneck is expected to be MySQL query performance on large un-indexed columns; all foreign keys and commonly filtered columns are indexed.

**Future work:** Run the Locust or curl-based load script from DOC-REQ-014 §12 on a dedicated machine with a 10,000-animal dataset.

---

## 5. UAT with real participants not conducted

**Status:** Not executed
**Applies to:** L10 — UAT
**Impact:** The usability testing described in DOC-REQ-014 §14 (UAT-01..UAT-10) with farmers, veterinarians, and authority staff was not conducted with real participants.

**Why:** Recruiting real participants, obtaining ethics approval, and conducting UAT sessions was outside the available time and resources.

**Mitigation:** The team used synthetic personas and conducted internal walkthroughs of all 10 UAT tasks. The 12-step E2E integration test covers the same functional paths.

---

## 6. iOS build not produced

**Status:** Excluded (EXCL-07)
**Applies to:** Mobile app
**Impact:** The app is Android-only. No `.ipa` file is provided.

**Why:** DOC-REQ-001 §4.2 EXCL-07 explicitly excludes iOS. The team did not have a Mac or Apple Developer account.

---

## 7. Offline operations limited to three write types

**Status:** Partial (de-scope ladder step 3 applied)
**Applies to:** `connectivity_service`, `sync_service`
**Impact:** Only three operations can be queued offline: health record creation, disease report submission, and veterinary assistance requests. Animal creation, farm creation, and other mutations require an active connection.

**Why:** DOC-REQ-012 §7 de-scope ladder step 3 authorizes reducing offline scope to core health observations. Implementing offline support for all mutations would have required significant additional work and cross-conflict resolution logic.

---

## 8. Map widget not implemented

**Status:** Partial (de-scope ladder step 4 applied)
**Applies to:** Veterinary assistance, GPS location
**Impact:** Veterinary search uses a list-based area selector rather than an interactive map. GPS coordinates are captured and stored when the user grants permission, but no map tile view is shown in the app.

**Why:** DOC-REQ-012 §7 de-scope ladder step 4 permits replacing the map widget with a list-based area search while keeping consent and manual fallback behaviour.

---

## 9. Backup/restore drill — cross-run verification pending

**Status:** Procedure documented; end-to-end execution pending
**Applies to:** SC-08, L9
**Impact:** The backup and restore scripts are written and tested in isolation. The full drill (drop database → restore → verify counts → pass test suite) is documented in `docs/04_deployment/backup-restore-guide.md` but awaits execution by a second team member (Member B) per the cross-run rule in DOC-REQ-014 §2.

---

## 10. Announcement versioning — no side-by-side compare UI

**Status:** Partial (de-scope ladder step 5 applied)
**Applies to:** `announcements` app, authority dashboard
**Impact:** Announcement updates are recorded as new versions in the database (the `version` field increments), but the dashboard does not provide a side-by-side diff view of two versions.

**Future work:** Implement a version-history view on the announcement detail page.

---

## 11. Email-based password reset not fully configured

**Status:** Partial
**Applies to:** `accounts` app
**Impact:** The password reset endpoints exist and are wired in URLs, but email delivery in production requires a configured SMTP provider. The default `EMAIL_BACKEND` is `console` (prints to stdout) which is not suitable for production.

**Configuration:** Set `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, and `EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend` in the `.env` file when deploying with a real mail provider.

---

## 12. Single-country, single-language scope

**Status:** By design
**Applies to:** Entire system
**Impact:** The system is designed for Zimbabwe; area names and content are Zimbabwe-specific. The UI is English-only.

**Future work:** Add `django-i18n` or `flutter_localizations` for multilingual support; abstract area hierarchy for multi-country deployment.
