import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.jsBase.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    valuePage.tag(0)
                    privacyPage.tag(1)
                    cameraPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            Button("Skip") { onComplete() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.trailing, 20)
                .padding(.top, 8)
                .accessibilityLabel("Skip onboarding")
        }
        .preferredColorScheme(.dark)
    }

    private var valuePage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("Your face, measured honestly.")
                .font(.title.weight(.heavy))
                .multilineTextAlignment(.center)
            Text("A deterministic geometry engine scores your scan the same way every time — then turns it into a plan that actually tracks.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var privacyPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "lock.iphone")
                .font(.system(size: 64))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("3D scan, on-device.")
                .font(.title.weight(.heavy))
                .multilineTextAlignment(.center)
            Text("Your face never leaves your phone. No account, no upload — scoring runs entirely on your device.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var cameraPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("The 3D scan happens only on your phone.")
                .font(.title3.weight(.heavy))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("You will see the camera permission next. Frames are used for the scan and then discarded.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                onComplete()
            } label: {
                Text("SCAN MY FACE")
                    .font(.title3.weight(.heavy))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jsTeal)
            .foregroundStyle(.black)
            .padding(.horizontal, 28)
            .accessibilityLabel("Scan my face, continue to camera permission")
            Spacer()
        }
    }
}
