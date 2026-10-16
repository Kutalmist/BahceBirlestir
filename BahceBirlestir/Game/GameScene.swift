import SpriteKit

private extension UIColor {
    func lerp(to other: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = max(0, min(1, fraction))
        return UIColor(
            red: r1 + (r2 - r1) * f,
            green: g1 + (g2 - g1) * f,
            blue: b1 + (b2 - b1) * f,
            alpha: a1 + (a2 - a1) * f
        )
    }
}

@MainActor
final class GameScene: SKScene {
    weak var gameState: GameState?

    private let boardColumns = Board.columns
    private let boardRows = Board.rows
    private var cellSize: CGFloat = 44
    private var boardOrigin: CGPoint = .zero
    private var itemNodes: [GridPosition: SKNode] = [:]
    private var draggedNode: SKNode?
    private var dragSourcePos: GridPosition?
    private var highlightNode: SKShapeNode?

    private let chainColors: [String: SKColor] = [
        "olive": SKColor(red: 0.42, green: 0.56, blue: 0.14, alpha: 1),
        "tomato": SKColor(red: 0.86, green: 0.2, blue: 0.18, alpha: 1),
        "fountain": SKColor(red: 0.35, green: 0.55, blue: 0.75, alpha: 1),
    ]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1)
        layoutBoard()
        renderBoard()
        NotificationCenter.default.addObserver(forName: Notification.Name("boardChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.renderBoard()
            }
        }
    }

    private func layoutBoard() {
        guard let view else { return }
        let availableWidth = view.bounds.width - 20
        let availableHeight = view.bounds.height - 120
        let cellW = availableWidth / CGFloat(boardColumns)
        let cellH = availableHeight / CGFloat(boardRows)
        cellSize = min(cellW, cellH)
        let boardWidth = cellSize * CGFloat(boardColumns)
        let boardHeight = cellSize * CGFloat(boardRows)
        boardOrigin = CGPoint(
            x: (view.bounds.width - boardWidth) / 2,
            y: (view.bounds.height - boardHeight) / 2 + 20
        )
        drawGrid()
    }

    private func drawGrid() {
        childNode(withName: "grid")?.removeFromParent()
        let gridNode = SKNode()
        gridNode.name = "grid"

        for row in 0..<boardRows {
            for col in 0..<boardColumns {
                let rect = cellRect(col: col, row: row)
                let cell = SKShapeNode(rect: rect, cornerRadius: 4)
                cell.fillColor = SKColor(white: 1, alpha: 0.5)
                cell.strokeColor = SKColor(white: 0.8, alpha: 1)
                cell.lineWidth = 1
                gridNode.addChild(cell)
            }
        }
        addChild(gridNode)
    }

    func renderBoard() {
        for (_, node) in itemNodes {
            node.removeFromParent()
        }
        itemNodes.removeAll()

        guard let gameState else { return }
        for (pos, item) in gameState.board.allItems {
            let node = createItemNode(item: item, at: pos)
            addChild(node)
            itemNodes[pos] = node
        }
    }

    private func createItemNode(item: BoardItem, at pos: GridPosition) -> SKNode {
        let container = SKNode()
        container.position = cellCenter(col: pos.col, row: pos.row)
        container.name = "item_\(pos.col)_\(pos.row)"
        container.zPosition = 10

        let size = cellSize - 6
        let bg = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 6)
        let color = chainColors[item.type.color] ?? .gray
        let brightness = CGFloat(item.type.level) / CGFloat(item.type.maxLevel)
        bg.fillColor = color.lerp(to: .white, fraction: 0.3 * (1 - brightness))
        bg.strokeColor = color.lerp(to: .black, fraction: 0.3)
        bg.lineWidth = 2
        container.addChild(bg)

        let label = SKLabelNode(text: item.type.displayName)
        label.fontSize = max(9, cellSize * 0.2)
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = size - 4
        container.addChild(label)

        let levelLabel = SKLabelNode(text: "Lv\(item.type.level)")
        levelLabel.fontSize = max(8, cellSize * 0.17)
        levelLabel.fontName = "AvenirNext-Medium"
        levelLabel.fontColor = SKColor(white: 1, alpha: 0.8)
        levelLabel.verticalAlignmentMode = .top
        levelLabel.position = CGPoint(x: 0, y: -size / 2 + 4)
        container.addChild(levelLabel)

        return container
    }

    private func cellRect(col: Int, row: Int) -> CGRect {
        let x = boardOrigin.x + CGFloat(col) * cellSize
        let flippedRow = boardRows - 1 - row
        let y = boardOrigin.y + CGFloat(flippedRow) * cellSize
        return CGRect(x: x, y: y, width: cellSize, height: cellSize)
    }

    private func cellCenter(col: Int, row: Int) -> CGPoint {
        let rect = cellRect(col: col, row: row)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func gridPosition(at point: CGPoint) -> GridPosition? {
        let col = Int((point.x - boardOrigin.x) / cellSize)
        let flippedRow = Int((point.y - boardOrigin.y) / cellSize)
        let row = boardRows - 1 - flippedRow
        let pos = GridPosition(col: col, row: row)
        guard gameState?.board.isValid(pos) == true else { return nil }
        return pos
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let gameState else { return }
        let location = touch.location(in: self)
        guard let pos = gridPosition(at: location),
              let _ = gameState.board.item(at: pos),
              let node = itemNodes[pos] else { return }

        draggedNode = node
        dragSourcePos = pos
        node.zPosition = 100

        let highlight = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
        highlight.fillColor = SKColor(white: 1, alpha: 0.3)
        highlight.strokeColor = .clear
        highlight.position = cellCenter(col: pos.col, row: pos.row)
        highlight.zPosition = 5
        highlight.name = "highlight"
        addChild(highlight)
        highlightNode = highlight
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggedNode else { return }
        node.position = touch.location(in: self)

        if let targetPos = gridPosition(at: touch.location(in: self)),
           let sourcePos = dragSourcePos {
            if gameState?.board.canMerge(from: sourcePos, to: targetPos) == true {
                highlightNode?.fillColor = SKColor(red: 0, green: 1, blue: 0, alpha: 0.3)
                highlightNode?.position = cellCenter(col: targetPos.col, row: targetPos.row)
            } else if gameState?.board.isEmpty(at: targetPos) == true {
                highlightNode?.fillColor = SKColor(white: 1, alpha: 0.3)
                highlightNode?.position = cellCenter(col: targetPos.col, row: targetPos.row)
            } else {
                highlightNode?.fillColor = SKColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                highlightNode?.position = cellCenter(col: targetPos.col, row: targetPos.row)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let sourcePos = dragSourcePos,
              let gameState else {
            resetDrag()
            return
        }

        let location = touch.location(in: self)
        if let targetPos = gridPosition(at: location), targetPos != sourcePos {
            if gameState.board.canMerge(from: sourcePos, to: targetPos) {
                _ = gameState.merge(from: sourcePos, to: targetPos)
                animateMerge(at: targetPos)
            } else if gameState.board.isEmpty(at: targetPos) {
                _ = gameState.moveItem(from: sourcePos, to: targetPos)
            }
        }

        resetDrag()
        renderBoard()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDrag()
        renderBoard()
    }

    private func resetDrag() {
        draggedNode?.zPosition = 10
        draggedNode = nil
        dragSourcePos = nil
        highlightNode?.removeFromParent()
        highlightNode = nil
    }

    private func animateMerge(at pos: GridPosition) {
        let center = cellCenter(col: pos.col, row: pos.row)
        let flash = SKShapeNode(circleOfRadius: cellSize * 0.6)
        flash.fillColor = SKColor(white: 1, alpha: 0.8)
        flash.strokeColor = .clear
        flash.position = center
        flash.zPosition = 50
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 1.5, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent()
        ]))
    }
}
