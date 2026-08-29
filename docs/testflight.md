# TestFlight release preparation

## Prepared in the project

- App name: **Milan Relocation**
- Bundle identifier: `com.hwebservices.MilanRelocation`
- Marketing version: `1.0`
- Build number: `1`
- Minimum deployment target: iOS 17.0
- Supported devices: iPhone and iPad
- App Store category: Productivity
- Apple Developer team: `VUF7XN44VH` (Automatic signing)
- App icon: opaque 1024×1024 PNG in the AppIcon asset catalog
- Export compliance: the app declares that it does not use non-exempt encryption
- Privacy manifest: no tracking or collected data; `UserDefaults` is declared for app-only preferences using required-reason code `CA92.1`

The application stores relocation information and imported attachment copies in its local sandbox and schedules Apple local notifications. Users can explicitly export or restore a complete local JSON backup from Settings. It has no backend, advertising, analytics, authentication, push provider, third-party SDK, or automatic external data transfer.

## Apple account prerequisites

Before distributing an archive through App Store Connect, complete these items in the Apple Developer portal and App Store Connect:

1. Confirm team `VUF7XN44VH`, which is preselected under the app target's Signing & Capabilities settings, is the intended distribution team.
2. Register the exact bundle identifier `com.hwebservices.MilanRelocation`, or update the project and App Store Connect record together if a different identifier is required.
3. Create the Milan Relocation app record in App Store Connect with version `1.0`.
4. Ensure Henry and Jeff have App Store Connect users if they will be internal TestFlight testers.
5. Complete App Privacy using the local-only behavior described below.
6. Review and approve the generated app icon before upload.

Do not commit a personal Apple ID, App Store Connect API key, issuer ID, private key, provisioning profile, or signing certificate to this repository.

## Suggested App Privacy answers

Based on the current codebase:

- Tracking: **No**
- Data collected: **No**
- Data linked to identity: **No**
- Data used for third-party advertising: **No**

These answers must be reconsidered before adding synchronization, analytics, authentication, crash reporting, external file storage, or push notifications.

## Archive and upload

1. Increment `CURRENT_PROJECT_VERSION` for every upload after build 1.
2. In Xcode, choose the MilanRelocation scheme and **Any iOS Device (arm64)**.
3. Choose **Product → Archive**.
4. In Organizer, run **Validate App** before distribution.
5. Choose **Distribute App → App Store Connect → Upload**.
6. Wait for processing, answer export-compliance questions consistently with the project declaration, and assign the build to internal testers.
7. Exercise create/edit/archive/delete flows, cold-launch persistence, attachment import and preview, backup export/restore, notification-denied behavior, and iPhone/iPad layouts in TestFlight before inviting external testers.

External TestFlight testing can require Beta App Review and additional beta-review contact information. No pull request should be merged as a release solely because an archive builds locally; validation and App Store Connect processing must also succeed.

## Build-number command

For the next upload after build 1:

```sh
xcrun agvtool next-version -all
```

Review the resulting project diff before committing it.
