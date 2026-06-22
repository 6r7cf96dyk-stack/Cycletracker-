import Foundation

// =============================================================================
//  Estimator.swift
//
//  WHAT THIS IS:
//    A plain, transparent summary of the user's own logged period history,
//    plus a naive projection of the same rhythm forward. Everything here is
//    ordinary arithmetic — sorting dates, averaging gaps, a standard deviation,
//    and a recency-weighted average.
//
//  WHAT THIS IS *NOT* (read before shipping any UI copy):
//    • NOT machine learning. NOT "AI". Do not label it as either.
//    • NOT a medical device, and NOT for fertility, ovulation, conception, or
//      contraception decisions. It cannot tell anyone when they are fertile or
//      safe. It only says: "your recent cycles averaged ~N days, so the next
//      one is roughly due around here, give or take."
//    • NOT a guarantee. Always present the result as an approximate RANGE.
//
//  THE ALGORITHM, STEP BY STEP:
//    1. Sort the logged periods by start date (oldest → newest).
//    2. A "cycle length" is the number of days from one period's start to the
//       NEXT period's start. So N logged periods give N-1 cycle observations.
//    3. If there aren't enough cycles yet (default: at least 2, i.e. 3 logged
//       periods), return nil — we refuse to guess from too little data.
//    4. Keep only the most recent `recentCycleWindow` cycles (a rolling
//       window), so the estimate tracks the body's current rhythm and isn't
//       dragged around by ancient history.
//    5. Report plain (unweighted) descriptive stats over that window:
//         • averageCycleLength            = mean of the cycle lengths
//         • cycleLengthStandardDeviation  = how spread out they are
//         • averagePeriodLength           = mean length of recent periods
//    6. For the FORECAST only, use a recency-WEIGHTED average of the same
//       cycle lengths (newest cycle counts most). This is the one place we
//       lean on recent cycles, per the spec.
//    7. Next start estimate = last logged start + weighted-average cycle length.
//    8. Turn that single day into a RANGE by padding ± about one standard
//       deviation (at least ± 1 day), so the UI never implies false precision.
//
//  WORKED EXAMPLE (so you can sanity-check by hand):
//    Logged period starts on days 0, 26, 56, 84.
//      cycle lengths = [26, 30, 28]            (the gaps between starts)
//      averageCycleLength            = (26+30+28)/3 = 28 days
//      cycleLengthStandardDeviation  = sqrt(((26-28)²+(30-28)²+(28-28)²)/2)
//                                    = sqrt((4+4+0)/2) = sqrt(4) = 2 days
//      weighted average (weights 1,2,3 oldest→newest):
//                                    = (1·26 + 2·30 + 3·28) / (1+2+3)
//                                    = 170 / 6 ≈ 28.3 → rounds to 28 days
//      next start estimate           = day 84 + 28 = day 112
//      next start window (± 2 days)  = day 110 … day 114
// =============================================================================

/// The result of summarizing logged history. See `Estimator` for the math.
public struct CycleEstimate: Equatable, Sendable {

    /// Plain (unweighted) mean of the recent cycle lengths, in days.
    public let averageCycleLength: Double

    /// Sample standard deviation (Bessel's n-1 correction) of the recent cycle
    /// lengths, in days. 0 when only one cycle is in the window.
    public let cycleLengthStandardDeviation: Double

    /// Mean length of recent *completed* periods, in days, counting both the
    /// first and last logged day (inclusive). `nil` if no recent period has an
    /// end date yet (e.g. only an ongoing one).
    public let averagePeriodLength: Double?

    /// Single best-guess day the next period starts. Prefer showing the window
    /// below instead of this exact day.
    public let nextPeriodStartEstimate: Date

    /// Approximate range around the estimate (estimate ± ~1 standard deviation,
    /// at least ± 1 day). This is the value to surface in the UI.
    public let nextPeriodStartWindow: ClosedRange<Date>

    /// How many cycle observations fed this estimate (after windowing).
    public let cyclesAnalyzed: Int
}

/// Computes a `CycleEstimate` from logged `Period` history.
///
/// Returns `nil` when there isn't enough history (see `minimumCycles`).
public enum Estimator {

