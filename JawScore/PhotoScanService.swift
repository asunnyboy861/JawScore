import CoreGraphics
import Foundation
import simd
import UIKit
import Vision

struct PhotoScanOutcome {
    let measurement: FaceMeasurement
    let quality: Int
    let image: UIImage
}

enum PhotoScanServiceError: LocalizedError {
    case invalidImage
    case noFaceDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "That image could not be read. Try another photo."
        case .noFaceDetected:
            return "No face found. Choose a clear, front-facing portrait."
        }
    }
}

enum PhotoScanService {
    static func process(image: UIImage) throws -> PhotoScanOutcome {
        guard let cgImage = image.cgImage else { throw PhotoScanServiceError.invalidImage }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw PhotoScanServiceError.invalidImage
        }
        guard let face = request.results?.first, let landmarks = face.landmarks else {
            throw PhotoScanServiceError.noFaceDetected
        }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let built = buildCanonical(face: face, landmarks: landmarks, imageSize: imageSize)
        let pixelStats = PixelStatsCalculator.compute(from: cgImage)
        let qualitySample = photoQuality(face: face, imageSize: imageSize, brightnessMean: pixelStats.brightnessMean)
        let measurement = GeometryExtractor.extract(
            canonical: built.landmarks,
            jawArcLeft: built.arcLeft,
            jawArcRight: built.arcRight,
            symmetryCloud: built.cloud,
            pixelStats: pixelStats,
            quality: qualitySample
        )
        return PhotoScanOutcome(measurement: measurement, quality: Int(qualitySample.total.rounded()), image: image)
    }

    private static func photoQuality(face: VNFaceObservation, imageSize: CGSize, brightnessMean: Double) -> CaptureQualitySample {
        let boxArea = Double(face.boundingBox.width * face.boundingBox.height)
        let estimatedDistance = min(1.0, max(0.3, 0.55 * (0.25 / max(boxArea, 0.01)).squareRoot()))
        let estimatedLux = brightnessMean * 700
        let rollDegrees = abs(Double(truncating: face.roll ?? 0)) * 180.0 / Double.pi
        return CaptureQualitySample(distanceMeters: estimatedDistance, ambientLux: estimatedLux, poseDeviationDegrees: rollDegrees)
    }

    private static func buildCanonical(
        face: VNFaceObservation,
        landmarks: VNFaceLandmarks2D,
        imageSize: CGSize
    ) -> (landmarks: CanonicalLandmarks, arcLeft: [simd_float3], arcRight: [simd_float3], cloud: [simd_float3]) {
        func regionPoints(_ region: VNFaceLandmarkRegion2D?) -> [simd_float3] {
            guard let region else { return [] }
            return region.pointsInImage(imageSize: imageSize).map { point in
                simd_float3(Float(point.x), Float(imageSize.height - point.y), 0)
            }
        }

        let contour = regionPoints(landmarks.faceContour)
        let medianLine = regionPoints(landmarks.medianLine)
        let leftEyeRegion = regionPoints(landmarks.leftEye)
        let rightEyeRegion = regionPoints(landmarks.rightEye)
        let leftBrowRegion = regionPoints(landmarks.leftEyebrow)
        let rightBrowRegion = regionPoints(landmarks.rightEyebrow)
        let noseRegion = regionPoints(landmarks.nose)
        let outerLips = regionPoints(landmarks.outerLips)

        func extreme(_ points: [simd_float3], by keyPath: (simd_float3) -> Float, maximum: Bool) -> simd_float3? {
            guard !points.isEmpty else { return nil }
            return points.max { a, b in maximum ? keyPath(a) < keyPath(b) : keyPath(a) > keyPath(b) }
        }

        let contourLeft = extreme(contour, by: { $0.x }, maximum: false)
        let contourRight = extreme(contour, by: { $0.x }, maximum: true)
        let chinPoint = extreme(contour, by: { $0.y }, maximum: false)
        let foreheadPoint = extreme(medianLine, by: { $0.y }, maximum: true)

        guard let chin = chinPoint,
              let forehead = foreheadPoint,
              let cheekLeft = contourLeft,
              let cheekRight = contourRight else {
            let fallback = simd_float3(0, 0, 0)
            let landmarksFallback = CanonicalLandmarks(
                chin: fallback, jawLowerLeft: fallback, jawLowerRight: fallback,
                eyeOuterLeft: fallback, eyeInnerLeft: fallback,
                eyeOuterRight: fallback, eyeInnerRight: fallback,
                browLeft: fallback, browRight: fallback,
                noseTip: fallback, noseBottom: fallback,
                mouthLeft: fallback, mouthRight: fallback,
                lipTop: fallback, lipBottom: fallback,
                foreheadTop: fallback, cheekLeft: fallback, cheekRight: fallback,
                gonionLeft: fallback, gonionRight: fallback, nasion: fallback
            )
            return (landmarksFallback, [], [], [])
        }

        func eyeCorners(_ region: [simd_float3]) -> (outer: simd_float3, inner: simd_float3)? {
            guard let leftmost = extreme(region, by: { $0.x }, maximum: false),
                  let rightmost = extreme(region, by: { $0.x }, maximum: true) else { return nil }
            return (leftmost, rightmost)
        }

        let leftCorners = eyeCorners(leftEyeRegion)
        let rightCorners = eyeCorners(rightEyeRegion)
        let leftBrow = extreme(leftBrowRegion, by: { $0.y }, maximum: true)
        let rightBrow = extreme(rightBrowRegion, by: { $0.y }, maximum: true)
        let mouthLeft = extreme(outerLips, by: { $0.x }, maximum: false)
        let mouthRight = extreme(outerLips, by: { $0.x }, maximum: true)
        let lipTop = extreme(outerLips, by: { $0.y }, maximum: true)
        let lipBottom = extreme(outerLips, by: { $0.y }, maximum: false)
        let noseBottom = extreme(noseRegion, by: { $0.y }, maximum: false)
        let noseTip = extreme(noseRegion, by: { $0.y }, maximum: true)

        let faceWidth = simd_distance(cheekLeft, cheekRight)
        let center = (cheekLeft + cheekRight) * 0.5
        let depthScale = faceWidth * 0.30
        func pseudoDepth(_ v: simd_float3) -> Float {
            let dx = (v.x - center.x) / max(faceWidth, 1e-6)
            let dy = (v.y - center.y) / max(faceWidth, 1e-6)
            return depthScale * max(0, 1 - dx * dx - dy * dy)
        }
        func withDepth(_ v: simd_float3) -> simd_float3 {
            simd_float3(v.x, v.y, pseudoDepth(v))
        }

        var leftEyeOuter = leftCorners?.outer ?? cheekLeft
        var leftEyeInner = leftCorners?.inner ?? cheekLeft
        var rightEyeOuter = rightCorners?.outer ?? cheekRight
        var rightEyeInner = rightCorners?.inner ?? cheekRight
        if leftEyeInner.x > rightEyeInner.x {
            swap(&leftEyeOuter, &rightEyeOuter)
            swap(&leftEyeInner, &rightEyeInner)
        }
        var browLeftPoint = leftBrow ?? forehead
        var browRightPoint = rightBrow ?? forehead
        if browLeftPoint.x > browRightPoint.x {
            swap(&browLeftPoint, &browRightPoint)
        }

        let gonionLeft = cheekLeft
        let gonionRight = cheekRight
        let browMidpointForNasion = (browLeftPoint + browRightPoint) * 0.5
        let nasionPoint = medianLine.min { a, b in
            simd_distance(a, browMidpointForNasion) < simd_distance(b, browMidpointForNasion)
        } ?? forehead
        let canonical = CanonicalLandmarks(
            chin: withDepth(chin),
            jawLowerLeft: withDepth(contourMiddle(contour, from: cheekLeft, to: chin) ?? chin),
            jawLowerRight: withDepth(contourMiddle(contour, from: chin, to: cheekRight) ?? chin),
            eyeOuterLeft: withDepth(leftEyeOuter),
            eyeInnerLeft: withDepth(leftEyeInner),
            eyeOuterRight: withDepth(rightEyeOuter),
            eyeInnerRight: withDepth(rightEyeInner),
            browLeft: withDepth(browLeftPoint),
            browRight: withDepth(browRightPoint),
            noseTip: withDepth(noseTip ?? chin),
            noseBottom: withDepth(noseBottom ?? chin),
            mouthLeft: withDepth(mouthLeft ?? chin),
            mouthRight: withDepth(mouthRight ?? chin),
            lipTop: withDepth(lipTop ?? chin),
            lipBottom: withDepth(lipBottom ?? chin),
            foreheadTop: withDepth(forehead),
            cheekLeft: withDepth(cheekLeft),
            cheekRight: withDepth(cheekRight),
            gonionLeft: withDepth(gonionLeft),
            gonionRight: withDepth(gonionRight),
            nasion: withDepth(nasionPoint)
        )

        let arcLeft = contour.filter { $0.x <= chin.x && $0.y <= (forehead.y + chin.y) * 0.5 }.map(withDepth)
        let arcRight = contour.filter { $0.x >= chin.x && $0.y <= (forehead.y + chin.y) * 0.5 }.map(withDepth)
        let cloud = (contour + medianLine + leftEyeRegion + rightEyeRegion + leftBrowRegion + rightBrowRegion + noseRegion + outerLips).map(withDepth)
        return (canonical, arcLeft, arcRight, cloud)
    }

    private static func contourMiddle(_ points: [simd_float3], from: simd_float3, to: simd_float3) -> simd_float3? {
        guard !points.isEmpty else { return nil }
        let midpoint = (from + to) * 0.5
        return points.min { simd_distance($0, midpoint) < simd_distance($1, midpoint) }
    }
}
