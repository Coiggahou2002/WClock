import SwiftUI

/// Draws one timeline strip: asleep/awake shading, hour ticks with labels, and
/// the shared center line marking "now". Geometry is rebuilt from the live
/// canvas width so it always fills the available space.
///
/// Colour mapping: awake hours use the standard "available" green (the window
/// when someone is reachable), asleep hours are cool and dark. Tick labels flip
/// between dark and light so they stay legible over whichever band they sit on.
struct TimelineCanvas: View {
    let now: Date
    let timeZone: TimeZone
    let use24Hour: Bool
    let asleepStartHour: Int
    let asleepEndHour: Int
    var windowHours: Double = 10

    // Palette: dark track matching the popover's dark theme, with "available"
    // green blocks for awake hours floating inside it.
    private let trackColor = Color(white: 0.16)                          // dark-mode track
    private let awakeColor = Color(red: 0.30, green: 0.73, blue: 0.41)   // "available" green
    private let centerLineColor = Color(red: 0.95, green: 0.62, blue: 0.10) // amber "now"

    // Inset of the green block inside the track (Tailwind-ish padding), plus
    // its corner radius.
    private let blockInset: CGFloat = 2
    private let blockCorner: CGFloat = 4

    // Tick/label colours, chosen per-band for contrast.
    private let tickOnAwake = Color.black.opacity(0.32)
    private let tickOnAsleep = Color.white.opacity(0.30)
    private let labelOnAwake = Color.black.opacity(0.60)
    private let labelOnAsleep = Color.white.opacity(0.55)

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

            // 1) Dark track fills the whole strip (asleep time = bare track).
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(trackColor)
            )

            // 2) Awake ("available") time as inset, rounded green blocks, with a
            //    small margin inside the track on every side.
            for seg in geo.asleepSegments() where !seg.isAsleep {
                let x = seg.startX + blockInset
                let width = (seg.endX - seg.startX) - 2 * blockInset
                guard width > 0 else { continue }
                let rect = CGRect(
                    x: x,
                    y: blockInset,
                    width: width,
                    height: size.height - 2 * blockInset
                )
                let radius = min(blockCorner, rect.height / 2)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: radius, style: .continuous),
                    with: .color(awakeColor)
                )
            }

            // 3) Hour ticks + labels (coloured to contrast their band).
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

            // 4) Center line = now (drawn last so it sits on top).
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
