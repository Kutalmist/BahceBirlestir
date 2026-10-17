import Foundation

enum DemoMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoMode")
    }
}

@MainActor
struct DemoDataProvider {
    static func applyDemoState(to gameState: GameState) {
        gameState.energy = 85
        gameState.gold = 230
        gameState.totalMerges = 47

        let demoItems: [(ItemChain, Int, Int, Int)] = [
            (.olive, 1, 0, 0), (.olive, 1, 1, 0), (.olive, 2, 2, 0),
            (.tomato, 1, 3, 0), (.tomato, 2, 4, 0),
            (.fountain, 1, 5, 0), (.fountain, 3, 6, 0),
            (.olive, 3, 0, 1), (.tomato, 1, 1, 1),
            (.olive, 1, 2, 1), (.fountain, 1, 3, 1),
            (.tomato, 3, 4, 1), (.olive, 4, 5, 1),
            (.fountain, 2, 0, 2), (.olive, 2, 1, 2),
        ]

        for (chain, level, col, row) in demoItems {
            let item = BoardItem(type: ItemType(chain: chain, level: level))
            let pos = GridPosition(col: col, row: row)
            gameState.board.placeItem(item, at: pos)
        }

        gameState.orders = [
            Order(title: "Nine'nin İsteği",
                  requirements: [OrderRequirement(chain: .olive, minLevel: 2, count: 2)],
                  goldReward: 10),
            Order(title: "Bakkalın Siparişi",
                  requirements: [OrderRequirement(chain: .tomato, minLevel: 2, count: 2)],
                  goldReward: 10),
            Order(title: "Çeşme Tamiri",
                  requirements: [OrderRequirement(chain: .fountain, minLevel: 2, count: 1)],
                  goldReward: 15),
        ]
    }
}
