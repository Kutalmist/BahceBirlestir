import StoreKit

@Observable
@MainActor
final class StoreManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    static let removeAdsID = "com.kutican.bahcebirlestir.removeads"
    static let energy50ID = "com.kutican.bahcebirlestir.energy50"
    static let energy200ID = "com.kutican.bahcebirlestir.energy200"
    static let gold500ID = "com.kutican.bahcebirlestir.gold500"

    static let allProductIDs: Set<String> = [
        removeAdsID, energy50ID, energy200ID, gold500ID
    ]

    var isAdFree: Bool {
        purchasedProductIDs.contains(Self.removeAdsID)
    }

    private var updateTask: Task<Void, Never>?

    func start() {
        updateTask = Task {
            await listenForTransactions()
        }
        Task {
            await loadProducts()
            await restorePurchases()
        }
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {}
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                    return true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {}
        return false
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            }
        }
    }
}
