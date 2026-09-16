import Foundation
import simd

nonisolated struct SkinPixelStats: Codable, Equatable {
    var brightnessMean: Double
    var brightnessVariance: Double
    var textureUniformity: Double
}

nonisolated struct CaptureQualitySample: Codable, Equatable {
    var distanceMeters: Double
    var ambientLux: Double
    var poseDeviationDegrees: Double

    var distanceScore: Double {
        if AestheticConstants.captureDistanceIdeal.contains(distanceMeters) { return 100 }
        let deviation = distanceMeters < AestheticConstants.captureDistanceIdeal.lowerBound
            ? AestheticConstants.captureDistanceIdeal.lowerBound - distanceMeters
            : distanceMeters - AestheticConstants.captureDistanceIdeal.upperBound
        return max(0, 100 * (1 - deviation / AestheticConstants.captureDistanceToleranceMeters))
    }

    var lightScore: Double {
        let span = AestheticConstants.captureLuxFull - AestheticConstants.captureLuxFloor
        guard span > 0 else { return 100 }
        return max(0, min(100, (ambientLux - AestheticConstants.captureLuxFloor) / span * 100))
    }

    var poseScore: Double {
        guard poseDeviationDegrees > AestheticConstants.capturePoseFullDegrees else { return 100 }
        let span = AestheticConstants.capturePoseZeroDegrees - AestheticConstants.capturePoseFullDegrees
        guard span > 0 else { return 100 }
        return max(0, 100 * (1 - (poseDeviationDegrees - AestheticConstants.capturePoseFullDegrees) / span))
    }

    var total: Double {
        AestheticConstants.qualityDistanceWeight * distanceScore / 100
            + AestheticConstants.qualityLightWeight * lightScore / 100
            + AestheticConstants.qualityPoseWeight * poseScore / 100
    }

    var needsCloser: Bool { distanceMeters > AestheticConstants.captureDistanceIdeal.upperBound }
    var needsLight: Bool { ambientLux < AestheticConstants.captureLuxFull }
    var needsCentering: Bool { poseDeviationDegrees > AestheticConstants.capturePoseFullDegrees }
}

