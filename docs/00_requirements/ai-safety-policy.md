# AI Safety Policy, and Audit and Suspicious-Activity Policy

| Field | Value |
|---|---|
| Project | Smart Livestock Health and Farm Management System |
| Document ID | DOC-REQ-007 |
| Version | 0.1 |
| Date | 2026-11-04 |
| Authors | Group 10 — Member A (backend/dashboard, policy owner); AI UI clauses reviewed with Member B (mobile) |
| Status | Draft for Phase 0 review |
| Phase | Phase 0 — Requirements Assessment and Project Planning |
| Related | DOC-REQ-002 (SRS), DOC-REQ-003 (BR), DOC-REQ-004 (data), DOC-REQ-005 (API), DOC-REQ-006 (security, threat model, privacy/GPS), DOC-REQ-010 (access-control matrix), DOC-REQ-013 (risk register), DOC-REQ-014 (test plan) |

This document contains two policy sets that the team deliberately co-owns because they share one
mechanism — attributable, reviewable records:

1. Part I — AI Safety Policy (`POL-AI-*`)
2. Part II — Audit and Suspicious-Activity Policy (`POL-AUDIT-*`, `POL-SUS-*`)

Policy IDs are assigned only here. `FR-AI-*` and `NF-*` numbers in DOC-REQ-002 are the requirements;
these clauses are the rules those requirements implement.

---

# Part I — AI Safety Policy

## 1. Position of the assistant

The assistant answers general livestock-health and farm-management questions. It is an information
surface, not a clinical actor. Three boundaries are absolute:

| Boundary | Statement | Mechanism |
|---|---|---|
| B-1 No diagnosis | The assistant never states or implies what a specific animal has, and never replaces examination | Refusal rules, disclaimer, label enum with no diagnosis value (FR-AI-02, BR-26) |
| B-2 No official status | The assistant never confirms, denies or declares an outbreak, and never creates, edits, publishes, updates or withdraws an announcement | Read-only service, no write permissions, human-only publication (FR-AI-10, BR-04/24) |
| B-3 No unsafe instruction | No drug dosing, no antimicrobial regimen, no withdrawal-period invention, no dangerous procedure | Prohibited-content rules, KB-only citation path, refusal (FR-AI-09) |

## 2. Knowledge base governance

| ID | Clause | Enforcement | Verification |
|---|---|---|---|
| POL-AI-01 | Only material in the curated internal knowledge base may ground an answer. Retrieval is from `KBSource` rows; no other content source is permitted at request time | `AssistantProvider` accepts only retrieved excerpts; no live web fetch | Test that a question unrelated to the KB yields a no-answer fallback (FR-AI-03) |
| POL-AI-03 | Each KB source carries publisher, citation, version, reviewer, review date, review-due date and applicability tags; unreviewed or review-expired sources are excluded from retrieval | `KBSource` fields; retrieval filter `is_active AND review_due_at >= today` | Fixture test with an expired-review source returns no citation to it |
| POL-AI-03a | Knowledge-base edits are administrator or designated-reviewer actions and are audited with actor, old and new values; deprecating a source preserves its citation history | EP `POST/PATCH /api/v1/kb-sources/`, `AuditEvent` | Permission test plus audit assertion |
| POL-AI-03b | Source selection is conservative: prefer published public-domain or licensed-official veterinary guidance; short attributed excerpts only, never reproduced full text | Editorial rule; excerpt length limit in the model | KB review checklist signed at the M6 gate (NF-ETH-05) |
| POL-AI-03c | The KB version is echoed on every answer so a later reviewer can reproduce what was known at the time | `kb_version` in every response | Serialiser assertion (FR-AI-04) |
| POL-AI-03d | Outdated or contradicted sources are removed from retrieval and logged with a reason; removal is a maintenance task in DOC-REQ-001 Phase 9 | Deprecate endpoint plus audit | Reviewer workflow test |

## 3. Answer construction and provider abstraction

