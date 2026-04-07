# Google Android OAuth Setup (TaxRefine)

## 1. Generate SHA-1 from debug.keystore
Run one of the following commands:

### Windows (PowerShell)

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

### macOS (Terminal)

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

Copy the `SHA1` value from the output.

## 2. Create OAuth Client ID (Android)
1. Open Google Cloud Console: https://console.cloud.google.com/
2. Select your project.
3. Go to `APIs & Services` -> `Credentials`.
4. Click `+ CREATE CREDENTIALS` -> `OAuth client ID`.
5. Choose `Application type: Android`.
6. Enter:
   - Name: `TaxRefine Android Debug`
   - Package name: `com.zultanite.taxrefine`
   - SHA-1 certificate fingerprint: paste the SHA-1 from keytool output.
7. Save.

## 3. Configure OAuth Consent Screen for Drive scope
1. Go to `APIs & Services` -> `OAuth consent screen`.
2. Set `User Type` to `External`.
3. Set publishing status to `Testing`.
4. Add the developer Gmail address under `Test users`.
5. Explicitly add scope: `https://www.googleapis.com/auth/drive.file`.

This setup allows use of sensitive Drive scopes during development without waiting for Google verification.

## 4. Enable Drive API
1. Go to `APIs & Services` -> `Library`.
2. Search for `Google Drive API`.
3. Click `Enable`.

## 5. Android app package alignment check
Verify your Flutter Android app package in:
- `android/app/build.gradle.kts`
- `namespace = "com.zultanite.taxrefine"`
- `applicationId = "com.zultanite.taxrefine"`
