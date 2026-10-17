import SwiftUI

@Observable
@MainActor
final class AdManager {
    var isAdFree = false
    private var interstitialReady = false
    private var ordersSinceLastAd = 0

    func configure() {}

    func loadInterstitial() {
        guard !isAdFree else { return }
        interstitialReady = true
    }

    func onOrderCompleted() {
        guard !isAdFree else { return }
        ordersSinceLastAd += 1
        if ordersSinceLastAd >= 3 {
            showInterstitial()
            ordersSinceLastAd = 0
        }
    }

    private func showInterstitial() {
        // AdMob interstitial will be shown here when SDK is integrated
        // GADInterstitialAd.load → present
        interstitialReady = false
        loadInterstitial()
    }
}

struct BannerAdView: View {
    var body: some View {
        // Placeholder — replace with GADBannerView when AdMob SDK is integrated
        ZStack {
            Color(.systemGray6)
            Text("Reklam Alanı")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 50)
    }
}
