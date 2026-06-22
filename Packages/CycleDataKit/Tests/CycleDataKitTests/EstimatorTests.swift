import Testing
import Foundation
@testable import CycleDataKit

@Suite("Estimator")
struct EstimatorTests {

    // A fixed UTC calendar + reference date so day arithmetic is deterministic
    // (no DST / time-zone flakiness).
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let reference = Date(timeIntervalSince1970: 1_600_000_000)

    /// A date `offset` whole days after the (normalized) reference day.
    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: reference))!
    }

    private func period(start: Int, end: Int? = nil) -> Period {
        Period(startDate: day(start), endDate: end.map { day($0) })
    }

    // MARK: - Guard rail: not enough data

    @Test("Returns nil with no periods")
    func nilWhenEmpty() {
        #expect(Estimator.estimate(from: [], calendar: calendar) == nil)
    }

    @Test("Returns nil with only one cycle (2 periods) by default")
    func nilBelowMinimumCycles() {
        let periods = [period(start: 0), period(start: 28)] // 1 cycle only
        #expect(Estimator.estimate(from: periods, calendar: calendar) == nil)
    }

    // MARK: - Perfectly regular history

    @Test("Regular 28-day cycles produce clean stats and a ±1-day window")
    func regularCycles() throws {
        // Starts on days 0, 28, 56, 84; each period lasts 5 days (e.g. 0…4).
        let periods = [
            period(start: 0, end: 4),
            period(start: 28, end: 32),
            period(start: 56, end: 60),
            period(start: 84, end: 88)
        ]
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))

        #expect(estimate.averageCycleLength == 28)
        #expect(estimate.cycleLengthStandardDeviation == 0)
        #expect(estimate.averagePeriodLength == 5)          // 4 - 0 + 1, inclusive
        #expect(estimate.cyclesAnalyzed == 3)
        #expect(estimate.nextPeriodStartEstimate == day(112)) // 84 + 28
        // stddev 0 → margin floored at 1 day.
        #expect(estimate.nextPeriodStartWindow == day(111)...day(113))
    }

    // MARK: - Recency weighting

    @Test("Forecast leans toward recent cycles, average stays a plain mean")
    func forecastIsWeightedTowardRecentCycles() throws {
        // Cycles: 30 then 26 (starts on days 0, 30, 56).
        let periods = [period(start: 0), period(start: 30), period(start: 56)]
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))

        // Plain mean of 30 and 26.
        #expect(estimate.averageCycleLength == 28)
        // Weighted = (1·30 + 2·26) / 3 = 82/3 ≈ 27.3 → 27, NOT 28.
        #expect(estimate.nextPeriodStartEstimate == day(56 + 27))
    }

    // MARK: - Standard deviation drives the window width

    @Test("Standard deviation widens the estimate window")
    func standardDeviationWidensWindow() throws {
        // Cycles: 26, 30, 28 (starts on days 0, 26, 56, 84) — matches the
        // worked example in Estimator.swift.
        let periods = [period(start: 0), period(start: 26), period(start: 56), period(start: 84)]
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))

        #expect(estimate.averageCycleLength == 28)
        #expect(estimate.cycleLengthStandardDeviation == 2)
        // Weighted = (1·26 + 2·30 + 3·28)/6 = 170/6 ≈ 28.3 → 28.
        #expect(estimate.nextPeriodStartEstimate == day(112)) // 84 + 28
        #expect(estimate.nextPeriodStartWindow == day(110)...day(114)) // ± 2
    }

    // MARK: - Rolling window

    @Test("Only the most recent cycles inside the window are used")
    func rollingWindowUsesOnlyRecentCycles() throws {
        // Starts 0,20,60,88,116 → cycles 20,40,28,28. With window 2 we keep the
        // last two cycles (28, 28) and ignore the noisy older ones.
        let periods = [
            period(start: 0), period(start: 20), period(start: 60),
            period(start: 88), period(start: 116)
        ]
        let estimate = try #require(
            Estimator.estimate(from: periods, recentCycleWindow: 2, calendar: calendar)
        )

        #expect(estimate.cyclesAnalyzed == 2)
        #expect(estimate.averageCycleLength == 28)
        #expect(estimate.cycleLengthStandardDeviation == 0)
        #expect(estimate.nextPeriodStartEstimate == day(116 + 28))
    }

    // MARK: - Ongoing (open) last period

    @Test("An ongoing last period still forecasts; only completed periods count for length")
    func handlesOngoingLastPeriod() throws {
        // Last period has no end date.
        let periods = [
            period(start: 0, end: 4),
            period(start: 28, end: 32),
            period(start: 56) // ongoing
        ]
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))

        #expect(estimate.cyclesAnalyzed == 2)               // cycles 28, 28
        #expect(estimate.averagePeriodLength == 5)          // only the two completed
        #expect(estimate.nextPeriodStartEstimate == day(84)) // 56 + 28
    }

    @Test("Unsorted input is handled")
    func sortsInput() throws {
        let periods = [period(start: 56), period(start: 0), period(start: 28)]
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))
        #expect(estimate.averageCycleLength == 28)
        #expect(estimate.nextPeriodStartEstimate == day(84))
    }
}
