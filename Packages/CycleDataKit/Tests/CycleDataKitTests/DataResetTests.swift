import Testing
import Foundation
import SwiftData
@testable import CycleDataKit

@Suite("DataReset")
@MainActor
struct DataResetTests {

    @Test("Deletes every model from the store")
    func deletesEverything() throws {
        let context = try DataStore.container(inMemory: true).mainContext
        try SymptomSeeder.syncBuiltIns(in: context)

        let symptom = try #require(try context.fetch(FetchDescriptor<Symptom>()).first)
        let log = DailyLog(date: .now, flow: .medium)
        context.insert(log)
        context.insert(LoggedSymptom(symptom: symptom, dailyLog: log))
        context.insert(Period(startDate: .now))
        try context.save()

        try DataReset.deleteAllData(in: context)

        #expect(try context.fetchCount(FetchDescriptor<DailyLog>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<LoggedSymptom>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Period>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Symptom>()) == 0)
    }

    @Test("Backup deletion is a safe no-op when absent, and removes when present")
    func backupDeletion() throws {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: LocalBackup.directoryURL)

        #expect(try DataReset.deleteLocalBackupFiles() == false)

        try fileManager.createDirectory(at: LocalBackup.directoryURL, withIntermediateDirectories: true)
        #expect(try DataReset.deleteLocalBackupFiles() == true)
        #expect(fileManager.fileExists(atPath: LocalBackup.directoryURL.path) == false)
    }
}
