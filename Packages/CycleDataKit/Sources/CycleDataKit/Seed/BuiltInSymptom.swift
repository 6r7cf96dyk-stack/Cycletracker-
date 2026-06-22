import Foundation

/// One entry in the built-in symptom catalog.
///
/// Built-ins are matched across app versions by their stable `key`, so the
/// list below can be revised freely and existing installs pick up the changes
/// on the next launch (see `SymptomSeeder.syncBuiltIns`).
public struct BuiltInSymptom: Sendable {
    public let key: String              // stable identifier — never reuse or rename
    public let name: String             // display name — safe to change anytime
    public let category: SymptomCategory
    public let icon: String             // SF Symbol name

    public init(key: String, name: String, category: SymptomCategory, icon: String) {
        self.key = key
        self.name = name
        self.category = category
        self.icon = icon
    }
}

public extension BuiltInSymptom {

    // ┌──────────────────────────────────────────────────────────────────────┐
    // │  EDIT THIS LIST.                                                        │
    // │                                                                        │
    // │  When revising with beta feedback:                                     │
    // │   • Add a symptom .......... add a line. It appears for everyone next   │
    // │                              launch.                                    │
    // │   • Rename / change icon ... edit `name` / `icon`. Keep the same `key`. │
    // │                              The change propagates to existing installs.│
    // │   • Reorder ................ move the line. List order = display order. │
    // │   • Retire a symptom ....... delete the line. New installs won't get it;│
    // │                              existing installs keep it (users can turn  │
    // │                              it off in Settings). Logged history is     │
    // │                              never touched.                            │
    // │   • NEVER change an existing `key` — that orphans saved data.           │
    // └──────────────────────────────────────────────────────────────────────┘

    /// The full catalog, in display order.
    static let catalog: [BuiltInSymptom] = physical + emotional

    // MARK: Physical
    static let physical: [BuiltInSymptom] = [
        BuiltInSymptom(key: "cramps",            name: "Cramps",            category: .physical, icon: "bolt.fill"),
        BuiltInSymptom(key: "headache",          name: "Headache",          category: .physical, icon: "brain.head.profile"),
        BuiltInSymptom(key: "backache",          name: "Backache",          category: .physical, icon: "figure.stand"),
        BuiltInSymptom(key: "fatigue",           name: "Fatigue",           category: .physical, icon: "zzz"),
        BuiltInSymptom(key: "bloating",          name: "Bloating",          category: .physical, icon: "circle.dashed"),
        BuiltInSymptom(key: "nausea",            name: "Nausea",            category: .physical, icon: "wind"),
        BuiltInSymptom(key: "breast_tenderness", name: "Tender breasts",    category: .physical, icon: "heart"),
        BuiltInSymptom(key: "acne",              name: "Acne",              category: .physical, icon: "drop.fill"),
        BuiltInSymptom(key: "cravings",          name: "Food cravings",     category: .physical, icon: "fork.knife"),
        BuiltInSymptom(key: "insomnia",          name: "Trouble sleeping",  category: .physical, icon: "moon.zzz")
    ]

    // MARK: Emotional
    static let emotional: [BuiltInSymptom] = [
        BuiltInSymptom(key: "mood_swings",   name: "Mood swings",   category: .emotional, icon: "arrow.up.arrow.down"),
        BuiltInSymptom(key: "irritability",  name: "Irritability",  category: .emotional, icon: "exclamationmark.bubble"),
        BuiltInSymptom(key: "anxiety",       name: "Anxiety",       category: .emotional, icon: "tornado"),
        BuiltInSymptom(key: "low_mood",      name: "Low mood",      category: .emotional, icon: "cloud.rain"),
        BuiltInSymptom(key: "tearfulness",   name: "Tearfulness",   category: .emotional, icon: "drop"),
        BuiltInSymptom(key: "brain_fog",     name: "Brain fog",     category: .emotional, icon: "brain")
    ]
}
