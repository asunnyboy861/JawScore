import SwiftUI

/// In-app disclosure of how JawScore processes face data, including the
/// ARKit TrueDepth face-tracking API. Required for App Review transparency.
struct FaceDataPrivacyView: View {
    private let privacyURL = URL(string: "https://asunnyboy861.github.io/JawScore/privacy.html")!

    var body: some View {
        List {
            summarySection
            collectedSection
            trueDepthSection
            storageSection
            sharingSection
            deletionSection
            linksSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.jsBase)
        .preferredColorScheme(.dark)
        .navigationTitle("Face Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your face stays on your device.")
                    .font(.headline)
                    .foregroundStyle(Color.jsTeal)
                Text("JawScore has no accounts, no servers, and no analytics. Scoring runs entirely on your phone, and history is stored only in the app's local database.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.jsSurface)
    }

    private var collectedSection: some View {
        Section("What JawScore processes") {
            bullet("48 numerical geometry measurements (distances, ratios, angles, symmetry)")
            bullet("A capture-quality value (lighting and framing)")
            bullet("Your overall score, confidence band, and 8 dimension scores")
            Text("These numbers are the only face-related data that persists.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.jsSurface)
    }

    private var trueDepthSection: some View {
        Section {
            Text("On devices with a TrueDepth camera, JawScore uses Apple's ARKit face tracking (ARFaceTrackingConfiguration). While the scan screen is open, ARKit supplies:")
                .font(.subheadline)
            bullet("A 3D face mesh of about 1,220 vertices")
            bullet("The current camera frame, read only to estimate brightness and texture")
            bullet("Face and camera position, used only for distance and head tilt")
            bullet("An ambient light estimate")
            Text("All of it is processed in real time and in memory. The app keeps at most the best frame of the current scan, then releases the mesh, frames, and pixel buffers when the scan ends. Nothing is written to disk or to a server, and no face template or faceprint is created. The TrueDepth API is not used for facial recognition, authentication, or advertising.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("TrueDepth API")
        }
        .listRowBackground(Color.jsSurface)
    }

    private var storageSection: some View {
        Section {
            Text("Only the numerical measurements and scores are stored, in the app's local database (SwiftData) inside the app sandbox on your device. There is no cloud sync and no developer-side storage.")
                .font(.subheadline)
            Text("Retention: there is no fixed period. A scan record is kept until you delete it, until you use Take a Break, or until you uninstall the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Storage & Retention")
        }
        .listRowBackground(Color.jsSurface)
    }

    private var sharingSection: some View {
        Section {
            Text("By default, face data never leaves your device, and it is never sold or shared. Apple's ARKit and Vision frameworks run on-device; the developer never receives your data.")
                .font(.subheadline)
            Text("One optional exception: if you unlock Deep Analysis, enter your own DeepSeek API key, and confirm the per-request dialog, one preview photo is sent directly from your device to api.deepseek.com. The app has no server and keeps no copy. DeepSeek's handling is governed by DeepSeek's privacy policy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Sharing")
        }
        .listRowBackground(Color.jsSurface)
    }

    private var deletionSection: some View {
        Section {
            Text("Swipe to delete a scan in Trends to remove its measurements. Take a Break hides and clears recent results. Uninstalling the app permanently deletes all locally stored data.")
                .font(.subheadline)
        } header: {
            Text("Delete Your Data")
        }
        .listRowBackground(Color.jsSurface)
    }

    private var linksSection: some View {
        Section {
            Link(destination: privacyURL) {
                Label("Full Privacy Policy", systemImage: "hand.raised")
            }
            .tint(Color.jsTeal)
        } footer: {
            Text("Sections 2, 2.1, 4, 5, 6, and 11 of the Privacy Policy cover face data collection, TrueDepth, storage, retention, sharing, and deletion.")
        }
        .listRowBackground(Color.jsSurface)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(Color.jsTeal)
                .padding(.top, 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
        }
    }
}
