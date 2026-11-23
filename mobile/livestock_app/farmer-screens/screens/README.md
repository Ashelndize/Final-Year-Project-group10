# Mobile app screen designs (reference)

Static HTML mockups at phone size (390x844) for the Flutter app (Android and iOS).
Open any file in a browser; links between screens work. Start at auth/Login.html.

## auth/ (shared by farmers and veterinarians)
- Login.html — sign in with phone number or email + password; show-password button; "Forgot password?" link; create account; language button
- ForgotPassword.html — enter phone or email to receive a 6-digit reset code
- ResetPassword.html — enter code, new password and confirmation; password rules; resend timer.
  The message does not reveal whether an account exists. Codes expire (15 min, draft).

## farmer/
- Home.html — official announcement, counts, upcoming vaccinations, quick actions, offline sync status
- Animals.html — search, species filter, status badges
- AnimalProfile.html — details, overdue vaccine alert, health history (farmer observation vs recorded by vet)
- FindVet.html — manual area, location consent, verified vets, request help
- Assistant.html — general information only, refers to a vet, no medicine advice

## vet/
- VetHome.html — requests inbox, availability switch, verified badge, follow-ups
- VetRequest.html — request detail; phone and exact location shared only after accepting
- VetConsult.html — record consultation ("Recorded by vet"); option to start a disease report
- VetReportForm.html — structured disease report to the authority (not an official announcement)
- VetReports.html — my reports with review statuses; reply to clarification requests

All names, animals, vets, dates and reports are sample data.
Visual references only: build the screens in Flutter; do not ship this HTML.
Colours: primary green #1E6B45, background #F5F6F1, official announcement blue #173F7A.
