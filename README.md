# taxrefine

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Sign-In Setup (Android)

1. Create both OAuth clients in Google Cloud Console:
	 - Android client for package `com.zultanite.taxrefine` with your debug/release SHA fingerprints.
	 - Web client for backend Google ID token audience verification.
2. Download `google-services.json` for the same Google project and place it at `android/app/google-services.json`.
3. Start the app with distinct client IDs:

```bash
flutter run \
	--dart-define=GOOGLE_ANDROID_CLIENT_ID=<android-client-id> \
	--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

4. Ensure backend `google.auth.client-id` (or `GOOGLE_AUTH_CLIENT_ID`) matches the same web client id.
