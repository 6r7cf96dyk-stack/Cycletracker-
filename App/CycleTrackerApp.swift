import SwiftUI
import SwiftData
import CycleDataKit

@main
struct CycleTrackerApp: App {
    let container: ModelContainer

    init() {
        do {
            let container = try DataStore.container()
            try SymptomSeeder.seedIfNeeded(in: container.mainContext)
            self.container = container
        } catch {
            // Local-only store: a failure here means the on-device database
            // could not be opened. There is no remote fallback by design.
            fatalError("Failed to set up the local data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
