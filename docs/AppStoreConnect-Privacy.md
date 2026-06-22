# App Privacy — App Store Connect entry

This is what to enter in **App Store Connect → your app → App Privacy**.

## The headline answer

When asked **"Do you or your third-party partners collect data from this app?"**
choose:

> **No, we do not collect data from this app.**

This produces the **"Data Not Collected"** nutrition label on the App Store
product page.

## Why this is accurate (audit basis)

"Collect" in Apple's definition means transmitting data off the device. This
app does none of that:

- **No network requests.** The app makes no internet connections. There is no
  backend, API, or server.
- **No account / identity.** No sign-in, email, name, or user identifier.
- **No third-party SDKs.** Zero external dependencies — no analytics, ads,
  attribution, crash reporting, or tracking libraries.
- **No iCloud / CloudKit / sync.** The SwiftData store is configured local-only
  (no `cloudKitDatabase`); data is never uploaded or synced.
- **No tracking.** No IDFA, no `AppTrackingTransparency`, no AdSupport.
- **On-device storage only.** All logs live in the app's private sandbox and are
  removed when the app is deleted.

All health/period data the user enters stays on device, so under Apple's rules
it is **not "collected"** and does not need to be declared.

## Checklist when filling out the form

- [ ] "Data Not Collected" selected (no data categories checked).
- [ ] **Privacy Nutrition Label** therefore shows **Data Not Collected**.
- [ ] A **Privacy Policy URL** is still required by App Store Connect even when
      no data is collected — host a short policy stating the same on-device-only
      facts. (The in-app Privacy screen text can be reused verbatim.)
- [ ] No `NSUserTrackingUsageDescription` key (we don't track).

## If a future version adds a feature, re-audit before changing this

The "Data Not Collected" claim is only true while the audit holds. Any of the
following would change the answer and **must** be re-evaluated before shipping:

- Adding iCloud sync / CloudKit, or any backup to a remote server.
- Adding analytics, crash reporting, or any third-party SDK.
- Adding a feature that uploads or shares data off device (note: a user-invoked
  **share sheet** / local file export is generally still "not collected," but
  confirm against Apple's current guidance).