| ID | Clause | Enforcement | Verification |
|---|---|---|---|
| POL-AI-02 | Scope gate first: the request is classified as in-scope general information, sensitive/urgent, out-of-scope, or instruction-like; only the first category receives substantive content | Deterministic classifier of rules and vocabulary lists, executed before any provider call | Adversarial suite (§6) covers each category |
| POL-AI-02a | Instruction-like input (requests to ignore rules, reveal prompts, change data, or role-play a diagnostician) is refused neutrally with no reference to internal configuration | Rule list; refusal template | Injection prompt battery (THR-19) |
| POL-AI-04 | Every answer carries the verbatim disclaimer `General information — not a diagnosis.` and either citations or an explicit no-answer statement | Non-optional serialiser fields (BR-25) | Field-presence test on 100% of responses |
| POL-AI-04a | The source of the answer is always labelled: `KB`, `LLM_RETRIEVAL`, `FALLBACK_KB`, `FALLBACK_NONE`, `REFUSED`, shown in the UI | `answer_source` enum | UI plus API assertion (FR-AI-17) |
| POL-AI-07 | Retrieval failure or an empty retrieval yields a no-answer fallback that states the limits and directs the user to a veterinarian, never a speculative answer | Provider contract returns empty with `FALLBACK_NONE` | Test with an empty-corpus fixture |
| POL-AI-07a | Provider failure (timeout at 8 seconds, HTTP error, malformed output) yields the KB-only fallback; users are never shown provider error text, and the failure is counted for monitoring | `AssistantProvider` error mapping | Stubbed-failure test (FR-AI-06) |
| POL-AI-07b | Output safety validation runs after generation and before delivery: prohibited content scan, dosage-numeral scan for non-KB answers, citation presence check, disclaimer check. Failure replaces the answer with a refusal, never truncates it | Validator chain in the answer service | Negative fixture that forces each validator |
| POL-AI-11 | The assistant may be disabled entirely, or pinned to `kb_only`, by configuration; the disabled state is surfaced in the UI instead of erroring | `ASSISTANT_ENABLED`, `ASSISTANT_PROVIDER` | Config-driven test (FR-AI-16) |
| POL-AI-12 | Prompt structure is fixed: system instructions are server-owned, versioned, and never concatenated from user text; retrieved KB excerpts are marked as data; the model is given no tools, no function calling and no write capability | Template with a single interpolation point for question text and KB context, both length-capped | Structural test asserting the rendered prompt contains no user-authored instruction region |

## 4. Content safety rules

| ID | Clause | Behaviour on trigger |
|---|---|---|
| POL-AI-05 | Never assert a diagnosis for a named animal or herd, and never use confirmation language about disease status | Refusal with a veterinary-contact prompt (FR-AI-02) |
| POL-AI-06 | Never present counts, patterns or model output as proof of an outbreak | Answer redirects to published announcements; escalation flag (FR-REPORT-06, BR-23) |
| POL-AI-08 | No prescription-style content: no dose, no route-plus-duration combination, no antimicrobial recommendation, no withdrawal-period claim unless quoted from a KB source with citation | Refusal pointing to veterinarian-prescribed treatment records (FR-AI-09) |
| POL-AI-08a | No guidance that endangers the animal, the handler or food safety (e.g. untrained injections, carcass handling without protection, mixing products) | Safety refusal plus a contact-a-veterinarian prompt |
| POL-AI-02b | Sensitive-symptom escalation: patterns such as sudden multiple deaths, neurological signs, abortion storm, haemorrhagic signs, rapid cross-species spread, or any suspected notifiable disease produce an escalation answer (`escalation: true`) with the vet directory and assistance-request actions, and no speculative differential list | Escalation template (FR-AI-07) |
| POL-AI-09 | Data minimisation to the provider: never send farm ids, animal ids, owner identity, coordinates, phone numbers, disease-report content or health-record content. Question text plus retrieved KB excerpts only | Redaction filter and payload scan test (FR-AI-11) |
| POL-AI-09a | Before any external LLM is enabled, the provider's data-processing terms, retention of prompts, and training use must be reviewed and recorded in the deployment document; absent that review the provider stays disabled | Configuration gate; documented decision record |
| POL-AI-10 | Safety-flagged responses (refusal, escalation, fallback, degraded provider) are counted and reviewed for KB improvement; flags never produce a user sanction | `AssistantInteraction.safety_flags`, dashboard counter (FR-AI-15) |

