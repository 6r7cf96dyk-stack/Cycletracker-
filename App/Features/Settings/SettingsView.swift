import SwiftUI
import SwiftData
import CycleDataKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKeys.appLockEnabled) private var appLockEnabled = false
    @AppStorage(SettingsKeys.theme) private var themeRaw = AppTheme.system.rawValue

    @State private var showFirstDeleteConfirm = false
    @State private var showSecondDeleteConfirm = false
    @State private var deleteError: String?

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                loggingSection
                securitySection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all data?",
                isPresented: $showFirstDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Continue", role: .destructive) { showSecondDeleteConfirm = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every logged day, period, and custom symptom from this device.")
            }
            .alert("This cannot be undone", isPresented: $showSecondDeleteConfirm) {
                Button("Delete Everything", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Permanently delete all your data? You will not be able to recover it.")
            }
            .alert(
                "Couldn't delete data",
                isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })
            ) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var loggingSection: some View {
        Section {
            NavigationLink {
                SymptomSettingsView()
            } label: {
                Label("Symptoms", systemImage: "list.bullet.clipboard")
            }
        } header: {
            Text("Logging")
        } footer: {
            Text("Turn symptoms on or off, or add your own.")
        }
    }

    private var securitySection: some View {
        Section {
            Toggle(isOn: $appLockEnabled) {
                Label("Require Face ID / Passcode", systemImage: "faceid")
            }
        } header: {
            Text("Security")
        } footer: {
            Text("Lock the app when you open it or return to it. Uses Face ID, Touch ID, or your device passcode.")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showFirstDeleteConfirm = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Permanently erase everything stored on this device, including any local backups.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                PrivacyView()
            } label: {
                Label("Privacy", systemImage: "lock.shield")
            }
            Link(destination: AppInfo.sourceRepoURL) {
                HStack {
                    Label("CycleDataKit source", systemImage: "chevron.left.forwardslash.chevron.right")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent {
                Text(AppInfo.versionString)
            } label: {
                Label("Version", systemImage: "info.circle")
            }
        } header: {
            Text("About")
        } footer: {
            Text(AppInfo.disclaimer)
        }
    }

    // MARK: - Actions

    private func deleteAllData() {
        do {
            try DataReset.deleteAllData(in: context)
            try DataReset.deleteLocalBackupFiles()
            // Restore the built-in symptom catalog so logging still works.
            try SymptomSeeder.syncBuiltIns(in: context)
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
