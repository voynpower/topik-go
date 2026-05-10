# topik-go (TOPIK GO)

TOPIK II preparation app built with Flutter.

This project aims to help learners pass TOPIK II through structured practice:

- Reading, Listening, Writing question practice
- Mock exam sessions with timer and progress
- Vocabulary and grammar study tools
- Onboarding with language and target level setup

## Current Project Status

Initial app scaffolding is implemented:

- Flutter + Riverpod + GoRouter setup
- App theme tokens (mint/teal style)
- Onboarding flow:
  - Splash
  - AI content notice
  - Language select
  - Goal level select
- Login screen UI
- Main tab shell:
  - Home
  - Practice
  - Mock Exam
  - Settings

## Tech Stack

- Flutter (Material 3)
- `flutter_riverpod` (state management)
- `go_router` (navigation)
- `dio` (network layer, prepared)
- `drift` + `sqlite3_flutter_libs` (local database, prepared)
- `shared_preferences` (local settings, prepared)
- `just_audio`, `flutter_tts` (audio/TTS, prepared)

## Project Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  features/
    auth/
    onboarding/
    home/
    practice/
    mock_exam/
    settings/
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Social Login Setup

Google and Kakao login use native SDKs and then send the provider token to:

```text
POST /auth/social-login
```

Run with your real provider credentials. Kakao needs a Dart define at runtime; Android also needs the same URL scheme as a Gradle property:

```bash
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=your_google_client_id \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=90307596930-qt1h0vrsqg2p97vmngejvopr4fc30prs.apps.googleusercontent.com \
  --dart-define=KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key \
  --dart-define=KAKAO_CUSTOM_SCHEME=kakaoYourKakaoNativeAppKey
```

For iOS, replace the placeholder values in:

- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`

Required iOS values:

```text
GOOGLE_CLIENT_ID=...apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps....
KAKAO_URL_SCHEME=kakao...
```

For Android, replace or pass the Kakao scheme in:

- `android/gradle.properties`
- `android/app/build.gradle.kts`

## Quality Checks

```bash
flutter analyze
flutter test
```

## Roadmap (Next Steps)

1. Persist onboarding preferences (`language`, `target level`, `timer mode`)
2. Integrate social/email authentication (Google, Kakao, Email)
3. Build practice engine (question session, answer submission, timer restore)
4. Add offline-first storage and sync queue
5. Implement mock exam result and weak-point analytics

## Notes

- UI and user flow reference existing TOPIK GO screenshots provided during planning.
- This repository is under active development.
