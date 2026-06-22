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
        try SymptomSeeder.seedIfNeeded(in: context)
        let builtInCount = SymptomSeeder.builtIns.count

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
}
