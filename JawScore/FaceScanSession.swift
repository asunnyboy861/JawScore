import ARKit
import AVFoundation
import Combine
import CoreImage
import Foundation
import RealityKit
import simd
import UIKit

@MainActor
protocol FaceMeshRendering: AnyObject {
    func updateMesh(vertices: [simd_float3], indices: [UInt32], transform: simd_float4x4)
}

nonisolated enum PixelStatsCalculator {
    static func neutral() -> SkinPixelStats {
        SkinPixelStats(brightnessMean: 0, brightnessVariance: 0, textureUniformity: 0)
    }

    static func compute(from pixelBuffer: CVPixelBuffer) -> SkinPixelStats {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return neutral() }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        guard width > 0, height > 0 else { return neutral() }
        let buffer = base.assumingMemoryBound(to: UInt8.self)
        let step = max(1, min(width, height) / 64)
        var values: [Double] = []
        values.reserveCapacity((width / step + 1) * (height / step + 1))
        var row = 0
        while row < height {
            var col = 0
            while col < width {
                values.append(Double(buffer[row * bytesPerRow + col]) / 255.0)
                col += step
            }
            row += step
        }
        guard !values.isEmpty else { return neutral() }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        var diffs: [Double] = []
        row = 0
        while row < height {
            var col = 0
            while col + step < width {
                let a = Double(buffer[row * bytesPerRow + col]) / 255.0
                let b = Double(buffer[row * bytesPerRow + col + step]) / 255.0
                diffs.append(abs(a - b))
                col += step * 2
            }
            row += step
        }
        let meanDiff = diffs.isEmpty ? 0 : diffs.reduce(0, +) / Double(diffs.count)
        let uniformity = max(0, min(1, 1 - meanDiff * 6))
        return SkinPixelStats(brightnessMean: mean, brightnessVariance: variance, textureUniformity: uniformity)
    }

    static func compute(from cgImage: CGImage) -> SkinPixelStats {
        let size = 96
        var pixels = [UInt8](repeating: 0, count: size * size)
        let stats: SkinPixelStats? = pixels.withUnsafeMutableBytes { raw -> SkinPixelStats? in
            guard let base = raw.baseAddress else { return nil }
            guard let context = CGContext(
                data: base,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: size,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return nil }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
            let buffer = base.assumingMemoryBound(to: UInt8.self)
            var values: [Double] = []
            var diffs: [Double] = []
            let step = 2
            var row = 0
            while row < size {
                var col = 0
                while col < size {
                    values.append(Double(buffer[row * size + col]) / 255.0)
                    if col + step < size {
                        diffs.append(abs(Double(buffer[row * size + col]) - Double(buffer[row * size + col + step])) / 255.0)
                    }
                    col += step
                }
                row += step
            }
            guard !values.isEmpty else { return nil }
            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
            let meanDiff = diffs.isEmpty ? 0 : diffs.reduce(0, +) / Double(diffs.count)
            let uniformity = max(0, min(1, 1 - meanDiff * 6))
            return SkinPixelStats(brightnessMean: mean, brightnessVariance: variance, textureUniformity: uniformity)
        }
        return stats ?? neutral()
    }
}

@MainActor
final class FaceScanSession: NSObject, ObservableObject {
    @Published var quality = CaptureQualitySample(distanceMeters: 0, ambientLux: 0, poseDeviationDegrees: 0)
    @Published var isTracking = false
    @Published var capturedMeasurement: FaceMeasurement?
    @Published var capturedQuality = 0
    @Published var capturedPreview: UIImage?
    @Published var cameraDenied = false

    weak var meshRenderer: FaceMeshRendering?

    private weak var arSession: ARSession?
    private var bestVertices: [simd_float3] = []
    private var bestIndices: [UInt32] = []
    private var bestTransform = matrix_identity_float4x4
    private var bestPixelStats = PixelStatsCalculator.neutral()
    private var bestQuality: CaptureQualitySample?
    private var hasAutoCaptured = false
    private var captureDeadline: Date?