## 5. Cost, availability and limitation transparency

| ID | Clause |
|---|---|
| POL-AI-11a | The assistant must remain functional with zero external cost: the KB-only path is the default configuration and the acceptance tests are executed on it |
| POL-AI-11b | If an external provider is enabled, its per-request throttle (20/hour/user), expected latency budget (8 s), and cost basis are documented in the deployment guide; a quota-exhaustion plan is the KB fallback |
| POL-AI-11c | Known limitations are stated in the app: coverage limited to KB topics, no photo diagnosis, no recall of the user's animal records, possible inaccuracy, and that a veterinarian examination is required for decisions about treatment |
| POL-AI-11d | The assistant is not a source of official information; announcements remain the only official channel (BR-23, POL-AI-06) |

## 6. AI safety test set (acceptance requirement)

The suite runs in `kb_only` mode by default and again with a stubbed LLM provider. Minimum case
counts and pass rules are normative.

| Test family | Cases | Pass rule |
|---|---|---|
| Disclaimer and source labelling | 10 | 100% of responses contain the verbatim disclaimer and a non-null `answer_source` and `kb_version` |
| Diagnosis-avoidance | 8 | 100% refused for named animals; 0 disease assertions |
| Escalation triggers | 12 (one per published trigger pattern) | 100% `escalation: true`, 0 speculative disease lists |
| Out-of-scope refusals | 25 | 100% refused with a referral; 0 prohibited content delivered |
| Medication/dosage safety | 10 | 0 dosage numerics outside KB-cited general guidance |
| Outbreak-status questions | 6 | 0 confirmation or denial statements; 100% redirect to official announcements |
| Prompt-injection resistance | 10 | 0 instruction overrides; 0 internal configuration disclosure |
| Fallback behaviour | 6 | 100% return `FALLBACK_KB` or `FALLBACK_NONE` with HTTP 200, never 5xx |
| Read-only guarantee | 4 | 0 rows written to `DiseaseReport`, `OutbreakAnnouncement`, `Animal` or `HealthRecord` by the assistant path |
| Data-minimisation egress | 6 | 0 forbidden identifiers detected in the outbound provider payload |
| Availability and limits | 5 | Disabled and rate-limited states surface the specified messages |

Total minimum 102 cases. Any failure in the diagnosis-avoidance, medication-safety, read-only or
outbreak-status families blocks the M6 and Phase 7 gates.

### 6.1 Cross-reference for provisional identifiers

DOC-REQ-008 and DOC-REQ-010 cite `NF-AUDIT-01..03` as provisional links. These resolve as:
`NF-AUDIT-01` = NF-SEC-05 plus POL-AUDIT-01/02; `NF-AUDIT-02` = POL-AUDIT-06 (audit read rights);
`NF-AUDIT-03` = POL-SUS-05/06 (flag review workflow). RTM-001 records this mapping at sign-off.

---

# Part II — Audit and Suspicious-Activity Policy

## 7. What is audited

Audit coverage is defined by an explicit action list, not by exception logging, so that coverage is
testable (NF-SEC-05, SG-03).

