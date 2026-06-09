import Foundation

/// Time formatting for a specific zone, with cached `DateFormatter`s keyed by
/// (identifier, 24h-flag, pattern). Formatters are expensive to build; the
/// strips refresh every second, so caching avoids needless churn.
@MainActor
enum TimeText {
    private static var cache: [String: DateFormatter] = [:]

    private static func formatter(timeZone: TimeZone, pattern: String) -> DateFormatter {
        let key = "\(timeZone.identifier)|\(pattern)"
        if let cached = cache[key] { return cached }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = pattern
        cache[key] = f
        return f
    }

    /// e.g. "10:50 AM" (12h) or "22:50" (24h).
    static func clock(_ date: Date, in timeZone: TimeZone, use24Hour: Bool) -> String {
        formatter(timeZone: timeZone, pattern: use24Hour ? "HH:mm" : "h:mm a").string(from: date)
    }

    /// e.g. "Mon, Jun 9" — the local calendar date in that zone.
    static func dayLabel(_ date: Date, in timeZone: TimeZone) -> String {
        formatter(timeZone: timeZone, pattern: "EEE, MMM d").string(from: date)
    }

    /// UTC offset relative to the user's local zone, e.g. "+8h", "-2.5h", "same".
    static func relativeOffset(_ timeZone: TimeZone, at date: Date) -> String {
        let local = TimeZone.current.secondsFromGMT(for: date)
        let other = timeZone.secondsFromGMT(for: date)
        let deltaHours = Double(other - local) / 3600.0
        if deltaHours == 0 { return "same" }
        let sign = deltaHours > 0 ? "+" : "-"
        let mag = abs(deltaHours)
        // Show ".5"/".75" only when fractional.
        let text = mag.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", mag)
            : String(format: "%.2g", mag)
        return "\(sign)\(text)h"
    }
}
