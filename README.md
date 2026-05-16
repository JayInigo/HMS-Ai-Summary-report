# Hotel Management System — Check-In Log

## Business App Idea
A Hotel Management System check-in log that allows hotel staff to record
site visits, client interactions, and property inspections. Staff can
capture photos, log GPS coordinates, and store room-specific details
for accountability and record-keeping.

## Collection Name & Fields
**Collection:** `hotel_checkins`

| Field        | Type      | Description                         |
|--------------|-----------|-------------------------------------|
| businessName | string    | Name of hotel/branch visited        |
| note         | string    | Visit notes                         |
| roomType     | string    | Room category (Deluxe, Suite, etc.) |
| guestStatus  | string    | Check-In / Check-Out / Staying      |
| photoUrl     | string    | Firebase Storage download URL       |
| lat          | number    | GPS latitude                        |
| lng          | number    | GPS longitude                       |
| createdBy    | string    | Group identifier                    |
| proofLabel   | string    | e.g. GroupName-Hotel-0423           |
| createdAt    | timestamp | Server timestamp                    |

## Steps to Run
1. Clone the repo
2. Run `flutter pub get`
3. Add your own `google-services.json` (Android) — not committed
4. Run `flutter run`

## Screenshots
- `screenshots/list_screen.png` — Log List with entries
- `screenshots/add_screen.png` — Add screen with photo + location
- `screenshots/firestore_doc.png` — Firestore document view# 🏨 Velour Grand — Hotel Management System

A Flutter mobile application for hotel staff to manage and log guest check-ins, built with Firebase Authentication and Firestore.

---

## 📱 Screens Overview

| Screen                     | Description                                 |
|----------------------------|---------------------------------------------|
| `welcome_screen.dart`      | Landing page with Sign In / Sign Up options |
| `login_screen.dart`        | Firebase email & password authentication    |
| `signup_screen.dart`       | New staff account registration              |
| `checkin_list_screen.dart` | Live list of all guest check-ins            |
| `add_checkin_screen.dart`  | Form to record a new guest check-in         |

---

## ✨ Features

- **Firebase Authentication** — Secure login and registration for hotel staff
- **Firestore Real-time Sync** — Check-in records update live via `StreamBuilder`
- **GPS Location Capture** — Records staff coordinates at the time of check-in using `geolocator`
- **Photo Upload** — Attach proof photos from the device gallery via `image_picker`
- **Auto Proof Label** — Each check-in is stamped with a unique label (e.g. `HMS-Hotel-0430`)
- **Delete with Confirmation** — Records and associated photos can be removed with a confirmation dialog
- **Logout** — Secure sign-out from the check-in list screen

---

## 🗂️ Firestore Data Structure

**Collection:** `hotel_checkins`

| Field         | Type        | Description                                  |
|---------------|-------------|----------------------------------------------|
| `clientName`  | `String`    | Name of the guest                            |
| `roomType`    | `String`    | `Deluxe`, `Suite`, or `Standard`             |
| `guestStatus` | `String`    | Guest category (e.g. VIP, Walk-in)           |
| `photoBase64` | `String`    | Base64-encoded proof photo                   |
| `lat`         | `double`    | GPS latitude                                 |
| `lng`         | `double`    | GPS longitude                                |
| `createdBy`   | `String`    | Group identifier (`HMS`)                     |
| `proofLabel`  | `String`    | Auto-generated label (e.g. `HMS-Hotel-0430`) |
| `createdAt`   | `Timestamp` | Server timestamp of submission               |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Firebase project with **Authentication** and **Firestore** enabled
- `google-services.json` placed in `android/app/`

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/velour-grand.git
cd velour-grand

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_storage:
  image_picker:
  geolocator:
```

---

## 📁 Project Structure

```
lib/
└── screens/
    ├── welcome_screen.dart
    ├── login_screen.dart
    ├── signup_screen.dart
    ├── checkin_list_screen.dart
    └── add_checkin_screen.dart

assets/
└── images/
    └── velour_grand.png
```

---

## 🔐 Authentication Flow

```
WelcomeScreen
    ├── → LoginScreen  → CheckInListScreen
    └── → SignUpScreen → LoginScreen
```

From `CheckInListScreen`, tapping the logout icon signs the user out and returns to `WelcomeScreen`, clearing the navigation stack.

---

## 👥 Group

**Group Name:** HMS
**Hotel Brand:** Velour Grand

---

## 📄 License

This project is for academic/internal use only.
- `screenshots/storage_file.png` — Firebase Storage uploaded image