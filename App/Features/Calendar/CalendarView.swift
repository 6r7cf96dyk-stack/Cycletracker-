import SwiftUI
import SwiftData
import CycleDataKit

/// A month grid that highlights logged period days and the estimated next-
/// period window (in a clearly lighter style). Tapping any day opens that
/// day's log for viewing/editing.
struct CalendarView: View {
    @Query(sort: [SortDescriptor(\DailyLog.date)]) private var logs: [DailyLog]

    /// First day of the month currently on screen.
    @State private var visibleMonth: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: DaySelection?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // MARK: - Derived data

    /// Days with a flow logged — the "period days".
    private var periodDays: Set<Date> {
        CycleHistory.periodDays(from: logs, calendar: calendar)
    }

    /// The estimated next-period start window, as a set of days (or empty if
    /// there isn't enough history yet).
    private var estimatedDays: Set<Date> {
        let periods = CycleHistory.derivePeriods(from: logs, calendar: calendar)
        guard let estimate = Estimator.estimate(from: periods, calendar: calendar) else {
            return []
        }
        var days: Set<Date> = []
        var day = calendar.startOfDay(for: estimate.nextPeriodStartWindow.lowerBound)
        let last = calendar.startOfDay(for: estimate.nextPeriodStartWindow.upperBound)
        while day <= last {
            days.insert(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                monthHeader
                weekdayHeader
                monthGrid
                Spacer(minLength: 0)
                legend
            }
            .padding()
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today", action: jumpToToday)
                        .disabled(isShowingCurrentMonth)
                }
            }
            .sheet(item: $selectedDay) { selection in
                DayLogSheet(date: selection.date)
            }
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(visibleMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.borderless)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 44) // leading blank
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isPeriod = periodDays.contains(calendar.startOfDay(for: date))
        let isEstimated = !isPeriod && estimatedDays.contains(calendar.startOfDay(for: date))
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDay = DaySelection(date: date)
        } label: {
            Text(date, format: .dateTime.day())
                .font(.callout)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if isPeriod {
                        // Logged period day — solid, full-strength.
                        Circle().fill(Color.accentColor)
                    } else if isEstimated {
                        // Estimated window — lighter, dashed outline.
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .overlay(
                                Circle().strokeBorder(
                                    Color.accentColor.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 1, dash: [3])
                                )
                            )
                    }
                }
                .foregroundStyle(isPeriod ? Color.white : Color.primary)
                .overlay {
                    if isToday {
                        Circle().strokeBorder(Color.primary.opacity(0.4), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Circle().fill(Color.accentColor).frame(width: 14, height: 14)
                Text("Period").font(.caption)
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .overlay(
                        Circle().strokeBorder(
                            Color.accentColor.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1, dash: [3])
                        )
                    )
                    .frame(width: 14, height: 14)
                Text("Estimated").font(.caption)
            }
            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Calendar math

    /// Day cells for the visible month, with leading `nil`s so the 1st lands
    /// under the correct weekday.
    private var monthCells: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count
        else { return [] }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        return cells
    }

    /// Weekday short symbols, rotated to honor the locale's first weekday.
    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var isShowingCurrentMonth: Bool {
        calendar.isDate(visibleMonth, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(by months: Int) {
        if let shifted = calendar.date(byAdding: .month, value: months, to: visibleMonth) {
            withAnimation { visibleMonth = shifted }
        }
    }

    private func jumpToToday() {
        withAnimation { visibleMonth = calendar.startOfDay(for: .now) }
    }
}

/// Identifiable wrapper so a tapped day can drive a `.sheet(item:)`.
private struct DaySelection: Identifiable {
    let date: Date
    var id: Date { date }
}

/// Presents `DayLogForm` for a specific date in a dismissable sheet.
private struct DayLogSheet: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DayLogForm(day: date)
                .navigationTitle(date.formatted(.dateTime.month().day().year()))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Period.self, DailyLog.self, Symptom.self, LoggedSymptom.self], inMemory: true)
}
