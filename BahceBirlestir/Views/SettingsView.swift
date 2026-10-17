import SwiftUI

struct SettingsView: View {
    @Environment(GameCenterManager.self) private var gameCenterManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Game Center") {
                    HStack {
                        Text("Durum")
                        Spacer()
                        Text(gameCenterManager.isAuthenticated ? "Bağlı" : "Bağlı Değil")
                            .foregroundStyle(gameCenterManager.isAuthenticated ? .green : .red)
                    }

                    if gameCenterManager.isAuthenticated {
                        Button("Sıralama & Başarılar") {
                            gameCenterManager.showDashboard()
                        }
                    }
                }

                Section("Hakkında") {
                    HStack {
                        Text("Sürüm")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Destek", destination: URL(string: "https://kutalmist.github.io/BahceBirlestir/support.html")!)
                    Link("Gizlilik Politikası", destination: URL(string: "https://kutalmist.github.io/BahceBirlestir/privacy.html")!)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
