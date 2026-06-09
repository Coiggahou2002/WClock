import Foundation
import Combine
import os

/// Owns all user-configurable state and persists it to `UserDefaults` as JSON.
///
/// Robustness: a corrupt or missing payload never crashes — it falls back to a
/// sensible default set and logs a warning. All decoded zones are re-validated
/// against `TimeZone(identifier:)`, so a stale/garbage identifier in storage is
/// dropped rather than silently resolving to the wrong zone.
@MainActor
final class SettingsStore: ObservableObject {
    @Published var zones: [ClockZone] { didSet { persist() } }
    @Published var primaryZoneID: UUID? { didSet { persist() } }
    @Published var use24Hour: Bool { didSet { persist() } }

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.rory.worldclock", category: "settings")

    private enum Key {
        static let zones = "zones.v1"
        static let primary = "primaryZoneID.v1"
        static let use24Hour = "use24Hour.v1"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load zones (validated) or seed defaults.
        let loadedZones = Self.loadZones(from: defaults, logger: logger)
        self.zones = loadedZones.isEmpty ? Self.defaultZones() : loadedZones

        // 24h preference defaults to the locale's convention.
        if defaults.object(forKey: Key.use24Hour) == nil {
            self.use24Hour = Self.localeUses24Hour()
        } else {
            self.use24Hour = defaults.bool(forKey: Key.use24Hour)
        }

        // Primary zone: validate the stored id still exists, else first zone.
        if let raw = defaults.string(forKey: Key.primary),
           let stored = UUID(uuidString: raw),
           self.zones.contains(where: { $0.id == stored }) {
            self.primaryZoneID = stored
        } else {
            self.primaryZoneID = self.zones.first?.id
        }
    }

    // MARK: - Derived

    /// The zone shown in the menu bar. Always non-nil if any zones exist.
    var primaryZone: ClockZone? {
        if let id = primaryZoneID, let z = zones.first(where: { $0.id == id }) {
            return z
        }
        return zones.first
    }

    // MARK: - Mutations

    func addZone(identifier: String) {
        guard let zone = ClockZone.make(identifier: identifier) else {
            logger.warning("Refused to add invalid time zone identifier: \(identifier, privacy: .public)")
            return
        }
        zones.append(zone)
        if primaryZoneID == nil { primaryZoneID = zone.id }
    }

    func removeZones(at offsets: IndexSet) {
        let removed = offsets.map { zones[$0].id }
        zones.remove(atOffsets: offsets)
        if let primary = primaryZoneID, removed.contains(primary) {
            primaryZoneID = zones.first?.id
        }
    }

    func moveZones(from source: IndexSet, to destination: Int) {
        zones.move(fromOffsets: source, toOffset: destination)
    }

    func rename(zoneID: UUID, to newLabel: String) {
        guard let idx = zones.firstIndex(where: { $0.id == zoneID }) else { return }
        let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        zones[idx].label = trimmed.isEmpty
            ? ClockZone.humanize(identifier: zones[idx].timeZoneIdentifier)
            : trimmed
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(zones)
            defaults.set(data, forKey: Key.zones)
        } catch {
            logger.error("Failed to encode zones: \(error.localizedDescription, privacy: .public)")
        }
        defaults.set(primaryZoneID?.uuidString, forKey: Key.primary)
        defaults.set(use24Hour, forKey: Key.use24Hour)
    }

    private static func loadZones(from defaults: UserDefaults, logger: Logger) -> [ClockZone] {
        guard let data = defaults.data(forKey: Key.zones) else { return [] }
        do {
            let decoded = try JSONDecoder().decode([ClockZone].self, from: data)
            // Re-validate every identifier; drop any that no longer resolve.
            let valid = decoded.filter { TimeZone(identifier: $0.timeZoneIdentifier) != nil }
            if valid.count != decoded.count {
                logger.warning("Dropped \(decoded.count - valid.count) zone(s) with invalid identifiers.")
            }
            return valid
        } catch {
            logger.warning("Corrupt zones payload, falling back to defaults: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - Defaults

    /// Seed set on first launch: the user's local zone plus a few common ones,
    /// de-duplicated so local isn't listed twice.
    static func defaultZones() -> [ClockZone] {
        var result: [ClockZone] = []
        let localID = TimeZone.current.identifier
        if let local = ClockZone.make(identifier: localID, label: "Local") {
            result.append(local)
        }
        let seeds = ["America/Los_Angeles", "America/New_York", "Europe/London", "Asia/Shanghai"]
        for id in seeds where id != localID {
            if let z = ClockZone.make(identifier: id) { result.append(z) }
        }
        return result
    }

    private static func localeUses24Hour() -> Bool {
        let fmt = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return !fmt.contains("a")
    }
}
