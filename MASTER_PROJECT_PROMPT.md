# MASTER PROJECT PROMPT: SMART LIVESTOCK HEALTH AND FARM MANAGEMENT SYSTEM

## PROJECT TITLE

Design and Implementation of a Secure Smart Livestock Health and Farm Management System with GPS-Based Veterinary Assistance, AI-Powered Health Information, and Disease Outbreak Monitoring.

## 1. YOUR ROLE

Act as a senior software engineer, business analyst, system architect, database engineer, cybersecurity specialist, Flutter developer, Django REST Framework developer, tester, and technical documentation writer.

Your responsibility is to guide and implement this project systematically, from requirements assessment to a working, tested, deployed, and documented application.

Work directly within the existing repository when repository access is available.

Before changing anything, inspect the existing repository, read its documentation, identify the technologies already installed, and preserve useful existing code.

Do not assume that a feature works merely because its files exist. Verify functionality using tests and actual execution where possible.

Do not skip phases, generate placeholder implementations that appear complete, invent test results, or claim success without evidence.

---

# PHASE 0: REQUIREMENTS ASSESSMENT AND PROJECT PLANNING

**Objective:** Define what the system must do, who will use it, and how its success will be evaluated before implementing application features.

### Step 0.1: Inspect the repository

- Inspect the project structure, README, existing code, configurations, dependencies, and tests.
- Identify existing components and missing components.
- Record environment problems and potential compatibility issues.
- Preserve useful code and document proposed changes before making destructive changes.

### Step 0.2: Define the project

Document:

- Problem statement.
- Main goal and specific objectives.
- Project scope and exclusions.
- Stakeholders and responsibilities.
- Assumptions, constraints, dependencies, and risks.
- Expected deliverables and measurable success criteria.

### Step 0.3: Prepare the Software Requirements Specification (SRS)

Document functional and non-functional requirements with unique IDs, priorities, dependencies, and acceptance criteria.

Cover all system modules described in this prompt.

### Step 0.4: Define user roles

Include:

1. Farmer.
2. Veterinarian.
3. Authorized veterinary authority or reviewer.
4. System administrator.

Define which data each role can create, read, update, approve, publish, archive, or delete.

Use least-privilege access and enforce permissions on the backend.

### Step 0.5: Document the workflows

Prepare user stories, use cases, business rules, activity diagrams, and acceptance criteria for the main workflows.

### Step 0.6: Prepare the design documents

Create:

- System architecture diagram.
- Use-case diagram.
- Entity-Relationship Diagram (ERD).
- Database data dictionary.
- API design.
- UI screen inventory and wireframes.
- Navigation flow.
- Preliminary deployment architecture.

### Step 0.7: Prepare the security and privacy requirements

Document:

- Threat model.
- Access-control matrix.
- Data inventory and classification.
- GPS consent and privacy policy.
- Audit-trail policy.
- AI safety policy.
- Suspicious-activity detection policy.
- Data retention and backup requirements.
- Research ethics requirements, where applicable.

### Step 0.8: Prepare delivery planning

Create:

- Work Breakdown Structure (WBS).
- Project timeline and milestones.
- Risk register.
- Minimum Viable Product (MVP).
- Test strategy.
- Requirements traceability matrix.
- Environment setup guide.
- Phase approval checklist.

### Phase 0 deliverables

Store the documentation under `docs/00_requirements/` or the existing equivalent structure.

Do not proceed to substantial implementation until the requirements, MVP, critical design decisions, and acceptance criteria have been reviewed.

---

# PHASE 1: DEVELOPMENT ENVIRONMENT AND REPOSITORY SETUP

**Objective:** Prepare a reproducible development environment.

## Required technology stack

- Mobile application: Flutter and Dart.
- Backend: Python and Django REST Framework.
- Central database: MySQL.
- Authority dashboard: Django templates or a separately justified web frontend.
- Local offline storage: SQLite or another justified Flutter-compatible solution.
- API testing: Postman or an equivalent tool.
- Version control: Git.
- IDE: VS Code or another compatible IDE.
- Automated testing: Django tests and Flutter tests.

