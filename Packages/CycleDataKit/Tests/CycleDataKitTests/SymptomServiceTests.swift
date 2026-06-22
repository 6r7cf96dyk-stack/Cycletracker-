import Testing
import SwiftData
@testable import CycleDataKit

@Suite("SymptomService")
@MainActor
struct SymptomServiceTests {

    private func makeContext() throws -> ModelContext {
        try DataStore.container(inMemory: true).mainContext
    }

    @Test("Adds a custom symptom after the built-in catalog")
    func addsCustomSymptom() throws {
        let context = try makeContext()
        try SymptomSeeder.syncBuiltIns(in: context)
        let builtInCount = BuiltInSymptom.catalog.count

        let created = try SymptomService.addCustomSymptom(
            name: "Backache", category: .physical, in: context
        )

        #expect(created.isBuiltIn == false)
        #expect(created.sortOrder == builtInCount) // appended after built-ins (0..<n)
        #expect(try context.fetchCount(FetchDescriptor<Symptom>()) == builtInCount + 1)
    }

    @Test("Trims whitespace and rejects a blank name")
    func rejectsBlankName() throws {
        let context = try makeContext()
        #expect(throws: SymptomServiceError.emptyName) {
            try SymptomService.addCustomSymptom(name: "   ", in: context)
        }
    }

    @Test("Rejects a duplicate name case-insensitively")
    func rejectsDuplicateName() throws {
        let context = try makeContext()
        try SymptomService.addCustomSymptom(name: "Backache", in: context)
        #expect(throws: SymptomServiceError.duplicateName) {
            try SymptomService.addCustomSymptom(name: "  backache ", in: context)
        }
    }

    @Test("Enabling/disabling toggles isArchived")
    func setArchivedTogglesState() throws {
        let context = try makeContext()
        let symptom = try SymptomService.addCustomSymptom(name: "Backache", in: context)

        try SymptomService.setArchived(true, on: symptom, in: context)
        #expect(symptom.isArchived == true)

        try SymptomService.setArchived(false, on: symptom, in: context)
        #expect(symptom.isArchived == false)
    }

    @Test("Custom symptoms can be deleted; built-ins cannot")
    func deleteOnlyRemovesCustom() throws {
        let context = try makeContext()
        try SymptomSeeder.syncBuiltIns(in: context)
        let custom = try SymptomService.addCustomSymptom(name: "Backache", in: context)
        let builtIn = try #require(
            try context.fetch(FetchDescriptor<Symptom>()).first { $0.isBuiltIn }
        )

        try SymptomService.deleteCustomSymptom(builtIn, in: context)   // no-op
        try SymptomService.deleteCustomSymptom(custom, in: context)    // removed

        let remaining = try context.fetch(FetchDescriptor<Symptom>())
        #expect(remaining.count == BuiltInSymptom.catalog.count)
        #expect(!remaining.contains { $0.name == "Backache" })
    }
}
