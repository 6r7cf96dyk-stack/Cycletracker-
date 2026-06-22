import Foundation

/// Menstrual flow intensity recorded on a `DailyLog`.
///
/// Stored on disk as an `Int` raw value (see `DailyLog.flowRaw`) so that cases
/// can be added later without corrupting existing stores.
public enum FlowLevel: Int, Codable, CaseIterable, Sendable {
    case spotting = 0
    case light = 1
    case medium = 2
    case heavy = 3

    public var label: String {
        switch self {
        case .spotting: "Spotting"
        case .light: "Light"
        case .medium: "Medium"
        case .heavy: "Heavy"
        }
    }
}
