import SwiftUI

/// Content shown when the menu bar item is clicked: a live-updating stack of
/// timeline rows (one per zone) with a header and footer controls.
struct PopoverView: View {
    @EnvironmentObject private var settings: SettingsStore
    /// Opens the settings window; supplied by the AppKit AppDelegate that hosts this view.
    let openSettings: () -> Void

    var body: some View {
        // TimelineView drives a 1s refresh for the whole popover so every
        // strip and clock advances together off a single schedule.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 0) {
                header(now: context.date)
                Divider().padding(.vertical, 6)
                content(now: context.date)
                Divider().padding(.vertical, 6)
                footer
            }
            .padding(12)
            .frame(width: 460)
        }
    }

    private func header(now: Date) -> some View {
        HStack {
            Text("World Clock")
                .font(.system(size: 13, weight: .bold))
            Spacer()
            // The center line marks this instant across all strips.
            Text(TimeText.clock(now, in: .current, use24Hour: settings.use24Hour))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if settings.zones.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "globe").font(.system(size: 22)).foregroundStyle(.secondary)
                Text("No time zones yet").font(.system(size: 12, weight: .medium))
                Text("Add zones in Settings to see their timelines.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            VStack(spacing: 10) {
                ForEach(settings.zones) { zone in
                    TimelineRow(
                        zone: zone,
                        now: now,
                        use24Hour: settings.use24Hour,
                        isPrimary: zone.id == settings.primaryZoneID
                    )
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .font(.system(size: 11))
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
