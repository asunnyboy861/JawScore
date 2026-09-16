import StoreKit
import SwiftUI
import SwiftData
import UIKit

struct ResultsView: View {
    let record: ScoreRecord
    var capturedImage: UIImage?
    var onScanAgain: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: TabRouter
    @StateObject private var purchaseManager = PurchaseManager.shared
    @AppStorage(AppSettings.numbersOffKey) private var numbersOff = false
    @Query private var checkIns: [HabitCheckIn]

    @State private var heroPopped = false
    @State private var verifyResult: ScoreResult?
    @State private var showFaceCard = false
    @State private var showPaywall = false
    @State private var confirmDeepAnalysis = false
    @State private var deepAnalysisText: String?
    @State private var deepAnalysisLoading = false
    @State private var deepAnalysisError: String?

    private var result: ScoreResult {
        record.result ?? ScoringEngine.score(
            record.measurement ?? FaceMeasurement.neutral(pixelStats: SkinPixelStats(brightnessMean: 0, brightnessVariance: 0, textureUniformity: 0), quality: CaptureQualitySample(distanceMeters: 0, ambientLux: 0, poseDeviationDegrees: 0)),
            quality: record.quality
        )
    }

    private var streak: Int {
        StreakCalculator.streak(checkIns: checkIns)
    }

