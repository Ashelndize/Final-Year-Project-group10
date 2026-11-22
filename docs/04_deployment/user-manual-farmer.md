# Farmer User Manual — Smart Livestock Mobile App

**Project:** Smart Livestock Health and Farm Management System
**Audience:** Farmers using the Android mobile application
**Date:** 2026-11-22

---

## Table of contents

1. [Getting started](#1-getting-started)
2. [Registration and login](#2-registration-and-login)
3. [Farm management](#3-farm-management)
4. [Animal management](#4-animal-management)
5. [Health records](#5-health-records)
6. [Vaccination schedules](#6-vaccination-schedules)
7. [Veterinary assistance](#7-veterinary-assistance)
8. [Disease reports](#8-disease-reports)
9. [Notifications](#9-notifications)
10. [AI health assistant](#10-ai-health-assistant)
11. [Offline use](#11-offline-use)
12. [Privacy and location](#12-privacy-and-location)
13. [Account settings](#13-account-settings)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Getting started

### Installing the app

1. Download the `.apk` file from the link provided by your administrator or the project team.
2. On your Android device, go to **Settings → Security** (or **Apps**) and enable **Install from unknown sources** (or **Allow from this source**) for your file manager.
3. Open the downloaded `.apk` file and tap **Install**.
4. Tap **Open** when installation finishes.

The app requires Android 7.0 (API 24) or later.

### What the app does

The Smart Livestock app helps you:
- Keep accurate health records for your animals
- Track vaccinations and receive reminders
- Find and contact veterinary services
- Report suspected livestock diseases
- Receive official advisories from the veterinary authority
- Get basic livestock health information from the AI assistant

---

## 2. Registration and login

### Creating an account

1. Open the app and tap **Register**.
2. Fill in:
   - **First name** and **Last name**
   - **Username** (you will use this to log in)
   - **Email address**
   - **Phone number** (optional)
   - **Password** (at least 10 characters; must not be a common word)
3. Confirm your password by typing it again.
4. Tap **Register**.

Your account is created immediately. You are automatically logged in.

### Logging in

1. Open the app.
2. Enter your **username** and **password**.
3. Tap **Sign in**.

If you enter the wrong password five times in a row, your account will be temporarily locked for 1 hour to protect against unauthorized access.

### Logging out

Tap the menu icon (top right corner) and select **Log out**. Any offline changes that have not yet been sent to the server will be cleared.

---

## 3. Farm management

### Registering a farm

1. From the home screen, tap **My Farms** then **+ Add farm**.
2. Enter:
   - **Farm name**
   - **Farm type** (Mixed, Cattle, Poultry, Goats, Pigs, or Other)
   - **Area** — choose from the list or type to search
   - **Address** (optional)
   - **Notes** (optional)
3. Tap **Save**.

Your farm appears in the **My Farms** list.

### Viewing and editing a farm

Tap a farm in the list to see its details. Tap the **Edit** icon to update the farm name, type, or address.

---

## 4. Animal management

### Registering an animal

1. Open a farm and tap **Animals** then **+ Add animal**.
2. Enter:
   - **Tag number** (required; unique within your farm)
   - **Name** (optional)
   - **Species** (Cattle, Goat, Sheep, Pig, Poultry, Equine, or Other)
   - **Breed** (optional)
   - **Sex** (Male / Female / Unknown)
   - **Date of birth** (optional; enter an estimate if not known exactly)
   - **Weight** in kg (optional)
   - **Notes** (optional)
3. Tap **Save**.

### Searching for an animal

Use the search bar at the top of the animals list to search by tag number or name. Use the filter button to filter by species or status.

### Archiving an animal

If an animal leaves your herd (sold, died, or transferred), tap the animal then tap **Archive**. Archived animals are hidden from the main list but their records are preserved.

---

## 5. Health records

### Adding a health record

1. Open an animal and tap **Health** then **+ Add record**.
2. Enter:
   - **Record date**
   - **Health status:** Healthy, Sick, Under Treatment, Recovered, or Deceased
   - **Weight** (optional)
   - **Temperature °C** (optional)
   - **Symptoms** (optional — describe what you observed)
   - **Diagnosis** (optional — enter what the vet told you)
   - **Notes** (optional)
3. Tap **Save**.

### Viewing health history

The **Health** tab on each animal shows all records in reverse date order. Tap any record to see its full details.

---

## 6. Vaccination schedules

Vaccination schedules are managed by your veterinary authority based on approved protocols. When a new vaccination schedule is created for your animals, it appears on the **Vaccinations** tab.

### Reading a vaccination schedule

| Colour | Meaning |
|---|---|
| Green | Due date is more than 7 days away |
| Orange | Due within 7 days — prepare |
| Red | Overdue |

### Recording a vaccination

After a vaccination is administered:
1. Open the vaccination schedule entry.
2. Tap **Record vaccination**.
3. Enter the date, vaccine batch number, and the name of the person who administered it.
4. Tap **Save**.

---

## 7. Veterinary assistance

### Requesting assistance

1. From the home screen, tap **Veterinary assistance** then **+ New request**.
2. Select the **farm** needing assistance.
3. Describe the problem in the **Description** field.
4. Optionally provide your **location** (see §12 for privacy details).
5. Tap **Submit request**.

Your request is sent with status **Pending**. A nearby veterinarian will accept and contact you.

### Tracking your request

The request list shows the current status:

| Status | Meaning |
|---|---|
| **Pending** | Waiting for a vet to accept |
| **Accepted** | A vet has accepted and will contact you |
| **In progress** | The vet is working on your case |
| **Completed** | The case is closed |
| **Cancelled** | The request was cancelled |

---

## 8. Disease reports

### Submitting a disease report

If you suspect a livestock disease that may affect other farms:
1. Tap **Disease reports** then **+ New report**.
2. Enter:
   - **Species affected**
   - **Date observed**
   - **Area** (choose from the list)
   - **Signs observed** (describe the symptoms)
   - **Notes** (optional)
   - **Location consent** — tick if you agree to share your location coordinates with the authority reviewer
3. Tap **Submit**.

Your report is sent to the veterinary authority for review. It will not be published publicly — only authorized reviewers can see it.

**Important:** Submitting a disease report does not automatically confirm an outbreak. The authority will investigate and, if warranted, publish an official announcement.

---

## 9. Notifications

### Reading notifications

Tap the bell icon on the home screen to open your notification inbox.

### Notification types

| Type | Sent when |
|---|---|
| **Official advisory** | The authority publishes an announcement |
| **Vaccination reminder** | A vaccination is due within 7 days |
| **Assistance update** | A vet accepts or updates your request |

### Marking notifications as read

Tap a notification to open it — it is automatically marked as read.
To mark all notifications as read at once, tap **Mark all read** at the top of the list.

---

## 10. AI health assistant

The AI health assistant can answer general questions about livestock health, common diseases, and farm management.

### How to use it

1. Tap **AI Assistant** on the home screen.
2. Type your question and tap **Ask**.
3. The assistant will respond with general information.

### Important limitations

- The assistant **cannot diagnose your animals**. It provides general information only.
- It **cannot prescribe medications** or recommend specific drug doses.
- Every response includes a disclaimer: *"General information — not a diagnosis."*
- If your animal is sick, **contact a veterinarian**.

### When the assistant is not available

If the assistant shows "Service not available", it has been disabled by the administrator. Contact your veterinary authority for health information.

---

## 11. Offline use

The app can record health observations when you have no internet connection.

### What works offline

- Recording health observations for existing animals
- Submitting disease reports
- Requesting veterinary assistance

### What requires internet

- Registration and login
- Creating new farms or animals
- Viewing notifications and announcements
- Using the AI assistant

### How offline sync works

When you have no connection, the app shows an amber **"You are offline"** banner.

Records created offline are stored securely on your device and uploaded automatically when you reconnect. The banner turns green and shows "Syncing N records" while this happens.

If you need to sync immediately: tap the green banner and then tap **Sync now**.

If the server rejects an offline record (for example, because a date is in the future), the item shows as **Failed** in the queue screen. You can edit and retry it.

---

## 12. Privacy and location

### Location permission

When you first use a feature that needs your location, the app asks for permission. You can:
- **Allow** — the app uses your device's GPS to find nearby vets and can optionally attach your location to requests
- **Deny** — you choose your area manually from a list; the app still works fully

You can change this choice at any time in your phone's Settings → Apps → Smart Livestock → Permissions.

### What is stored

| Data | Stored without consent | Stored with consent |
|---|---|---|
| Coarse area name | Yes | Yes |
| Precise GPS coordinates | Never | Only if you explicitly tick "Share location" when submitting |

GPS coordinates are stored server-side only when you tick the **location consent** checkbox on the report or request form. You can decline at any time without losing access to any features.

---

## 13. Account settings

Tap the menu icon (top right) → **Profile** to:
- Update your name, email, or phone number
- Change your password
- View your location consent history

---

## 14. Troubleshooting

| Problem | Solution |
|---|---|
| Cannot log in | Check your username spelling. After 5 failed attempts your account is locked for 1 hour. Contact your administrator if locked. |
| App says "Cannot connect to server" | Check your internet connection. Try again when connected. |
| Health record not saved | If the amber banner is showing, the record was saved offline and will sync later. |
| Notification badge not updating | Pull down on the notification list to refresh. |
| Vaccination schedule not showing | Schedules are created by your veterinary authority. Contact them if you believe a schedule is missing. |
| App crashes | Note what you were doing and report it to your administrator with the app version number (Settings → About). |
