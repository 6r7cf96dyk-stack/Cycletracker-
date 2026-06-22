import SwiftUI
import SwiftData
import CycleDataKit

/// Turn symptoms on/off (per category) and add or delete custom ones.
struct SymptomSettingsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Symptom.sortOrder)])
    private var symptoms: [Symptom]

    @State private var showAddSymptom = false

    /// Symptoms grouped into the category order defined by the enum, skipping
    /// empty categories.
    private var groups: [(category: SymptomCategory, items: [Symptom])] {
        let byCategory = Dictionary(grouping: symptoms) { $0.category ?? .other }
        return SymptomCategory.allCases.compactMap { category in
            guard let items = byCategory[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.category) { group in
                Section(group.category.label) {
                    ForEach(group.items) { symptom in
                        row(for: symptom)
                    }
                }
            }
        }
        .navigationTitle("Symptoms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSymptom = true
                } label: {
                    Label("Add Symptom", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSymptom) {
            AddSymptomView { _ in }
        }
        .overlay {
            if symptoms.isEmpty {
                ContentUnavailableView("No Symptoms", systemImage: "list.bullet")
            }
        }
    }

    private func row(for symptom: Symptom) -> some View {
        Toggle(isOn: enabledBinding(for: symptom)) {
            Label(symptom.name, systemImage: symptom.iconName ?? "circle")
        }
        .swipeActions(edge: .trailing) {
            if !symptom.isBuiltIn {
                Button(role: .destructive) {
                    try? SymptomService.deleteCustomSymptom(symptom, in: context)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func enabledBinding(for symptom: Symptom) -> Binding<Bool> {
        Binding(
            get: { !symptom.isArchived },
            set: { isEnabled in
                try? SymptomService.setArchived(!isEnabled, on: symptom, in: context)
            }
        )
    }
}

#Preview {
    NavigationStack {
        SymptomSettingsView()
    }
    .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
