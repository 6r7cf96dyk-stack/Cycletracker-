import Foundation

/// Grouping for symptoms in the catalog. Stored as a `String` raw value.
public enum SymptomCategory: String, Codable, CaseIterable, Sendable {
    case physical
    case emotional
    case digestive
    case skin
    case sleep
    case other

    public var label: String {
        switch self {
        case .physical: "Physical"
        case .emotional: "Emotional"
        case .digestive: "Digestive"
        case .skin: "Skin"
        case .sleep: "Sleep"
        case .other: "Other"
        }
    }
}
