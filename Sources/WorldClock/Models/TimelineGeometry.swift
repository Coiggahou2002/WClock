import Foundation

/// Pure geometry for one timeline strip. Given the current instant, a time
/// zone, and a pixel width, it computes where the hour ticks fall and which
/// horizontal regions are night vs day.
///
/// Design notes:
/// - The strip is centered on `now`: the center x always represents the present
///   moment, identical across every zone (that is why the shared vertical line
///   aligns trivially — it is the same absolute instant for all rows).
/// - All tick positions come from real `Calendar`-derived instants, so
///   fractional UTC offsets (e.g. +5:30, +5:45, +8:45) and DST transitions are
///   handled correctly: ticks shift between rows exactly as they should.
struct TimelineGeometry {
    let now: Date
    let timeZone: TimeZone
    let width: Double
    let windowHours: Double
    let use24Hour: Bool

    /// Local wall-clock hours [nightEnd, nightStart) count as day; the rest is night.
    let nightStartHour: Int
    let nightEndHour: Int

    init(
        now: Date,
        timeZone: TimeZone,
        width: Double,
        windowHours: Double = 10,
        use24Hour: Bool,
        nightStartHour: Int = 20,
        nightEndHour: Int = 6
    ) {
        self.now = now
        self.timeZone = timeZone
        self.width = width
        self.windowHours = windowHours
        self.use24Hour = use24Hour
        self.nightStartHour = nightStartHour
        self.nightEndHour = nightEndHour
    }

    private var halfWindowSeconds: Double { windowHours * 3600 / 2 }
    private var pointsPerSecond: Double { width / (windowHours * 3600) }
    var centerX: Double { width / 2 }

    private var windowStart: Date { now.addingTimeInterval(-halfWindowSeconds) }
    private var windowEnd: Date { now.addingTimeInterval(halfWindowSeconds) }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// Horizontal position (in points) for an absolute instant.
    func x(for date: Date) -> Double {
        centerX + date.timeIntervalSince(now) * pointsPerSecond
    }

    // MARK: - Hour ticks

    struct Tick: Identifiable {
        let id = UUID()
        let x: Double
        let label: String
        let isMidnight: Bool
    }

    func ticks() -> [Tick] {
        let cal = calendar
        // Top of the hour at or before the window start.
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: windowStart)
        guard var tick = cal.date(from: comps) else { return [] }

        var result: [Tick] = []
        var guardCount = 0
        while tick <= windowEnd && guardCount < 48 {
            guardCount += 1
            if tick >= windowStart {
                let hour = cal.component(.hour, from: tick)
                result.append(
                    Tick(x: x(for: tick), label: hourLabel(for: tick, hour: hour), isMidnight: hour == 0)
                )
            }
            guard let next = cal.date(byAdding: .hour, value: 1, to: tick) else { break }
            tick = next
        }
        return result
    }

    private func hourLabel(for date: Date, hour: Int) -> String {
        if use24Hour {
            return String(format: "%02d", hour)
        }
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "a" : "p"
        return "\(h12)\(suffix)"
    }

    // MARK: - Day / night shading

    struct DayNightSegment: Identifiable {
        let id = UUID()
        let startX: Double
        let endX: Double
        let isNight: Bool
    }

    private func isNight(at date: Date) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= nightStartHour || hour < nightEndHour
    }

    /// Splits the visible window at every dawn/dusk transition and reports each
    /// region's night/day state. Transitions are computed as exact wall-clock
    /// instants (06:00 and 20:00 local) on each day the window touches.
    func dayNightSegments() -> [DayNightSegment] {
        let cal = calendar
        var boundaries: Set<Date> = [windowStart, windowEnd]

        // A 10h window touches at most parts of two days; scan a generous range.
        let startDay = cal.startOfDay(for: windowStart.addingTimeInterval(-86400))
        var day = startDay
        for _ in 0..<4 {
            for hour in [nightEndHour, nightStartHour] {
                if let t = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                   t > windowStart, t < windowEnd {
                    boundaries.insert(t)
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let sorted = boundaries.sorted()
        var segments: [DayNightSegment] = []
        for i in 0..<(sorted.count - 1) {
            let a = sorted[i], b = sorted[i + 1]
            let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
            segments.append(
                DayNightSegment(startX: x(for: a), endX: x(for: b), isNight: isNight(at: mid))
            )
        }
        return segments
    }
}
