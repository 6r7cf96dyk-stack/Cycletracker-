import Testing
import Foundation
import SwiftData
@testable import CycleDataKit

@Suite("DailyLogService")
@MainActor
struct DailyLogServiceTests {

    private func makeContext() throws -> ModelContext {
        try DataStore.container(inMemory: true).mainContext
    }

    private func seededSymptoms(_ context: ModelContext) throws -> [Symptom] {
        try SymptomSeeder.seedIfNeeded(in: context)
        return try context.fetch(
            FetchDescriptor<Symptom>(sortBy: [SortDescriptor(\.sortOrder)])
        )
    }

    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Saving then fetching round-trips every field")
    func savesAndFetches() throws {
        let context = try makeContext()
        let cramps = try seededSymptoms(context)[0]

        try DailyLogService.save(
            date: date, flow: .medium, mood: .low, notes: "tired",
            symptomSelections: [SymptomSelection(symptom: cramps, intensity: .moderate)],
            in: context
        )

        let log = try DailyLogService.fetchLog(on: date, in: context)
        #expect(log?.flow == .medium)
        #expect(log?.mood == .low)
        #expect(log?.notes == "tired")
        #expect(log?.loggedSymptoms.count == 1)
        #expect(log?.loggedSymptoms.first?.intensity == .moderate)
    }

    @Test("A second save on the same day updates rather than duplicates")
    func upsertIsSinglePerDay() throws {
        let context = try makeContext()

        try DailyLogService.save(date: date, flow: .light, mood: nil, notes: nil,
                                 symptomSelections: [], in: context)
        try DailyLogService.save(date: date, flow: .heavy, mood: nil, notes: nil,
                                 symptomSelections: [], in: context)

        let all = try context.fetch(FetchDescriptor<DailyLog>())
        #expect(all.count == 1)
        #expect(all.first?.flow == .heavy)
    }

    @Test("Blank notes are stored as nil")
    func blankNotesBecomeNil() throws {
        let context = try makeContext()
        try DailyLogService.save(date: date, flow: nil, mood: nil, notes: "   ",
                                 symptomSelections: [], in: context)
        let log = try DailyLogService.fetchLog(on: date, in: context)
        #expect(log?.notes == nil)
    }

    @Test("Re-saving reconciles symptoms: removes, keeps, and re-rates")
    func reconcilesSymptoms() throws {
        let context = try makeContext()
        let symptoms = try seededSymptoms(context)
        let a = symptoms[0]
        let b = symptoms[1]

        try DailyLogService.save(
            date: date, flow: nil, mood: nil, notes: nil,
            symptomSelections: [
                SymptomSelection(symptom: a, intensity: .mild),
                SymptomSelection(symptom: b, intensity: nil)
            ],
            in: context
        )
        #expect(try DailyLogService.fetchLog(on: date, in: context)?.loggedSymptoms.count == 2)

        // Drop b; change a to severe.
        try DailyLogService.save(
            date: date, flow: nil, mood: nil, notes: nil,
            symptomSelections: [SymptomSelection(symptom: a, intensity: .severe)],
            in: context
        )

        let log = try DailyLogService.fetchLog(on: date, in: context)
        #expect(log?.loggedSymptoms.count == 1)
        #expect(log?.loggedSymptoms.first?.symptom?.persistentModelID == a.persistentModelID)
        #expect(log?.loggedSymptoms.first?.intensity == .severe)

        // No orphaned join rows left behind.
        let orphans = try context.fetch(FetchDescriptor<LoggedSymptom>())
        #expect(orphans.count == 1)
    }
}