Do not add unnecessary technologies without documenting why they are needed.

## Tasks

1. Verify Python, Django, MySQL, Flutter, Dart, Git, and the Android development environment.
2. Resolve installation or configuration problems before continuing.
3. Organize the repository into backend, mobile, dashboard, documentation, and testing folders as appropriate.
4. Configure Git and `.gitignore`.
5. Create a Python virtual environment.
6. Install and record compatible backend dependencies.
7. Configure MySQL and create a dedicated application database and least-privilege database user.
8. Configure environment variables for credentials, secret keys, allowed hosts, and external service configuration.
9. Never commit passwords, API keys, tokens, or other secrets.
10. Create a basic Django health-check endpoint.
11. Create a minimal Flutter application that can communicate with the backend.
12. Document exact setup commands and troubleshooting procedures.

### Phase 1 acceptance criteria

- Backend starts successfully.
- Database connection succeeds.
- Health-check endpoint responds correctly.
- Flutter app runs on a supported test device or emulator.
- App-to-backend communication works.
- Another developer can reproduce the setup using the documentation.

---

# PHASE 2: DATABASE, BACKEND, AUTHENTICATION, AND API

**Objective:** Implement the secure foundation of the system.

## Tasks

1. Implement the approved database design using Django models.
2. Create and apply database migrations.
3. Implement authentication and account management.
4. Implement role-based access control.
5. Enforce record ownership and object-level permissions.
6. Create the API for the core project modules.
7. Validate input and return consistent error responses.
8. Implement pagination, filtering, and search where appropriate.
9. Add audit logging for sensitive operations.
10. Add API documentation.
11. Prepare synthetic development data.
12. Write automated tests for models, permissions, validation, and API behavior.

## Core data entities to assess

- User and role.
- Farmer profile.
- Veterinarian profile.
- Farm.
- Animal.
- Health record.
- Treatment record.
- Vaccination record.
- Veterinary assistance request.
- Disease report.
- Official outbreak announcement.
- Notification.
- Audit event.
- Offline synchronization metadata, if required.

Choose the final models and relationships based on the approved ERD. Avoid unnecessary duplication of data.

### Phase 2 acceptance criteria

- Migrations work reproducibly.
- Authentication works.
- Protected endpoints enforce server-side permissions.
- Farmers cannot access another farmer's private records without explicit authorization.
- Core API tests pass.
- API documentation matches the implementation.

---

# PHASE 3: FARMER MOBILE APPLICATION AND FARM MANAGEMENT

**Objective:** Build a functional mobile application for farmers.

## Tasks

1. Establish app navigation and reusable UI components.
2. Implement registration, login, logout, and profile management.
3. Create the farmer dashboard.
4. Implement farm creation and farm management.
5. Implement animal registration and animal inventory.
6. Implement animal profile and identification.
7. Implement health histories and treatment records.
8. Implement vaccination schedules and reminders.
9. Connect the app to the backend through a reusable API service layer.
10. Implement loading, empty, validation, success, and error states.
11. Handle expired sessions and network failures.
12. Test the app on supported screen sizes and devices.

### Phase 3 acceptance criteria

A farmer can authenticate, manage their farm, register animals, record permitted health information, and view vaccination reminders through the mobile application.

Data must persist correctly in the central database, and access restrictions must be enforced.

---

# PHASE 4: GPS, VETERINARY ASSISTANCE, AND DISEASE REPORTING

**Objective:** Connect farmers with veterinary services and enable structured reporting.

## Tasks

1. Select a suitable map provider.
2. Document map API restrictions, pricing, privacy, and configuration.
3. Implement location permission handling and consent.
4. Provide manual area selection when GPS is unavailable or declined.
5. Display verified veterinary service locations where reliable data exists.
6. Implement veterinary profile search.
7. Implement assistance requests.
8. Track assistance request status.
9. Implement structured disease reports.
10. Include appropriate fields for species, observation date, area, observed signs, notes, and supporting evidence when justified.
11. Restrict access to reports according to role and jurisdiction.
12. Test denied location permissions, inaccurate location, offline operation, and invalid submissions.

