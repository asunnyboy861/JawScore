import SwiftUI

struct DecodingView: View {
    let measurement: FaceMeasurement
    let quality: Int
    let onComplete: () -> Void

    @State private var revealed = 0

    private var metrics: [(String, Double)] {
        measurement.allMetrics
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Decoding \(FaceMeasurement.metricCount) measurements")
                .font(.title3.weight(.bold))
                .padding(.top, 24)
            ProgressView(value: Double(revealed), total: Double(FaceMeasurement.metricCount))
                .tint(Color.jsTeal)
                .padding(.horizontal, 24)
                .accessibilityLabel("Decoding progress")
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        metricChip(name: metric.0, value: metric.1, revealed: index < revealed)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.jsBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            for step in 1...FaceMeasurement.metricCount {
                try? await Task.sleep(nanoseconds: AestheticConstants.decodingAnimationStepNanoseconds)
                withAnimation(.easeOut(duration: 0.12)) {
                    revealed = step
                }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            onComplete()
        }
        .accessibilityLabel("Decoding your scan")
    }

    private func metricChip(name: String, value: Double, revealed: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(formatValue(value))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(revealed ? Color.jsTeal : Color.secondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.jsSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(revealed ? 1 : 0.45)
    }

    private func formatValue(_ value: Double) -> String {
        if abs(value) >= 100 { return String(format: "%.0f", value) }
        if abs(value) >= 10 { return String(format: "%.1f", value) }
        return String(format: "%.3f", value)
    }
}
