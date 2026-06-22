import Foundation

/// Optional severity attached to a `LoggedSymptom`. Users may leave it unset.
public enum Intensity: Int, Codable, CaseIterable, Sendable {
    case mild = 1
    case moderate = 2
    case severe = 3

    public var label: String {
        switch self {
        case .mild: "Mild"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }
}
