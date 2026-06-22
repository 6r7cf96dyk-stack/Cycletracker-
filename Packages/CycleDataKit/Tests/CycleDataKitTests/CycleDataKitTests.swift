import Testing
import SwiftData
@testable import CycleDataKit

@Suite("CycleDataKit model layer")
struct CycleDataKitTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let container = try DataStore.container(inMemory: true)
        return container.mainContext
    }

    @Test("DailyLog normalizes its date to the start of day")
    @MainActor
    func dailyLogNormalizesDate() throws {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 34, second: 0, of: .now)!
        let log = DailyLog(date: noon, flow: .medium, mood: .okay)
        #expect(log.date == Calendar.current.startOfDay(for: noon))
        #expect(log.flow == .medium)
        #expect(log.mood == .okay)
    }

    @Test("Sync inserts the built-in catalog once and is idempotent")
    @MainActor
    func syncIsIdempotent() throws {
        let context = try makeContext()
        try SymptomSeeder.syncBuiltIns(in: context)
        let first = try context.fetchCount(FetchDescriptor<Symptom>())
        #expect(first == BuiltInSymptom.catalog.count)

        try SymptomSeeder.syncBuiltIns(in: context)
        let second = try context.fetchCount(FetchDescriptor<Symptom>())
        #expect(second == first)
    }

    @Test("Re-syncing preserves the user's enable/disable choice")
    @MainActor
    func syncPreservesArchivedState() throws {
        let context = try makeContext()
        try SymptomSeeder.syncBuiltIns(in: context)

        // User disables one built-in.
        let all = try context.fetch(FetchDescriptor<Symptom>())
        let target = try #require(all.first { $0.builtInKey == "cramps" })
        target.isArchived = true
        try context.save()

        // A later launch must not re-enable it.
        try SymptomSeeder.syncBuiltIns(in: context)
        let after = try context.fetch(FetchDescriptor<Symptom>())
        let stillDisabled = try #require(after.first { $0.builtInKey == "cramps" })
        #expect(stillDisabled.isArchived == true)
    }

    @Test("LoggedSymptom snapshots the symptom name")
    @MainActor
    func loggedSymptomSnapshotsName() throws {
        let symptom = Symptom(name: "Cramps", category: .physical)
        let logged = LoggedSymptom(symptom: symptom, intensity: .moderate)
        #expect(logged.symptomNameSnapshot == "Cramps")
        #expect(logged.intensity == .moderate)
    }
}
