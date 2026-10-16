import Foundation

struct GridPosition: Hashable, Codable, Equatable {
    let col: Int
    let row: Int
}

struct Board: Codable, Equatable {
    static let columns = 7
    static let rows = 9

    private var cells: [[BoardItem?]]

    init() {
        cells = Array(repeating: Array(repeating: nil, count: Board.columns), count: Board.rows)
    }

    func isValid(_ pos: GridPosition) -> Bool {
        pos.row >= 0 && pos.row < Board.rows && pos.col >= 0 && pos.col < Board.columns
    }

    func item(at pos: GridPosition) -> BoardItem? {
        guard isValid(pos) else { return nil }
        return cells[pos.row][pos.col]
    }

    func isEmpty(at pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        return cells[pos.row][pos.col] == nil
    }

    var emptyCount: Int {
        cells.flatMap { $0 }.filter { $0 == nil }.count
    }

    var allItems: [(GridPosition, BoardItem)] {
        var result: [(GridPosition, BoardItem)] = []
        for row in 0..<Board.rows {
            for col in 0..<Board.columns {
                if let item = cells[row][col] {
                    result.append((GridPosition(col: col, row: row), item))
                }
            }
        }
        return result
    }

    @discardableResult
    mutating func addItem(_ item: BoardItem) -> Bool {
        guard let pos = firstEmptyPosition() else { return false }
        cells[pos.row][pos.col] = item
        return true
    }

    mutating func placeItem(_ item: BoardItem, at pos: GridPosition) {
        guard isValid(pos) else { return }
        cells[pos.row][pos.col] = item
    }

    mutating func removeItem(at pos: GridPosition) {
        guard isValid(pos) else { return }
        cells[pos.row][pos.col] = nil
    }

    mutating func moveItem(from: GridPosition, to: GridPosition) -> Bool {
        guard isValid(from), isValid(to),
              cells[from.row][from.col] != nil,
              cells[to.row][to.col] == nil else { return false }
        cells[to.row][to.col] = cells[from.row][from.col]
        cells[from.row][from.col] = nil
        return true
    }

    mutating func merge(from sourcePos: GridPosition, to targetPos: GridPosition) -> BoardItem? {
        guard isValid(sourcePos), isValid(targetPos),
              let source = cells[sourcePos.row][sourcePos.col],
              let target = cells[targetPos.row][targetPos.col],
              source.type == target.type,
              let mergedType = source.type.merged() else { return nil }

        let merged = BoardItem(type: mergedType)
        cells[targetPos.row][targetPos.col] = merged
        cells[sourcePos.row][sourcePos.col] = nil
        return merged
    }

    func canMerge(from: GridPosition, to: GridPosition) -> Bool {
        guard let source = item(at: from), let target = item(at: to) else { return false }
        return source.type == target.type && !source.type.isMaxLevel
    }

    private func firstEmptyPosition() -> GridPosition? {
        for row in 0..<Board.rows {
            for col in 0..<Board.columns {
                if cells[row][col] == nil {
                    return GridPosition(col: col, row: row)
                }
            }
        }
        return nil
    }
}
