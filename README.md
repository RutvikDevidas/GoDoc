# GoDoc

GoDoc is a Flutter telemedicine application with separate doctor and patient roles.

### ✅ What it does

- **Doctors** can:
  - view and manage appointments
  - initiate a secure video consultation (only doctor can start the call)
  - see call start/end timestamps
  - review feedback submitted by patients after each visit

- **Patients** can:
  - view and book appointments
  - receive a real-time "call pending" notification when a doctor starts a call
  - join the video call once the doctor has started it
  - submit feedback after an appointment (online or offline)

---

## 🧩 Core Architecture

### Firebase (Firestore)

- Stores collections:
  - `doctors`
  - `patients`
  - `appointments`
- `AppointmentModel` includes:
  - doctor/patient usernames
  - call state (`callStarted`, `callRoom`, `callStartedAt`, `callEndedAt`)
  - feedback (`feedbackSubmitted`, `feedbackRating`, `feedbackComments`)

### Authentication

- Custom login handled via Firestore (not Firebase Auth).
- Credentials are stored in Firestore (`doctors` and `patients` collections).
- Admin is hard-coded as `admin/admin`.

### Video Calls (ZEGOCLOUD)

- Uses `zego_uikit_prebuilt_call` for video sessions.
- Doctor creates a room and starts the call.
- Patients can join when the doctor has started the call.
- Call state is tracked in Firestore so both sides stay in sync.

### Notifications (Call Pending)

- Patients listen to their appointment documents via Firestore snapshot streams.
- When `callStarted` is set, patients get an in-app SnackBar notification.

---

## 📁 Key Code Locations

- `lib/main.dart` – app entry point and Firebase bootstrap.
- `lib/core/firebase/firebase_bootstrap.dart` – Firebase initialization (web + mobile).
- `lib/core/firebase/firestore_data_service.dart` – Firestore read/write helpers.
- `lib/models` – data models used across the app.
- `lib/modules/auth` – unified login screen and registration flows.
- `lib/modules/doctor` – doctor dashboard, appointment list, call initiation.
- `lib/modules/patient` – patient home, appointment list, join call UI, feedback.
- `lib/modules/video_call` – video call screen using ZEGOCLOUD.

---

## 🚀 How to Run (Local)

1. **Install Flutter**

```bash
flutter --version
```

2. **Configure Firebase**

This project relies on Firestore and requires Firebase initialization for web and mobile.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

The `flutterfire configure` command generates `lib/firebase_options.dart`.

3. **Install dependencies**

```bash
flutter pub get
```

4. **Run**

```bash
flutter run -d chrome
```

Or on a connected mobile device:

```bash
flutter run
```

---

## 🛠 Development Notes

- If Firebase init fails on web, ensure `lib/firebase_options.dart` contains valid project settings.
- If Firestore reads/writes fail, verify Firestore is enabled in the Firebase console and rules allow access.

---

## 🧪 Useful Tips

- To quickly test a doctor login, use the in-app doctor registration and then login as the created doctor.
- App state is kept in `AppState` and synced from Firestore on startup.
- Video call room names are stored on the appointment document so doctor/patient stay in sync.
  gi