    var supportsFaceTracking: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    static var cameraPermissionDenied: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .denied || status == .restricted
    }

    func attach(_ session: ARSession) {
        arSession = session
        session.delegate = self
    }

    func start() {
        guard supportsFaceTracking, let session = arSession else { return }
        if Self.cameraPermissionDenied {
            cameraDenied = true
            return
        }
        cameraDenied = false
        reset()
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        arSession?.pause()
        isTracking = false
    }

    func reset() {
        bestVertices = []
        bestIndices = []
        bestTransform = matrix_identity_float4x4
        bestPixelStats = PixelStatsCalculator.neutral()
        bestQuality = nil
        hasAutoCaptured = false
        captureDeadline = nil
        capturedMeasurement = nil
        capturedQuality = 0
        capturedPreview = nil
    }

    func captureMeasurement() -> (FaceMeasurement, Int)? {
        guard let sample = bestQuality, !bestVertices.isEmpty else { return nil }
        let measurement = GeometryExtractor.extract(
            vertices: bestVertices,
            pixelStats: bestPixelStats,
            quality: sample
        )
        return (measurement, Int(sample.total.rounded()))
    }
}

extension FaceScanSession: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        let vertices = faceAnchor.geometry.vertices
        let indices = faceAnchor.geometry.triangleIndices.map { UInt32(max(0, $0)) }
        let transform = faceAnchor.transform
        let pixelStats = PixelStatsCalculator.compute(from: frame.capturedImage)
        let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
        let facePosition = simd_make_float3(faceAnchor.transform.columns.3)
        let distance = Double(simd_distance(cameraPosition, facePosition))
        let lux = Double(frame.lightEstimate?.ambientIntensity ?? 0)

        let faceNormal = simd_make_float3(faceAnchor.transform.columns.2)
        let yaw = abs(atan2(faceNormal.x, max(abs(faceNormal.z), 1e-6)))
        let pitch = abs(asin(max(-1, min(1, -faceNormal.y))))
        let poseDeviation = Double(max(yaw, pitch)) * 180.0 / Double.pi
        let sample = CaptureQualitySample(
            distanceMeters: distance,
            ambientLux: lux,
            poseDeviationDegrees: poseDeviation
        )

        Task { @MainActor in
            self.isTracking = true
            self.quality = sample
            self.meshRenderer?.updateMesh(vertices: vertices, indices: indices, transform: transform)
            if self.bestQuality == nil || sample.total > self.bestQuality!.total {
                self.bestVertices = vertices
                self.bestIndices = indices
                self.bestTransform = transform
                self.bestPixelStats = pixelStats
                self.bestQuality = sample
            }
            guard !self.hasAutoCaptured else { return }
            if let deadline = self.captureDeadline {
                if Date() >= deadline {
                    if self.bestQuality?.total ?? 0 >= AestheticConstants.qualityAutoCaptureThreshold {
                        self.finalizeCapture(previewBuffer: frame.capturedImage)
                        if self.capturedMeasurement != nil {
                            self.hasAutoCaptured = true
                        } else {
                            self.captureDeadline = Date().addingTimeInterval(AestheticConstants.qualityCaptureWindowSeconds)
                        }
                    } else {
                        self.captureDeadline = nil
                    }
                }
            } else if sample.total >= AestheticConstants.qualityAutoCaptureThreshold {
                self.captureDeadline = Date().addingTimeInterval(AestheticConstants.qualityCaptureWindowSeconds)
            }
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.isTracking = false
            if let arError = error as? ARError, arError.code == .cameraUnauthorized {
                self.cameraDenied = true
            }
        }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in
            self.isTracking = false
        }
    }

    private func finalizeCapture(previewBuffer: CVPixelBuffer) {
        guard let (measurement, quality) = captureMeasurement() else {
            hasAutoCaptured = false
            return
        }
        let ciImage = CIImage(cvPixelBuffer: previewBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            capturedPreview = UIImage(cgImage: cgImage)
        }
        capturedMeasurement = measurement
        capturedQuality = quality
    }
}
