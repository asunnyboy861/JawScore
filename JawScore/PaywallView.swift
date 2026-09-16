import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var purchasingProductID: String?
    @State private var message: String?
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    productCards
                    legalSection
                }
                .padding(16)
                .appContentWidth()
                .frame(maxWidth: .infinity)
            }
            .background(Color.jsBase.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("JawScore Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.jsTeal)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Color.jsTeal)
                .accessibilityHidden(true)
            Text("Unlimited scans, trends, no watermark")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Every price is shown up front. No per-scan charges inside any paid tier.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var productCards: some View {
        if purchaseManager.products.isEmpty {
            VStack(spacing: 10) {
                Text(purchaseManager.hasLoadedProducts ? "Products could not be loaded. Check your connection and try Restore." : "Loading products…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if purchaseManager.hasLoadedProducts {
                    restoreButton
                }
            }
            .padding(16)
            .jsCard()
        } else {
            ForEach(purchaseManager.products, id: \.id) { product in
                productCard(product)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isAnnual = product.id == PurchaseManager.annualID
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.headline)
                        if isAnnual {
                            Text("Best value")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.jsOrangeSoft, in: Capsule())
                                .foregroundStyle(Color.jsOrange)
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.jsTeal)
            }
            trialHint(for: product)
            Button {
                Task { await purchase(product) }
            } label: {
                if purchasingProductID == product.id {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Text(purchaseManager.isPro && product.type != .nonConsumable ? "Current plan" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isAnnual ? Color.jsOrange : Color.jsTeal)
            .foregroundStyle(.black)
            .disabled(purchasingProductID != nil)
            .accessibilityLabel("Purchase \(product.displayName) for \(product.displayPrice)")
        }
        .padding(16)
        .jsCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isAnnual ? Color.jsOrange.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func trialHint(for product: Product) -> some View {
        if product.id == PurchaseManager.monthlyID || product.id == PurchaseManager.annualID {
            Text("7-day free trial, then \(product.displayPrice) per period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if product.id == PurchaseManager.lifetimeID {
            Text("Buy once. Pro forever.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if product.id == PurchaseManager.byoID {
            Text("Use your own DeepSeek API key for deep analysis. Pro features not included.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var legalSection: some View {
        VStack(spacing: 10) {
            restoreButton
            Text("Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Cancel anytime in Settings → Apple ID → Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 18) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/JawScore/privacy.html")!)
                    .font(.footnote.weight(.semibold))
                Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/JawScore/terms.html")!)
                    .font(.footnote.weight(.semibold))
            }
            .tint(Color.jsTeal)
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.jsOrange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 4)
    }

    private var restoreButton: some View {
        Button {
            Task { await restore() }
        } label: {
            if isRestoring {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Restore Purchases")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .tint(Color.jsTeal)
        .disabled(isRestoring)
        .accessibilityLabel("Restore purchases")
    }

    private func purchase(_ product: Product) async {
        purchasingProductID = product.id
        message = nil
        defer { purchasingProductID = nil }
        do {
            let succeeded = try await purchaseManager.purchase(product)
            if succeeded {
                dismiss()
            } else {
                message = "Purchase did not complete. You were not charged."
            }
        } catch {
            message = "Purchase did not complete. Please try again."
        }
    }

    private func restore() async {
        isRestoring = true
        message = nil
        defer { isRestoring = false }
        do {
            try await purchaseManager.restorePurchases()
            message = purchaseManager.isPro ? "Pro restored." : "Nothing to restore yet."
        } catch {
            message = "Restore did not complete. Please try again."
        }
    }
}
