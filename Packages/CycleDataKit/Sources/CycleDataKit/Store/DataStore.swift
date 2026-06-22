import Foundation
import SwiftData

/// Central place that defines the schema and builds the `ModelContainer`.
///
/// The configuration is deliberately local-only: no `cloudKitDatabase` is
/// set, so data never leaves the device. Pass `inMemory: true` for tests and
/// SwiftUI previews.
public enum DataStore {
    public static let schema = Schema([
        Period.self,
        DailyLog.self,
        Symptom.self,
        LoggedSymptom.self
    ])

    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
            // No cloudKitDatabase — storage stays on-device.
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
