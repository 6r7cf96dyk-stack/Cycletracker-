import SwiftUI

/// Placeholder. Descriptive (never predictive) summaries of logged history
/// will live here — e.g. past cycle lengths, symptom frequency.
struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Insights",
                systemImage: "chart.bar.xaxis",
                description: Text("Descriptive summaries of what you've logged.")
            )
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
}
