import SwiftUI

/// Onglet « Aujourd'hui » : le questionnaire du jour, ou son résultat s'il a déjà été joué.
struct TodayView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        QuizView(date: DateKey.today, replay: false, showsBack: false) {
            app.tab = .history
        }
    }
}
