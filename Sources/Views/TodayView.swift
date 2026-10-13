import SwiftUI

/// Onglet « Aujourd'hui » : le questionnaire du jour, ou son résultat s'il a déjà été joué.
/// Tant que celui du jour n'est pas disponible, l'écran l'annonce et renvoie vers l'historique.
struct TodayView: View {
    @Environment(AppState.self) private var app
    @Environment(QuizStore.self) private var store

    var body: some View {
        if store.quiz(for: DateKey.today) != nil {
            QuizView(date: DateKey.today, replay: false, showsBack: false) {
                app.tab = .history
            }
        } else {
            unavailable
        }
    }

    private var unavailable: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Wordmark()
                    Spacer(minLength: 0)
                    Text(DateKey.long(DateKey.today)).font(AppFont.sans(13)).foregroundStyle(Palette.muted)
                }
                LabelText("Questionnaire du jour").padding(.top, 40)
                Text("Il arrive bientôt.")
                    .font(AppFont.serif(44)).foregroundStyle(Palette.ink).padding(.top, 12)
                Text("Le questionnaire d'aujourd'hui n'est pas encore disponible. Revenez un peu plus tard, ou parcourez les questionnaires précédents en attendant.")
                    .font(AppFont.sans(17)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 16)
                Button { Task { await store.refresh() } } label: {
                    HStack(spacing: 8) {
                        if store.isRefreshing { ProgressView() }
                        Text(store.isRefreshing ? "Vérification…" : "Vérifier à nouveau")
                    }
                    .font(AppFont.sansSemi(16)).foregroundStyle(Palette.ink)
                    .frame(minHeight: 44)
                }
                .disabled(store.isRefreshing)
                .padding(.top, 8)
                if store.lastRefreshFailed && !store.isRefreshing {
                    Text("Impossible de joindre le serveur pour le moment.")
                        .font(AppFont.sans(14)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
                CtaButton(title: "Parcourir les questionnaires précédents") { app.tab = .history }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }
}
