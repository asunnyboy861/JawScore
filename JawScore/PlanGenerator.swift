import Foundation

struct GlowPlanContent: Equatable, Codable {
    var habits: [String]
    var reasons: [String]
    var milestones: [String]
}

enum PlanSource: String {
    case fms
    case library
    case deepseek
}

protocol CoachProvider {
    func generatePlan(measurement: FaceMeasurement, streak: Int) async throws -> GlowPlanContent
}

enum PlanGenerator {
    static var canGenerate: Bool { true }

    static var usesOnDeviceModel: Bool {
        if #available(iOS 26.0, *) {
            return AppleFMsCoach.isAvailable
        }
        return false
    }

    static func generate(measurement: FaceMeasurement, streak: Int) async -> (GlowPlanContent, PlanSource) {
        if #available(iOS 26.0, *), AppleFMsCoach.isAvailable {
            do {
                let plan = try await AppleFMsCoach().generatePlan(measurement: measurement, streak: streak)
                return (plan, .fms)
            } catch {
                let plan = await LibraryCoach().generatePlan(measurement: measurement, streak: streak)
                return (plan, .library)
            }
        }
        let plan = await LibraryCoach().generatePlan(measurement: measurement, streak: streak)
        return (plan, .library)
    }
}

struct LibraryCoach: CoachProvider {
    private static let library: [String: [(habit: String, reason: String)]] = [
        "Jawline": [
            ("Mew + posture", "Tongue posture and upright head position support a defined lower face."),
            ("Chewing routine", "Balanced chewing workload keeps jaw muscles toned."),
            ("Neck stretches", "Relaxed neck muscles let your jawline read cleanly.")
        ],
        "Symmetry": [
            ("Sleep on your back", "Back sleeping avoids overnight pressure that skews facial balance."),
            ("Even chewing", "Chewing on both sides keeps masseter muscles balanced."),
            ("Brow grooming", "Even brow shaping visually balances your upper face.")
        ],
        "Facial Thirds": [
            ("Hairstyle audit", "Volume up top rebalances facial zones in photos."),
            ("Posture reset", "Lifting the crown of your head lengthens the midface view."),
            ("Hydration goal", "Hydrated skin reads smoother across all three zones.")
        ],
        "Facial Fifths": [
            ("Brow shaping", "Shaped brows fine-tune feature spacing across your face."),
            ("Glasses fitting", "Well-fitted frames flatter your natural feature spacing."),
            ("Photo eye line", "Level eye line in photos shows your true proportions.")
        ],
        "Canthal Tilt": [
            ("Sleep 8 hours", "Rest reduces puffiness so your eye line reads lifted."),
            ("Cold morning rinse", "A cool rinse de-puffs and lifts the eye area."),
            ("SPF daily", "Protected skin keeps the eye area firm over time.")
        ],
        "Golden Ratio": [
            ("Styling check", "Simple styling choices can echo classical harmony."),
            ("Grooming ritual", "A tidy beard or clean shave sharpens proportions."),
            ("Weekly photo log", "Progress photos keep proportion goals on track.")
        ],
        "Skin Clarity": [
            ("Cleanse nightly", "A steady cleanse keeps your skin trending upward."),
            ("Moisturize AM + PM", "Moisturized skin reads even and healthy."),
            ("SPF daily", "Sun protection is the clearest skin move there is."),
            ("Weekly exfoliate", "Gentle exfoliation keeps texture smooth.")
        ],
        "Capture Quality": [
            ("Bright window selfie", "Facing a window makes your next scan sharper."),
            ("Steady tripod shot", "A steady capture sharpens every score."),
            ("Clean lens wipe", "A clean lens keeps captures crisp.")
        ]
    ]

    private static let defaultHabits = library["Skin Clarity"]! + library["Jawline"]!

    func generatePlan(measurement: FaceMeasurement, streak: Int) async -> GlowPlanContent {
        let result = ScoringEngine.score(measurement, quality: Int(measurement.captureQualityScore.rounded()))
        let ranked = result.dimensionList
            .filter { $0.name != "Quality" }
            .sorted { $0.value < $1.value }
        var habits: [String] = []
        var reasons: [String] = []
        for dimension in ranked {
            guard let entries = Self.library[dimension.name] else { continue }
            for entry in entries where habits.count < 4 {
                if !habits.contains(entry.habit) {
                    habits.append(entry.habit)
                    reasons.append(entry.reason)
                }
            }
            if habits.count >= 4 { break }
        }
        if habits.count < 3 {
            for entry in Self.defaultHabits where habits.count < 3 {
                if !habits.contains(entry.habit) {
                    habits.append(entry.habit)
                    reasons.append(entry.reason)
                }
            }
        }
        let milestones = Self.milestoneTemplates(streak: streak)
        return GlowPlanContent(habits: habits, reasons: reasons, milestones: milestones)
    }
}

private extension LibraryCoach {
    static func milestoneTemplates(streak: Int) -> [String] {
        [
            "Week 1: run every habit 5 of 7 days",
            "Week 2: hold a \(max(streak, 3) + 7)-day streak",
            "Week 3: retake one bright, steady scan",
            "Week 4: compare your before and after"
        ]
    }
}