### Phase 4 acceptance criteria

Farmers can locate available veterinary services or select an area manually, submit assistance requests, and report observations securely.

Location sharing must be consent-based, and unverified reports must not be treated as confirmed diagnoses or outbreaks.

---

# PHASE 5: AUTHORITY DASHBOARD AND OFFICIAL OUTBREAK ANNOUNCEMENTS

**Objective:** Enable authorized veterinary personnel to review disease reports and publish official information.

## Tasks

1. Build a secure authority dashboard.
2. Implement role-specific authentication and permissions.
3. Create a disease-report review queue.
4. Implement report statuses such as submitted, under review, clarification requested, accepted for further assessment, rejected, and closed.
5. Record reviewer decisions, timestamps, reasons, and relevant changes.
6. Allow authorized reviewers to assess possible patterns in reports.
7. Implement official announcement creation, review, publication, updating, expiry, and withdrawal.
8. Include issuing authority, affected area, publication date, review or expiry date, and prevention guidance.
9. Notify relevant users when appropriate.
10. Ensure that official announcements are distinguishable from unverified reports.
11. Test unauthorized publication attempts and workflow errors.

### Critical rule

Only authorized human personnel can publish official outbreak announcements.

AI output, report counts, or automated pattern detection must never independently confirm an outbreak or publish an official notice.

### Phase 5 acceptance criteria

Authorized reviewers can manage reports and publish official announcements, while unauthorized users cannot perform those actions.

All important review decisions and publication events must be auditable.

---

# PHASE 6: SECURITY, AUDIT TRAIL, SUSPICIOUS ACTIVITY, OFFLINE SYNC, AND AI

**Objective:** Complete and test the advanced security and assistance capabilities.

## A. Security

- Enforce least privilege and deny access by default.
- Validate input on the server.
- Protect authentication sessions or tokens.
- Apply rate limiting where appropriate.
- Protect sensitive configuration and credentials.
- Use HTTPS in deployed environments.
- Prevent unauthorized access to other users' records.
- Review file uploads and external integrations for security risks.

## B. Audit trail

Record relevant security and business events, including:

- Authentication successes and failures.
- Sensitive health-record changes.
- Role and permission changes.
- Disease-report review decisions.
- Official announcement publication or withdrawal.
- Important administrative actions.

Include actor, action, target, timestamp, and an appropriate change summary.

Never store passwords or authentication tokens in audit logs. Restrict audit access and protect audit records from unauthorized modification.

## C. Suspicious-activity detection

Implement simple, explainable rules where justified, such as repeated failed logins or unusual repeated changes to sensitive records.

Define thresholds, review procedures, false-positive handling, and alert access.

Suspicious activity is a signal for review, not proof of misconduct.

## D. Offline operation

1. Identify which workflows require offline support.
2. Implement local storage for approved data.
3. Minimize sensitive information stored on the device.
4. Track pending changes and synchronization state.
5. Implement retry handling and duplicate prevention.
6. Define conflict-resolution rules.
7. Test reconnecting, conflicting updates, failed sync, logout, and device-loss scenarios.

Do not claim that all features work offline unless they have been implemented and tested.

## E. AI health-information assistant

1. Identify an affordable and maintainable AI integration.
2. Use reviewed veterinary sources.
3. Display source information where feasible.
4. Clearly label responses as general information.
5. Recommend professional veterinary assistance when appropriate.
6. Prevent the assistant from independently diagnosing animals or publishing official alerts.
7. Avoid unsafe treatment instructions and unsupported medication recommendations.
8. Test incorrect assumptions, unsupported questions, ambiguous prompts, and failure scenarios.
9. Protect user data and document any external AI service's costs and limitations.
10. Provide a safe fallback when the AI service is unavailable.

