import Foundation

/// Maps IANA time-zone identifiers to an emoji flag.
///
/// The mapping is built by parsing the system tzdata table
/// (`/usr/share/zoneinfo/zone.tab`) once and caching it. Parsing the OS table
/// keeps flags correct as tzdata updates and avoids hardcoding ~400
/// zone→country rows. Identifiers absent from the table (e.g. `UTC`, legacy
/// aliases like `US/Pacific`) fall back to a globe.
@MainActor
enum FlagProvider {
    private static let fallback = "🌐"
    private static let tabPath = "/usr/share/zoneinfo/zone.tab"
    private static var countryByZone: [String: String]?

    /// Emoji flag for a zone identifier, or 🌐 if unknown.
    static func flag(for identifier: String) -> String {
        guard let code = loadIfNeeded()[identifier] else { return fallback }
        return emojiFlag(country: code) ?? fallback
    }

    private static func loadIfNeeded() -> [String: String] {
        if let map = countryByZone { return map }
        let map = parse(path: tabPath)
        countryByZone = map
        return map
    }

    /// zone.tab rows are `COUNTRY_CODE \t coords \t ZONE \t [comment]`, with
    /// exactly one ISO 3166 alpha-2 code in column 0. Comment lines start `#`.
    private static func parse(path: String) -> [String: String] {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { return [:] }
        var result: [String: String] = [:]
        for rawLine in contents.split(separator: "\n") {
            if rawLine.hasPrefix("#") { continue }
            let cols = rawLine.split(separator: "\t")
            guard cols.count >= 3 else { continue }
            let code = String(cols[0])
            guard code.count == 2 else { continue }
            result[String(cols[2])] = code
        }
        return result
    }

    /// ISO 3166 alpha-2 → regional-indicator emoji (e.g. "US" → 🇺🇸).
    private static func emojiFlag(country: String) -> String? {
        let upper = country.uppercased()
        guard upper.count == 2, upper.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        var scalars = String.UnicodeScalarView()
        for ch in upper.unicodeScalars {
            guard let scalar = Unicode.Scalar(0x1F1E6 + (ch.value - 0x41)) else { return nil }
            scalars.append(scalar)
        }
        return String(scalars)
    }
}
