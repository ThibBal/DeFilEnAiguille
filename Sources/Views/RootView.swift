import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.tab) {
            TodayView()
                .tabItem { Label("Aujourd'hui", systemImage: "calendar") }
                .tag(AppTab.today)
            HistoryView()
                .tabItem { Label("Historique", systemImage: "list.bullet") }
                .tag(AppTab.history)
        }
        .background(Palette.paper)
    }
}
