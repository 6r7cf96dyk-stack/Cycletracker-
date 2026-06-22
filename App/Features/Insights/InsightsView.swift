import SwiftUI
import SwiftData
import Charts
import CycleDataKit

/// Descriptive summaries of logged history: key metrics, a cycle-length chart,
/// and a plain-language restatement of the estimate with its basis.
struct InsightsView: View {
    @Query(sort: [SortDescriptor(\DailyLog.date)]) private var logs: [DailyLog]

    private let calendar = Calendar.current

    private var periods: [Period] {
        CycleHistory.derivePeriods(from: logs, calendar: calendar)
    }
    private var allCycleLengths: [Int] {
        Estimator.observedCycleLengths(from: periods, calendar: calendar)
    }
    private var estimate: CycleEstimate? {
        Estimator.estimate(from: periods, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let estimate {
                    content(estimate)
                } else {
                    ContentUnavailableView {
                        Label("Not enough data yet", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Log a couple of cycles and your insights will appear here.")
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private func content(_ estimate: CycleEstimate) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                metricsGrid(estimate)
                chartSection
                estimateCard(estimate)
                exportSection
            }
            .padding()
        }
    }

    // MARK: - Metrics

    private func metricsGrid(_ estimate: CycleEstimate) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "Avg cycle length",
                       value: "\(days(estimate.averageCycleLength))")
            MetricCard(title: "Avg period length",
                       value: estimate.averagePeriodLength.map(days) ?? "—")
            MetricCard(title: "Variability",
                       value: "± \(days(estimate.cycleLengthStandardDeviation))")
            MetricCard(title: "Cycles logged",
                       value: "\(allCycleLengths.count)")
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cycle length history").font(.headline)
            Chart(Array(allCycleLengths.enumerated()), id: \.offset) { index, length in
                BarMark(
                    x: .value("Cycle", index + 1),
                    y: .value("Days", length)
                )
                .foregroundStyle(Color.accentColor)
                .annotation(position: .top) {
                    Text("\(length)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .chartXAxisLabel("Cycle")
            .chartYAxisLabel("Days")
            .frame(height: 200)
            Text("Averages reflect your most recent \(estimateWindowDescription).")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var estimateWindowDescription: String {
        let count = estimate?.cyclesAnalyzed ?? 0
        return count == 1 ? "cycle" : "\(count) cycles"
    }

    // MARK: - Estimate restatement

    private func estimateCard(_ estimate: CycleEstimate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimate").font(.headline)
            Text(basis(estimate))
                .font(.callout)
            Text("Based only on the days you've logged — this is not medical advice and not a fertility or contraception guide.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    /// e.g. "Based on your last 4 cycles (28, 30, 27, 29), your average is
    /// 28.5 days; next period estimated June 28–30."
    private func basis(_ estimate: CycleEstimate) -> String {
        let count = estimate.recentCycleLengths.count
        let lengths = estimate.recentCycleLengths.map(String.init).joined(separator: ", ")
        let average = estimate.averageCycleLength
            .formatted(.number.precision(.fractionLength(0...1)))
        let range = formattedRange(estimate.nextPeriodStartWindow)
        let cycleWord = count == 1 ? "cycle" : "cycles"
        return "Based on your last \(count) \(cycleWord) (\(lengths)), your average is \(average) days; next period estimated \(range)."
    }

    // MARK: - Export (placeholder)

    private var exportSection: some View {
        VStack(spacing: 4) {
            Button {
                // TODO: wire up PDF export for sharing with a clinician.
            } label: {
                Label("Export PDF for doctor", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(true)
            Text("Coming soon")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Formatting helpers

    private func days(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) days"
    }

    /// "June 28–30" when the bounds share a month, else "June 28 – July 2".
    private func formattedRange(_ range: ClosedRange<Date>) -> String {
        let lower = range.lowerBound
        let upper = range.upperBound
        let lowerText = lower.formatted(.dateTime.month(.wide).day())
        if calendar.isDate(lower, equalTo: upper, toGranularity: .month) {
            return "\(lowerText)–\(upper.formatted(.dateTime.day()))"
        }
        return "\(lowerText) – \(upper.formatted(.dateTime.month(.wide).day()))"
    }
}

/// A labeled metric tile.
private struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
