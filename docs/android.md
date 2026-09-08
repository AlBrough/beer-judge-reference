# Android build

Beer Judge Reference now has a native Kotlin and Jetpack Compose Android client. It reads the same BJCP, AABC and BA JSON snapshots as the iOS app and provides edition selection, search, style browsing and full style details.

Build locally from the repository root:

```powershell
Set-Location android
./gradlew assembleDebug
```

The debug APK is written to `android/app/build/outputs/apk/debug/app-debug.apk`.

GitHub Actions builds the debug APK on pushes and pull requests through `Android CI`. A signed Play Store bundle will be added once the Play Console application and Android signing credentials are ready.
