import SwiftUI
import SwiftData
import CycleDataKit

/// The editable form for a single day. The day drives a `@Query` so that
/// switching dates loads that day's saved values. Edits are held in local
/// draft state and committed via `DailyLogService` on Save.
///
/// Used both inline by `LogView` and inside a sheet from `CalendarView`.
struct DayLogForm: View {
    let day: Date

    @Environment(\.modelContext) private var context

    @Query private var existing: [DailyLog]
    @Query(
        filter: #Predicate<Symptom> { !$0.isArchived },
        sort: [SortDescriptor(\Symptom.sortOrder)]
    )
    private var symptoms: [Symptom]

    @State private var flow: FlowLevel?
    @State private var mood: Mood?
    @State private var notes: String = ""
    @State private var selectedSymptomIDs: Set<PersistentIdentifier> = []
    @State private var intensities: [PersistentIdentifier: Intensity] = [:]
    @State private var showSavedToast = false
    @State private var showAddSymptom = false

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        _existing = Query(FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == start }))
    }

    var body: some View {
        Form {
            flowSection
            moodSection
            symptomsSection
            notesSection
        }
        .onChange(of: day, initial: true) { _, _ in loadDraft() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
            }
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("Saved")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAddSymptom) {
            AddSymptomView { newSymptomID in
                selectedSymptomIDs.insert(newSymptomID)
            }
        }
    }

    // MARK: - Sections

    private var flowSection: some View {
        Section("Flow") {
            Picker("Flow", selection: $flow) {
                Text("None").tag(FlowLevel?.none)
                ForEach(FlowLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(FlowLevel?.some(level))
                }
            }
        }
    }

    private var moodSection: some View {
        Section("Mood") {
            Picker("Mood", selection: $mood) {
                Text("None").tag(Mood?.none)
                ForEach(Mood.allCases, id: \.self) { mood in
                    Text(mood.label).tag(Mood?.some(mood))
                }
            }
        }
    }

    private var symptomsSection: some View {
        Section("Symptoms") {
            ForEach(symptoms) { symptom in
                symptomRow(symptom)
            }
            Button {
                showAddSymptom = true
            } label: {
                Label("Add Custom Symptom", systemImage: "plus.circle")
            }
        }
    }

    private func symptomRow(_ symptom: Symptom) -> some View {
        let id = symptom.persistentModelID
        let isSelected = selectedSymptomIDs.contains(id)
        return VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: selectionBinding(for: id)) {
                Label(symptom.name, systemImage: symptom.iconName ?? "circle")
            }
            if isSelected {
                Picker("Intensity", selection: intensityBinding(for: id)) {
                    Text("Unspecified").tag(Intensity?.none)
                    ForEach(Intensity.allCases, id: \.self) { intensity in
                        Text(intensity.label).tag(Intensity?.some(intensity))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Bindings

    private func selectionBinding(for id: PersistentIdentifier) -> Binding<Bool> {
        Binding(
            get: { selectedSymptomIDs.contains(id) },
            set: { isOn in
                if isOn {
                    selectedSymptomIDs.insert(id)
                } else {
                    selectedSymptomIDs.remove(id)
                    intensities[id] = nil
                }
            }
        )
    }

    private func intensityBinding(for id: PersistentIdentifier) -> Binding<Intensity?> {
        Binding(
            get: { intensities[id] },
            set: { intensities[id] = $0 }
        )
    }

    // MARK: - Load / Save

    private func loadDraft() {
        let log = existing.first
        flow = log?.flow
        mood = log?.mood
        notes = log?.notes ?? ""

        var ids = Set<PersistentIdentifier>()
        var levels: [PersistentIdentifier: Intensity] = [:]
        for logged in log?.loggedSymptoms ?? [] {
            guard let symptomID = logged.symptom?.persistentModelID else { continue }
            ids.insert(symptomID)
            if let intensity = logged.intensity { levels[symptomID] = intensity }
        }
        selectedSymptomIDs = ids
        intensities = levels
    }

    private func save() {
        let selections = symptoms
            .filter { selectedSymptomIDs.contains($0.persistentModelID) }
            .map { SymptomSelection(symptom: $0, intensity: intensities[$0.persistentModelID]) }

        do {
            try DailyLogService.save(
                date: day,
                flow: flow,
                mood: mood,
                notes: notes,
                symptomSelections: selections,
                in: context
            )
            flashSavedToast()
        } catch {
            // Local store write failed; nothing left the device. Log it.
            print("Failed to save daily log: \(error)")
        }
    }

    private func flashSavedToast() {
        withAnimation { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation { showSavedToast = false }
        }
    }
}
