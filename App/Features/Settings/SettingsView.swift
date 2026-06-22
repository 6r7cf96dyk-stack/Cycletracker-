import SwiftUI

/// Placeholder. App lock, data export, delete-all, and symptom management
/// will live here.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings",
                systemImage: "gearshape",
                description: Text("App lock, data export, and managing your data.")
            )
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
