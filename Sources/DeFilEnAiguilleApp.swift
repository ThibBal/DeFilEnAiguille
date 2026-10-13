import SwiftData
import SwiftUI

@main
struct DeFilEnAiguilleApp: App {
    @State private var app = AppState()
    @State private var store = QuizStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Barre d'onglets : papier crème, encre pour l'onglet actif, gris pour les autres.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Palette.paper)
        appearance.shadowColor = UIColor(Palette.hair)
        let item = UITabBarItemAppearance()
        let font = UIFont(name: "HankenGrotesk-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        item.normal.iconColor = UIColor(Palette.muted)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(Palette.muted), .font: font]
        item.selected.iconColor = UIColor(Palette.ink)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(Palette.ink), .font: font]
        appearance.stackedLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(store)
                .tint(Palette.ink)
                .task { await store.refresh() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await store.refresh() } }
                }
        }
        .modelContainer(for: Play.self)
    }
}

enum AppTab { case today, history }

enum Route: Hashable {
    case review(String)
    case play(String, replay: Bool)
}

/// État partagé entre les onglets : onglet affiché et pile de navigation de l'historique.
@Observable
final class AppState {
    var tab: AppTab = .today
    var historyPath: [Route] = []
}
