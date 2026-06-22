import Foundation
import SwiftData

/// Derives period history from the per-day logs the user actually records.
///
/// The Log screen stores a `flow` on a `DailyLog`. A "period" is therefore a
/// run of consecutive calendar days that each have a flow logged. This service
/// groups those days into spans so the calendar can highlight period days and
/// the `Estimator` has `Period` history to work from — all from the single
/// source of truth (logged flow), with nothing extra for the user to enter.
public enum CycleHistory {

    /// The set of days (normalized to start-of-day) that have a flow logged.
    public static func periodDays(from logs: [DailyLog], calendar: Calendar = .current) -> Set<Date> {
        Set(
            logs
                .filter { $0.flowRaw != nil }
                .map { calendar.startOfDay(for: $0.date) }
        )
    }

    /// Groups flow-logged days into contiguous period spans.
    ///
    /// The returned `Period` values are *transient* — they are constructed for
    /// computation and are NOT inserted into any `ModelContext`. Consecutive
    /// days (no gap) belong to the same period; any gap starts a new one.
    public static func derivePeriods(from logs: [DailyLog], calendar: Calendar = .current) -> [Period] {
        let days = periodDays(from: logs, calendar: calendar).sorted()
        guard !days.isEmpty else { return [] }

        var periods: [Period] = []
        var spanStart = days[0]
        var spanEnd = days[0]

        for day in days.dropFirst() {
            let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: spanEnd)
            if let dayAfterEnd, calendar.isDate(day, inSameDayAs: dayAfterEnd) {
                spanEnd = day // contiguous — extend the current span
            } else {
                periods.append(Period(startDate: spanStart, endDate: spanEnd))
                spanStart = day
                spanEnd = day
            }
        }
        periods.append(Period(startDate: spanStart, endDate: spanEnd))
        return periods
    }
}
