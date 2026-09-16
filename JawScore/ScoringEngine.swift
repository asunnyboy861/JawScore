import Foundation

struct ScoreResult: Codable, Equatable {
    let jawline: Double
    let symmetry: Double
    let facialThirds: Double
    let facialFifths: Double
    let canthalTilt: Double
    let goldenRatio: Double
    let skinClarity: Double
    let captureQuality: Double
    let overall: Double
    let band: Double

    var dimensionList: [(name: String, value: Double)] {
        [
            ("Jawline", jawline),
            ("Symmetry", symmetry),
            ("Thirds", facialThirds),
            ("Fifths", facialFifths),
            ("Canthal", canthalTilt),
            ("Golden", goldenRatio),
            ("Skin", skinClarity),
            ("Quality", captureQuality)
        ]
    }
}

enum ScoringEngine {
    static func proximityScore(_ value: Double, center: Double, tolerance: Double) -> Double {
        guard tolerance > 0 else { return value == center ? 10 : 0 }
        let deviation = abs(value - center)
        return 10 * max(0, 1 - deviation / tolerance)
    }

    static func roundToTenth(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    static func score(_ m: FaceMeasurement, quality: Int) -> ScoreResult {
        let gonialSpread = m.gonialAngleLeftDegrees + m.gonialAngleRightDegrees
        let gonialScore = proximityScore(
            gonialSpread,
            center: AestheticConstants.gonialIdealCenterDegrees,
            tolerance: AestheticConstants.gonialToleranceDegrees
        )
        let curvatureScore = proximityScore(
            m.jawlineCurvatureVariance,
            center: AestheticConstants.jawCurvatureIdealVariance,
            tolerance: AestheticConstants.jawCurvatureTolerance
        )
        let jawCheekScore = proximityScore(
            m.jawWidthToCheekWidthRatio,
            center: AestheticConstants.goldenJawToCheekIdeal,
            tolerance: AestheticConstants.goldenDeviationTolerance
        )
        let chinScore = proximityScore(
            m.chinProjectionDepthRatio,
            center: AestheticConstants.chinProjectionIdealCenter,
            tolerance: AestheticConstants.chinProjectionTolerance
        )
        let jawline = (gonialScore + curvatureScore + jawCheekScore + chinScore) / 4

        let residualScore = proximityScore(
            m.mirrorSymmetryResidual,
            center: 0,
            tolerance: AestheticConstants.symmetryResidualTolerance
        )
        let eyeDeltaScore = proximityScore(
            m.eyePairVerticalDeltaRatio,
            center: 0,
            tolerance: AestheticConstants.featureDeltaTolerance
        )
        let browDeltaScore = proximityScore(
            m.browHeightDeltaRatio,
            center: 0,
            tolerance: AestheticConstants.featureDeltaTolerance
        )
        let mouthDeltaScore = proximityScore(
            m.mouthVerticalDeltaRatio,
            center: 0,
            tolerance: AestheticConstants.featureDeltaTolerance
        )
        let symmetry = (residualScore + eyeDeltaScore + browDeltaScore + mouthDeltaScore) / 4

        let thirdsUpperScore = proximityScore(
            m.thirdsUpperRatio,
            center: AestheticConstants.thirdsIdealSegment,
            tolerance: AestheticConstants.thirdsTolerance
        )
        let thirdsMiddleScore = proximityScore(
            m.thirdsMiddleRatio,
            center: AestheticConstants.thirdsIdealSegment,
            tolerance: AestheticConstants.thirdsTolerance
        )
        let thirdsLowerScore = proximityScore(
            m.thirdsLowerRatio,
            center: AestheticConstants.thirdsIdealSegment,
            tolerance: AestheticConstants.thirdsTolerance
        )
        let facialThirds = (thirdsUpperScore + thirdsMiddleScore + thirdsLowerScore) / 3

        let fifthsSegments = [
            m.fifthsLeftOuterSegment,
            m.fifthsLeftEyeSegment,
            m.fifthsCenterSegment,
            m.fifthsRightEyeSegment,
            m.fifthsRightOuterSegment
        ]
        let fifthsScores = fifthsSegments.map {
            proximityScore($0, center: AestheticConstants.fifthsIdealSegment, tolerance: AestheticConstants.fifthsTolerance)
        }
        let facialFifths = fifthsScores.reduce(0, +) / Double(fifthsScores.count)

        let canthalTiltScore = proximityScore(
            m.canthalTiltMeanDegrees,
            center: AestheticConstants.canthalTiltIdealCenter,
            tolerance: AestheticConstants.canthalTiltToleranceDegrees
        )

        let goldenDeviations = [
            m.goldenFaceWidthToLengthDeviation,
            m.goldenNoseToMouthWidthDeviation,
            m.goldenEyeSpacingToFaceWidthDeviation,
            m.goldenMouthToNoseWidthDeviation,
            m.goldenJawToCheekWidthDeviation
        ]
        let goldenScores = goldenDeviations.map {
            proximityScore($0, center: 0, tolerance: AestheticConstants.goldenDeviationTolerance)
        }
        let goldenRatioScore = goldenScores.reduce(0, +) / Double(goldenScores.count)

        let varianceScore = proximityScore(
            m.skinBrightnessVariance,
            center: AestheticConstants.skinBrightnessVarianceIdeal,
            tolerance: AestheticConstants.skinBrightnessVarianceTolerance
        )
        let textureScore = proximityScore(
            m.skinTextureUniformity,
            center: AestheticConstants.skinTextureUniformityIdeal,
            tolerance: AestheticConstants.skinTextureUniformityTolerance
        )
        let skinClarity = (varianceScore + textureScore) / 2

        let qualityClamped = Double(max(0, min(100, quality)))
        let captureQualityScore = qualityClamped / 10

        let overall = roundToTenth(
            AestheticConstants.overallJawWeight * jawline
                + AestheticConstants.overallSymmetryWeight * symmetry
                + AestheticConstants.overallCanthalWeight * canthalTiltScore
        )
        let band = roundToTenth((100.0 - qualityClamped) / 100.0 * 0.9 + 0.1)

        return ScoreResult(
            jawline: jawline,
            symmetry: symmetry,
            facialThirds: facialThirds,
            facialFifths: facialFifths,
            canthalTilt: canthalTiltScore,
            goldenRatio: goldenRatioScore,
            skinClarity: skinClarity,
            captureQuality: captureQualityScore,
            overall: overall,
            band: band
        )
    }
}
