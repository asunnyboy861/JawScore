import SwiftUI
import SwiftData
import UIKit

struct FaceCardView: View {
    let record: ScoreRecord
    let streak: Int
    let isPro: Bool
    let numbersOff: Bool

    private var result: ScoreResult? {
        record.result
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("JAWSCORE")
                .font(.caption.weight(.heavy))
                .tracking(6)
                .foregroundStyle(Color.jsTeal)
            if let result {
                Text(ScoreDisplay.hero(result.overall, numbersOff: numbersOff))
                    .font(.jsHeroCompact)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                RadarChartView(values: result.dimensionList.map { $0.value })
                    .frame(height: 150)
            } else {
                Text(numbersOff ? "•••" : "—")
                    .font(.jsHeroCompact)
                    .foregroundStyle(.white)
            }
            HStack(spacing: 20) {
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.jsOrange)
                    .accessibilityLabel("\(streak) day streak")
                Text("Scan \(record.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !isPro {
                Text("JawScore.app")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 320, height: 480)
        .background(Color.jsBase, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.jsTeal.opacity(0.35), lineWidth: 1.5)
        )
    }
}

struct FaceCardShareSheet: View {
    let record: ScoreRecord
    let streak: Int
    let isPro: Bool
    let numbersOff: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var saveMessage: String?

    var body: some View {
        VStack(spacing: 18) {
            Text("Your FaceCard")
                .font(.title3.weight(.bold))
                .padding(.top, 20)
            if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 380)
                    .accessibilityLabel("FaceCard preview")
                HStack(spacing: 12) {
                    ShareLink(
                        item: Image(uiImage: renderedImage),
                        preview: SharePreview("My JawScore FaceCard", image: Image(uiImage: renderedImage))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.jsTeal)
                    .foregroundStyle(.black)
                    .accessibilityLabel("Share FaceCard")

                    Button {
                        UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
                        saveMessage = "Saved to Photos"
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.jsTeal)
                    .accessibilityLabel("Save FaceCard to Photos")
                }
                .padding(.horizontal, 20)
                if let saveMessage {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.jsTeal)
                }
                if !isPro {
                    Text("Pro removes the watermark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .frame(maxHeight: 380)
            }
            Spacer()
        }
        .background(Color.jsBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            renderCard()
        }
    }

    private func renderCard() {
        let renderer = ImageRenderer(
            content: FaceCardView(record: record, streak: streak, isPro: isPro, numbersOff: numbersOff)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3
        renderedImage = renderer.uiImage
    }
}
