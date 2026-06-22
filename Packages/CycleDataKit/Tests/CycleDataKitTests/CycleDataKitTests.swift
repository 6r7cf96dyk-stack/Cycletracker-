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

    @Test("Seeder inserts the built-in catalog once and is idempotent")
    @MainActor
    func seederIsIdempotent() throws {
        let context = try makeContext()
        try SymptomSeeder.seedIfNeeded(in: context)
        let first = try context.fetchCount(FetchDescriptor<Symptom>())
        #expect(first == SymptomSeeder.builtIns.count)

        try SymptomSeeder.seedIfNeeded(in: context)
        let second = try context.fetchCount(FetchDescriptor<Symptom>())
        #expect(second == first)
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
