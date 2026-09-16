import SwiftUI
import SwiftData

struct TrendsView: View {
    @Query(sort: \ScoreRecord.date, order: .reverse) private var records: [ScoreRecord]
    @StateObject private var purchaseManager = PurchaseManager.shared
    @AppStorage(AppSettings.numbersOffKey) private var numbersOff = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if records.isEmpty {
                        emptyState
                    } else {
                        if records.count > 1 {
                            DeltaView(latest: records[0], baseline: records[1], numbersOff: numbersOff)
                                .padding(16)
                                .jsCard()
                        }
                        historySection
                        if !purchaseManager.isPro {
                            ProUpsellCard(
                                title: "Unlimited history with Pro",
                                message: "Free keeps your last 7 scans. Pro keeps every scan and sharpens your trend lines."
                            )
                        }
                    }
                }
                .padding(.vertical, 16)
                .appContentWidth()
                .frame(maxWidth: .infinity)
            }
            .background(Color.jsBase.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Trends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("No scans yet")
                .font(.title3.weight(.bold))
            Text("Run your first scan and your trend line starts here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .jsCard()
    }

    private var visibleRecords: [ScoreRecord] {
        purchaseManager.isPro ? records : Array(records.prefix(AestheticConstants.freeHistoryRecordLimit))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.title3.weight(.bold))
            ForEach(Array(visibleRecords.enumerated()), id: \.element.id) { index, record in
                recordRow(record: record, previous: index + 1 < records.count ? records[index + 1] : nil)
            }
            if !purchaseManager.isPro && records.count > AestheticConstants.freeHistoryRecordLimit {
                Text("\(records.count - AestheticConstants.freeHistoryRecordLimit) earlier scans are part of Pro history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .jsCard()
    }

    private func recordRow(record: ScoreRecord, previous: ScoreRecord?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                Text("Capture quality \(record.quality)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let previous, let latestResult = record.result, let previousResult = previous.result {
                let delta = latestResult.overall - previousResult.overall
                HStack(spacing: 4) {
                    Image(systemName: TrendArrow.symbol(for: delta))
                        .foregroundStyle(TrendArrow.color(for: delta))
                        .accessibilityHidden(true)
                    Text(TrendArrow.text(for: delta, numbersOff: numbersOff))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(TrendArrow.color(for: delta))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Since previous scan, \(delta > 0.05 ? "up" : delta < -0.05 ? "down" : "unchanged")")
            } else if !numbersOff {
                Text(ScoreDisplay.decimal(record.overall))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.jsTeal)
            } else {
                Text("•••")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct DeltaView: View {
    let latest: ScoreRecord
    let baseline: ScoreRecord
    let numbersOff: Bool

    private var latestResult: ScoreResult? { latest.result }
    private var baselineResult: ScoreResult? { baseline.result }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Since last scan")
                .font(.title3.weight(.bold))
            if let latestResult, let baselineResult {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(latestResult.dimensionList, id: \.name) { dimension in
                        let baselineValue = baselineResult.dimensionList.first { $0.name == dimension.name }?.value ?? 0
                        let delta = dimension.value - baselineValue
                        deltaCard(name: dimension.name, delta: delta)
                    }
                }
                RadarCompareSlider(baseline: baselineResult.dimensionList.map { $0.value }, latest: latestResult.dimensionList.map { $0.value })
                Text("Left of the slider: previous scan. Right: latest scan.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Stored scores could not be read for comparison.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deltaCard(name: String, delta: Double) -> some View {
        HStack {
            Image(systemName: TrendArrow.symbol(for: delta))
                .foregroundStyle(TrendArrow.color(for: delta))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text(numbersOff ? "trend only" : "Since last scan \(TrendArrow.text(for: delta, numbersOff: false))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(delta > 0.05 ? "up" : delta < -0.05 ? "down" : "unchanged") since last scan")
    }
}

struct ProUpsellCard: View {
    let title: String
    let message: String
    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showPaywall = true
            } label: {
                Text("See Pro")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jsTeal)
            .foregroundStyle(.black)
            .accessibilityLabel("See Pro upgrade")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .jsCard()
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
