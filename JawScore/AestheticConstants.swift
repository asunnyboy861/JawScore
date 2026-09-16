import Foundation

nonisolated enum AestheticConstants {
    static let goldenRatio = 1.6180339887498949
    static let goldenWidthToLengthIdeal = 1.0 / goldenRatio
    static let goldenNoseToMouthIdeal = 1.0 / goldenRatio
    static let goldenMouthToNoseIdeal = goldenRatio
    static let goldenJawToCheekIdeal = 1.0 / goldenRatio
    static let goldenEyeSpacingIdealToFaceWidth = 0.2
    static let goldenDeviationTolerance = 0.10

    static let gonialIdealRange: ClosedRange<Double> = 100.0...110.0
    static var gonialIdealCenterDegrees: Double {
        (gonialIdealRange.lowerBound + gonialIdealRange.upperBound) / 2
    }
    static let gonialToleranceDegrees = 5.0

    static let jawCurvatureIdealVariance = 0.0
    static let jawCurvatureTolerance = 0.0004

    static let chinProjectionIdealRange: ClosedRange<Double> = 0.06...0.16
    static var chinProjectionIdealCenter: Double {
        (chinProjectionIdealRange.lowerBound + chinProjectionIdealRange.upperBound) / 2
    }
    static let chinProjectionTolerance = 0.09

    static let symmetryResidualTolerance = 0.012
    static let featureDeltaTolerance = 0.02

    static let thirdsIdealSegment = 1.0 / 3.0
    static let thirdsTolerance = 0.05
    static let fifthsIdealSegment = 0.2
    static let fifthsTolerance = 0.035

    static let canthalTiltIdealRange: ClosedRange<Double> = 3.0...8.0
    static var canthalTiltIdealCenter: Double {
        (canthalTiltIdealRange.lowerBound + canthalTiltIdealRange.upperBound) / 2
    }
    static let canthalTiltToleranceDegrees = 5.0

    static let skinBrightnessVarianceIdeal = 0.008
    static let skinBrightnessVarianceTolerance = 0.035
    static let skinTextureUniformityIdeal = 0.9
    static let skinTextureUniformityTolerance = 0.35

    static let captureDistanceIdeal: ClosedRange<Double> = 0.45...0.65
    static let captureDistanceToleranceMeters = 0.12
    static let captureLuxFull = 250.0
    static let captureLuxFloor = 100.0
    static let capturePoseFullDegrees = 8.0
    static let capturePoseZeroDegrees = 22.0
    static let qualityDistanceWeight = 40.0
    static let qualityLightWeight = 35.0
    static let qualityPoseWeight = 25.0
    static let qualityAutoCaptureThreshold = 70.0
    static let qualityCaptureWindowSeconds: TimeInterval = 1.2

    static let overallJawWeight = 0.35
    static let overallSymmetryWeight = 0.35
    static let overallCanthalWeight = 0.30

    static let freeScansPerDay = 1
    static let freeHistoryRecordLimit = 7
    static let breakDurationDays = 30
    static let planGenerationMinDurationSeconds = 2.0
    static let habitGridDays = 90
    static let decodingAnimationStepNanoseconds: UInt64 = 42_000_000
    static let faceMeshVertexCount = 1220
    static let arkitMinimumVertexCount = 455
}
