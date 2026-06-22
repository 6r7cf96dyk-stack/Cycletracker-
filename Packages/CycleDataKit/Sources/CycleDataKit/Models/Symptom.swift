import Foundation
import SwiftData

/// A symptom *definition* in the catalog — reusable reference data, shared
/// across the days on which it is logged. Built-in symptoms are seeded;
/// users may also add custom ones.
///
/// Symptoms are retired via `isArchived` rather than hard-deleted, so that
/// historical `LoggedSymptom` entries remain meaningful.
@Model
public final class Symptom {
    public var id: UUID
    public var name: String
    /// `SymptomCategory.rawValue`; `nil` if uncategorized.
    public var categoryRaw: String?
    /// SF Symbol name used to render the symptom.
    public var iconName: String?
    /// `true` for seeded symptoms, `false` for user-created ones.
    public var isBuiltIn: Bool
    /// Soft-hide flag — archived symptoms stay out of pickers but keep history.
    public var isArchived: Bool
    public var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \LoggedSymptom.symptom)
    public var logs: [LoggedSymptom]

    public init(
        id: UUID = UUID(),
        name: String,
        category: SymptomCategory? = nil,
        iconName: String? = nil,
        isBuiltIn: Bool = false,
        isArchived: Bool = false,
        sortOrder: Int = 0,
        logs: [LoggedSymptom] = []
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category?.rawValue
        self.iconName = iconName
        self.isBuiltIn = isBuiltIn
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.logs = logs
    }

    public var category: SymptomCategory? {
        get { categoryRaw.flatMap(SymptomCategory.init(rawValue:)) }
        set { categoryRaw = newValue?.rawValue }
    }
}
