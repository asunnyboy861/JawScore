import Combine
import PhotosUI
import RealityKit
import ARKit
import SwiftUI
import SwiftData

@MainActor
final class ScanViewModel: ObservableObject {
    enum Phase {
        case idle
        case scanning
        case decoding(FaceMeasurement, Int)
        case results(ScoreRecord)
        case limitReached
    }

    @Published var phase: Phase = .idle
    @Published var isPro = false
    @Published var showPaywall = false
    @Published var photoError: String?
    @Published var isProcessingPhoto = false
    @Published var lastCapturedImage: UIImage?
    @Published var manualPhotoMode = false

    let session = FaceScanSession()
    private let purchaseManager = PurchaseManager.shared

    init() {
        purchaseManager.$isPro.assign(to: &$isPro)
    }

    var usesAR: Bool {
        session.supportsFaceTracking
    }

    var showsNavigationBar: Bool {
        switch phase {
        case .idle, .limitReached:
            return true
        default:
            return false
        }
    }

    func beginScan() {
        photoError = nil
        manualPhotoMode = false
        guard FreeScanCounter.canScan(isPro: isPro) else {
            phase = .limitReached
            return
        }
        Task { await NotificationService.requestAuthorizationIfNeeded() }
        if usesAR {
            session.reset()
            session.start()
            phase = .scanning
        } else {
            phase = .scanning
        }
    }

    func startPhotoMode() {
        photoError = nil
        guard FreeScanCounter.canScan(isPro: isPro) else {
            phase = .limitReached
            return
        }
        session.stop()
        manualPhotoMode = true
        phase = .scanning
    }

    func handleCapture(_ measurement: FaceMeasurement, quality: Int) {
        session.stop()
        lastCapturedImage = session.capturedPreview
        FreeScanCounter.recordScan()
        Task { await NotificationService.scheduleWeeklyRescan() }
        phase = .decoding(measurement, quality)
    }

    func completeDecoding(_ measurement: FaceMeasurement, quality: Int, context: ModelContext) {
        let record = ScoreRecord.create(from: measurement, quality: quality)
        context.insert(record)
        phase = .results(record)
    }

    func processPhoto(_ item: PhotosPickerItem) {
        isProcessingPhoto = true
        photoError = nil
        Task {
            defer { isProcessingPhoto = false }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoError = "That photo could not be opened. Try another one."
                return
            }
            do {
                let outcome = try await Task.detached(priority: .userInitiated) {
                    try PhotoScanService.process(image: image)
                }.value
                lastCapturedImage = outcome.image
                FreeScanCounter.recordScan()
                Task { await NotificationService.scheduleWeeklyRescan() }
                phase = .decoding(outcome.measurement, outcome.quality)
            } catch {
                photoError = error.localizedDescription
            }
        }
    }

    func backToIdle() {
        session.stop()
        manualPhotoMode = false
        phase = .idle
    }
}

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ScanViewModel()
    @EnvironmentObject private var router: TabRouter
    @AppStorage(AppSettings.numbersOffKey) private var numbersOff = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.phase {
                case .idle:
                    idleStage
                case .scanning:
                    if viewModel.usesAR && !viewModel.manualPhotoMode {
                        ARScanStage(
                            session: viewModel.session,
                            onCancel: { viewModel.backToIdle() },
                            onPhotoFallback: { viewModel.startPhotoMode() }
                        )
                        .onReceive(viewModel.session.$capturedMeasurement) { measurement in
                            if let measurement {
                                viewModel.handleCapture(measurement, quality: viewModel.session.capturedQuality)
                            }
                        }
                    } else {
                        photoStage
                    }
                case .decoding(let measurement, let quality):
                    DecodingView(measurement: measurement, quality: quality, numbersOff: numbersOff) {
                        viewModel.completeDecoding(measurement, quality: quality, context: modelContext)
                    }
                case .results(let record):
                    ResultsView(record: record, capturedImage: viewModel.lastCapturedImage) {
                        viewModel.backToIdle()
                    }
                case .limitReached:
                    limitStage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.jsBase.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar(viewModel.showsNavigationBar ? .visible : .hidden, for: .navigationBar)
            .navigationTitle(viewModel.showsNavigationBar ? "Scan" : "")
        }
    }

    private var idleStage: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: viewModel.usesAR ? "faceid" : "photo.on.rectangle.angled")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.jsTeal)
                        .accessibilityHidden(true)
                    Text("Your 3D scan, on-device")
                        .font(.title2.weight(.bold))
                    Text(viewModel.usesAR
                        ? "Hold your phone at eye level. The scan finishes in seconds and your face never leaves your phone."
                        : "This device has no depth camera, so photo mode will read your features from a portrait.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                Button {
                    viewModel.beginScan()
                } label: {
                    Text("Start Scan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.jsTeal)
                .foregroundStyle(.black)
                .accessibilityLabel("Start face scan")

                Button {
                    viewModel.startPhotoMode()
                } label: {
                    Label("Import Photo", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(Color.jsTeal)
                .accessibilityLabel("Import a portrait photo instead")

                Text("1 free full scan every day. Scoring runs entirely on your device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .appContentWidth()
            .frame(maxWidth: .infinity)
        }
    }

    private var photoStage: some View {
        VStack(spacing: 20) {
            Text("Photo Scan")
                .font(.title2.weight(.bold))
            Text("Pick a bright, front-facing portrait. Your photo is analyzed on-device and never uploaded.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if viewModel.isProcessingPhoto {
                ProgressView()
                    .padding()
            } else {
                PhotoPickerButton { item in
                    viewModel.processPhoto(item)
                }
                .padding(.horizontal, 20)
            }
            if let error = viewModel.photoError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.jsOrange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            Button("Back") { viewModel.backToIdle() }
                .foregroundStyle(Color.jsTeal)
                .padding(.bottom, 16)
        }
        .appContentWidth()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var limitStage: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(Color.jsOrange)
                .accessibilityHidden(true)
            Text("That was your free scan for today")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Unlimited scans, trends, and no watermark with Pro. Your free scan returns at midnight.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Button {
                viewModel.showPaywall = true
            } label: {
                Text("See Pro")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jsTeal)
            .foregroundStyle(.black)
            .accessibilityLabel("See Pro upgrade options")
            Button("Maybe later") { viewModel.backToIdle() }
                .foregroundStyle(Color.jsTeal)
            Spacer()
        }
        .padding(20)
        .appContentWidth()
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
    }
}

struct PhotoPickerButton: View {
    let onPick: (PhotosPickerItem) -> Void
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            Text("Choose a Portrait")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.jsTeal)
        .foregroundStyle(.black)
        .accessibilityLabel("Choose a portrait photo")
        .onChange(of: selection) { _, newValue in
            if let newValue {
                onPick(newValue)
                selection = nil
            }
        }
    }
}

