# OpenBird Maintainer Release Guide

`OpenBird` now uses `Sparkle` for macOS auto-updates, following the same model as `Vibe Read`.

This file is public and is intended as maintainer documentation for the open-source project. It only documents public wiring and local release steps. Secrets such as Apple credentials, Supabase service-role keys, and the private Sparkle signing key must stay outside the repository.

## The Real Update Trigger

Sparkle does **not** decide updates from the marketing version alone.

- `CFBundleShortVersionString` / `MARKETING_VERSION`: user-facing version, like `1.1`
- `CFBundleVersion` / `CURRENT_PROJECT_VERSION`: build number Sparkle compares, like `2`
- `sparkle:shortVersionString`: user-facing version in the appcast
- `sparkle:version`: build number in the appcast

Users only get offered an update when the appcast `sparkle:version` is **higher** than the installed app's `CFBundleVersion`.

If you forget to increment the build number, Sparkle will not treat the release as new.

## Current Wiring

- Appcast URL in `OpenBird/Info.plist`:
  - `https://www.openbird.app/api/desktop/sparkle/appcast.xml`
- Public Sparkle key in `OpenBird/Info.plist`:
  - `+F3ZI9mwgUf402WzCgnd96eQrRzS892RqjyvJjTMVo8=`
- Website feed config:
  - `openbirdweb/src/lib/desktop-release.ts`
- Website appcast route:
  - `openbirdweb/src/app/api/desktop/sparkle/appcast.xml/route.ts`

If the production site is not `https://www.openbird.app`, update `SUFeedURL` in `OpenBird/Info.plist` before shipping.

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
3. Archive the app and export a signed + notarized `.app`.
4. Create a DMG from the exported app.
5. Sign the DMG with your local Sparkle signing key stored in Keychain.
6. Upload the DMG to the Supabase public bucket.
7. Update `openbirdweb/src/lib/desktop-release.ts` with the new version, build number, DMG URL, file size, signature, and release notes.
8. Deploy `openbirdweb`.

## Xcode Version Fields

Open the `OpenBird` target in Xcode and update:

- `Version`: user-facing release, for example `1.1`
- `Build`: monotonically increasing integer, for example `2`

Equivalent project values:

- `MARKETING_VERSION`
- `CURRENT_PROJECT_VERSION`

## Create and Sign the DMG

After exporting the notarized `.app`, create the DMG and sign it with Sparkle.

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
  "OpenBird-1.1.dmg" \
  "OpenBird.app"
```

```bash
SIGN_UPDATE=$(ls ~/Library/Developer/Xcode/DerivedData/*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update | head -1)
"$SIGN_UPDATE" ~/path/to/OpenBird-1.1.dmg
```

`sign_update` prints output like this:

```text
sparkle:edSignature="ABC123..." length="12345678"
```

Copy both values into `openbirdweb/src/lib/desktop-release.ts`.

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
- Supabase service-role keys
- Any deployment tokens or CI secrets

## What To Update In The Feed

For each release, update all of these in `openbirdweb/src/lib/desktop-release.ts`:

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
