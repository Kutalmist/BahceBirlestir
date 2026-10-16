import Testing
@testable import BahceBirlestir

@Suite("Board Tests")
struct BoardTests {
    @Test func boardDimensions() {
        let board = Board()
        #expect(Board.columns == 7)
        #expect(Board.rows == 9)
        #expect(board.emptyCount == 63)
    }

    @Test func addItem() {
        var board = Board()
        let item = BoardItem(type: ItemType(chain: .olive, level: 1))
        let success = board.addItem(item)
        #expect(success)
        #expect(board.emptyCount == 62)
    }

    @Test func addItemToFullBoard() {
        var board = Board()
        for _ in 0..<63 {
            board.addItem(BoardItem(type: ItemType(chain: .olive, level: 1)))
        }
        #expect(board.emptyCount == 0)
        let overflow = board.addItem(BoardItem(type: ItemType(chain: .olive, level: 1)))
        #expect(!overflow)
    }

    @Test func placeAndRetrieveItem() {
        var board = Board()
        let item = BoardItem(type: ItemType(chain: .tomato, level: 3))
        let pos = GridPosition(col: 2, row: 4)
        board.placeItem(item, at: pos)
        let retrieved = board.item(at: pos)
        #expect(retrieved?.type == item.type)
    }

    @Test func removeItem() {
        var board = Board()
        let pos = GridPosition(col: 0, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: pos)
        #expect(board.item(at: pos) != nil)
        board.removeItem(at: pos)
        #expect(board.item(at: pos) == nil)
    }

    @Test func moveItem() {
        var board = Board()
        let from = GridPosition(col: 0, row: 0)
        let to = GridPosition(col: 3, row: 3)
        board.placeItem(BoardItem(type: ItemType(chain: .fountain, level: 2)), at: from)
        let success = board.moveItem(from: from, to: to)
        #expect(success)
        #expect(board.item(at: from) == nil)
        #expect(board.item(at: to) != nil)
    }

    @Test func moveToOccupiedFails() {
        var board = Board()
        let from = GridPosition(col: 0, row: 0)
        let to = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: from)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 2)), at: to)
        let success = board.moveItem(from: from, to: to)
        #expect(!success)
    }

    @Test func mergeMatchingItems() {
        var board = Board()
        let a = GridPosition(col: 0, row: 0)
        let b = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: a)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: b)
        let result = board.merge(from: a, to: b)
        #expect(result != nil)
        #expect(result?.type.level == 2)
        #expect(result?.type.chain == .olive)
        #expect(board.item(at: a) == nil)
        #expect(board.item(at: b)?.type.level == 2)
    }

    @Test func mergeDifferentChainsFails() {
        var board = Board()
        let a = GridPosition(col: 0, row: 0)
        let b = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: a)
        board.placeItem(BoardItem(type: ItemType(chain: .tomato, level: 1)), at: b)
        let result = board.merge(from: a, to: b)
        #expect(result == nil)
    }

    @Test func mergeDifferentLevelsFails() {
        var board = Board()
        let a = GridPosition(col: 0, row: 0)
        let b = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: a)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 2)), at: b)
        let result = board.merge(from: a, to: b)
        #expect(result == nil)
    }

    @Test func mergeMaxLevelFails() {
        var board = Board()
        let a = GridPosition(col: 0, row: 0)
        let b = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 6)), at: a)
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 6)), at: b)
        let result = board.merge(from: a, to: b)
        #expect(result == nil)
    }

    @Test func canMergeCheck() {
        var board = Board()
        let a = GridPosition(col: 0, row: 0)
        let b = GridPosition(col: 1, row: 0)
        board.placeItem(BoardItem(type: ItemType(chain: .tomato, level: 2)), at: a)
        board.placeItem(BoardItem(type: ItemType(chain: .tomato, level: 2)), at: b)
        #expect(board.canMerge(from: a, to: b))
    }

    @Test func isValidPosition() {
        let board = Board()
        #expect(board.isValid(GridPosition(col: 0, row: 0)))
        #expect(board.isValid(GridPosition(col: 6, row: 8)))
        #expect(!board.isValid(GridPosition(col: -1, row: 0)))
        #expect(!board.isValid(GridPosition(col: 7, row: 0)))
        #expect(!board.isValid(GridPosition(col: 0, row: 9)))
    }

    @Test func allItems() {
        var board = Board()
        board.placeItem(BoardItem(type: ItemType(chain: .olive, level: 1)), at: GridPosition(col: 0, row: 0))
        board.placeItem(BoardItem(type: ItemType(chain: .tomato, level: 2)), at: GridPosition(col: 3, row: 5))
        let items = board.allItems
        #expect(items.count == 2)
    }
}

@Suite("Item Type Tests")
struct ItemTypeTests {
    @Test func oliveChainHas6Levels() {
        let item = ItemType(chain: .olive, level: 1)
        #expect(item.maxLevel == 6)
        #expect(!item.isMaxLevel)
        let max = ItemType(chain: .olive, level: 6)
        #expect(max.isMaxLevel)
    }

    @Test func tomatoChainHas5Levels() {
        let item = ItemType(chain: .tomato, level: 5)
        #expect(item.isMaxLevel)
    }

    @Test func fountainChainHas5Levels() {
        let item = ItemType(chain: .fountain, level: 5)
        #expect(item.isMaxLevel)
    }

    @Test func mergedReturnsNextLevel() {
        let item = ItemType(chain: .olive, level: 3)
        let merged = item.merged()
        #expect(merged?.level == 4)
        #expect(merged?.chain == .olive)
    }

    @Test func mergedMaxReturnsNil() {
        let item = ItemType(chain: .olive, level: 6)
        #expect(item.merged() == nil)
    }

    @Test func displayNames() {
        let seed = ItemType(chain: .olive, level: 1)
        #expect(seed.displayName == "Zeytin Tohumu")
        let fountain = ItemType(chain: .fountain, level: 5)
        #expect(fountain.displayName == "Çeşme")
    }

    @Test func fullOliveChainMerge() {
        var type = ItemType(chain: .olive, level: 1)
        var steps = 0
        while let next = type.merged() {
            type = next
            steps += 1
        }
        #expect(steps == 5)
        #expect(type.level == 6)
        #expect(type.displayName == "Anıt Zeytin")
    }
}

@Suite("Order Tests")
struct OrderTests {
    @Test func orderCompletion() {
        var order = Order(
            title: "Test",
            requirements: [OrderRequirement(chain: .olive, minLevel: 2, count: 1)],
            goldReward: 10
        )
        #expect(!order.isComplete)
        order.requirements[0].count = 0
        #expect(order.isComplete)
    }
}