struct ARScanStage: View {
    @ObservedObject var session: FaceScanSession
    let onCancel: () -> Void
    let onPhotoFallback: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            ARViewContainer(session: session)
                .ignoresSafeArea()
            VStack {
                ProgressRingView(progress: session.quality.total / 100)
                    .frame(width: 92, height: 92)
                    .padding(.top, 12)
                    .accessibilityLabel("Capture quality")
                    .accessibilityValue("\(Int(session.quality.total)) percent")
                Spacer()
                if session.cameraDenied {
                    deniedCard
                        .padding(.bottom, 28)
                } else {
                    GuidanceOverlay(sample: session.quality)
                        .padding(.bottom, 28)
                }
                Button("Cancel", action: onCancel)
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)
                    .accessibilityLabel("Cancel scan")
            }
        }
        .onAppear {
            session.start()
        }
        .onDisappear {
            session.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                session.start()
            default:
                session.stop()
            }
        }
    }

    private var deniedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color.jsOrange)
                .accessibilityHidden(true)
            Text("Camera access is off")
                .font(.headline)
            Text("JawScore needs the camera for the 3D scan. Enable it in Settings, or import a portrait photo instead — everything stays on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jsTeal)
            .foregroundStyle(.black)
            .accessibilityLabel("Open Settings to enable the camera")
            Button("Import a Photo Instead", action: onPhotoFallback)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.jsTeal)
                .accessibilityLabel("Import a portrait photo instead")
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 24)
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var session: FaceScanSession

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        session.attach(arView.session)
        session.meshRenderer = context.coordinator
        context.coordinator.arView = arView
        session.start()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, FaceMeshRendering {
        weak var arView: ARView?
        private var meshEntity: ModelEntity?
        private var anchorEntity: AnchorEntity?

        func updateMesh(vertices: [simd_float3], indices: [UInt32], transform: simd_float4x4) {
            guard #available(iOS 18.0, *) else { return }
            guard let arView else { return }
            var descriptor = MeshDescriptor(name: "faceMesh")
            descriptor.positions = MeshBuffers.Positions(vertices)
            descriptor.primitives = .triangles(indices)
            Task { @MainActor in
                guard let mesh = try? await MeshResource(from: [descriptor]) else { return }
                if let entity = self.meshEntity {
                    entity.model?.mesh = mesh
                } else {
                    let entity = ModelEntity(mesh: mesh)
                    let material = SimpleMaterial(color: UIColor(Color.jsTeal), isMetallic: false)
                    entity.model?.materials = [material]
                    entity.components.set(OpacityComponent(opacity: 0.35))
                    let anchor = AnchorEntity(world: matrix_identity_float4x4)
                    anchor.addChild(entity)
                    arView.scene.addAnchor(anchor)
                    self.meshEntity = entity
                    self.anchorEntity = anchor
                }
                self.meshEntity?.transform = Transform(matrix: transform)
            }
        }
    }
}

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.jsTeal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
            Image(systemName: "faceid")
                .font(.title3)
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
        }
    }
}

struct GuidanceOverlay: View {
    let sample: CaptureQualitySample

    var body: some View {
        VStack(spacing: 8) {
            if sample.needsCloser {
                guidanceChip(icon: "plus.magnifyingglass", text: "Move closer")
            }
            if sample.needsLight {
                guidanceChip(icon: "sun.max.fill", text: "Add light")
            }
            if sample.needsCentering {
                guidanceChip(icon: "viewfinder", text: "Center your face")
            }
            if !sample.needsCloser && !sample.needsLight && !sample.needsCentering {
                guidanceChip(icon: "checkmark.seal.fill", text: "Hold steady")
            }
        }
    }

    private func guidanceChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}
