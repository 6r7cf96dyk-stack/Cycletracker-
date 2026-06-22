import SwiftUI

/// Placeholder. Logging flow, mood, and symptoms for a day will live here.
struct LogView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Log",
                systemImage: "square.and.pencil",
                description: Text("Record flow, mood, and symptoms for a day.")
            )
            .navigationTitle("Log")
        }
    }
}

#Preview {
    LogView()
}
