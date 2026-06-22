import Foundation
import SwiftData

/// The join entity: a `Symptom` recorded on a particular `DailyLog`, with an
/// optional `Intensity`.
///
/// `symptomNameSnapshot` captures the symptom's name at log time so that
/// archiving or renaming the catalog `Symptom` (a `.nullify` relationship)
/// never makes a past entry unreadable.
@Model
public final class LoggedSymptom {
    public var id: UUID
    /// `Intensity.rawValue`; `nil` when the user didn't specify a severity.
    public var intensityRaw: Int?
    public var symptomNameSnapshot: String

    public var dailyLog: DailyLog?
    public var symptom: Symptom?

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        symptom: Symptom,
        intensity: Intensity? = nil,
        dailyLog: DailyLog? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.intensityRaw = intensity?.rawValue
        self.symptomNameSnapshot = symptom.name
        self.symptom = symptom
        self.dailyLog = dailyLog
        self.createdAt = createdAt
    }

    public var intensity: Intensity? {
        get { intensityRaw.flatMap(Intensity.init(rawValue:)) }
        set { intensityRaw = newValue?.rawValue }
    }
}
