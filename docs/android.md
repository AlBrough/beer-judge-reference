# Android build and deployment

Beer Judge Reference uses a native Kotlin and Jetpack Compose Android client. It reads the bundled BJCP, AABC and BA guideline snapshots and works offline.

## Deploy locally from Android Studio

1. Pull the Android branch:

   ```powershell
   git fetch origin
   git switch agent/android-port
   git pull
   ```

2. Open `C:\Users\Al\GIT\webstuff\beer-judge-reference\android` in Android Studio.
3. Set the Gradle JDK to Android Studio's bundled JDK 21.
4. Enable USB debugging on the Android device and accept the authorisation prompt.
5. Select the device in Android Studio's device picker.
6. Click the green **Run** button. Android Studio builds and installs the debug APK.

## Continuous integration

GitHub Actions builds the debug APK through `Android CI`. To run it manually:

```powershell
gh workflow run android.yml --repo AlBrough/beer-judge-reference --ref agent/android-port
```

The APK is available as an artifact on the completed workflow run.

## Deploy to Google Play internal testing

The signed Play upload is handled by `Android Play Release` on `main`.

```powershell
git switch main
git pull
gh workflow run android-release.yml --repo AlBrough/beer-judge-reference --ref main
```

The workflow uses the protected `mobile-release` environment secrets, builds the signed AAB and uploads it to the `com.brewvault.beerjudge` internal testing track. Testers install from the track-specific Play opt-in link, not by searching the Play Store.
