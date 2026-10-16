import Foundation

enum ItemChain: String, Codable, CaseIterable {
    case olive
    case tomato
    case fountain
}

struct ItemType: Equatable, Hashable, Codable {
    let chain: ItemChain
    let level: Int

    var maxLevel: Int {
        switch chain {
        case .olive: 6
        case .tomato: 5
        case .fountain: 5
        }
    }

    var isMaxLevel: Bool { level >= maxLevel }

    var displayName: String {
        switch chain {
        case .olive:
            switch level {
            case 1: "Zeytin Tohumu"
            case 2: "Zeytin Filizi"
            case 3: "Zeytin Fidesi"
            case 4: "Zeytin Ağacı"
            case 5: "Yaşlı Zeytin"
            case 6: "Anıt Zeytin"
            default: "Zeytin \(level)"
            }
        case .tomato:
            switch level {
            case 1: "Domates Tohumu"
            case 2: "Domates Filizi"
            case 3: "Domates Fidesi"
            case 4: "Domates Çalısı"
            case 5: "Domates Tarlası"
            default: "Domates \(level)"
            }
        case .fountain:
            switch level {
            case 1: "Çakıl"
            case 2: "Taş Yığını"
            case 3: "Kaba Duvar"
            case 4: "Taş Havuz"
            case 5: "Çeşme"
            default: "Taş \(level)"
            }
        }
    }

    var sfSymbol: String {
        switch chain {
        case .olive:
            switch level {
            case 1: "leaf"
            case 2: "leaf.fill"
            case 3: "tree"
            case 4: "tree.fill"
            case 5, 6: "tree.circle.fill"
            default: "leaf"
            }
        case .tomato:
            switch level {
            case 1: "carrot"
            case 2: "carrot.fill"
            case 3: "basket"
            case 4: "basket.fill"
            case 5: "shippingbox.fill"
            default: "carrot"
            }
        case .fountain:
            switch level {
            case 1: "circle.fill"
            case 2: "square.stack.fill"
            case 3: "building.columns"
            case 4: "drop.halffull"
            case 5: "drop.circle.fill"
            default: "circle.fill"
            }
        }
    }

    var color: String {
        switch chain {
        case .olive: "olive"
        case .tomato: "tomato"
        case .fountain: "fountain"
        }
    }

    func merged() -> ItemType? {
        guard !isMaxLevel else { return nil }
        return ItemType(chain: chain, level: level + 1)
    }
}

struct BoardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var type: ItemType

    init(type: ItemType) {
        self.id = UUID()
        self.type = type
    }
}
