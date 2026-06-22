import Foundation
import SwiftData

/// Seeds the built-in symptom catalog the first time the app launches.
public enum SymptomSeeder {
    /// The default catalog. SF Symbol names are used for `iconName`.
    public static let builtIns: [(name: String, category: SymptomCategory, icon: String)] = [
        ("Cramps", .physical, "bolt.fill"),
        ("Headache", .physical, "brain.head.profile"),
        ("Fatigue", .physical, "zzz"),
        ("Bloating", .digestive, "circle.dashed"),
        ("Nausea", .digestive, "stomach"),
        ("Mood swings", .emotional, "face.dashed"),
        ("Irritability", .emotional, "exclamationmark.bubble"),
        ("Acne", .skin, "drop.fill"),
        ("Tender breasts", .physical, "heart"),
        ("Insomnia", .sleep, "moon.zzz")
    ]

    /// Inserts the built-in symptoms if the catalog is empty. Safe to call on
    /// every launch — it no-ops once seeded.
    public static func seedIfNeeded(in context: ModelContext) throws {
        let existing = try context.fetchCount(FetchDescriptor<Symptom>())
        guard existing == 0 else { return }

        for (index, entry) in builtIns.enumerated() {
            context.insert(
                Symptom(
                    name: entry.name,
                    category: entry.category,
                    iconName: entry.icon,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }
        try context.save()
    }
}
