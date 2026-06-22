import SwiftUI

/// The app's root tab bar. Four sections, all local.
struct RootView: View {
    var body: some View {
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
}

#Preview {
    RootView()
}
