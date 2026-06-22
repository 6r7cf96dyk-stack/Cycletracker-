import Foundation
import SwiftData

/// Location reserved for local, user-initiated backups/exports.
///
/// Nothing writes here yet, but defining it now means "Delete all data" can
/// guarantee any future on-device backup files are wiped too. (Never a remote
/// location — backups, if added, stay on the device.)
public enum LocalBackup {
    public static var directoryURL: URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )) ?? URL.applicationSupportDirectory
        return base.appendingPathComponent("Backups", isDirectory: true)
    }
}

/// Irreversibly erases everything the app has stored on the device.
public enum DataReset {

    /// Deletes all model data from the SwiftData store. Children are removed
    /// before parents so nothing is orphaned.
    public static func deleteAllData(in context: ModelContext) throws {
        try context.delete(model: LoggedSymptom.self)
        try context.delete(model: DailyLog.self)
        try context.delete(model: Period.self)
        try context.delete(model: Symptom.self)
        try context.save()
    }

    /// Removes the local backup directory (and anything in it), if present.
    /// Returns `true` if a directory existed and was removed.
    @discardableResult
    public static func deleteLocalBackupFiles(fileManager: FileManager = .default) throws -> Bool {
        let url = LocalBackup.directoryURL
        guard fileManager.fileExists(atPath: url.path) else { return false }
        try fileManager.removeItem(at: url)
        return true
    }
}
