import Foundation

struct OrderRequirement: Codable, Equatable {
    let chain: ItemChain
    let minLevel: Int
    var count: Int
}

struct Order: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    var requirements: [OrderRequirement]
    let goldReward: Int

    init(title: String, requirements: [OrderRequirement], goldReward: Int) {
        self.id = UUID()
        self.title = title
        self.requirements = requirements
        self.goldReward = goldReward
    }

    var isComplete: Bool {
        requirements.allSatisfy { $0.count <= 0 }
    }
}