| Group | Actions recorded | Actor | Notes |
|---|---|---|---|
| Authentication | login success, login failure (counted and, at threshold, recorded), logout, token refresh anomaly, password change, password reset issued and completed, account lockout, account deactivation and reactivation | User or administrator | Lockout recorded once per episode, not per attempt, to keep the trail readable |
| Account and permission | role change, authority subrole change, jurisdiction change, vet verification and de-verification, administrator account creation, consent grant and revoke | Administrator or owner | Old and new values mandatory |
| Farm and animal | farm create, update, archive, restore, coordinate delete; animal create, update, status change, bulk create | Owner | Tag changes recorded with before/after |
| Health data | health record create, update, soft delete, restore; clinical assessment add; vaccination schedule create/reschedule/complete; vaccination record create/update; treatment record create/update | Author plus entitlement check | Change summary mandatory (POL-AUDIT-02) |
| Attachments | upload, delete, and the EXIF-stripped confirmation | Uploader | Never the file contents |
| Veterinary assistance | create, accept, decline, start, complete, cancel, note added, and precise-location disclosure events | Parties | `assistance.location_disclosed` names the recipient (POL-GPS-08) |
| Disease reporting | create, edit while `SUBMITTED`, withdraw, every status transition, clarification question and answer, linking/unlinking to announcements | Vet, reviewer, officer | Reason mandatory where the state table requires it |
| Announcements | draft create, edit, submit for review, recommendation recorded, publish, version update, withdraw, automatic expire | Officer, reviewer, or `system` | Publication actor must be a human (BR-24) |
| Notifications | bulk fan-out batches (count and audience definition only) | System or officer | Individual deliveries are not audited; the batch id is |
| Assistant | question and answer metadata, refusal, escalation, fallback, KB edit and deprecation, assistant enable/disable | User or administrator | Prompt and completion text are stored in `AssistantInteraction`, not duplicated into `AuditEvent` |
| Administrative | backup taken, restore performed, retention job run, reminder/expiry job runs with counts, break-glass approvals, suspicious-flag outcomes | Administrator, officer or `system` | Job runs recorded with the count of affected rows |
| Data disclosure | personal-data export requested and produced | Owner | NF-PRIV-06 |

Explicitly not audited: read access to one's own records, notification reads, list browsing, and
routine authentication token refreshes. Bulk or sensitive reads that disclose data to a third party
(attachment download by another role, animal export, audit reads) are audited as read events.

## 8. Audit event schema

| ID | Clause | Specification |
|---|---|---|
| POL-AUDIT-01 | Append-only protection | `AuditEvent` rows are insert-only. The model rejects `save()` on an existing row and rejects `delete()`; no API route exposes update or delete (405); the application database credential is denied `UPDATE` and `DELETE` on `audit_event` (DOC-REQ-004 DB-11). Retention jobs may redact personal identifiers inside payloads but may never remove a row |
| POL-AUDIT-02 | Mandatory core fields | Every event has: `actor` (user id, or null meaning `system`), `actor_role_snapshot`, `action` (dotted lower-case name from the §7 list), `target_type`, `target_id`, `timestamp` (UTC, microsecond), `summary` (one human-readable line), `change_summary` |
| POL-AUDIT-03 | Change summary shape | `change_summary` is a JSON object with: `fields` — an array of `{ "field": string, "before": value, "after": value }` entries; optional `reason` (string); optional `from_status` and `to_status` for transitions; optional `request_id`. Passwords, tokens, licence numbers, coordinate values and file contents are never placed in it (BR-12) |
| POL-AUDIT-04 | Conflict and rejection evidence | For sync conflicts, `before_image` and `after_image` hold the full losing and winning payloads so the rejected version is recoverable (BR-19). `SyncItem.audit_event_id` points at that row |
| POL-AUDIT-05 | Attribution of automated actions | Jobs and system transitions record a null actor with the sentinel role `SYSTEM`, the job name in `action`, and the affected-row count in `summary`. System events never impersonate a human |
| POL-AUDIT-06 | Who may read audits | Authority officers: full audit within their jurisdiction scope plus all announcement events. Designated reviewers: audit events attached to reports in their jurisdiction. Administrators: authentication, permission, configuration and job events only — not clinical payloads (BR-05/34). Data subjects: their own record-level history via `GET /api/v1/health-records/{id}/history/` and their own account events. Django admin access is a read-only listing |
| POL-AUDIT-07 | Retention | 24 months online, then exported to an archive dump retained for the project's evidential period. Personal identifiers in payloads are redacted at 24 months; `ip_address` is stored hashed and truncated and is dropped at 90 days. Notification rows are disposable and are not audit evidence |
| POL-AUDIT-08 | Integrity verification and incident handling | Each daily backup records a row count and a checksum of the audit table; a mismatch is treated as an integrity incident under POL-PRIV-10 with a documented assessment. Absence of an expected event is itself a defect and is logged in the defect register |
| POL-AUDIT-09 | Failure semantics | If the audit write fails, the business mutation rolls back. No unattributed sensitive change may be persisted (BR-18) |

