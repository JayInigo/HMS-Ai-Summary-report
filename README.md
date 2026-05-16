# 🏨 Velour Grand Hotel Management System

A **Flutter Android mobile app** built for hotel staff to manage guest check-ins, view AI-generated business reports, and interact with an AI-powered staff assistant chatbot.

---

## 👥 Group Members

| Name | Role |
| Ian Barredo | Backend Coding  |
| Jay Leonard Iñigo | Backend Coding |
| Mark Jolo Lañada | AI Features |
| Jenelyn Miraflor | UI Design  |

---

## 📱 App Overview

**App Name:** Velour Grand Hotel MS  
**Business Type:** Hotel Management  
**Target Users:** Hotel staff and administrators  
**Platform:** Android Mobile App (Flutter)

The Velour Grand Hotel Management System solves the problem of manual, paper-based guest check-in tracking. It allows hotel staff to digitally log guest check-ins, manage records, and gain AI-powered insights into daily hotel operations.

---

## ✨ Features

### 🔐 Authentication
- Staff sign-up with full form validation (name, email, address, contact, birthdate, gender, password)
- Secure login via Firebase Authentication
- Logout with confirmation dialog

### 📋 Guest Check-In Management (CRUD)
- **Add** new guest check-in records with:
  - Client name
  - Room type (Deluxe, Suite, Standard)
  - Guest status/category
  - Photo from gallery
  - GPS location capture
- **View** all check-ins in a real-time scrollable list
- **Delete** check-in records with confirmation
- **Detail view** via bottom sheet modal

### 🤖 AI Check-In Summary Report *(Semi-Final Feature)*
- Reads all Firestore check-in data automatically
- Sends data to **Groq AI (LLaMA 3.1)** for analysis
- Generates a structured business report with:
  - Total check-ins count
  - Room type breakdown
  - Guest status breakdown
  - Revenue estimate (based on room rates)
  - Management recommendations
- Bold, professional UI with color-coded report sections

### 💬 AI Staff Assistant Chatbot *(Semi-Final Feature)*
- Loads all current check-in records as context
- Staff can ask natural language questions about guests and hotel data
- Examples: *"How many guests checked in?"*, *"List all Deluxe room guests"*, *"Any VIP guests?"*
- Multi-turn conversation with full history
- Quick suggestion chips for common queries
- Animated typing indicator

---

## 🛠️ Tech Stack

| Technology | Usage |
|------------|-------|
| **Flutter** | UI framework (Android) |
| **Dart** | Programming language |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time database / CRUD |
| **Firebase Storage** | Photo storage |
| **Geolocator** | GPS location capture |
| **Image Picker** | Gallery photo selection |
| **HTTP** | API calls to Groq AI |
| **Groq API (LLaMA 3.1)** | AI summary report + chatbot |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, Firebase init
├── firebase_options.dart        # Firebase configuration
└── screens/
    ├── welcome_screen.dart      # Landing screen
    ├── login_screen.dart        # Staff login
    ├── signup_screen.dart       # Staff registration
    ├── checkin_list_screen.dart # Main check-in list (CRUD)
    ├── add_checkin_screen.dart  # Add new check-in form
    ├── ai_summary_screen.dart   # AI business summary report
    └── chatbot_screen.dart      # AI staff assistant chatbot
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.10.7`
- Android Studio or VS Code
- A Firebase project
- A free Groq API key from [console.groq.com](https://console.groq.com)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/JayInigo/HMS-Ai-Summary-report.git
   cd HMS-Ai-Summary-report
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Add your own `google-services.json` to `android/app/`
   - Add your own `firebase_options.dart` to `lib/`

4. **Add your Groq API key**
   - Open `lib/screens/ai_summary_screen.dart` and `lib/screens/chatbot_screen.dart`
   - Replace `YOUR_GROQ_API_KEY` with your actual key

5. **Run the app**
   ```bash
   flutter run
   ```

### Build APK
```bash
flutter build apk --release
```
APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  firebase_storage: ^13.3.0
  image_picker: ^1.2.1
  geolocator: ^14.0.2
  http: ^1.2.0
```

---

## 📋 Course Topics Implemented

| Topic | Implementation |
|-------|----------------|
| **Dart fundamentals** | Classes, async/await, state, controllers |
| **Flutter widgets** | Scaffold, ListView, Card, Form, Stack, Column |
| **Layout & design** | Gradients, responsive layout, custom UI |
| **Multiple screens** | 7 screens with proper routing |
| **State management** | `setState`, `StatefulWidget` |
| **Form validation** | Validators on all sign-up fields |
| **Firebase Auth** | Sign up, login, logout |
| **Cloud Firestore** | Real-time CRUD with `StreamBuilder` |
| **Firebase Storage** | Photo upload and deletion |
| **Device features** | GPS via Geolocator, image picker |
| **AI feature** | Groq API for summary report and chatbot |
| **API integration** | HTTP calls to Groq REST API |

---

## ⚠️ Notes

- The Groq API key is **not included** in this repository for security reasons.
- Firebase credentials (`google-services.json`, `firebase_options.dart`) are also excluded..
- The app is built and tested as an **Android mobile app**.

---

## 📄 License

This project was created for academic purposes as part of a Mobile Application Development course.