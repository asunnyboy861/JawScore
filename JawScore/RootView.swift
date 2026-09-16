import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.onboardingKey) private var hasCompletedOnboarding = false
    @AppStorage(AppSettings.breakUntilKey) private var breakUntilTimestamp = 0.0
    @StateObject private var router = TabRouter()

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if breakUntilTimestamp > Date().timeIntervalSince1970 {
                TakeBreakView {
                    AppSettings.endBreak()
                    breakUntilTimestamp = 0
                }
            } else {
                MainTabView()
                    .environmentObject(router)
            }
        }
        .tint(Color.jsTeal)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: TabRouter

    var body: some View {
        TabView(selection: $router.selection) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "viewfinder")
                }
                .tag(AppTab.scan)
            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "checklist")
                }
                .tag(AppTab.plan)
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.trends)
        }
        .tint(Color.jsTeal)
    }
}

struct TakeBreakView: View {
    let onEndBreak: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 52))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("Enjoy the break")
                .font(.largeTitle.weight(.bold))
            Text("Scanning and results are resting for a while. Your streak and history are safe, and everything returns automatically.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Text("Your worth ≠ a number")
                .font(.headline)
                .foregroundStyle(Color.jsTeal)
                .padding(.top, 6)
            Spacer()
            Button("End break early", action: onEndBreak)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.jsTeal)
                .padding(.bottom, 24)
                .accessibilityLabel("End break early")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.jsBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