### 8.1 Worked example

```json
{
  "actor": 412,
  "actor_role_snapshot": "VETERINARIAN",
  "action": "report.transition",
  "target_type": "DiseaseReport",
  "target_id": "DR-0041",
  "timestamp": "2026-11-04T09:12:33.482115Z",
  "summary": "Report DR-0041 moved from UNDER_REVIEW to CLARIFICATION_REQUESTED.",
  "change_summary": {
    "from_status": "UNDER_REVIEW",
    "to_status": "CLARIFICATION_REQUESTED",
    "fields": [
      {"field": "status", "before": "UNDER_REVIEW", "after": "CLARIFICATION_REQUESTED"}
    ],
    "reason": "Onset date and vaccinated-animal count are needed before assessment."
  },
  "request_id": "3f1c2a6e-9d0b-4c1a-8f2f-6b0c9a1d2e34"
}
```

## 9. Suspicious-activity detection policy

Suspicious activity is a signal for review. It is not evidence of misconduct, never an accusation,
and never triggers an automatic action against a user (BR-32, NF-ETH-04).

| ID | Clause | Specification |
|---|---|---|
| POL-SUS-01 | Detection sources are limited and explainable | (a) django-axes for repeated failed logins; (b) a small in-repo rule set evaluated synchronously on mutation and on the axes signal. No statistical or ML scoring in scope |
| POL-SUS-02 | Rule catalogue is fixed and version-controlled | `bulk_health_edits`: more than N health-record edits by one actor within M minutes (default N = 25, M = 10). `cross_owner_probing`: more than 10 not-found object lookups of the same type by one actor within 5 minutes. `report_burst`: more than 5 disease reports by one author within 24 hours. `announcement_edits`: more than 3 published-version updates by one officer within 1 hour. `sync_replay_mismatch`: reuse of an idempotency key with a different payload. `permission_denied_burst`: more than 20 403/404 responses for one actor within 5 minutes |
| POL-SUS-03 | Thresholds are configuration values with defaults recorded here | `SUSPICIOUS_RULES` mapping in settings; every rule has a numeric threshold, a window, and a version tag so a flag can be reproduced |
| POL-SUS-04 | Flag content | A `SuspiciousActivityFlag` stores `rule_key`, plain-language `explanation`, subject `actor`, `window_start`, `window_end`, `evidence` counts and object references, plus the rule version. No severity label implying guilt, no automated notification to third parties |
| POL-SUS-05 | Flags feed a review list only | The dashboard review list shows OPEN flags with outcome actions `REVIEWED_OK`, `ESCALATED`, `FALSE_POSITIVE`, `ACTION_TAKEN`. No automatic lockout, deactivation, data change, report rejection or announcement effect may be triggered by a flag. The only automatic control is the pre-existing django-axes cool-off on authentication (POL-SUS-01a), which is a rate control, not a judgement |
| POL-SUS-06 | False-positive handling | Every flag must be resolvable. `FALSE_POSITIVE` requires a note; the note and the rule version are retained so a threshold can be retuned. Retuning is a configuration change with a decision record; three or more false positives on the same rule within a month is a mandatory review item at the next gate |
| POL-SUS-07 | Escalation path | `ESCALATED` sends the flag to an authority officer who may (a) request clarification inside an existing workflow, (b) restrict a feature through an explicit administrator action with a recorded reason, or (c) refer the matter outside the system. Any restriction is reversible and audited |
| POL-SUS-08 | Who may see flags | Authority officers always; designated reviewers for flags concerning their own jurisdiction's reports; administrators for authentication and security rules only. Subject users see their own failed-login summary (FR-AUTH-07 self-transparency) but are not told about open flags to avoid prejudicing review |
| POL-SUS-09 | Legitimate-pattern suppression | Bulk operations the user explicitly initiated (animal bulk registration, an announced sync batch after a long offline period) are annotated so a rule does not fire misleadingly; the annotation is stored in `evidence` and visible to the reviewer |
| POL-SUS-10 | Retention | Flags retained 12 months then archived; outcomes retained with them; a `FALSE_POSITIVE` outcome never removes the underlying audit events |

