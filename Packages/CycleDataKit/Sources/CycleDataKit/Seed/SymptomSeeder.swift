import Foundation
import SwiftData

/// Keeps the stored symptom catalog in sync with `BuiltInSymptom.catalog`.
public enum SymptomSeeder {

    /// Reconciles built-in symptoms against the code catalog. Call once on
    /// every launch.
    ///
    /// For each catalog entry (matched by `builtInKey`):
    ///  • inserts it if missing;
    ///  • otherwise refreshes its name, category, icon, and order from code,
    ///    while preserving the user's enable/disable choice (`isArchived`).
    ///
    /// Built-ins removed from the catalog and all custom symptoms are left
    /// untouched, so no user data is lost.
    public static func syncBuiltIns(in context: ModelContext) throws {
        let stored = try context.fetch(FetchDescriptor<Symptom>())
        let storedByKey = Dictionary(
            stored.compactMap { symptom in symptom.builtInKey.map { ($0, symptom) } },
            uniquingKeysWith: { first, _ in first }
        )

        for (index, entry) in BuiltInSymptom.catalog.enumerated() {
            if let existing = storedByKey[entry.key] {
                existing.name = entry.name
                existing.category = entry.category
                existing.iconName = entry.icon
                existing.sortOrder = index
                existing.isBuiltIn = true
                // isArchived is intentionally left as the user set it.
            } else {
                context.insert(
                    Symptom(
                        name: entry.name,
                        category: entry.category,
                        iconName: entry.icon,
                        isBuiltIn: true,
                        sortOrder: index,
                        builtInKey: entry.key
                    )
                )
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }
}
