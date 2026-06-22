import SwiftUI
import CycleDataKit

/// App settings. Data export and delete-all will join the list here later.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SymptomSettingsView()
                    } label: {
                        Label("Symptoms", systemImage: "list.bullet.clipboard")
                    }
                } header: {
                    Text("Logging")
                } footer: {
                    Text("Turn symptoms on or off, or add your own. Turning one off hides it from logging but keeps its history.")
                }

                Section {
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                } footer: {
                    Text("Your data stays on this device. No account, no internet, no tracking.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
