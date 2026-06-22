import Foundation

/// Overall mood recorded on a `DailyLog`. Descriptive only — never used for
/// prediction or medical inference.
public enum Mood: Int, Codable, CaseIterable, Sendable {
    case great = 0
    case good = 1
    case okay = 2
    case low = 3
    case bad = 4

    public var label: String {
        switch self {
        case .great: "Great"
        case .good: "Good"
        case .okay: "Okay"
        case .low: "Low"
        case .bad: "Bad"
        }
    }
}