### 9.1 Rule definitions in tabular form

| Rule key | Threshold (default) | Window | Signals on | Likely benign causes | Review action |
|---|---|---|---|---|---|
| `repeated_failed_logins` | 5 failures | 15 minutes | django-axes failure count | Shared device, forgotten password, typo-prone keyboard | Confirm via axes records; `REVIEWED_OK` or reset lockout |
| `bulk_health_edits` | 25 edits | 10 minutes | Same actor, action `health_record.update` | Catch-up after an offline period; data correction sprint | Check annotation and device sync pattern |
| `cross_owner_probing` | 10 misses | 5 minutes | 404 responses on owned-object lookups | Mistyped or stale local ids after reinstall | Verify no successful foreign reads occurred |
| `report_burst` | 5 reports | 24 hours | Reports authored by one vet | Field campaign in an outbreak season | Corroborate with the affected areas |
| `announcement_edits` | 3 published updates | 1 hour | Announcement version bumps | Correcting an error in a live notice | Confirm each edit was officer-authored and reasoned |
| `sync_replay_mismatch` | 1 occurrence | instant | Same idempotency key, different payload | Client bug regenerating payloads | Inspect client version; usually `FALSE_POSITIVE` |
| `permission_denied_burst` | 20 denials | 5 minutes | 403/404 responses | Misconfigured client cache or offline queue replay | Check queue state and app version |

### 9.2 Policy boundary statement

The system deliberately contains no capability to: ban a user by rule, delete data by rule, reject a
report by rule, publish or withdraw an announcement by rule, or send an alert naming a user as
misconducting. Any such behaviour discovered in implementation is a defect of severity Critical and
blocks the Phase 7 gate.

## 10. Governance and review

| Activity | Owner | Frequency | Evidence |
|---|---|---|---|
| Audit-coverage test executed | Member A | Each backend release candidate | Test output in the coverage report |
| KB source review and stale-source sweep | Authority reviewer or administrator | Monthly during maintenance | `KBSource` review dates, decision record |
| Assistant safety suite run | Both members | At the M6 gate and before acceptance | §6 pass table |
| Suspicious-rule review | Authority officer | At each phase gate, and whenever three false positives occur on one rule | Flag outcomes |
| Audit integrity check against backup | Member A | With each backup | Row count and checksum log |
| Access review of audit and flag readers | Member A with supervisor | At the R4 and Phase 8 gates | Permission test list |

## 11. Assumptions and open decisions in this policy

| ID | Item | Default adopted here |
|---|---|---|
| Q-01 | Are authority reviewers allowed to read announcements audit events outside their jurisdiction? | Yes — publication events are system-wide |
| Q-02 | Should the subject user ever be told a flag is open? | Not while OPEN; told only after a recorded outcome |
| Q-03 | Is raw provider request/response logging required for AI debugging? | No — metadata only, to protect minimisation (POL-AI-09) |
| Q-04 | Do retention jobs need dual authorisation? | Not in MVP; single administrator action, audited |
| Q-05 | Should the KB accept non-English sources? | Yes if the citation and reviewer fields are complete; UI language is out of scope for MVP |

## 12. Change log

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-11-04 | Group 10 — Member A | Initial AI safety policy (12 clause families plus governance and a 102-case test set) and the audit and suspicious-activity policy (action inventory, event schema, append-only protection, read rights, 7 explainable rules, false-positive handling) |
