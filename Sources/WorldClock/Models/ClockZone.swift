import Foundation

/// A single time zone the user wants to track.
///
/// `timeZoneIdentifier` is always an IANA identifier validated against
/// `TimeZone(identifier:)` before a `ClockZone` is ever constructed from
/// persisted data, so `resolvedTimeZone` can never silently fall back to a
/// wrong zone. `label` is the user-facing display name (e.g. "Beijing"),
/// independent of the identifier (e.g. "Asia/Shanghai").
struct ClockZone: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var timeZoneIdentifier: String
    var label: String

    init(id: UUID = UUID(), timeZoneIdentifier: String, label: String) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.label = label
    }

    /// The resolved `TimeZone`. Falls back to the current zone only as a last
    /// resort; callers should validate identifiers up front so this never
    /// triggers in practice.
    var resolvedTimeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    /// Build a `ClockZone` from an identifier, returning `nil` if the
    /// identifier is not a real IANA zone. The default label is the last
    /// path component humanized ("Asia/Shanghai" -> "Shanghai").
    static func make(identifier: String, label: String? = nil) -> ClockZone? {
        guard TimeZone(identifier: identifier) != nil else { return nil }
        let derived = label ?? Self.humanize(identifier: identifier)
        return ClockZone(timeZoneIdentifier: identifier, label: derived)
    }

    /// "Asia/Shanghai" -> "Shanghai", "America/New_York" -> "New York".
    static func humanize(identifier: String) -> String {
        let last = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return last.replacingOccurrences(of: "_", with: " ")
    }
}
