import SwiftUI

/// Draws one timeline strip: asleep/awake shading, hour ticks with labels, and
/// the shared center line marking "now". Geometry is rebuilt from the live
/// canvas width so it always fills the available space.
///
/// Colour mapping is intentionally "natural": awake hours are warm and light
/// (daylight), asleep hours are cool and dark (night). Tick labels flip between
/// dark and light so they stay legible over whichever band they sit on.
struct TimelineCanvas: View {
    let now: Date
    let timeZone: TimeZone
    let use24Hour: Bool
    let asleepStartHour: Int
    let asleepEndHour: Int
    var windowHours: Double = 10

    // Palette tuned for the translucent dark popover background.
    private let awakeColor = Color(red: 0.96, green: 0.88, blue: 0.64)   // warm daylight
    private let asleepColor = Color(red: 0.11, green: 0.13, blue: 0.24)  // deep cool night
    private let centerLineColor = Color(red: 0.90, green: 0.22, blue: 0.20) // strong red "now"

    // Tick/label colours, chosen per-band for contrast.
    private let tickOnAwake = Color.black.opacity(0.28)
    private let tickOnAsleep = Color.white.opacity(0.30)
    private let labelOnAwake = Color.black.opacity(0.55)
    private let labelOnAsleep = Color.white.opacity(0.60)

    var body: some View {
        Canvas { context, size in
            let geo = TimelineGeometry(
                now: now,
                timeZone: timeZone,
                width: size.width,
                windowHours: windowHours,
                use24Hour: use24Hour,
                asleepStartHour: asleepStartHour,
                asleepEndHour: asleepEndHour
            )

            // 1) Asleep / awake background.
            for seg in geo.asleepSegments() {
                let rect = CGRect(
                    x: seg.startX,
                    y: 0,
                    width: max(0, seg.endX - seg.startX),
                    height: size.height
                )
                context.fill(Path(rect), with: .color(seg.isAsleep ? asleepColor : awakeColor))
            }

            // 2) Hour ticks + labels (coloured to contrast their band).
            for tick in geo.ticks() {
                guard tick.x >= 0, tick.x <= size.width else { continue }
                let tickColor = tick.isAsleep ? tickOnAsleep : tickOnAwake
                let labelColor = tick.isAsleep ? labelOnAsleep : labelOnAwake

                var line = Path()
                line.move(to: CGPoint(x: tick.x, y: size.height - 12))
                line.addLine(to: CGPoint(x: tick.x, y: size.height))
                context.stroke(line, with: .color(tickColor), lineWidth: tick.isMidnight ? 1.2 : 0.75)

                let label = Text(tick.label)
                    .font(.system(size: 8, weight: tick.isMidnight ? .semibold : .regular))
                    .foregroundStyle(labelColor)
                context.draw(label, at: CGPoint(x: tick.x, y: 7), anchor: .center)
            }

            // 3) Center line = now (drawn last so it sits on top).
            var center = Path()
            center.move(to: CGPoint(x: geo.centerX, y: 0))
            center.addLine(to: CGPoint(x: geo.centerX, y: size.height))
            context.stroke(center, with: .color(centerLineColor), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
