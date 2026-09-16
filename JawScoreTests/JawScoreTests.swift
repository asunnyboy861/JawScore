import XCTest
import simd
@testable import JawScore

@MainActor
final class JawScoreTests: XCTestCase {

    private func makeFixture(gonialHalfAngleDegrees: Double) -> FaceMeasurement {
        let phi = AestheticConstants.goldenRatio
        let faceWidth: Float = 0.12
        let faceLength = Float(Double(faceWidth) * phi)

        let chin = simd_float3(0, 0, 0.02)
        let nasion = simd_float3(0, 0.10, 0.02)
        let third = faceLength / 3
        let foreheadTop = simd_float3(0, third * 3, 0.02)
        let noseBottom = simd_float3(0, third, 0.02)
        let noseTip = simd_float3(0, 0.052, 0.02)
        let browY = third * 2
        let browLeft = simd_float3(-0.02, browY, 0.02)
        let browRight = simd_float3(0.02, browY, 0.02)
        let cheekLeft = simd_float3(-faceWidth / 2, 0.10, 0.02)
        let cheekRight = simd_float3(faceWidth / 2, 0.10, 0.02)

        let eyeY: Float = 0.08
        let innerX: Float = 0.012
        let outerX: Float = 0.036
        let canthalRise = Float(0.024 * tan(5.5 * Double.pi / 180.0))
        let eyeOuterLeft = simd_float3(-outerX, eyeY + canthalRise, 0.02)
        let eyeInnerLeft = simd_float3(-innerX, eyeY, 0.02)
        let eyeInnerRight = simd_float3(innerX, eyeY, 0.02)
        let eyeOuterRight = simd_float3(outerX, eyeY + canthalRise, 0.02)

        let mouthHalf = Float(0.024 * phi / 2)
        let mouthY: Float = 0.042
        let mouthLeft = simd_float3(-mouthHalf, mouthY, 0.02)
        let mouthRight = simd_float3(mouthHalf, mouthY, 0.02)
        let lipTop = simd_float3(0, 0.048, 0.02)
        let lipBottom = simd_float3(0, 0.035, 0.02)

        let jawHalf = Float(Double(faceWidth) / (2 * phi))
        let dz = Float(-0.0132)
        let halfAngle = Float(gonialHalfAngleDegrees * Double.pi / 180.0)
        let gonionLength = sqrt(jawHalf * jawHalf + dz * dz) / sin(halfAngle)
        let dy = gonionLength * cos(halfAngle)
        let gonionLeft = simd_float3(-jawHalf, dy, 0.02 + dz)
        let gonionRight = simd_float3(jawHalf, dy, 0.02 + dz)

        var arcLeft: [simd_float3] = []
        var arcRight: [simd_float3] = []
        let leftVector = gonionLeft - chin
        let rightVector = gonionRight - chin
        let arcLength = simd_length(leftVector)
        let leftDirection = leftVector / arcLength
        let rightDirection = rightVector / simd_length(rightVector)
        for step in 0...12 {
            let t = Float(step) / 12
            arcLeft.append(chin + leftDirection * arcLength * t)
            arcRight.append(chin + rightDirection * arcLength * t)
        }

        var cloud: [simd_float3] = [
            chin, nasion, foreheadTop, noseBottom, noseTip,
            browLeft, browRight,
            eyeOuterLeft, eyeInnerLeft, eyeOuterRight, eyeInnerRight,
            mouthLeft, mouthRight, lipTop, lipBottom,
            cheekLeft, cheekRight, gonionLeft, gonionRight
        ]
        cloud.append(contentsOf: arcLeft.dropFirst().dropLast())
        cloud.append(contentsOf: arcRight.dropFirst().dropLast())
        var fillerIndex: Float = 0
        while cloud.count < AestheticConstants.faceMeshVertexCount {
            let angle = fillerIndex * 0.71
            let base = simd_float3(cos(angle) * 0.07, 0.15 + sin(angle) * 0.02, 0.02)
            cloud.append(base)
            cloud.append(simd_float3(-base.x, base.y, base.z))
            fillerIndex += 1
        }

        let canonical = CanonicalLandmarks(
            chin: chin,
            jawLowerLeft: arcLeft[6],
            jawLowerRight: arcRight[6],
            eyeOuterLeft: eyeOuterLeft,
            eyeInnerLeft: eyeInnerLeft,
            eyeOuterRight: eyeOuterRight,
            eyeInnerRight: eyeInnerRight,
            browLeft: browLeft,
            browRight: browRight,
            noseTip: noseTip,
            noseBottom: noseBottom,
            mouthLeft: mouthLeft,
            mouthRight: mouthRight,
            lipTop: lipTop,
            lipBottom: lipBottom,
            foreheadTop: foreheadTop,
            cheekLeft: cheekLeft,
            cheekRight: cheekRight,
            gonionLeft: gonionLeft,
            gonionRight: gonionRight,
            nasion: nasion
        )

        let pixelStats = SkinPixelStats(brightnessMean: 0.5, brightnessVariance: 0.008, textureUniformity: 0.9)
        let quality = CaptureQualitySample(distanceMeters: 0.55, ambientLux: 300, poseDeviationDegrees: 4)

        return GeometryExtractor.extract(
            canonical: canonical,
            jawArcLeft: arcLeft,
            jawArcRight: arcRight,
            symmetryCloud: cloud,
            pixelStats: pixelStats,
            quality: quality
        )
    }

