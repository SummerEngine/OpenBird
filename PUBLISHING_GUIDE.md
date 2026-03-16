# OpenBird Release Guide

`OpenBird` uses `Sparkle` for macOS auto-updates.

This file is public maintainer documentation for the open-source project. It covers the public wiring and the local release flow only. Secrets such as Apple credentials, deployment tokens, and the private Sparkle signing key must stay outside the repository.

## The Real Update Trigger

Sparkle does **not** decide updates from the marketing version alone.

- `CFBundleShortVersionString` / `MARKETING_VERSION`: user-facing version, like `1.1`
- `CFBundleVersion` / `CURRENT_PROJECT_VERSION`: build number Sparkle compares, like `2`
- `sparkle:shortVersionString`: user-facing version in the appcast
- `sparkle:version`: build number in the appcast

Users only get offered an update when the appcast `sparkle:version` is **higher** than the installed app's `CFBundleVersion`.

If you forget to increment the build number, Sparkle will not treat the release as new.

## Current Wiring

- Appcast URL is configured in `OpenBird/Info.plist`
- Public Sparkle key is configured in `OpenBird/Info.plist`
- The appcast can be hosted wherever you publish signed release metadata for OpenBird

If your production appcast host changes, update `SUFeedURL` in `OpenBird/Info.plist` before shipping.

## App Behavior

- `OpenBird` initializes `UpdateService` on launch
- Release builds rely on Sparkle's scheduled background checks
- Debug builds do not auto-check unless `SparkleTestFeedURL` is explicitly set
- Users can also manually trigger `Check for Updates...`
  - from the status bar menu
  - from Preferences -> Updates

## Release Checklist

1. Update the version in Xcode.
2. Increment the build number in Xcode.
3. Confirm the `Release` configuration is set up locally for your Apple developer team.
4. Archive the app.
5. Export a signed `Developer ID` `.app`.
6. Notarize the exported app and staple the notarization ticket.
7. Create a DMG from the notarized app.
8. Sign the DMG with your local Sparkle signing key stored outside the repository.
9. Publish the DMG and updated appcast metadata to your public release host.

## Xcode Version Fields

Open the `OpenBird` target in Xcode and update:

- `Version`: user-facing release, for example `1.1`
- `Build`: monotonically increasing integer, for example `2`

Equivalent project values:

- `MARKETING_VERSION`
- `CURRENT_PROJECT_VERSION`

The repo is already wired so the built app reads those values from Xcode via:

- `CFBundleShortVersionString = $(MARKETING_VERSION)`
- `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`

## Xcode Signing Setup

Before the first production release, open the `OpenBird` target in Xcode and verify:

1. `Signing & Capabilities` -> `Team` is set to your Apple developer account
2. `Release` uses `Automatically manage signing`
3. `Release` signs with `Developer ID Application` for direct distribution
4. `Debug` can stay on `Apple Development`
5. `Hardened Runtime` stays enabled for `Release`

If Xcode prompts to download or refresh certificates, do that in the account you are using to ship OpenBird.

## Archive, Export, And Notarize

Archive from Terminal:

```bash
xcodebuild \
  -project OpenBird.xcodeproj \
  -scheme OpenBird \
  -configuration Release \
  -archivePath "release/OpenBird.xcarchive" \
  archive
```

Export a signed Developer ID app after archiving:

```bash
xcodebuild \
  -exportArchive \
  -archivePath "release/OpenBird.xcarchive" \
  -exportPath "release/export" \
  -exportOptionsPlist ~/path/to/OpenBird-DeveloperID-ExportOptions.plist
```

Minimal `ExportOptions.plist` values for a direct-distribution macOS export:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
```

Zip, notarize, and staple the exported app:

```bash
ditto -c -k --keepParent "release/export/OpenBird.app" "release/OpenBird.zip"

xcrun notarytool submit "release/OpenBird.zip" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD" \
  --wait

xcrun stapler staple "release/export/OpenBird.app"
spctl -a -vvv -t install "release/export/OpenBird.app"
```

After exporting and stapling the notarized `.app`, create the DMG and sign it with Sparkle:

```bash
create-dmg \
  --volname "OpenBird" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 120 \
  --icon "OpenBird.app" 160 200 \
  --app-drop-link 500 200 \
  --hide-extension "OpenBird.app" \
  --no-internet-enable \
  "release/OpenBird-1.1.dmg" \
  "release/export/OpenBird.app"
```

```bash
SIGN_UPDATE=/path/to/sign_update
"$SIGN_UPDATE" "release/OpenBird-1.1.dmg"
```

`sign_update` prints output like this:

```text
sparkle:edSignature="ABC123..." length="12345678"
```

Publish both values in the appcast entry for the release.

## Public vs Private

Public and safe to commit:

- `SUFeedURL`
- `SUPublicEDKey`
- Appcast version metadata
- Public DMG download URLs
- Sparkle enclosure signatures and file sizes

Private and never commit:

- Sparkle private signing key
- Apple notarization credentials
- Any deployment tokens or CI secrets

## What To Update In The Feed

For each release, update all of these in your appcast entry:

- `version`
- `buildNumber`
- `dmgUrl`
- `fileSize`
- `edSignature`
- `pubDate`
- `releaseNotesHtml`

## Smoke Test

1. Install an older OpenBird build.
2. Run the app.
3. Trigger `Check for Updates...`
4. Confirm Sparkle finds the newer build and offers the signed DMG.

## Common Failure Mode

If users do not see the new version, the first thing to check is the build number.

- Installed app build: `CFBundleVersion`
- Feed build: `sparkle:version`

The feed build must be higher.
