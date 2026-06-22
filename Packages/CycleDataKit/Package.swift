// swift-tools-version: 6.0
import PackageDescription

// CycleDataKit — the local-only data layer for CycleTracker.
//
// Privacy boundary: this package declares NO dependencies. It therefore
// cannot link any networking, analytics, or telemetry code. The "no cloud,
// no data-collection SDKs" constraints are enforced here as a build boundary,
// not just a convention.
let package = Package(
    name: "CycleDataKit",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "CycleDataKit", targets: ["CycleDataKit"])
    ],
    targets: [
        .target(name: "CycleDataKit"),
        .testTarget(name: "CycleDataKitTests", dependencies: ["CycleDataKit"])
    ],
    swiftLanguageModes: [.v5]
)
