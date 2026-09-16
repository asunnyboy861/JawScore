import Foundation
import UIKit

struct DeepSeekCoach: CoachProvider {
    enum DeepSeekError: LocalizedError {
        case missingKey
        case requestFailed

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Add your DeepSeek API key in Settings first."
            case .requestFailed:
                return "DeepSeek did not respond. Check your key and connection."
            }
        }
    }

    static let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    static let modelName = "deepseek-reasoner"

    private static let systemPrompt = """
    You are a supportive grooming coach. Celebrate potential, stay uplifting, and never judge the person. \
    Reply with a compact analysis of the measurements and 3 to 5 concrete next steps.
    """

    func generateAnalysis(measurement: FaceMeasurement, image: UIImage?) async throws -> String {
        guard let key = KeychainHelper.readBYOKey(), !key.isEmpty else {
            throw DeepSeekError.missingKey
        }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        var messages: [[String: Any]] = [
            ["role": "system", "content": Self.systemPrompt],
            ["role": "user", "content": Self.userPrompt(for: measurement)]
        ]
        if let image, let data = image.jpegData(compressionQuality: 0.5) {
            messages.append([
                "role": "user",
                "content": [
                    "type": "text",
                    "text": "This is the captured portrait for the measurements above."
                ]
            ])
            messages[messages.count - 1]["content"] = [
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(data.base64EncodedString())"]
            ]
        }
        let body: [String: Any] = [
            "model": Self.modelName,
            "messages": messages,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.requestFailed
        }
        return content
    }

    func generatePlan(measurement: FaceMeasurement, streak: Int) async throws -> GlowPlanContent {
        guard let key = KeychainHelper.readBYOKey(), !key.isEmpty else {
            throw DeepSeekError.missingKey
        }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": Self.modelName,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": Self.userPrompt(for: measurement) + " Reply as JSON with keys habits, reasons, milestones (each an array of strings; habits at most 4 words, 4 weekly milestones at most 12 words)."]
            ],
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.requestFailed
        }
        guard let contentData = content.data(using: .utf8),
              let plan = try? JSONDecoder().decode(GlowPlanContent.self, from: contentData) else {
            throw DeepSeekError.requestFailed
        }
        return plan
    }

    private static func userPrompt(for measurement: FaceMeasurement) -> String {
        """
        Measurement snapshot: gonial angles \(String(format: "%.1f", measurement.gonialAngleLeftDegrees)) and \(String(format: "%.1f", measurement.gonialAngleRightDegrees)) degrees, \
        chin projection \(String(format: "%.3f", measurement.chinProjectionDepthRatio)), mirror symmetry residual \(String(format: "%.4f", measurement.mirrorSymmetryResidual)), \
        thirds \(String(format: "%.3f", measurement.thirdsUpperRatio)) / \(String(format: "%.3f", measurement.thirdsMiddleRatio)) / \(String(format: "%.3f", measurement.thirdsLowerRatio)), \
        canthal tilt \(String(format: "%.1f", measurement.canthalTiltMeanDegrees)) degrees, skin texture uniformity \(String(format: "%.2f", measurement.skinTextureUniformity)).
        """
    }
}
