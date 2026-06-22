import SwiftUI
import SwiftData
import CycleDataKit

/// Pick a day, then log flow / mood / symptoms / notes for it.
struct LogView: View {
    @State private var selectedDate: Date = .now

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                DayLogForm(day: selectedDate)
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LogView()
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
