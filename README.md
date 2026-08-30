# Beer Judge Reference

Native, offline-first iOS reference for competition beer judging.

## What it includes

- BJCP 2021 beer style guidelines sourced from `BrewVault/bjcp-json`.
- Brewers Association 2026 beer style guidelines sourced verbatim from the official free reference.
- Fast full-text search, category browsing, bookmarks, recents and side-by-side comparison.
- Bundled datasets for guaranteed offline use plus validated, checksum-protected updates from GitHub.
- Native light, dark and system appearance.

No AWS service is required. GitHub stores the versioned source and data snapshots; every app build contains a complete offline fallback.

## Refresh guideline data

```bash
npm ci
npm run data:sync
npm run data:validate
```

The sync script preserves provider text and writes a versioned normalised schema. A scheduled workflow checks upstream sources and creates a pull request when data changes.

## Build on macOS

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project BeerJudgeReference.xcodeproj -scheme BeerJudgeReference -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Rights and attribution

The application source is GPLv3. Guideline text remains copyright of its respective publisher and is presented for free educational and judging reference use.

- BJCP source and permission questions: <https://www.bjcp.org/bjcp-style-guidelines/>
- Brewers Association usage terms: <https://www.brewersassociation.org/edu/brewers-association-beer-style-guidelines/>

This project is independent and is not affiliated with or endorsed by BJCP or the Brewers Association. Confirm permission with BJCP before public App Store distribution.
