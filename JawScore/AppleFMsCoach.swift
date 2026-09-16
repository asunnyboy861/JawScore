import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct GlowPlanSchema {
    @Guide(description: "Three to five daily habit names, each at most four words")
    var habits: [String]

    @Guide(description: "One short encouraging sentence per habit, tied to the measurement numbers")
    var reasons: [String]

    @Guide(description: "Four weekly milestones, each at most twelve words")
    var milestones: [String]
}

@available(iOS 26.0, *)
struct AppleFMsCoach: CoachProvider {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    private static let instructions = """
    You are a supportive grooming coach. Celebrate potential, stay uplifting, and never judge the person. \
    Produce a short list of daily habits, one encouraging reason per habit tied to the provided measurements, \
    and four weekly milestones. Habit names are at most four words. Milestones are at most twelve words.
    """

    func generatePlan(measurement: FaceMeasurement, streak: Int) async throws -> GlowPlanContent {
        let prompt = """
        Measurement snapshot: gonial angles \(format(measurement.gonialAngleLeftDegrees)) and \(format(measurement.gonialAngleRightDegrees)) degrees, \
        chin projection \(format(measurement.chinProjectionDepthRatio)), mirror symmetry residual \(format(measurement.mirrorSymmetryResidual)), \
        thirds \(format(measurement.thirdsUpperRatio)) / \(format(measurement.thirdsMiddleRatio)) / \(format(measurement.thirdsLowerRatio)), \
        fifths \(format(measurement.fifthsLeftEyeSegment)) and \(format(measurement.fifthsRightEyeSegment)), \
        canthal tilt \(format(measurement.canthalTiltMeanDegrees)) degrees, golden width to length \(format(measurement.goldenFaceWidthToLength)), \
        skin texture uniformity \(format(measurement.skinTextureUniformity)). \
        Current habit streak: \(streak) days. Build this week's plan.
        """
        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(to: prompt, generating: GlowPlanSchema.self)
        let content = response.content
        var habits = content.habits
        var reasons = content.reasons
        let milestones = content.milestones
        if reasons.count < habits.count {
            reasons.append(contentsOf: Array(repeating: "Steady reps move this upward.", count: habits.count - reasons.count))
        }
        if habits.count > reasons.count {
            habits = Array(habits.prefix(reasons.count))
        }
        return GlowPlanContent(habits: habits, reasons: reasons, milestones: milestones)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }
}

#endif