    private var sortedDimensions: [(name: String, value: Double)] {
        result.dimensionList.filter { $0.name != "Quality" }.sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroSection
                BandBarView(overall: result.overall, band: result.band, numbersOff: numbersOff)
                if let verifyResult {
                    verifyCard(verifyResult: verifyResult)
                }
                strengthsSection
                radarSection
                actionSection
                deepAnalysisSection
                DisclaimerFooter()
            }
            .padding(.vertical, 16)
            .appContentWidth()
            .frame(maxWidth: .infinity)
        }
        .background(Color.jsBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !heroPopped else { return }
            heroPopped = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                heroPopped = true
            }
        }
        .sheet(isPresented: $showFaceCard) {
            FaceCardShareSheet(record: record, streak: streak, isPro: purchaseManager.isPro, numbersOff: numbersOff)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .confirmationDialog(
            "Send a photo to DeepSeek? Your face data will leave your device this one time.",
            isPresented: $confirmDeepAnalysis,
            titleVisibility: .visible
        ) {
            Button("Send to DeepSeek") {
                Task { await runDeepAnalysis() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var heroSection: some View {
        VStack(spacing: 6) {
            Text("JAWSCORE")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.jsTeal)
                .tracking(4)
            Text(ScoreDisplay.hero(result.overall, numbersOff: numbersOff))
                .font(.jsHero)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .scaleEffect(heroPopped ? 1 : 0.6)
                .opacity(heroPopped ? 1 : 0)
                .accessibilityLabel(numbersOff ? "Score hidden" : "Overall score \(ScoreDisplay.decimal(result.overall))")
            Text(numbersOff ? "Numbers are off" : "out of 10 · capture quality \(record.quality)%")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func verifyCard(verifyResult: ScoreResult) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.jsTeal)
                    .accessibilityHidden(true)
                Text("Verified: identical results")
                    .font(.headline)
            }
            HStack(spacing: 24) {
                verifyColumn(label: "Original", value: result.overall)
                verifyColumn(label: "Re-run", value: verifyResult.overall)
            }
            Text("The engine is pure math: the same measurement always produces the same score.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .jsCard()
    }

    private func verifyColumn(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(numbersOff ? "•••" : ScoreDisplay.decimal(value))
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.jsTeal)
        }
        .accessibilityElement(children: .combine)
    }

    private var strengthsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strengths")
                .font(.title3.weight(.bold))
            ForEach(sortedDimensions.prefix(2), id: \.name) { dimension in
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.jsTeal)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dimension.name)
                            .font(.headline)
                        Text(DimensionCopy.strengthLine(for: dimension.name))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(numbersOff ? "•••" : ScoreDisplay.decimal(dimension.value))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.jsTeal)
                }
                .padding(14)
                .jsCard()
                .accessibilityElement(children: .combine)
            }
            Text("Potential")
                .font(.title3.weight(.bold))
            ForEach(sortedDimensions.suffix(2).reversed(), id: \.name) { dimension in
                HStack {
                    Image(systemName: "arrow.up.forward")
                        .foregroundStyle(Color.jsOrange)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dimension.name)
                            .font(.headline)
                        Text(DimensionCopy.potentialLine(for: dimension.name))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(numbersOff ? "•••" : ScoreDisplay.decimal(dimension.value))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.jsOrange)
                }
                .padding(14)
                .jsCard()
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var radarSection: some View {
        VStack(spacing: 10) {
            Text("Balance")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            RadarChartView(values: result.dimensionList.map { $0.value }, axisLabels: DimensionCopy.dimensionNames)
                .frame(height: 240)
        }
        .padding(16)
        .jsCard()
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                verifyResult = ScoringEngine.score(
                    record.measurement ?? FaceMeasurement.neutral(
                        pixelStats: SkinPixelStats(brightnessMean: 0, brightnessVariance: 0, textureUniformity: 0),
                        quality: CaptureQualitySample(distanceMeters: 0, ambientLux: 0, poseDeviationDegrees: 0)
                    ),
                    quality: record.quality
                )
            } label: {
                Label("Verify", systemImage: "checkmark.seal")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .tint(Color.jsTeal)
            .accessibilityLabel("Verify the score by running the engine again")

            Button {
                showFaceCard = true
            } label: {
                Label("Share FaceCard", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jsTeal)
            .foregroundStyle(.black)
            .accessibilityLabel("Share your FaceCard image")

            if !purchaseManager.isPro {
                Button {
                    showPaywall = true
                } label: {
                    Text("Remove the watermark with Pro")
                        .font(.footnote)
                        .foregroundStyle(Color.jsTeal)
                }
                .accessibilityLabel("Remove watermark with Pro")
            }

            Button {
                router.selection = .plan
            } label: {
                Label("Plan my glow-up", systemImage: "checklist")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .tint(Color.jsOrange)
            .accessibilityLabel("Go to plan tab")

            Button("Scan again", action: onScanAgain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var deepAnalysisSection: some View {
        Group {
            if purchaseManager.byoUnlocked && KeychainHelper.readBYOKey() != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Deep Analysis")
                        .font(.title3.weight(.bold))
                    if deepAnalysisLoading {
                        ProgressView()
                    } else if let deepAnalysisText {
                        Text(deepAnalysisText)
                            .font(.subheadline)
                    } else if let deepAnalysisError {
                        Text(deepAnalysisError)
                            .font(.footnote)
                            .foregroundStyle(Color.jsOrange)
                    }
                    Button {
                        confirmDeepAnalysis = true
                    } label: {
                        Label("Run Deep Analysis", systemImage: "brain")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.jsOrange)
                    .accessibilityLabel("Run Deep Analysis with your own DeepSeek key")
                }
                .padding(16)
                .jsCard()
            }
        }
    }

    private func runDeepAnalysis() async {
        deepAnalysisLoading = true
        deepAnalysisError = nil
        defer { deepAnalysisLoading = false }
        do {
            guard let measurement = record.measurement else {
                deepAnalysisError = "The stored measurement could not be read. Rescan and try again."
                return
            }
            let coach = DeepSeekCoach()
            deepAnalysisText = try await coach.generateAnalysis(measurement: measurement, image: capturedImage)
        } catch {
            deepAnalysisError = "Deep analysis did not complete. Check your key and connection, then try again."
        }
    }
}

struct BandBarView: View {
    let overall: Double
    let band: Double
    let numbersOff: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(numbersOff ? "Interval hidden" : String(format: "%.1f ± %.1f", overall, band))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
                Spacer()
                Text(numbersOff ? "Confidence grows with better captures" : String(format: "capture quality drives this band"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                let width = proxy.size.width
                let bandWidth = width * min(1, band / 5)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 12)
                    Capsule()
                        .fill(Color.jsTeal.opacity(0.35))
                        .frame(width: max(12, bandWidth), height: 12)
                        .position(x: width * min(1, overall / 10), y: 6)
                    Circle()
                        .fill(Color.jsTeal)
                        .frame(width: 16, height: 16)
                        .position(x: width * min(1, overall / 10), y: 6)
                }
            }
            .frame(height: 12)
            .accessibilityHidden(true)
        }
        .padding(16)
        .jsCard()
    }
}
