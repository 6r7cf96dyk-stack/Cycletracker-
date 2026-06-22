import Foundation
import SwiftData

/// A user's choice of a symptom for a given day, with an optional severity.
public struct SymptomSelection {
    public let symptom: Symptom
    public let intensity: Intensity?

    public init(symptom: Symptom, intensity: Intensity? = nil) {
        self.symptom = symptom
        self.intensity = intensity
    }
}

/// Reads and writes `DailyLog`s. Because there is at most one log per calendar
/// day (`#Unique` on `DailyLog.date`), writes are an upsert: fetch the day's
/// log or create it, then reconcile its symptom children to match the
/// selection.
public enum DailyLogService {

    /// The day's log, if one exists. `date` is normalized to the start of day.
    public static func fetchLog(on date: Date, in context: ModelContext) throws -> DailyLog? {
        let start = Calendar.current.startOfDay(for: date)
        var descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == start })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Creates or updates the log for `date` and reconciles its symptoms.
    @discardableResult
    public static func save(
        date: Date,
        flow: FlowLevel?,
        mood: Mood?,
        notes: String?,
        symptomSelections: [SymptomSelection],
        in context: ModelContext
    ) throws -> DailyLog {
        let start = Calendar.current.startOfDay(for: date)

        let log: DailyLog
        if let existing = try fetchLog(on: start, in: context) {
            log = existing
        } else {
            log = DailyLog(date: start)
            context.insert(log)
        }

        log.flow = flow
        log.mood = mood
        let trimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        log.notes = (trimmed?.isEmpty ?? true) ? nil : trimmed
        log.updatedAt = .now

        let selectionsBySymptomID = Dictionary(
            symptomSelections.map { ($0.symptom.persistentModelID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Update intensities for still-selected symptoms; delete the rest.
        var keptSymptomIDs = Set<PersistentIdentifier>()
        for logged in Array(log.loggedSymptoms) {
            if let symptomID = logged.symptom?.persistentModelID,
               let selection = selectionsBySymptomID[symptomID] {
                logged.intensity = selection.intensity
                keptSymptomIDs.insert(symptomID)
            } else {
                context.delete(logged)
            }
        }

        // Insert newly selected symptoms.
        for selection in symptomSelections
        where !keptSymptomIDs.contains(selection.symptom.persistentModelID) {
            let logged = LoggedSymptom(
                symptom: selection.symptom,
                intensity: selection.intensity,
                dailyLog: log
            )
            context.insert(logged)
        }

        try context.save()
        return log
    }
}
