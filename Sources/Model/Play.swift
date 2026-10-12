import Foundation
import SwiftData

struct ReviewItem: Codable, Hashable {
    var question: String
    var right: String
    /// Réponse donnée, uniquement quand elle était fausse.
    var mine: String?
}

/// Une partie jouée, enregistrée sur l'appareil. Rejouer remplace la partie précédente.
@Model
final class Play {
    @Attribute(.unique) var date: String
    var title: String
    var score: Int
    var detail: [ReviewItem]

    init(date: String, title: String, score: Int, detail: [ReviewItem]) {
        self.date = date
        self.title = title
        self.score = score
        self.detail = detail
    }
}

/// Ligne de l'historique : un jour avec un questionnaire, joué ou non.
struct HistoryEntry: Identifiable, Hashable {
    let id: String
    let title: String?
    let score: Int?
    let detail: [ReviewItem]?
    var played: Bool { score != nil }
}

enum History {
    /// Tous les jours qui ont un questionnaire ou une partie, du plus récent au plus ancien.
    static func entries(plays: [Play]) -> [HistoryEntry] {
        let byDate = Dictionary(uniqueKeysWithValues: plays.map { ($0.date, $0) })
        let dates = Set(QuizCatalog.shared.availableDates).union(byDate.keys)
        return dates.filter { $0 <= DateKey.today }.sorted(by: >).map { date in
            if let p = byDate[date] {
                return HistoryEntry(id: date, title: p.title, score: p.score, detail: p.detail)
            }
            return HistoryEntry(id: date, title: nil, score: nil, detail: nil)
        }
    }

    static func stats(_ entries: [HistoryEntry]) -> (streak: Int, played: Int, average: Double) {
        let played = entries.filter(\.played)
        // Série : jours joués consécutifs en partant du plus récent. Aujourd'hui ne la rompt pas tant qu'il n'est pas joué.
        var streak = 0
        for e in entries {
            if !e.played {
                if e.id == DateKey.today && streak == 0 { continue }
                break
            }
            streak += 1
        }
        let total = played.reduce(0) { $0 + ($1.score ?? 0) }
        return (streak, played.count, played.isEmpty ? 0 : Double(total) / Double(played.count))
    }

    /// Enregistre (ou remplace) la partie d'une date.
    static func save(date: String, quiz: DailyQuiz, picked: [Int], in context: ModelContext) {
        let detail = quiz.questions.enumerated().map { i, q in
            ReviewItem(
                question: q.question,
                right: q.options[q.answer],
                mine: picked[i] == q.answer ? nil : q.options[picked[i]]
            )
        }
        let score = detail.filter { $0.mine == nil }.count
        let existing = try? context.fetch(FetchDescriptor<Play>(predicate: #Predicate { $0.date == date }))
        if let play = existing?.first {
            play.title = quiz.thread
            play.score = score
            play.detail = detail
        } else {
            context.insert(Play(date: date, title: quiz.thread, score: score, detail: detail))
        }
        try? context.save()
    }
}
