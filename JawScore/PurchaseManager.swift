import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let weeklyID = "com.zzoutuo.JawScore.pro.weekly"
    static let monthlyID = "com.zzoutuo.JawScore.pro.monthly"
    static let annualID = "com.zzoutuo.JawScore.pro.annual"
    static let lifetimeID = "com.zzoutuo.JawScore.pro.lifetime"
    static let byoID = "com.zzoutuo.JawScore.byo.unlock"
    static let proProductIDs = [weeklyID, monthlyID, annualID, lifetimeID]

    @Published var isPro = false
    @Published var byoUnlocked = false
    @Published var products: [Product] = []
    @Published var hasLoadedProducts = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task { await loadProducts() }
    }

    deinit {
        updatesTask?.cancel()
    }

    var allProductIDs: [String] {
        Self.proProductIDs + [Self.byoID]
    }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: allProductIDs)
            products = Self.sortedProducts(fetched)
        } catch {
            products = []
        }
        hasLoadedProducts = true
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var pro = false
        for id in Self.proProductIDs {
            if case .verified(let transaction) = await Transaction.currentEntitlement(for: id),
               transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
        if case .verified(let transaction) = await Transaction.currentEntitlement(for: Self.byoID) {
            byoUnlocked = transaction.revocationDate == nil
        } else {
            byoUnlocked = false
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .unverified:
                await refreshEntitlements()
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    private static func sortedProducts(_ products: [Product]) -> [Product] {
        let order = [annualID, monthlyID, weeklyID, lifetimeID, byoID]
        var byID: [String: Product] = [:]
        for product in products { byID[product.id] = product }
        var ordered: [Product] = []
        for id in order {
            if let product = byID.removeValue(forKey: id) { ordered.append(product) }
        }
        for product in byID.values.sorted(by: { $0.id < $1.id }) {
            ordered.append(product)
        }
        return ordered
    }
}
