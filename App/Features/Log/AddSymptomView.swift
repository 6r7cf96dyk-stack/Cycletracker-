import SwiftUI
import SwiftData
import CycleDataKit

/// A sheet for creating a custom symptom. On success it reports the new
/// symptom's id so the caller can auto-select it.
struct AddSymptomView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let onCreated: (PersistentIdentifier) -> Void

    @State private var name: String = ""
    @State private var category: SymptomCategory = .other
    @State private var errorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Backache", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(SymptomCategory.allCases, id: \.self) { category in
                            Text(category.label).tag(category)
                        }
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func add() {
        do {
            let symptom = try SymptomService.addCustomSymptom(
                name: name,
                category: category,
                in: context
            )
            onCreated(symptom.persistentModelID)
            dismiss()
        } catch SymptomServiceError.duplicateName {
            errorMessage = "A symptom with that name already exists."
        } catch SymptomServiceError.emptyName {
            errorMessage = "Please enter a name."
        } catch {
            errorMessage = "Couldn't add symptom: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AddSymptomView { _ in }
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