### Phase 6 acceptance criteria

Security tests pass, audit events are recorded correctly, suspicious-activity rules are testable, offline synchronization behaves according to specification, and AI safety rules are enforced.

---

# PHASE 7: INTEGRATION, TESTING, AND ACCEPTANCE

**Objective:** Verify that the complete system works reliably and satisfies its requirements.

## Testing activities

1. Unit testing.
2. Backend API testing.
3. Database and migration testing.
4. Flutter widget testing.
5. Mobile integration testing.
6. End-to-end workflow testing.
7. Authentication and authorization testing.
8. Security testing.
9. GPS permission and location-privacy testing.
10. Notification testing.
11. Offline and synchronization testing.
12. AI response safety testing.
13. Performance and reliability testing.
14. Backup restoration testing.
15. Usability testing, where appropriate and approved.

## Required end-to-end workflow

Verify this complete sequence:

1. A farmer creates an account.
2. The farmer creates a farm.
3. The farmer registers an animal.
4. The farmer records a health event.
5. The system records a vaccination schedule.
6. The farmer requests veterinary assistance.
7. A veterinarian responds within their permissions.
8. A permitted user submits a disease report.
9. An authorized reviewer assesses the report.
10. The authorized authority publishes an official notice when justified.
11. Relevant users receive the notification.
12. Sensitive actions appear in the audit history.

## Defect management

Maintain a defect log containing:

- Defect ID.
- Description.
- Reproduction steps.
- Expected behavior.
- Actual behavior.
- Severity.
- Status.
- Resolution.
- Retest result.

Maintain a requirements traceability matrix linking each requirement to its implementation and test evidence.

### Phase 7 acceptance criteria

Critical workflows work end-to-end, permission tests pass, critical defects are resolved or formally accepted, and acceptance results are documented.

Never report a test as passed unless it was actually executed successfully.

---

# PHASE 8: DEPLOYMENT, DOCUMENTATION, AND HANDOVER

**Objective:** Prepare a secure and usable deployment.

## Tasks

1. Select an appropriate hosting environment.
2. Document deployment prerequisites and costs.
3. Configure production settings.
4. Configure HTTPS/TLS.
5. Configure environment variables and secrets securely.
6. Configure the production database with least-privilege access.
7. Apply migrations using a controlled deployment process.
8. Configure backups and retention.
9. Test database restoration.
10. Configure error monitoring and appropriate logging.
11. Deploy the backend API.
12. Deploy the authority dashboard.
13. Build and distribute the mobile app through an appropriate channel.
14. Verify production API connectivity and external integrations.
15. Prepare user and administrator documentation.
16. Prepare installation, deployment, troubleshooting, and backup/restore guides.
17. Train intended users where required.
18. Prepare a handover package.

## Required documentation

- Project README.
- Installation guide.
- Environment configuration guide.
- API documentation.
- User manual.
- Administrator manual.
- Database design and data dictionary.
- Security and privacy documentation.
- Test report.
- Deployment guide.
- Backup and recovery guide.
- Known limitations.
- Handover checklist.

### Phase 8 acceptance criteria

The agreed release runs in the target environment, production configuration is reviewed, backup restoration is verified, and the documentation and handover package are complete.

---

# PHASE 9: MAINTENANCE, EVALUATION, AND FINAL RESEARCH REPORT

**Objective:** Maintain the system and evaluate the project against its research objectives.

## Maintenance tasks

- Monitor application errors and service availability.
- Review security events and access permissions.
- Apply necessary dependency and security updates.
- Verify backup success and recovery procedures.
- Monitor failed notifications and synchronization.
- Correct data-quality problems through authorized procedures.
- Review AI sources and remove outdated information.
- Record user feedback and prioritize improvements.
- Maintain version history and release notes.

## Final research report

Prepare the final report using the institution's required format.

Include:

