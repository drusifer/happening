# macOS App Store Submission Guide

## Prerequisites

1. **App registered in App Store Connect** — bundle ID `works.gs.happening`, category Productivity
2. **Apple Distribution certificate** in Keychain
   - Xcode → Settings → Accounts → Manage Certificates → **+** → Apple Distribution
3. **App Store Connect API key** (for `make dist-macos-appstore`)
   - App Store Connect → Users & Access → Integrations → App Store Connect API → generate key
   - Download the `.p8` file (only downloadable once)
   - Note the Key ID and Issuer ID

---

## Build Number Rules

Flutter derives `CFBundleVersion` from the `+N` suffix in `pubspec.yaml`:

```
version: 0.5.3+2   →  marketing version 0.5.3, build number 2
```

**Every upload to App Store Connect must have a strictly higher build number than the previous one**, even for the same marketing version. Apple will reject the upload silently if the build number is not new.

`sync_version.py` / `make set-version` only manages the marketing version — you must manually increment the `+N` suffix each time you upload.

---

## First Submission

```bash
# 1. Set version and build number in pubspec.yaml
#    e.g. version: 0.5.3+1

# 2. Sync marketing version across project files
make set-version VERSION=0.5.3

# 3. Archive and upload (via command line)
export ASC_API_KEY_ID=XXXXXXXXXX
export ASC_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export ASC_API_KEY_PATH=~/private_keys/AuthKey_XXXXXXXXXX.p8
make dist-macos-appstore
```

### Via Xcode GUI

1. Open `app/macos/Runner.xcworkspace`
2. **Signing & Capabilities → Release tab** — confirm Team = RG3GPMUR4V, Automatically manage signing
3. **Product → Archive** (scheme destination = Any Mac)
4. Organizer opens automatically → select the archive → **Distribute App**
5. App Store Connect → Upload → Next through defaults → **Upload**
6. Wait 10–30 min for Apple to process, then go to App Store Connect → TestFlight to confirm

---

## Resubmitting After Rejection

### Same version, fix and resubmit

```
version: 0.5.3+1  →  version: 0.5.3+2
```

1. Increment the `+N` build number in `app/pubspec.yaml`
2. Address the rejection reason in code
3. Archive and upload (Organizer or `make dist-macos-appstore`)
4. App Store Connect → your app → the rejected version → **Add Build** → select the new build
5. Respond to the reviewer in the Resolution Center if needed → **Submit for Review**

### New version

```bash
# Bump marketing version and reset build number
# Edit pubspec.yaml: version: 0.5.4+1
make set-version VERSION=0.5.4
```

Then archive, upload, and submit the new version in App Store Connect.

---

## Common Rejection Reasons & Fixes

| Rejection | Fix |
|---|---|
| Missing privacy manifest | Add `PrivacyInfo.xcprivacy` to Runner target |
| `ITSAppUsesNonExemptEncryption` missing | Add `<key>ITSAppUsesNonExemptEncryption</key><false/>` to `Info.plist` |
| Sandbox violation | Check `Release.entitlements` — only declare entitlements you actually use |
| Outdated bundle ID | Confirm `works.gs.happening` matches App Store Connect registration |
| Build number not incremented | Increment `+N` in `pubspec.yaml` before archiving |
| Guideline 2.1 (app completeness) | Make sure all features work without a reviewer account — provide demo credentials if login is required |

---

## Key Files

| File | Purpose |
|---|---|
| `app/pubspec.yaml` | Source of truth for `version: X.Y.Z+N` |
| `app/assets/version.txt` | Marketing version only — read by `make set-version` |
| `app/macos/Runner/Info.plist` | References `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` |
| `app/macos/Runner/Release.entitlements` | Sandbox entitlements for release |
| `app/macos/ExportOptions-AppStore.plist` | `xcodebuild -exportArchive` config (method + destination) |
