import SwiftUI

/// Draws one timeline strip: day/night shading, hour ticks with labels, and
/// the shared center line marking "now". Geometry is rebuilt from the live
/// canvas width so it always fills the available space.
struct TimelineCanvas: View {
    let now: Date
    let timeZone: TimeZone
    let use24Hour: Bool
    var windowHours: Double = 10

    // Palette (fixed, tuned for the dark popover background).
    private let dayColor = Color(red: 0.42, green: 0.52, blue: 0.66)
    private let nightColor = Color(red: 0.10, green: 0.12, blue: 0.18)
    private let tickColor = Color.white.opacity(0.28)
    private let tickLabelColor = Color.white.opacity(0.55)
    private let midnightTickColor = Color.white.opacity(0.5)
    private let centerLineColor = Color.orange

    var body: some View {
        Canvas { context, size in
            let geo = TimelineGeometry(
                now: now,
                timeZone: timeZone,
                width: size.width,
                windowHours: windowHours,
                use24Hour: use24Hour
            )

            // 1) Day / night background.
            for seg in geo.dayNightSegments() {
                let rect = CGRect(
                    x: seg.startX,
                    y: 0,
                    width: max(0, seg.endX - seg.startX),
                    height: size.height
                )
                context.fill(Path(rect), with: .color(seg.isNight ? nightColor : dayColor))
            }

            // 2) Hour ticks + labels.
            for tick in geo.ticks() {
                guard tick.x >= 0, tick.x <= size.width else { continue }
                var line = Path()
                line.move(to: CGPoint(x: tick.x, y: size.height - 12))
                line.addLine(to: CGPoint(x: tick.x, y: size.height))
                context.stroke(
                    line,
                    with: .color(tick.isMidnight ? midnightTickColor : tickColor),
                    lineWidth: tick.isMidnight ? 1.2 : 0.75
                )
                let label = Text(tick.label)
                    .font(.system(size: 8, weight: tick.isMidnight ? .semibold : .regular))
                    .foregroundStyle(tick.isMidnight ? .white.opacity(0.8) : tickLabelColor)
                context.draw(label, at: CGPoint(x: tick.x, y: 7), anchor: .center)
            }

            // 3) Center line = now (drawn last so it sits on top).
            var center = Path()
            center.move(to: CGPoint(x: geo.centerX, y: 0))
            center.addLine(to: CGPoint(x: geo.centerX, y: size.height))
            context.stroke(center, with: .color(centerLineColor), lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