    func testIdealFixtureProducesExactScores() {
        let measurement = makeFixture(gonialHalfAngleDegrees: 52.5)
        let result = ScoringEngine.score(measurement, quality: 85)

        XCTAssertEqual(result.jawline, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.symmetry, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.facialThirds, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.facialFifths, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.canthalTilt, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.goldenRatio, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.skinClarity, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.captureQuality, 8.5, accuracy: 0.0001)
        XCTAssertEqual(result.overall, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.band, 0.2, accuracy: 0.0001)
    }

    func testOffsetFixtureShiftsJawlineAndOverall() {
        let measurement = makeFixture(gonialHalfAngleDegrees: 53.75)
        let result = ScoringEngine.score(measurement, quality: 85)

        XCTAssertEqual(result.jawline, 8.75, accuracy: 0.0001)
        XCTAssertEqual(result.symmetry, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.facialThirds, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.canthalTilt, 10.0, accuracy: 0.0001)
        XCTAssertEqual(result.overall, 9.6, accuracy: 0.0001)
    }

    func testSameInputProducesIdenticalResult() {
        let measurement = makeFixture(gonialHalfAngleDegrees: 52.5)
        let first = ScoringEngine.score(measurement, quality: 85)
        let second = ScoringEngine.score(measurement, quality: 85)
        XCTAssertEqual(first, second)
    }

    func testBandDecreasesAsQualityIncreases() {
        let measurement = makeFixture(gonialHalfAngleDegrees: 52.5)
        let low = ScoringEngine.score(measurement, quality: 10).band
        let mid = ScoringEngine.score(measurement, quality: 40).band
        let high = ScoringEngine.score(measurement, quality: 70).band
        let top = ScoringEngine.score(measurement, quality: 95).band
        XCTAssertEqual(low, 0.9, accuracy: 0.0001)
        XCTAssertEqual(mid, 0.6, accuracy: 0.0001)
        XCTAssertEqual(high, 0.4, accuracy: 0.0001)
        XCTAssertEqual(top, 0.1, accuracy: 0.0001)
        XCTAssertGreaterThan(low, mid)
        XCTAssertGreaterThan(mid, high)
        XCTAssertGreaterThan(high, top)
    }

    func testAllMetricsHasExactly48LabeledEntries() {
        let measurement = makeFixture(gonialHalfAngleDegrees: 52.5)
        let metrics = measurement.allMetrics
        XCTAssertEqual(metrics.count, 48)
        let labels = metrics.map { $0.0 }
        XCTAssertEqual(Set(labels).count, 48)
    }

    func testMeasurementCodableRoundTrip() throws {
        let measurement = makeFixture(gonialHalfAngleDegrees: 52.5)
        let data = try JSONEncoder().encode(measurement)
        let decoded = try JSONDecoder().decode(FaceMeasurement.self, from: data)
        XCTAssertEqual(decoded, measurement)
    }

    func testVertexPathMatchesCanonicalFixtureScores() {
        let ideal = makeFixture(gonialHalfAngleDegrees: 52.5)
        let result = ScoringEngine.score(ideal, quality: 85)
        XCTAssertGreaterThanOrEqual(result.overall, 9.99)
        XCTAssertLessThanOrEqual(result.band, 0.2)
    }
}
