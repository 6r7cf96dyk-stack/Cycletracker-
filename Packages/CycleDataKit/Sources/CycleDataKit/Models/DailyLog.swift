import Foundation
import SwiftData

/// One entry per calendar day. The `date` is normalized to the start of the
/// day and is unique — there is at most one `DailyLog` per day.
@Model
public final class DailyLog {
    /// Enforce one log per calendar day (iOS 18 `#Unique` macro).
    #Unique<DailyLog>([\.date])

    public var id: UUID
    /// Always store the *start of day* (use `init(date:)` which normalizes).
    public var date: Date
    /// `FlowLevel.rawValue`; `nil` when no flow was logged for the day.
    public var flowRaw: Int?
    /// `Mood.rawValue`; `nil` when no mood was logged.
    public var moodRaw: Int?
    public var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSymptom.dailyLog)
    public var loggedSymptoms: [LoggedSymptom]

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        flow: FlowLevel? = nil,
        mood: Mood? = nil,
        notes: String? = nil,
        loggedSymptoms: [LoggedSymptom] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.flowRaw = flow?.rawValue
        self.moodRaw = mood?.rawValue
        self.notes = notes
        self.loggedSymptoms = loggedSymptoms
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Typed accessors over the stored raw values

    public var flow: FlowLevel? {
        get { flowRaw.flatMap(FlowLevel.init(rawValue:)) }
        set { flowRaw = newValue?.rawValue }
    }

    public var mood: Mood? {
        get { moodRaw.flatMap(Mood.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }
}