nonisolated struct FaceMeasurement: Codable, Equatable {
    var gonialAngleLeftDegrees: Double
    var gonialAngleRightDegrees: Double
    var gonialAngleAsymmetryDeltaDegrees: Double
    var chinProjectionDepthRatio: Double
    var jawlineCurvatureVariance: Double
    var jawWidthToCheekWidthRatio: Double
    var jawSymmetryWidthRatio: Double
    var mirrorSymmetryResidual: Double
    var eyePairVerticalDeltaRatio: Double
    var browHeightDeltaRatio: Double
    var mouthVerticalDeltaRatio: Double
    var thirdsUpperRatio: Double
    var thirdsMiddleRatio: Double
    var thirdsLowerRatio: Double
    var fifthsLeftOuterSegment: Double
    var fifthsLeftEyeSegment: Double
    var fifthsCenterSegment: Double
    var fifthsRightEyeSegment: Double
    var fifthsRightOuterSegment: Double
    var canthalTiltLeftDegrees: Double
    var canthalTiltRightDegrees: Double
    var canthalTiltMeanDegrees: Double
    var interocularToFaceWidthRatio: Double
    var eyeWidthToFaceWidthMean: Double
    var goldenFaceWidthToLength: Double
    var goldenFaceWidthToLengthDeviation: Double
    var goldenNoseToMouthWidth: Double
    var goldenNoseToMouthWidthDeviation: Double
    var goldenEyeSpacingToFaceWidth: Double
    var goldenEyeSpacingToFaceWidthDeviation: Double
    var goldenMouthToNoseWidth: Double
    var goldenMouthToNoseWidthDeviation: Double
    var goldenJawToCheekWidth: Double
    var goldenJawToCheekWidthDeviation: Double
    var noseWidthToFaceWidth: Double
    var mouthWidthToFaceWidth: Double
    var lipFullnessRatio: Double
    var noseLengthToFaceLength: Double
    var faceWidthToLengthRatio: Double
    var cheekboneProminenceRatio: Double
    var midfaceToFaceLengthRatio: Double
    var skinBrightnessMean: Double
    var skinBrightnessVariance: Double
    var skinTextureUniformity: Double
    var captureDistanceMeters: Double
    var captureAmbientLux: Double
    var capturePoseDeviationDegrees: Double
    var captureQualityScore: Double

    static let metricCount = 48

    var allMetrics: [(String, Double)] {
        [
            ("Gonial L", gonialAngleLeftDegrees),
            ("Gonial R", gonialAngleRightDegrees),
            ("Gonial Δ", gonialAngleAsymmetryDeltaDegrees),
            ("Chin Projection", chinProjectionDepthRatio),
            ("Jaw Curvature", jawlineCurvatureVariance),
            ("Jaw / Cheek", jawWidthToCheekWidthRatio),
            ("Jaw Symmetry", jawSymmetryWidthRatio),
            ("Mirror Residual", mirrorSymmetryResidual),
            ("Eye Level Δ", eyePairVerticalDeltaRatio),
            ("Brow Level Δ", browHeightDeltaRatio),
            ("Mouth Level Δ", mouthVerticalDeltaRatio),
            ("Thirds Upper", thirdsUpperRatio),
            ("Thirds Middle", thirdsMiddleRatio),
            ("Thirds Lower", thirdsLowerRatio),
            ("Fifths Outer L", fifthsLeftOuterSegment),
            ("Fifths Eye L", fifthsLeftEyeSegment),
            ("Fifths Center", fifthsCenterSegment),
            ("Fifths Eye R", fifthsRightEyeSegment),
            ("Fifths Outer R", fifthsRightOuterSegment),
            ("Canthal L", canthalTiltLeftDegrees),
            ("Canthal R", canthalTiltRightDegrees),
            ("Canthal Mean", canthalTiltMeanDegrees),
            ("Eye Spacing", interocularToFaceWidthRatio),
            ("Eye Width", eyeWidthToFaceWidthMean),
            ("Width / Length", goldenFaceWidthToLength),
            ("W/L Deviation", goldenFaceWidthToLengthDeviation),
            ("Nose / Mouth", goldenNoseToMouthWidth),
            ("N/M Deviation", goldenNoseToMouthWidthDeviation),
            ("Spacing / Face", goldenEyeSpacingToFaceWidth),
            ("Spacing Deviation", goldenEyeSpacingToFaceWidthDeviation),
            ("Mouth / Nose", goldenMouthToNoseWidth),
            ("M/N Deviation", goldenMouthToNoseWidthDeviation),
            ("Jaw / Cheek φ", goldenJawToCheekWidth),
            ("J/C Deviation", goldenJawToCheekWidthDeviation),
            ("Nose Width", noseWidthToFaceWidth),
            ("Mouth Width", mouthWidthToFaceWidth),
            ("Lip Fullness", lipFullnessRatio),
            ("Nose Length", noseLengthToFaceLength),
            ("Face W / L", faceWidthToLengthRatio),
            ("Cheek Bone", cheekboneProminenceRatio),
            ("Midface", midfaceToFaceLengthRatio),
            ("Skin Brightness", skinBrightnessMean),
            ("Skin Variance", skinBrightnessVariance),
            ("Texture Uniformity", skinTextureUniformity),
            ("Distance", captureDistanceMeters),
            ("Light", captureAmbientLux),
            ("Pose", capturePoseDeviationDegrees),
            ("Capture Quality", captureQualityScore)
        ]
    }

    static func neutral(pixelStats: SkinPixelStats, quality: CaptureQualitySample) -> FaceMeasurement {
        FaceMeasurement(
            gonialAngleLeftDegrees: 0,
            gonialAngleRightDegrees: 0,
            gonialAngleAsymmetryDeltaDegrees: 0,
            chinProjectionDepthRatio: 0,
            jawlineCurvatureVariance: 0,
            jawWidthToCheekWidthRatio: 0,
            jawSymmetryWidthRatio: 1,
            mirrorSymmetryResidual: 0,
            eyePairVerticalDeltaRatio: 0,
            browHeightDeltaRatio: 0,
            mouthVerticalDeltaRatio: 0,
            thirdsUpperRatio: 0,
            thirdsMiddleRatio: 0,
            thirdsLowerRatio: 0,
            fifthsLeftOuterSegment: 0,
            fifthsLeftEyeSegment: 0,
            fifthsCenterSegment: 0,
            fifthsRightEyeSegment: 0,
            fifthsRightOuterSegment: 0,
            canthalTiltLeftDegrees: 0,
            canthalTiltRightDegrees: 0,
            canthalTiltMeanDegrees: 0,
            interocularToFaceWidthRatio: 0,
            eyeWidthToFaceWidthMean: 0,
            goldenFaceWidthToLength: 0,
            goldenFaceWidthToLengthDeviation: 0,
            goldenNoseToMouthWidth: 0,
            goldenNoseToMouthWidthDeviation: 0,
            goldenEyeSpacingToFaceWidth: 0,
            goldenEyeSpacingToFaceWidthDeviation: 0,
            goldenMouthToNoseWidth: 0,
            goldenMouthToNoseWidthDeviation: 0,
            goldenJawToCheekWidth: 0,
            goldenJawToCheekWidthDeviation: 0,
            noseWidthToFaceWidth: 0,
            mouthWidthToFaceWidth: 0,
            lipFullnessRatio: 0,
            noseLengthToFaceLength: 0,
            faceWidthToLengthRatio: 0,
            cheekboneProminenceRatio: 0,
            midfaceToFaceLengthRatio: 0,
            skinBrightnessMean: pixelStats.brightnessMean,
            skinBrightnessVariance: pixelStats.brightnessVariance,
            skinTextureUniformity: pixelStats.textureUniformity,
            captureDistanceMeters: quality.distanceMeters,
            captureAmbientLux: quality.ambientLux,
            capturePoseDeviationDegrees: quality.poseDeviationDegrees,
            captureQualityScore: quality.total
        )
    }
}

