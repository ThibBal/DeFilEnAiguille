import Foundation

struct Question: Codable, Hashable {
    let question: String
    let options: [String]
    /// Index de la bonne réponse dans `options`.
    let answer: Int
    /// Réponse courte, affichée dans le fil récapitulatif.
    let short: String
    let explanation: String
    /// Passage de la question qui reprend la réponse précédente (absent pour la première question).
    /// C'est le mot que la bonne réponse rejoint dans l'animation.
    let link: String?
}

struct DailyQuiz: Codable, Hashable {
    /// Le « fil du jour », révélé à la fin du questionnaire.
    let thread: String
    let questions: [Question]
}

/// Les questionnaires, embarqués dans `quizzes.json` (clés AAAA-MM-JJ).
/// Une date absente n'a pas de questionnaire : aujourd'hui l'écran l'indique.
struct QuizCatalog: Decodable {
    let quizzes: [String: DailyQuiz]

    static let shared: QuizCatalog = {
        guard let url = Bundle.main.url(forResource: "quizzes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(QuizCatalog.self, from: data)
        else { fatalError("quizzes.json introuvable ou invalide") }
        return catalog
    }()

    func quiz(for date: String) -> DailyQuiz? {
        quizzes[date]
    }

    /// Dates qui ont un questionnaire, jusqu'à aujourd'hui.
    var availableDates: [String] {
        quizzes.keys.filter { $0 <= DateKey.today }.sorted()
    }
}
