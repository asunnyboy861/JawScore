import SwiftUI

struct RadarChartView: View {
    let values: [Double]
    var tint: Color = .jsTeal
    var fillOpacity: Double = 0.18
    var axisLabels: [String] = []
    var hidesNumbers: Bool = false

    var body: some View {
        Canvas { context, size in
            let count = max(3, values.count)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 14

            for ring in 1...4 {
                let ringRadius = radius * Double(ring) / 4
                var ringPath = Path()
                for step in 0..<count {
                    let angle = angleFor(step, count: count)
                    let point = pointAt(center: center, radius: ringRadius, angle: angle)
                    if step == 0 {
                        ringPath.move(to: point)
                    } else {
                        ringPath.addLine(to: point)
                    }
                }
                ringPath.closeSubpath()
                context.stroke(ringPath, with: .color(.white.opacity(0.10)), lineWidth: 1)
            }

            for step in 0..<count {
                let angle = angleFor(step, count: count)
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: pointAt(center: center, radius: radius, angle: angle))
                context.stroke(spoke, with: .color(.white.opacity(0.10)), lineWidth: 1)
            }

            var shape = Path()
            for step in 0..<count {
                let angle = angleFor(step, count: count)
                let value = max(0, min(10, step < values.count ? values[step] : 0))
                let point = pointAt(center: center, radius: radius * value / 10, angle: angle)
                if step == 0 {
                    shape.move(to: point)
                } else {
                    shape.addLine(to: point)
                }
            }
            shape.closeSubpath()
            context.fill(shape, with: .color(tint.opacity(fillOpacity)))
            context.stroke(shape, with: .color(tint), style: StrokeStyle(lineWidth: 2, lineJoin: .round))

            for step in 0..<count {
                let angle = angleFor(step, count: count)
                let value = max(0, min(10, step < values.count ? values[step] : 0))
                let point = pointAt(center: center, radius: radius * value / 10, angle: angle)
                let dot = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
                context.fill(Path(ellipseIn: dot), with: .color(tint))
            }
        }
        .accessibilityLabel("Radar chart of your eight scores")
        .accessibilityValue(accessibilitySummary)
    }

    private func angleFor(_ step: Int, count: Int) -> Double {
        -Double.pi / 2 + Double(step) * 2 * Double.pi / Double(count)
    }

    private func pointAt(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private var accessibilitySummary: String {
        if hidesNumbers { return "Scores hidden" }
        let names = axisLabels.isEmpty ? DimensionCopy.dimensionNames : axisLabels
        return zip(names, values).map { "\($0.0) \(String(format: "%.1f", $0.1))" }.joined(separator: ", ")
    }
}

struct RadarCompareSlider: View {
    let baseline: [Double]
    let latest: [Double]
    @State private var fraction: Double = 0.5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                RadarChartView(values: baseline, tint: .secondary, fillOpacity: 0.10)
                RadarChartView(values: latest, tint: .jsTeal, fillOpacity: 0.18)
                    .mask(
                        Rectangle()
                            .frame(width: width * fraction)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                Rectangle()
                    .fill(Color.jsOrange)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .position(x: width * fraction, y: proxy.size.height / 2)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        fraction = max(0, min(1, Double(value.location.x / max(width, 1))))
                    }
            )
        }
        .frame(height: 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Before and after comparison")
        .accessibilityHint("Drag to reveal the latest scan over the previous scan")
    }
}
