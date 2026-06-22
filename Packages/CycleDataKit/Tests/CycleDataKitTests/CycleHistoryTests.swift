import Testing
import Foundation
@testable import CycleDataKit

@Suite("CycleHistory")
struct CycleHistoryTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let reference = Date(timeIntervalSince1970: 1_600_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: reference))!
    }

    private func log(_ offset: Int, flow: FlowLevel?) -> DailyLog {
        DailyLog(date: day(offset), flow: flow)
    }

    @Test("Only flow-logged days count as period days")
    func periodDaysIgnoreFlowlessLogs() {
        let logs = [
            log(0, flow: .medium),
            log(1, flow: nil),          // mood/symptoms only — not a period day
            log(2, flow: .light)
        ]
        let days = CycleHistory.periodDays(from: logs, calendar: calendar)
        #expect(days == [day(0), day(2)])
    }

    @Test("Consecutive flow days group into one period; gaps split them")
    func derivesContiguousSpans() {
        // Days 0,1,2 form one period; day 5 (after a gap) starts another.
        let logs = [
            log(0, flow: .light),
            log(1, flow: .medium),
            log(2, flow: .light),
            log(5, flow: .medium)
        ]
        let periods = CycleHistory.derivePeriods(from: logs, calendar: calendar)
            .sorted { $0.startDate < $1.startDate }

        #expect(periods.count == 2)
        #expect(periods[0].startDate == day(0))
        #expect(periods[0].endDate == day(2))
        #expect(periods[1].startDate == day(5))
        #expect(periods[1].endDate == day(5)) // single-day period
    }

    @Test("Derived periods feed the estimator end to end")
    func derivedPeriodsDriveEstimate() throws {
        // Three 28-day-apart 3-day periods → two cycles of 28 days.
        var logs: [DailyLog] = []
        for start in [0, 28, 56] {
            for offset in 0..<3 { logs.append(log(start + offset, flow: .medium)) }
        }
        let periods = CycleHistory.derivePeriods(from: logs, calendar: calendar)
        let estimate = try #require(Estimator.estimate(from: periods, calendar: calendar))

        #expect(estimate.averageCycleLength == 28)
        #expect(estimate.averagePeriodLength == 3)
        #expect(estimate.nextPeriodStartEstimate == day(84)) // 56 + 28
    }

    @Test("No logs yields no periods")
    func emptyHistory() {
        #expect(CycleHistory.derivePeriods(from: [], calendar: calendar).isEmpty)
    }
}
