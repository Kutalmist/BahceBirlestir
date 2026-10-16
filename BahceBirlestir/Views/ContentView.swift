import SwiftUI
import SpriteKit

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @State private var scene: GameScene?

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            GeometryReader { geo in
                if let scene {
                    SpriteView(scene: scene)
                } else {
                    Color(red: 0.95, green: 0.93, blue: 0.88)
                        .onAppear {
                            let s = GameScene(size: geo.size)
                            s.scaleMode = .resizeFill
                            s.gameState = gameState
                            scene = s
                        }
                }
            }

            SeedButton()

            OrderPanelView()
                .frame(height: 120)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TopBar: View {
    @Environment(GameState.self) private var gameState

    var body: some View {
        HStack {
            Label("\(gameState.energy)/\(gameState.maxEnergy)", systemImage: "bolt.fill")
                .foregroundStyle(.orange)
            Spacer()
            Text("Bahçe Birleştir")
                .font(.headline)
            Spacer()
            Label("\(gameState.gold)", systemImage: "dollarsign.circle.fill")
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

struct SeedButton: View {
    @Environment(GameState.self) private var gameState

    var body: some View {
        Button(action: seedTapped) {
            HStack(spacing: 6) {
                Image(systemName: "shippingbox.fill")
                Text("Tohum Kes (\(gameState.energy) enerji)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(gameState.energy > 0 ? .green : .gray, in: Capsule())
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
        }
        .disabled(gameState.energy <= 0)
        .padding(.vertical, 6)
    }

    private func seedTapped() {
        let _ = gameState.tapSeedPouch()
        NotificationCenter.default.post(name: .boardChanged, object: nil)
    }
}

extension Notification.Name {
    static let boardChanged = Notification.Name("boardChanged")
}

struct OrderPanelView: View {
    @Environment(GameState.self) private var gameState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sipariş Panosu")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(gameState.orders) { order in
                        OrderCard(order: order)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

struct OrderCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(order.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            ForEach(Array(order.requirements.enumerated()), id: \.offset) { _, req in
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForChain(req.chain))
                        .frame(width: 10, height: 10)
                    Text("\(req.chain == .olive ? "Zeytin" : req.chain == .tomato ? "Domates" : "Taş") Lv\(req.minLevel)+ x\(req.count)")
                        .font(.caption2)
                }
            }

            HStack(spacing: 2) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text("+\(order.goldReward)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding(8)
        .frame(width: 130)
        .background(Color(.systemBackground).opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.secondary.opacity(0.3)))
    }

    private func colorForChain(_ chain: ItemChain) -> Color {
        switch chain {
        case .olive: .green
        case .tomato: .red
        case .fountain: .blue
        }
    }
}
