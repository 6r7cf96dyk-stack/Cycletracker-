import SwiftUI

/// The app's root tab bar. Four sections, all local.
struct RootView: View {
    @AppStorage(SettingsKeys.theme) private var themeRaw = AppTheme.system.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }

    var body: some View {
        LockGate {
            TabView {
                CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }

                LogView()
                    .tabItem { Label("Log", systemImage: "square.and.pencil") }

                InsightsView()
                    .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView()
}
