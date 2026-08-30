# TestFlight release

## Current Apple setup

Already configured:

- Bundle ID `com.brewvault.beerjudge`
- `IOS_APP_STORE` profile `AppStore com.brewvault.beerjudge`
- GitHub environment `mobile-release`
- Apple team/API variables and signing secrets

One portal-only step remains. Create the App Store Connect app record:

1. Open <https://appstoreconnect.apple.com/apps> and choose **My Apps → + → New App**.
2. Enter:
   - Name: Beer Judge Reference
   - Bundle ID: `com.brewvault.beerjudge`
   - SKU: `beer-judge-reference-ios`
   - Primary language: English (Australia)
   - Platform: iOS
3. Click **Create**.

## Send a build

1. Open GitHub Actions.
2. Select **iOS TestFlight Release**.
3. Select **Run workflow**, enter the version, and run it from `main`.
4. After App Store Connect finishes processing, add the build to an internal TestFlight group.

Every workflow run uses its GitHub run number as the monotonically increasing Apple build number.
