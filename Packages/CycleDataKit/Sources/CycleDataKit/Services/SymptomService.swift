import Foundation
import SwiftData

public enum SymptomServiceError: Error, Equatable {
    case emptyName
    case duplicateName
}

/// Manages the symptom catalog — currently, adding user-defined symptoms.
public enum SymptomService {

    /// Creates a custom (non-built-in) symptom, appended to the end of the
    /// catalog. Throws if the name is blank or duplicates an existing,
    /// non-archived symptom (case-insensitive).
    @discardableResult
    public static func addCustomSymptom(
        name: String,
        category: SymptomCategory? = nil,
        iconName: String? = nil,
        in context: ModelContext
    ) throws -> Symptom {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SymptomServiceError.emptyName }

        let allSymptoms = try context.fetch(FetchDescriptor<Symptom>())
        let isDuplicate = allSymptoms.contains {
            !$0.isArchived && $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame
        }
        guard !isDuplicate else { throw SymptomServiceError.duplicateName }

        let nextSortOrder = (allSymptoms.map(\.sortOrder).max() ?? -1) + 1
        let symptom = Symptom(
            name: trimmed,
            category: category,
            iconName: iconName ?? "circle",
            isBuiltIn: false,
            sortOrder: nextSortOrder
        )
        context.insert(symptom)
        try context.save()
        return symptom
    }

    /// Enables or disables a symptom. Disabled (archived) symptoms are hidden
    /// from the logging picker but keep all historical entries.
    public static func setArchived(
        _ archived: Bool,
        on symptom: Symptom,
        in context: ModelContext
    ) throws {
        symptom.isArchived = archived
        try context.save()
    }

    /// Permanently deletes a custom symptom. Built-ins cannot be deleted (turn
    /// them off instead); this is a no-op for them.
    public static func deleteCustomSymptom(
        _ symptom: Symptom,
        in context: ModelContext
    ) throws {
        guard !symptom.isBuiltIn else { return }
        context.delete(symptom)
        try context.save()
    }
}