1. Introduction and background.
2. Problem statement.
3. General and specific objectives.
4. Research questions, if required.
5. Literature review.
6. Methodology.
7. Requirements analysis.
8. System design and architecture.
9. Database design.
10. Implementation.
11. Testing methodology and actual results.
12. Discussion of findings.
13. Security and privacy considerations.
14. Limitations.
15. Conclusion.
16. Recommendations and future work.
17. References.
18. Appendices.

Also prepare presentation slides, a demonstration script, screenshots, test evidence, and source-code documentation as required.

Never fabricate research findings, performance measurements, participant feedback, or test results.

### Phase 9 acceptance criteria

The system has a documented maintenance plan, the final research report reflects the actual implementation and results, and project limitations and future improvements are clearly stated.

---

# REQUIRED REPOSITORY STRUCTURE

Inspect the existing repository first and adapt the structure without destroying existing work.

Use this as a target structure where appropriate:

```text
smart-livestock-system/
├── README.md
├── MASTER_PROJECT_PROMPT.md
├── .gitignore
├── .env.example
├── docs/
│   ├── 00_requirements/
│   │   ├── project-charter.md
│   │   ├── software-requirements-specification.md
│   │   ├── user-stories-and-use-cases.md
│   │   ├── business-rules.md
│   │   ├── access-control-matrix.md
│   │   ├── architecture-overview.md
│   │   ├── data-requirements-and-erd-plan.md
│   │   ├── api-requirements.md
│   │   ├── ui-screen-inventory.md
│   │   ├── security-and-threat-model.md
│   │   ├── privacy-and-gps-policy.md
│   │   ├── ai-safety-policy.md
│   │   ├── audit-and-suspicious-activity-policy.md
│   │   ├── risk-register.md
│   │   ├── mvp-and-release-plan.md
│   │   ├── test-and-acceptance-plan.md
│   │   ├── requirements-traceability-matrix.md
│   │   └── phase-0-exit-checklist.md
│   ├── 01_design/
│   ├── 02_setup/
│   ├── 03_testing/
│   ├── 04_deployment/
│   └── 05_final_report/
├── backend/
├── mobile/
├── dashboard/
└── tests/
```

If the repository already has working components or a different established structure, preserve and adapt them rather than blindly recreating this layout.

---

# GENERAL DEVELOPMENT RULES

Apply these rules throughout all phases:

1. Work one phase at a time.
2. Inspect existing code before editing.
3. Keep the application modular and maintainable.
4. Use clear names, consistent formatting, and appropriate comments.
5. Keep credentials and secrets out of source control.
6. Enforce authorization on the backend, not only in the user interface.
7. Validate all user input.
8. Handle errors and network failures explicitly.
9. Write tests alongside features.
10. Update documentation when requirements or implementation change.
11. Use synthetic data for development and testing.
12. Record important technical decisions.
13. Do not introduce unnecessary dependencies.
14. Do not overwrite or delete existing work without review and justification.
15. Do not invent service data, veterinary advice, official findings, or successful test results.
16. Keep unverified reports separate from official announcements.
17. Protect farm and location information.
18. Make AI limitations clear to users.
19. Do not mark a phase complete until its acceptance criteria have been checked against evidence.
20. Request human approval at phase gates.

# HOW TO EXECUTE THIS PROMPT

Begin with Phase 0.

Inspect the repository, create or update the requirements documentation, identify gaps, and report the results.

Do not implement application features during Phase 0.

At the end of each phase, provide:

- Tasks completed.
- Files created or changed.
- Commands executed.
- Tests performed and their actual results.
- Outstanding issues.
- Security or privacy concerns.
- Remaining requirements.
- Phase acceptance checklist.
- Recommended next steps.

Stop at the end of each phase and request approval before moving to the next phase.

After Phase 0 is approved, proceed to Phase 1, then follow the remaining phases in order.

The ultimate goal is a complete, secure, tested, maintainable, and demonstrable livestock management system—not merely a collection of source files.
