import SwiftUI

/// Placeholder. The cycle calendar will live here.
struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Calendar",
                systemImage: "calendar",
                description: Text("Your cycle calendar will appear here.")
            )
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
