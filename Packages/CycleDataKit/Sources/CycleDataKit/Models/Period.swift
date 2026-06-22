import Foundation
import SwiftData

/// A single menstrual episode, modeled as a date span.
///
/// Per our design decision, a `Period` is *not* directly related to
/// `DailyLog`s; the logs that fall inside a period are derived by comparing
/// dates. This keeps a single source of truth and avoids a stored
/// relationship drifting out of sync with the dates.
@Model
public final class Period {
    public var id: UUID
    public var startDate: Date
    /// `nil` means the period is still ongoing.
    public var endDate: Date?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
