# Firebase Google Login Setup (Foodie)

The Google button now signs in with Google through Firebase Authentication, then exchanges the Firebase ID token for the existing Foodie API access and refresh tokens.

## 1. Configure Firebase for Android

1. Open the Firebase Console and select the separate Firebase project created for Foodie.
2. In **Authentication → Sign-in method**, enable **Google**.
3. Open **Project settings → General** and add an Android app if one is not registered.
4. Use this Android application ID from `android/app/build.gradle.kts`: `com.example.pos_product`.
5. Add the SHA-1 and SHA-256 fingerprints for the debug/release signing keys as needed for your test/build.
6. Download `google-services.json` and place it at `android/app/google-services.json`. Do not rename it.
7. In Firebase Authentication settings, make sure your test Google account is allowed if your project uses authorized domains or test-user restrictions.

## 2. Install packages and run

From the Foodie Flutter project root:

```powershell
flutter pub get
flutter run
```

The project initializes Firebase with the Android native configuration. The Firebase options file is not committed because it is generated/configured for the specific Firebase project. For iOS or Web, follow FlutterFire setup to add platform-specific configuration before running on those platforms.

## 3. Backend must be running

The Flutter client posts the Firebase ID token to `POST /api/v1/auth/google`. The backend verifies it using Firebase Admin SDK, then returns the existing `access` and `refresh` token fields. The app saves them through the same token store as email/password login.

Do not send the Firebase service-account JSON to the Flutter app or commit it to Git. Configure server credentials separately; see the backend repository's Firebase setup guide.
