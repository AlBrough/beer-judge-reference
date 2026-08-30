# TestFlight release

## One-time Apple setup

1. Create bundle ID `com.brewvault.beerjudge` in Certificates, Identifiers & Profiles.
2. Create the App Store Connect app record:
   - Name: Beer Judge Reference
   - Bundle ID: `com.brewvault.beerjudge`
   - SKU: `beer-judge-reference-ios`
3. Create an `IOS_APP_STORE` provisioning profile named `AppStore com.brewvault.beerjudge` using the existing Apple Distribution certificate.
4. Create the GitHub environment `mobile-release`.
5. Add repository/environment variables:
   - `APPLE_TEAM_ID`
   - `APPSTORE_ISSUER_ID`
   - `APPSTORE_API_KEY_ID`
6. Add repository/environment secrets:
   - `APPSTORE_API_PRIVATE_KEY`
   - `APPSTORE_CERTIFICATES_FILE_BASE64`
   - `APPSTORE_CERTIFICATES_PASSWORD`

## Send a build

1. Open GitHub Actions.
2. Select **iOS TestFlight Release**.
3. Select **Run workflow**, enter the version, and run it from `main`.
4. After App Store Connect finishes processing, add the build to an internal TestFlight group.

Every workflow run uses its GitHub run number as the monotonically increasing Apple build number.

