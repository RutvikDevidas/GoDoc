# GoDoc

GoDoc is a Flutter telemedicine app built for doctor and patient workflows. It supports appointment booking, doctor-managed video consultations, clinic location selection, feedback collection, and Firebase-backed data syncing.

## Features

- Doctor and patient login/registration flows
- Appointment booking and management
- Video consultations using ZEGOCLOUD
- Clinic location and route support
- In-app appointment and call status updates
- Post-appointment patient feedback
- Firebase Firestore data storage

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Firebase Storage
- ZEGOCLOUD prebuilt call UI
- Razorpay
- Flutter Map / Geolocator

## Project Structure

- `lib/main.dart`: app entry point
- `lib/core/`: shared app services, Firebase setup, theme, constants, payments, and video config
- `lib/models/`: app data models
- `lib/modules/auth/`: login and authentication-related screens
- `lib/modules/doctor/`: doctor dashboard and appointment features
- `lib/modules/patient/`: patient booking, profile, and notification features
- `lib/modules/shared/`: shared screens such as clinic location picker
- `lib/modules/video_call/`: video call UI

## Prerequisites

- Flutter SDK installed
- Android Studio or a connected Android device
- Firebase project configured for Android, iOS, and web as needed

## Local Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Verify Flutter setup:

```bash
flutter doctor
```

3. Run the app:

```bash
flutter run
```

4. Run on Chrome if needed:

```bash
flutter run -d chrome
```

## Firebase Notes

This project includes Firebase configuration files in the repo:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

If you change the Firebase project, regenerate or replace these files with your own project configuration.

## Build APK Locally

To generate a release APK on your machine:

```bash
flutter build apk --release
```

The APK will be created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Download APK From GitHub

This repository includes a GitHub Actions workflow that builds the Android APK automatically.

### Option 1: Download from GitHub Actions

1. Open the repository on GitHub.
2. Go to the `Actions` tab.
3. Open the latest `Build Android APK` workflow run.
4. Download the `godoc-apk` artifact.

This is the easiest option for team members who just need the latest build.

### Option 2: Download from GitHub Releases

When a version tag such as `v1.0.0` is pushed, the workflow also creates a GitHub Release and uploads the APK there.

Example:

```bash
git tag v1.0.0
git push origin v1.0.0
```

After the workflow completes, teammates can open the repository `Releases` page and download the APK directly.

## Development Notes

- Android release builds are currently signed with the debug signing config in Gradle.
- Firestore is used for app data and custom credential storage.
- Video call state is synchronized through Firestore appointment documents.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
