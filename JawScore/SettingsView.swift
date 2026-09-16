import SwiftUI

struct SettingsView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @AppStorage(AppSettings.numbersOffKey) private var numbersOff = false
    @AppStorage(AppSettings.breakUntilKey) private var breakUntilTimestamp = 0.0
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var keySavedMessage: String?
    @State private var showPaywall = false
    @State private var restoreMessage: String?
    @State private var isRestoring = false

    private var isOnBreak: Bool {
        breakUntilTimestamp > Date().timeIntervalSince1970
    }

    var body: some View {
        List {
            proSection
            displaySection
            breakSection
            byoSection
            legalSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.jsBase)
        .preferredColorScheme(.dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiKey = KeychainHelper.readBYOKey() ?? ""
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var proSection: some View {
        Section("Pro") {
            HStack {
                Text("JawScore Pro")
                Spacer()
                Text(purchaseManager.isPro ? "Active" : "Not active")
                    .foregroundStyle(purchaseManager.isPro ? Color.jsTeal : .secondary)
            }
            .accessibilityElement(children: .combine)
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Text(purchaseManager.isPro ? "Manage plan" : "Upgrade")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.jsTeal)
            .accessibilityLabel("Upgrade or manage Pro")
            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Text("Restore Purchases")
                    Spacer()
                    if isRestoring {
                        ProgressView()
                    }
                }
            }
            .tint(Color.jsTeal)
            if let restoreMessage {
                Text(restoreMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var displaySection: some View {
        Section {
            Toggle("Numbers Off", isOn: $numbersOff)
                .tint(Color.jsTeal)
                .accessibilityLabel("Numbers Off hides all scores and shows trend arrows instead")
        } footer: {
            Text("Hides every score and shows trend arrows instead.")
        }
    }

    private var breakSection: some View {
        Section {
            if isOnBreak {
                HStack {
                    Text("Break until \(AppSettings.breakUntilDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                    Spacer()
                    Button("End break") {
                        AppSettings.endBreak()
                        breakUntilTimestamp = 0
                    }
                    .foregroundStyle(Color.jsTeal)
                    .accessibilityLabel("End break early")
                }
            } else {
                Button {
                    AppSettings.startBreak()
                    breakUntilTimestamp = AppSettings.breakUntilDate?.timeIntervalSince1970 ?? 0
                } label: {
                    Text("Take a Break")
                        .foregroundStyle(Color.jsOrange)
                }
                .accessibilityLabel("Take a 30 day break from scanning")
            }
        } footer: {
            Text("Scan and results hide for 30 days. The app returns on its own — no data is deleted.")
        }
    }

    private var byoSection: some View {
        Section {
            HStack {
                Text("BYO AI Unlock")
                Spacer()
                Text(purchaseManager.byoUnlocked ? "Unlocked" : "Not unlocked")
                    .foregroundStyle(purchaseManager.byoUnlocked ? Color.jsTeal : .secondary)
            }
            .accessibilityElement(children: .combine)
            if !purchaseManager.byoUnlocked {
                Button("Unlock with your own key plan") {
                    showPaywall = true
                }
                .tint(Color.jsTeal)
            } else {
                SecureField("DeepSeek API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("DeepSeek API key")
                Button("Save key") {
                    let saved = KeychainHelper.saveBYOKey(apiKey.trimmingCharacters(in: .whitespaces))
                    keySavedMessage = saved ? "Key stored in Keychain." : "Could not store the key."
                }
                .tint(Color.jsTeal)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Delete key", role: .destructive) {
                    KeychainHelper.deleteBYOKey()
                    apiKey = ""
                    keySavedMessage = "Key removed."
                }
                .foregroundStyle(Color.jsOrange)
                if let keySavedMessage {
                    Text(keySavedMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("BYO AI")
        } footer: {
            Text("Deep mode requires confirmation each time. Your key stays in the Keychain and the app is fully functional without it.")
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: URL(string: "https://asunnyboy861.github.io/JawScore/support.html")!) {
                Label("Support", systemImage: "questionmark.circle")
            }
            .tint(Color.jsTeal)
            Link(destination: URL(string: "https://asunnyboy861.github.io/JawScore/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .tint(Color.jsTeal)
            Link(destination: URL(string: "https://asunnyboy861.github.io/JawScore/terms.html")!) {
                Label("Terms of Use", systemImage: "doc.text")
            }
            .tint(Color.jsTeal)
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            .tint(Color.jsTeal)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(versionText)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            DisclaimerFooter()
                .listRowBackground(Color.clear)
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await purchaseManager.restorePurchases()
            restoreMessage = purchaseManager.isPro ? "Pro restored." : "Nothing to restore yet."
        } catch {
            restoreMessage = "Restore did not complete. Please try again."
        }
    }
}
