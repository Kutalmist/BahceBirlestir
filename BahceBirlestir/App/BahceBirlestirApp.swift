import SwiftUI

@main
struct BahceBirlestirApp: App {
    @State private var gameState = GameState()
    @State private var adManager = AdManager()
    @State private var gameCenterManager = GameCenterManager()
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(adManager)
                .environment(gameCenterManager)
                .environment(storeManager)
                .onAppear {
                    if DemoMode.isActive {
                        DemoDataProvider.applyDemoState(to: gameState)
                    }

                    adManager.configure()
                    adManager.loadInterstitial()
                    gameCenterManager.authenticate()
                    storeManager.start()

                    gameState.adManager = adManager
                    gameState.gameCenterManager = gameCenterManager
                    gameState.storeManager = storeManager
                }
                .onChange(of: storeManager.isAdFree) { _, newValue in
                    adManager.isAdFree = newValue
                }
        }
    }
}
