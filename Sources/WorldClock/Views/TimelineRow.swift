import SwiftUI

/// One row in the popover: a fixed-width label block (zone name, current local
/// time, offset + date) on the left, and the timeline strip filling the rest.
struct TimelineRow: View {
    let zone: ClockZone
    let now: Date
    let use24Hour: Bool
    let isPrimary: Bool
    let asleepStartHour: Int
    let asleepEndHour: Int

    private var tz: TimeZone { zone.resolvedTimeZone }

    var body: some View {
        HStack(spacing: 10) {
            // Country flag at the far left, for quick visual scanning.
            Text(FlagProvider.flag(for: zone.timeZoneIdentifier))
                .font(.system(size: 22))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    if isPrimary {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                    Text(zone.label)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                Text(TimeText.clock(now, in: tz, use24Hour: use24Hour))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Text("\(TimeText.dayLabel(now, in: tz)) · \(TimeText.relativeOffset(tz, at: now))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 116, alignment: .leading)

            TimelineCanvas(
                now: now,
                timeZone: tz,
                use24Hour: use24Hour,
                asleepStartHour: asleepStartHour,
                asleepEndHour: asleepEndHour
            )
            .frame(height: 44)
        }
    }
}
