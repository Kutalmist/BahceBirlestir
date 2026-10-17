import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Satın Alımlar") {
                    if storeManager.isLoading {
                        ProgressView("Yükleniyor...")
                    } else if storeManager.products.isEmpty {
                        Text("Ürün bulunamadı")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(storeManager.products, id: \.id) { product in
                            ProductRow(product: product)
                        }
                    }
                }

                Section {
                    Button("Satın Alımları Geri Yükle") {
                        Task { await storeManager.restorePurchases() }
                    }
                }
            }
            .navigationTitle("Mağaza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    @Environment(StoreManager.self) private var storeManager
    @Environment(GameState.self) private var gameState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .fontWeight(.semibold)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if storeManager.purchasedProductIDs.contains(product.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(product.displayPrice) {
                    Task {
                        let success = await storeManager.purchase(product)
                        if success {
                            handlePurchase(product.id)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private func handlePurchase(_ productID: String) {
        switch productID {
        case StoreManager.energy50ID:
            gameState.addEnergy(50)
        case StoreManager.energy200ID:
            gameState.addEnergy(200)
        case StoreManager.gold500ID:
            gameState.addGold(500)
        default:
            break
        }
    }
}