struct CanonicalLandmarks {
    var chin: simd_float3
    var jawLowerLeft: simd_float3
    var jawLowerRight: simd_float3
    var eyeOuterLeft: simd_float3
    var eyeInnerLeft: simd_float3
    var eyeOuterRight: simd_float3
    var eyeInnerRight: simd_float3
    var browLeft: simd_float3
    var browRight: simd_float3
    var noseTip: simd_float3
    var noseBottom: simd_float3
    var mouthLeft: simd_float3
    var mouthRight: simd_float3
    var lipTop: simd_float3
    var lipBottom: simd_float3
    var foreheadTop: simd_float3
    var cheekLeft: simd_float3
    var cheekRight: simd_float3
    var gonionLeft: simd_float3
    var gonionRight: simd_float3
    var nasion: simd_float3
}

nonisolated enum GeometryExtractor {
    static func extract(
        vertices: [simd_float3],
        pixelStats: SkinPixelStats,
        quality: CaptureQualitySample
    ) -> FaceMeasurement {
        guard vertices.count >= AestheticConstants.arkitMinimumVertexCount else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let canonical = CanonicalLandmarks(
            chin: vertices[152],
            jawLowerLeft: vertices[172],
            jawLowerRight: vertices[397],
            eyeOuterLeft: vertices[33],
            eyeInnerLeft: vertices[133],
            eyeOuterRight: vertices[263],
            eyeInnerRight: vertices[362],
            browLeft: vertices[105],
            browRight: vertices[334],
            noseTip: vertices[4],
            noseBottom: vertices[2],
            mouthLeft: vertices[61],
            mouthRight: vertices[291],
            lipTop: vertices[0],
            lipBottom: vertices[17],
            foreheadTop: vertices[10],
            cheekLeft: vertices[234],
            cheekRight: vertices[454],
            gonionLeft: vertices[58],
            gonionRight: vertices[288],
            nasion: vertices[168]
        )
        let faceWidth = simd_distance(canonical.cheekLeft, canonical.cheekRight)
        guard faceWidth > 1e-5 else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let tubeRadius = faceWidth * 0.35
        let arcLeft = jawArc(vertices: vertices, from: canonical.chin, to: canonical.gonionLeft, tubeRadius: tubeRadius)
        let arcRight = jawArc(vertices: vertices, from: canonical.chin, to: canonical.gonionRight, tubeRadius: tubeRadius)
        let symmetryCloud = stride(from: 0, to: vertices.count, by: 4).map { vertices[$0] }
        return extract(
            canonical: canonical,
            jawArcLeft: arcLeft,
            jawArcRight: arcRight,
            symmetryCloud: symmetryCloud,
            pixelStats: pixelStats,
            quality: quality
        )
    }

    static func extract(
        canonical: CanonicalLandmarks,
        jawArcLeft: [simd_float3],
        jawArcRight: [simd_float3],
        symmetryCloud: [simd_float3],
        pixelStats: SkinPixelStats,
        quality: CaptureQualitySample
    ) -> FaceMeasurement {
        let chin = canonical.chin
        let faceWidth = simd_distance(canonical.cheekLeft, canonical.cheekRight)
        let faceLength = simd_distance(canonical.foreheadTop, chin)
        let verticalRaw = canonical.nasion - chin
        let rightRaw = canonical.cheekRight - canonical.cheekLeft
        guard faceWidth > 1e-5, faceLength > 1e-5,
              simd_length(verticalRaw) > 1e-5, simd_length(rightRaw) > 1e-5 else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let verticalAxis = verticalRaw / simd_length(verticalRaw)
        let rightComponent = rightRaw - verticalAxis * simd_dot(rightRaw, verticalAxis)
        guard simd_length(rightComponent) > 1e-6 else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let rightAxis = rightComponent / simd_length(rightComponent)
        let outAxis = simd_normalize(simd_cross(rightAxis, verticalAxis))

        func lateral(_ v: simd_float3) -> Double {
            Double(simd_dot(v - chin, rightAxis) / faceWidth)
        }
        func elevation(_ v: simd_float3) -> Double {
            Double(simd_dot(v - chin, verticalAxis) / faceLength)
        }

        let gonialAngleLeftDegrees = angleFromAxis(canonical.gonionLeft - chin, axis: verticalAxis)
        let gonialAngleRightDegrees = angleFromAxis(canonical.gonionRight - chin, axis: verticalAxis)
        let gonialAngleAsymmetryDeltaDegrees = abs(gonialAngleLeftDegrees - gonialAngleRightDegrees)

        let gonionMidpoint = (canonical.gonionLeft + canonical.gonionRight) * 0.5
        let chinProjectionDepthRatio = Double(simd_dot(chin - gonionMidpoint, outAxis) / faceWidth)

        let leftCurvature = curvatureVariance(jawArcLeft, chin: chin, verticalAxis: verticalAxis, faceLength: faceLength)
        let rightCurvature = curvatureVariance(jawArcRight, chin: chin, verticalAxis: verticalAxis, faceLength: faceLength)
        let jawlineCurvatureVariance = (leftCurvature + rightCurvature) * 0.5

        let jawWidthToCheekWidthRatio = Double(simd_distance(canonical.gonionLeft, canonical.gonionRight) / faceWidth)
        let leftLateral = abs(lateral(canonical.gonionLeft))
        let rightLateral = abs(lateral(canonical.gonionRight))
        let jawSymmetryWidthRatio = rightLateral > 1e-6 ? leftLateral / rightLateral : 1.0

        let mirrorSymmetryResidual = symmetryResidual(
            cloud: symmetryCloud,
            chin: chin,
            rightAxis: rightAxis,
            faceWidth: faceWidth
        )

        let eyePairVerticalDeltaRatio = abs(elevation(canonical.eyeOuterLeft) - elevation(canonical.eyeOuterRight)) * Double(faceLength / faceWidth)
        let browHeightDeltaRatio = abs(elevation(canonical.browLeft) - elevation(canonical.browRight)) * Double(faceLength / faceWidth)
        let mouthVerticalDeltaRatio = abs(elevation(canonical.mouthLeft) - elevation(canonical.mouthRight)) * Double(faceLength / faceWidth)

        let browMidpoint = (canonical.browLeft + canonical.browRight) * 0.5
        let upperThird = simd_distance(canonical.foreheadTop, browMidpoint)
        let middleThird = simd_distance(browMidpoint, canonical.noseBottom)
        let lowerThird = simd_distance(canonical.noseBottom, chin)
        let thirdsTotal = upperThird + middleThird + lowerThird
        guard thirdsTotal > 1e-6 else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let thirdsUpperRatio = Double(upperThird / thirdsTotal)
        let thirdsMiddleRatio = Double(middleThird / thirdsTotal)
        let thirdsLowerRatio = Double(lowerThird / thirdsTotal)

        let cheekLeftX = lateral(canonical.cheekLeft)
        let eyeOuterLeftX = lateral(canonical.eyeOuterLeft)
        let eyeInnerLeftX = lateral(canonical.eyeInnerLeft)
        let eyeInnerRightX = lateral(canonical.eyeInnerRight)
        let eyeOuterRightX = lateral(canonical.eyeOuterRight)
        let cheekRightX = lateral(canonical.cheekRight)
        let fifthsSpan = cheekRightX - cheekLeftX
        guard fifthsSpan > 1e-6 else {
            return FaceMeasurement.neutral(pixelStats: pixelStats, quality: quality)
        }
        let fifthsLeftOuterSegment = (eyeOuterLeftX - cheekLeftX) / fifthsSpan
        let fifthsLeftEyeSegment = (eyeInnerLeftX - eyeOuterLeftX) / fifthsSpan
        let fifthsCenterSegment = (eyeInnerRightX - eyeInnerLeftX) / fifthsSpan
        let fifthsRightEyeSegment = (eyeOuterRightX - eyeInnerRightX) / fifthsSpan
        let fifthsRightOuterSegment = (cheekRightX - eyeOuterRightX) / fifthsSpan

        let canthalTiltLeftDegrees = canthalTiltDegrees(
            outer: canonical.eyeOuterLeft,
            inner: canonical.eyeInnerLeft,
            rightAxis: rightAxis,
            verticalAxis: verticalAxis
        )
        let canthalTiltRightDegrees = canthalTiltDegrees(
            outer: canonical.eyeOuterRight,
            inner: canonical.eyeInnerRight,
            rightAxis: rightAxis,
            verticalAxis: verticalAxis
        )
        let canthalTiltMeanDegrees = (canthalTiltLeftDegrees + canthalTiltRightDegrees) * 0.5

        let interocularToFaceWidthRatio = Double(simd_distance(canonical.eyeInnerLeft, canonical.eyeInnerRight) / faceWidth)
        let eyeWidthToFaceWidthMean = Double(
            (simd_distance(canonical.eyeOuterLeft, canonical.eyeInnerLeft)
                + simd_distance(canonical.eyeOuterRight, canonical.eyeInnerRight)) * 0.5 / faceWidth
        )

        let noseWidth = Double(simd_distance(canonical.eyeInnerLeft, canonical.eyeInnerRight))
        let mouthWidth = Double(simd_distance(canonical.mouthLeft, canonical.mouthRight))

        let goldenFaceWidthToLength = Double(faceWidth / faceLength)
        let goldenNoseToMouthWidth = mouthWidth > 1e-9 ? noseWidth / mouthWidth : 0
        let goldenEyeSpacingToFaceWidth = interocularToFaceWidthRatio
        let goldenMouthToNoseWidth = noseWidth > 1e-9 ? mouthWidth / noseWidth : 0
        let goldenJawToCheekWidth = jawWidthToCheekWidthRatio

        let goldenFaceWidthToLengthDeviation = abs(goldenFaceWidthToLength - AestheticConstants.goldenWidthToLengthIdeal)
        let goldenNoseToMouthWidthDeviation = abs(goldenNoseToMouthWidth - AestheticConstants.goldenNoseToMouthIdeal)
        let goldenEyeSpacingToFaceWidthDeviation = abs(goldenEyeSpacingToFaceWidth - AestheticConstants.goldenEyeSpacingIdealToFaceWidth)
        let goldenMouthToNoseWidthDeviation = abs(goldenMouthToNoseWidth - AestheticConstants.goldenMouthToNoseIdeal)
        let goldenJawToCheekWidthDeviation = abs(goldenJawToCheekWidth - AestheticConstants.goldenJawToCheekIdeal)

        let mouthMidpoint = (canonical.mouthLeft + canonical.mouthRight) * 0.5
        let upperLipHeight = simd_distance(canonical.lipTop, mouthMidpoint)
        let lowerLipHeight = simd_distance(mouthMidpoint, canonical.lipBottom)
        let lipFullnessRatio = lowerLipHeight > 1e-7 ? Double(upperLipHeight / lowerLipHeight) : 0
        let noseLengthToFaceLength = Double(simd_distance(canonical.noseBottom, canonical.nasion) / faceLength)
        let faceWidthToLengthRatio = Double(faceWidth / faceLength)
        let cheekMidpoint = (canonical.cheekLeft + canonical.cheekRight) * 0.5
        let cheekboneProminenceRatio = Double(
            (simd_dot(cheekMidpoint - chin, outAxis) - simd_dot(canonical.noseTip - chin, outAxis)) / faceWidth
        )
        let midfaceToFaceLengthRatio = Double(simd_distance(canonical.nasion, canonical.lipBottom) / faceLength)

        return FaceMeasurement(
            gonialAngleLeftDegrees: gonialAngleLeftDegrees,
            gonialAngleRightDegrees: gonialAngleRightDegrees,
            gonialAngleAsymmetryDeltaDegrees: gonialAngleAsymmetryDeltaDegrees,
            chinProjectionDepthRatio: chinProjectionDepthRatio,
            jawlineCurvatureVariance: jawlineCurvatureVariance,
            jawWidthToCheekWidthRatio: jawWidthToCheekWidthRatio,
            jawSymmetryWidthRatio: jawSymmetryWidthRatio,
            mirrorSymmetryResidual: mirrorSymmetryResidual,
            eyePairVerticalDeltaRatio: eyePairVerticalDeltaRatio,
            browHeightDeltaRatio: browHeightDeltaRatio,
            mouthVerticalDeltaRatio: mouthVerticalDeltaRatio,
            thirdsUpperRatio: thirdsUpperRatio,
            thirdsMiddleRatio: thirdsMiddleRatio,
            thirdsLowerRatio: thirdsLowerRatio,
            fifthsLeftOuterSegment: fifthsLeftOuterSegment,
            fifthsLeftEyeSegment: fifthsLeftEyeSegment,
            fifthsCenterSegment: fifthsCenterSegment,
            fifthsRightEyeSegment: fifthsRightEyeSegment,
            fifthsRightOuterSegment: fifthsRightOuterSegment,
            canthalTiltLeftDegrees: canthalTiltLeftDegrees,
            canthalTiltRightDegrees: canthalTiltRightDegrees,
            canthalTiltMeanDegrees: canthalTiltMeanDegrees,
            interocularToFaceWidthRatio: interocularToFaceWidthRatio,
            eyeWidthToFaceWidthMean: eyeWidthToFaceWidthMean,
            goldenFaceWidthToLength: goldenFaceWidthToLength,
            goldenFaceWidthToLengthDeviation: goldenFaceWidthToLengthDeviation,
            goldenNoseToMouthWidth: goldenNoseToMouthWidth,
            goldenNoseToMouthWidthDeviation: goldenNoseToMouthWidthDeviation,
            goldenEyeSpacingToFaceWidth: goldenEyeSpacingToFaceWidth,
            goldenEyeSpacingToFaceWidthDeviation: goldenEyeSpacingToFaceWidthDeviation,
            goldenMouthToNoseWidth: goldenMouthToNoseWidth,
            goldenMouthToNoseWidthDeviation: goldenMouthToNoseWidthDeviation,
            goldenJawToCheekWidth: goldenJawToCheekWidth,
            goldenJawToCheekWidthDeviation: goldenJawToCheekWidthDeviation,
            noseWidthToFaceWidth: noseWidth / Double(faceWidth),
            mouthWidthToFaceWidth: mouthWidth / Double(faceWidth),
            lipFullnessRatio: lipFullnessRatio,
            noseLengthToFaceLength: noseLengthToFaceLength,
            faceWidthToLengthRatio: faceWidthToLengthRatio,
            cheekboneProminenceRatio: cheekboneProminenceRatio,
            midfaceToFaceLengthRatio: midfaceToFaceLengthRatio,
            skinBrightnessMean: pixelStats.brightnessMean,
            skinBrightnessVariance: pixelStats.brightnessVariance,
            skinTextureUniformity: pixelStats.textureUniformity,
            captureDistanceMeters: quality.distanceMeters,
            captureAmbientLux: quality.ambientLux,
            capturePoseDeviationDegrees: quality.poseDeviationDegrees,
            captureQualityScore: quality.total
        )
    }

    static func jawArc(vertices: [simd_float3], from: simd_float3, to: simd_float3, tubeRadius: Float) -> [simd_float3] {
        let axis = to - from
        let length = simd_length(axis)
        guard length > 1e-6 else { return [] }
        let direction = axis / length
        var candidates: [(t: Float, point: simd_float3)] = []
        candidates.reserveCapacity(vertices.count / 8)
        for v in vertices {
            let t = simd_dot(v - from, direction)
            guard t >= -tubeRadius, t <= length + tubeRadius else { continue }
            let projected = from + direction * t
            if simd_distance(v, projected) <= tubeRadius {
                candidates.append((t, v))
            }
        }
        candidates.sort { $0.t < $1.t }
        return candidates.map { $0.point }
    }

    private static func angleFromAxis(_ v: simd_float3, axis: simd_float3) -> Double {
        let length = simd_length(v)
        guard length > 1e-8 else { return 0 }
        let cosine = max(-1.0, min(1.0, Double(simd_dot(v, axis) / length)))
        return degreesFromRadians(acos(cosine))
    }

    private static func canthalTiltDegrees(
        outer: simd_float3,
        inner: simd_float3,
        rightAxis: simd_float3,
        verticalAxis: simd_float3
    ) -> Double {
        let v = outer - inner
        let horizontal = abs(simd_dot(v, rightAxis))
        guard horizontal > 1e-8 else { return 0 }
        let verticalComponent = simd_dot(v, verticalAxis)
        return degreesFromRadians(atan2(Double(verticalComponent), Double(horizontal)))
    }

    private static func symmetryResidual(
        cloud: [simd_float3],
        chin: simd_float3,
        rightAxis: simd_float3,
        faceWidth: Float
    ) -> Double {
        guard cloud.count > 8 else { return 0 }
        var total = 0.0
        var count = 0
        for v in cloud {
            let offset = simd_dot(v - chin, rightAxis)
            if abs(offset) < 1e-7 * faceWidth { continue }
            let mirrored = v - rightAxis * (2 * offset)
            var best = Float.greatestFiniteMagnitude
            for u in cloud {
                let d = simd_distance(mirrored, u)
                if d < best { best = d }
            }
            if best < Float.greatestFiniteMagnitude {
                total += Double(best)
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        return total / Double(count) / Double(faceWidth)
    }

    private static func curvatureVariance(
        _ arc: [simd_float3],
        chin: simd_float3,
        verticalAxis: simd_float3,
        faceLength: Float
    ) -> Double {
        guard arc.count >= 4 else { return 0 }
        let ys = arc.map { Double(simd_dot($0 - chin, verticalAxis) / faceLength) }
        let n = ys.count
        var secondDifferences: [Double] = []
        secondDifferences.reserveCapacity(n - 2)
        for i in 1..<(n - 1) {
            let t0 = Double(i - 1) / Double(n - 1)
            let t1 = Double(i) / Double(n - 1)
            let t2 = Double(i + 1) / Double(n - 1)
            let span0 = max(t1 - t0, 1e-9)
            let span1 = max(t2 - t1, 1e-9)
            let slope0 = (ys[i] - ys[i - 1]) / span0
            let slope1 = (ys[i + 1] - ys[i]) / span1
            secondDifferences.append((slope1 - slope0) / (span0 + span1))
        }
        guard !secondDifferences.isEmpty else { return 0 }
        let mean = secondDifferences.reduce(0, +) / Double(secondDifferences.count)
        let variance = secondDifferences.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(secondDifferences.count)
        return variance
    }

    private static func degreesFromRadians(_ value: Double) -> Double {
        value * 180.0 / Double.pi
    }
}
