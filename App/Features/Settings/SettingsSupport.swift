import SwiftUI

/// Keys for persisted settings (`@AppStorage`).
enum SettingsKeys {
    static let appLockEnabled = "settings.appLockEnabled"
    static let theme = "settings.theme"
}

/// User-selectable appearance.
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` lets the system decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Static app metadata used in the About section.
enum AppInfo {
    /// Shown in About. Keep this aligned with the in-app Privacy explainer.
    static let disclaimer = """
    CycleTracker is a personal logging tool. It is not a medical device and does \
    not provide medical advice. Estimates are based only on the data you enter and \
    must not be used for fertility, contraception, or any health decision. Please \
    consult a qualified healthcare professional with any medical questions.
    """

    /// TODO: replace with the real public repository URL before release.
    static let sourceRepoURL = URL(string: "https://github.com/your-org/CycleDataKit")!

    /// e.g. "1.0 (1)" from the bundle's marketing and build versions.
    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
