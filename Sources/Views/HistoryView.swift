import SwiftData
import SwiftUI

/// Tous les jours, par mois : un jour joué ouvre sa revue, un jour à jouer ouvre le questionnaire.
struct HistoryView: View {
    @Environment(AppState.self) private var app
    @Query private var plays: [Play]

    var body: some View {
        @Bindable var app = app
        let entries = History.entries(plays: plays)
        let stats = History.stats(entries)
        let todayPlayed = entries.first(where: { $0.id == DateKey.today })?.played ?? false
        let months = Dictionary(grouping: entries, by: { DateKey.month($0.id) })
            .sorted { ($0.value.first?.id ?? "") > ($1.value.first?.id ?? "") }

        NavigationStack(path: $app.historyPath) {
            ZStack {
                Palette.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Wordmark()
                        Text("Historique").font(AppFont.serif(44)).foregroundStyle(Palette.ink)
                            .padding(.top, 28).accessibilityAddTraits(.isHeader)
                        Text("Tous vos questionnaires, du plus récent au plus ancien.")
                            .font(AppFont.sans(15)).foregroundStyle(Palette.muted).padding(.top, 8)

                        statsRow(stats).padding(.top, 20)
                        if QuizCatalog.shared.quiz(for: DateKey.today) != nil {
                            todayCard(played: todayPlayed).padding(.top, 24)
                        }

                        ForEach(months, id: \.key) { month in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(month.key.uppercased())
                                    .font(AppFont.sansSemi(13)).tracking(1).foregroundStyle(Palette.ink)
                                    .padding(.bottom, 8)
                                    .accessibilityAddTraits(.isHeader)
                                Rectangle().fill(Palette.ink).frame(height: 1)
                                ForEach(month.value) { entry in
                                    NavigationLink(value: entry.played ? Route.review(entry.id) : Route.play(entry.id, replay: false)) {
                                        Row(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 32)
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 8)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .review(let date):
                    ReviewView(date: date)
                case .play(let date, let replay):
                    QuizView(date: date, replay: replay, showsBack: true) { app.historyPath.removeAll() }
                }
            }
        }
    }

    private func statsRow(_ stats: (streak: Int, played: Int, average: Double)) -> some View {
        HStack(spacing: 0) {
            Stat(value: "\(stats.streak)", unit: stats.streak > 1 ? "jours" : "jour", label: "Série en cours", first: true)
            Stat(value: "\(stats.played)", unit: nil, label: "Questionnaires joués", first: false)
            Stat(value: String(format: "%.1f", stats.average).replacingOccurrences(of: ".", with: ","), unit: "/ 5", label: "Moyenne", first: false)
        }
        .overlay(alignment: .top) { Rectangle().fill(Palette.hair).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.hair).frame(height: 1) }
    }

    private func todayCard(played: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                LabelText("Aujourd'hui · \(DateKey.short(DateKey.today))", color: Palette.accent)
                Text(played ? "Questionnaire du jour terminé." : "5 questions à relier, du premier fil au dernier.")
                    .font(AppFont.serif(28)).exactLineHeight(31).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            CtaButton(title: played ? "Voir le résultat" : "Commencer") { app.tab = .today }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.border, lineWidth: 1.5))
    }
}

private struct Stat: View {
    let value: String
    let unit: String?
    let label: String
    let first: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(AppFont.serif(34)).foregroundStyle(Palette.ink)
                if let unit { Text(unit).font(AppFont.sans(14)).foregroundStyle(Palette.muted) }
            }
            Text(label).font(AppFont.sans(12)).foregroundStyle(Palette.muted)
        }
        .padding(.vertical, 14)
        .padding(.leading, first ? 0 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) { if !first { Rectangle().fill(Palette.hair).frame(width: 1) } }
        .accessibilityElement(children: .combine)
    }
}

private struct Row: View {
    let entry: HistoryEntry

    var body: some View {
        let todo = !entry.played
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(DateKey.day(entry.id)).font(AppFont.serif(32)).foregroundStyle(Palette.ink)
                Text(DateKey.weekday(entry.id)).font(AppFont.sans(12)).foregroundStyle(Palette.muted)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(todo ? "Non joué" : (entry.title ?? ""))
                    .font(AppFont.sansMedium(16)).foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                Text(todo ? "À jouer" : "\(entry.score ?? 0) sur 5")
                    .font(AppFont.sans(13)).foregroundStyle(todo ? Palette.accent : Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ScoreDots(score: entry.score)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 72)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.hair).frame(height: 1) }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DateKey.weekday(entry.id)) \(DateKey.day(entry.id)), \(todo ? "non joué" : (entry.title ?? "")), \(todo ? "à jouer" : "\(entry.score ?? 0) sur 5")")
        .accessibilityAddTraits(.isButton)
    }
}