    /// - Parameters:
    ///   - periods: All logged periods (any order; ongoing ones allowed).
    ///   - minimumCycles: Minimum cycle observations required before we'll
    ///     estimate. Default 2 (needs ≥ 3 logged periods). Raise to 3 to be
    ///     more conservative.
    ///   - recentCycleWindow: How many of the most recent cycles to consider.
    ///   - calendar: Injectable for deterministic tests; defaults to current.
    public static func estimate(
        from periods: [Period],
        minimumCycles: Int = 2,
        recentCycleWindow: Int = 6,
        calendar: Calendar = .current
    ) -> CycleEstimate? {

        // 1. Oldest → newest.
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        guard sorted.count >= 2 else { return nil }

        // 2. Cycle length = whole-day gap between consecutive period starts.
        //    N periods → N-1 observations. Skip non-positive gaps (e.g. two
        //    periods logged on the same day).
        var cycleLengths: [Int] = []
        for index in 1..<sorted.count {
            let gap = dayGap(from: sorted[index - 1].startDate,
                             to: sorted[index].startDate,
                             calendar: calendar)
            if gap > 0 { cycleLengths.append(gap) }
        }

        // 3. Refuse to guess from too little data.
        let requiredCycles = max(1, minimumCycles)
        guard cycleLengths.count >= requiredCycles else { return nil }

        // 4. Rolling window: only the most recent cycles.
        let window = Array(cycleLengths.suffix(max(1, recentCycleWindow)))
        let windowValues = window.map(Double.init)

        // 5. Unweighted descriptive stats over the window.
        let average = mean(windowValues)
        let standardDeviation = sampleStandardDeviation(windowValues)

        // 6. Recency-weighted average, used ONLY for the forecast below.
        let weightedAverage = linearlyWeightedMean(windowValues)

        // 7. Average completed-period length over the same recent span.
        //    The windowed cycles correspond to the last (window + 1) periods.
        let recentPeriods = sorted.suffix(window.count + 1)
        let periodLengths = recentPeriods.compactMap { period -> Int? in
            guard let end = period.endDate else { return nil }
            // +1 so a Jun 1 → Jun 5 period counts as 5 days, not 4.
            let span = dayGap(from: period.startDate, to: end, calendar: calendar) + 1
            return span >= 1 ? span : nil
        }
        let averagePeriodLength = periodLengths.isEmpty
            ? nil
            : mean(periodLengths.map(Double.init))

        // 8. Forecast = last start + weighted-average cycle length.
        let lastStart = calendar.startOfDay(for: sorted[sorted.count - 1].startDate)
        let offsetDays = Int(weightedAverage.rounded())
        guard let nextStart = calendar.date(byAdding: .day, value: offsetDays, to: lastStart) else {
            return nil
        }

        // 9. Widen the single day into an honest range: ± ~1 standard
        //    deviation, never narrower than ± 1 day.
        let margin = max(1, Int(standardDeviation.rounded()))
        guard
            let lower = calendar.date(byAdding: .day, value: -margin, to: nextStart),
            let upper = calendar.date(byAdding: .day, value: margin, to: nextStart)
        else { return nil }

        return CycleEstimate(
            averageCycleLength: average,
            cycleLengthStandardDeviation: standardDeviation,
            averagePeriodLength: averagePeriodLength,
            nextPeriodStartEstimate: nextStart,
            nextPeriodStartWindow: lower...upper,
            cyclesAnalyzed: window.count
        )
    }

    // MARK: - Pure helpers (no SwiftData, easy to unit test)

    /// Whole-day difference between two dates, normalized to midnight so the
    /// time-of-day a period was logged never affects the result.
    private static func dayGap(from start: Date, to end: Date, calendar: Calendar) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Sample standard deviation (divides by n-1). Returns 0 for < 2 values.
    private static func sampleStandardDeviation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let m = mean(values)
        let sumOfSquares = values.reduce(0) { $0 + ($1 - m) * ($1 - m) }
        return (sumOfSquares / Double(values.count - 1)).squareRoot()
    }

    /// Linearly recency-weighted mean: the oldest value in the array has
    /// weight 1, the next 2, … and the newest has weight n.
    /// Result = Σ(weightᵢ · valueᵢ) / Σ(weightᵢ).
    private static func linearlyWeightedMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        var weightedSum = 0.0
        var weightTotal = 0.0
        for (index, value) in values.enumerated() {
            let weight = Double(index + 1) // oldest = 1 … newest = n
            weightedSum += weight * value
            weightTotal += weight
        }
        return weightedSum / weightTotal
    }
}
