import Foundation
import Observation

@Observable
@MainActor
final class GameState {
    var board: Board
    var energy: Int
    var maxEnergy: Int
    var gold: Int
    var orders: [Order]
    private var energyTimer: Timer?
    private var lastEnergyTime: Date

    private static let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("bahce_save.json")
    }()

    init() {
        self.board = Board()
        self.energy = 100
        self.maxEnergy = 100
        self.gold = 50
        self.orders = []
        self.lastEnergyTime = Date()
        load()
        generateOrdersIfNeeded()
        startEnergyTimer()
    }

    // MARK: - Energy

    func spendEnergy(_ amount: Int = 1) -> Bool {
        guard energy >= amount else { return false }
        energy -= amount
        save()
        return true
    }

    private func startEnergyTimer() {
        energyTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.regenEnergy()
            }
        }
    }

    private func regenEnergy() {
        if energy < maxEnergy {
            energy += 1
            save()
        }
    }

    func restoreOfflineEnergy() {
        let elapsed = Date().timeIntervalSince(lastEnergyTime)
        let ticks = Int(elapsed / 120)
        if ticks > 0 {
            energy = min(maxEnergy, energy + ticks)
        }
        lastEnergyTime = Date()
    }

    // MARK: - Producer (Seed Pouch)

    func tapSeedPouch() -> BoardItem? {
        guard spendEnergy() else { return nil }
        let chains: [ItemChain] = [.olive, .tomato, .fountain]
        let chain = chains.randomElement()!
        let item = BoardItem(type: ItemType(chain: chain, level: 1))
        if board.addItem(item) {
            save()
            return item
        }
        energy += 1
        return nil
    }

    // MARK: - Merge

    func merge(from sourcePos: GridPosition, to targetPos: GridPosition) -> Bool {
        guard let result = board.merge(from: sourcePos, to: targetPos) else { return false }
        checkOrderDelivery(item: result)
        save()
        return true
    }

    func moveItem(from: GridPosition, to: GridPosition) -> Bool {
        let success = board.moveItem(from: from, to: to)
        if success { save() }
        return success
    }

    // MARK: - Orders

    func generateOrdersIfNeeded() {
        while orders.count < 3 {
            orders.append(generateOrder())
        }
    }

    private func generateOrder() -> Order {
        let templates: [(String, [OrderRequirement], Int)] = [
            ("Nine'nin İsteği", [OrderRequirement(chain: .olive, minLevel: 2, count: 2)], 10),
            ("Bakkalın Siparişi", [OrderRequirement(chain: .tomato, minLevel: 2, count: 2)], 10),
            ("Çeşme Tamiri", [OrderRequirement(chain: .fountain, minLevel: 2, count: 1)], 15),
            ("Bahçe Süsü", [OrderRequirement(chain: .olive, minLevel: 3, count: 1)], 20),
            ("Domates Kasası", [OrderRequirement(chain: .tomato, minLevel: 3, count: 1)], 20),
            ("Köy Meydanı", [OrderRequirement(chain: .fountain, minLevel: 3, count: 1)], 25),
            ("Zeytin Hasadı", [OrderRequirement(chain: .olive, minLevel: 4, count: 1)], 30),
            ("Salça Yapımı", [OrderRequirement(chain: .tomato, minLevel: 3, count: 2)], 30),
        ]
        let t = templates.randomElement()!
        return Order(title: t.0, requirements: t.1, goldReward: t.2)
    }

    private func checkOrderDelivery(item: BoardItem) {
        // no-op here; delivery is explicit via deliverItem
    }

    func deliverItem(at pos: GridPosition, toOrder orderID: UUID) -> Bool {
        guard let item = board.item(at: pos),
              let idx = orders.firstIndex(where: { $0.id == orderID }) else { return false }

        var order = orders[idx]
        guard let reqIdx = order.requirements.firstIndex(where: {
            $0.chain == item.type.chain && item.type.level >= $0.minLevel && $0.count > 0
        }) else { return false }

        order.requirements[reqIdx].count -= 1
        board.removeItem(at: pos)

        if order.isComplete {
            gold += order.goldReward
            orders.remove(at: idx)
            generateOrdersIfNeeded()
        } else {
            orders[idx] = order
        }
        save()
        return true
    }

    // MARK: - Persistence

    private struct SaveData: Codable {
        var board: Board
        var energy: Int
        var maxEnergy: Int
        var gold: Int
        var orders: [Order]
        var lastEnergyTime: Date
    }

    func save() {
        lastEnergyTime = Date()
        let data = SaveData(
            board: board,
            energy: energy,
            maxEnergy: maxEnergy,
            gold: gold,
            orders: orders,
            lastEnergyTime: lastEnergyTime
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: Self.saveURL, options: .atomic)
        } catch {}
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.saveURL),
              let saved = try? JSONDecoder().decode(SaveData.self, from: data) else { return }
        self.board = saved.board
        self.energy = saved.energy
        self.maxEnergy = saved.maxEnergy
        self.gold = saved.gold
        self.orders = saved.orders
        self.lastEnergyTime = saved.lastEnergyTime
        restoreOfflineEnergy()
    }
}
