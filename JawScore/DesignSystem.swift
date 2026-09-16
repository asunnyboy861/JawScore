import SwiftUI

extension Color {
    static let jsBase = Color(red: 0.039, green: 0.047, blue: 0.063)
    static let jsSurface = Color(red: 0.075, green: 0.086, blue: 0.110)
    static let jsSurfaceRaised = Color(red: 0.110, green: 0.125, blue: 0.161)
    static let jsTeal = Color(red: 0.0, green: 0.898, blue: 0.780)
    static let jsOrange = Color(red: 1.0, green: 0.478, blue: 0.271)
    static let jsTealSoft = Color(red: 0.0, green: 0.898, blue: 0.780, opacity: 0.14)
    static let jsOrangeSoft = Color(red: 1.0, green: 0.478, blue: 0.271, opacity: 0.16)
    static let jsStroke = Color.white.opacity(0.08)
}

enum DesignTokens {
    static let contentMaxWidth: CGFloat = 720
    static let heroScoreSize: CGFloat = 96
}

extension Font {
    static var jsHero: Font { .system(size: DesignTokens.heroScoreSize, weight: .heavy, design: .rounded) }
    static var jsHeroCompact: Font { .system(size: 56, weight: .heavy, design: .rounded) }
    static var jsDisplay: Font { .system(size: 32, weight: .bold, design: .rounded) }
}

extension View {
    func appContentWidth() -> some View {
        frame(maxWidth: DesignTokens.contentMaxWidth)
    }

    func jsCard() -> some View {
        background(Color.jsSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.jsStroke, lineWidth: 1)
            )
    }
}

struct DisclaimerFooter: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("JawScore is for self-discovery and entertainment. It does not measure your worth, health, or real-world attractiveness.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Your worth ≠ a number")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.jsTeal)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

enum ScoreDisplay {
    static func decimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func hero(_ value: Double, numbersOff: Bool) -> String {
        numbersOff ? "•••" : decimal(value)
    }
}

enum TrendArrow {
    static func symbol(for delta: Double) -> String {
        if delta > 0.05 { return "arrow.up" }
        if delta < -0.05 { return "arrow.down" }
        return "arrow.right"
    }

    static func color(for delta: Double) -> Color {
        if delta > 0.05 { return .jsTeal }
        if delta < -0.05 { return .jsOrange }
        return .secondary
    }

    static func text(for delta: Double, numbersOff: Bool) -> String {
        if numbersOff { return "" }
        let sign = delta >= 0 ? "+" : "−"
        return "\(sign)\(ScoreDisplay.decimal(abs(delta)))"
    }
}

enum DimensionCopy {
    static let dimensionNames: [String] = [
        "Jawline", "Symmetry", "Facial Thirds", "Facial Fifths",
        "Canthal Tilt", "Golden Ratio", "Skin Clarity", "Capture Quality"
    ]

    static func strengthLine(for dimension: String) -> String {
        switch dimension {
        case "Jawline": return "Strong, defined structure in your lower face."
        case "Symmetry": return "Your left and right sides balance beautifully."
        case "Facial Thirds": return "Your facial zones sit in pleasing proportion."
        case "Facial Fifths": return "Your features are evenly spaced across your face."
        case "Canthal Tilt": return "Your eye line carries a lifted, positive tilt."
        case "Golden Ratio": return "Your proportions echo classical harmony."
        case "Skin Clarity": return "Your skin reads even and well cared for."
        case "Capture Quality": return "A clean, well-lit capture made this scan precise."
        default: return "A clear strength of your profile."
        }
    }

    static func potentialLine(for dimension: String) -> String {
        switch dimension {
        case "Jawline": return "Daily posture and jaw habits can add definition."
        case "Symmetry": return "Small grooming rituals can even out your balance."
        case "Facial Thirds": return "Hairstyle choices can play up your proportions."
        case "Facial Fifths": return "Glasses or brow shaping can refine feature spacing."
        case "Canthal Tilt": return "Sleep, hydration, and light grooming lift the eye area."
        case "Golden Ratio": return "Simple styling can highlight your natural harmony."
        case "Skin Clarity": return "A steady routine keeps your skin trending upward."
        case "Capture Quality": return "A brighter, steadier retake will sharpen every score."
        default: return "Steady habits will move this upward."
        }
    }
}
