import GameKit

@Observable
@MainActor
final class GameCenterManager {
    var isAuthenticated = false

    static let leaderboardGoldID = "com.kutican.bahcebirlestir.gold"
    static let leaderboardMergesID = "com.kutican.bahcebirlestir.merges"

    static let achievementFirstMerge = "com.kutican.bahcebirlestir.first_merge"
    static let achievementOlive6 = "com.kutican.bahcebirlestir.olive_max"
    static let achievementTomato5 = "com.kutican.bahcebirlestir.tomato_max"
    static let achievementFountain5 = "com.kutican.bahcebirlestir.fountain_max"
    static let achievement100Gold = "com.kutican.bahcebirlestir.gold_100"
    static let achievement1000Gold = "com.kutican.bahcebirlestir.gold_1000"

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let vc = viewController {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = windowScene.windows.first?.rootViewController {
                        root.present(vc, animated: true)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                }
            }
        }
    }

    func reportScore(_ score: Int, leaderboardID: String) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { _ in }
    }

    func reportAchievement(_ id: String, percent: Double = 100) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = percent
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { _ in }
    }

    func showDashboard() {
        guard isAuthenticated else { return }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            let gc = GKGameCenterViewController(state: .default)
            gc.gameCenterDelegate = GameCenterDismisser.shared
            root.present(gc, animated: true)
        }
    }
}

@MainActor
final class GameCenterDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismisser()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
