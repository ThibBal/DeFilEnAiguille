import Foundation
import SwiftData

struct ReviewItem: Codable, Hashable {
    var question: String
    var right: String
    /// Réponse donnée, uniquement quand elle était fausse.
    var mine: String?
}

/// Points par question : 5 trouvée sans indice, 3 avec l'indice, 1 avec les propositions, 0 sinon.
enum Scoring {
    static let withoutHint = 5
    static let withHint = 3
    static let withChoices = 1
    static let perQuestion = 5

    static func maxPoints(questions count: Int) -> Int { count * perQuestion }

    /// « sans indice », « avec l'indice »… pour afficher comment une question a été réussie.
    static func method(points: Int) -> String? {
        switch points {
        case withoutHint: "sans indice"
        case withHint: "avec l'indice"
        case withChoices: "avec les propositions"
        default: nil
        }
    }
}

/// Une partie jouée, enregistrée sur l'appareil. Rejouer remplace la partie précédente.
@Model
final class Play {
    @Attribute(.unique) var date: String
    var title: String
    /// Nombre de bonnes réponses.
    var score: Int
    var detail: [ReviewItem]
    /// Points de chaque question. Absent pour les parties jouées avant le barème (réponses à choix, 5 points chacune).
    var pointsByQuestion: [Int]?

    init(date: String, title: String, score: Int, detail: [ReviewItem], pointsByQuestion: [Int]? = nil) {
        self.date = date
        self.title = title
        self.score = score
        self.detail = detail
        self.pointsByQuestion = pointsByQuestion
    }

    var pointsList: [Int] {
        pointsByQuestion ?? detail.map { $0.mine == nil ? Scoring.perQuestion : 0 }
    }
    var points: Int { pointsList.reduce(0, +) }
    var maxPoints: Int { Scoring.maxPoints(questions: detail.count) }
}

/// Résultat d'une question jouée.
struct Outcome: Equatable {
    let points: Int
    /// Réponse fausse donnée (proposition choisie), pour la revue.
    let wrongAnswer: String?
    /// Réponse choisie parmi les propositions plutôt que tapée.
    let viaChoices: Bool
    let picked: Int?
    var isRight: Bool { points > 0 }
}

/// Ligne de l'historique : un jour avec un questionnaire, joué ou non.
struct HistoryEntry: Identifiable, Hashable {
    let id: String
    let title: String?
    let score: Int?
    let detail: [ReviewItem]?
    let points: Int?
    var played: Bool { score != nil }
}

enum History {
    /// Tous les jours qui ont un questionnaire ou une partie, du plus récent au plus ancien.
    static func entries(plays: [Play], dates available: [String]) -> [HistoryEntry] {
        let byDate = Dictionary(uniqueKeysWithValues: plays.map { ($0.date, $0) })
        let dates = Set(available).union(byDate.keys)
        return dates.filter { $0 <= DateKey.today }.sorted(by: >).map { date in
            if let p = byDate[date] {
                return HistoryEntry(id: date, title: p.title, score: p.score, detail: p.detail, points: p.points)
            }
            return HistoryEntry(id: date, title: nil, score: nil, detail: nil, points: nil)
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
        let total = played.reduce(0) { $0 + ($1.points ?? 0) }
        return (streak, played.count, played.isEmpty ? 0 : Double(total) / Double(played.count))
    }

    /// Le détail d'une partie : question, bonne réponse, et réponse donnée quand elle était fausse.
    static func detail(quiz: DailyQuiz, outcomes: [Outcome]) -> [ReviewItem] {
        quiz.questions.enumerated().map { i, q in
            ReviewItem(question: q.question, right: q.options[q.answer], mine: i < outcomes.count ? outcomes[i].wrongAnswer : nil)
        }
    }

    /// Enregistre (ou remplace) la partie d'une date.
    static func save(date: String, quiz: DailyQuiz, outcomes: [Outcome], in context: ModelContext) {
        let detail = detail(quiz: quiz, outcomes: outcomes)
        let score = outcomes.filter(\.isRight).count
        let points = outcomes.map(\.points)
        let existing = try? context.fetch(FetchDescriptor<Play>(predicate: #Predicate { $0.date == date }))
        if let play = existing?.first {
            play.title = quiz.thread
            play.score = score
            play.detail = detail
            play.pointsByQuestion = points
        } else {
            context.insert(Play(date: date, title: quiz.thread, score: score, detail: detail, pointsByQuestion: points))
        }
        try? context.save()
    }
}
