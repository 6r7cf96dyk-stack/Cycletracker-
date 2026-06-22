# CycleTracker

A privacy-first, **local-only** period tracker for iOS, built with SwiftUI + SwiftData.

## Hard constraints (non-negotiable)

1. **No cloud, no accounts.** All data stays on-device. No sync, no backend, no network calls for app functionality.
2. **No medical-device claims, no fertility features.** Descriptive logging only — never predictive or prescriptive.
3. **No data-collection SDKs.** No analytics, crash reporting, ads, or third-party telemetry.

Constraint #1 and #3 are enforced as a *build boundary*: the data layer
(`CycleDataKit`) is a separate Swift package that declares **zero
dependencies**, so it cannot link networking or telemetry code.

## Architecture

- **MV (Model–View).** Views use SwiftData's `@Query` / `modelContext`
  directly; logic lives in `@Model` methods and stateless services inside
  `CycleDataKit`. No per-screen ViewModel layer.
- **iOS 18+.** Uses the `#Unique` macro (one `DailyLog` per day) and modern
  SwiftData APIs.

## Project layout

```
CycleTracker/
├── App/                      # iOS app target (UI only)
│   ├── CycleTrackerApp.swift # @main; builds the local ModelContainer
│   ├── RootView.swift        # TabView: Calendar / Log / Insights / Settings
│   └── Features/<Tab>/       # one folder per tab (placeholders for now)
├── Packages/
│   └── CycleDataKit/         # data layer — NO networking, ever
│       └── Sources/CycleDataKit/{Models,Enums,Store,Seed}
└── CycleTracker.xcodeproj
```

## Running in the Simulator

1. Open `CycleTracker.xcodeproj` in **Xcode 16 or newer**.
2. Wait for the local `CycleDataKit` package to resolve (automatic).
3. Pick an iOS 18 simulator (e.g. *iPhone 16*) from the scheme's run
   destination.
4. Press **⌘R**.

Run the data-layer tests with **⌘U**, or from the package directory:

```sh
cd Packages/CycleDataKit && swift test
```
