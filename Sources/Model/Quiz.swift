import Foundation

struct Question: Codable, Hashable {
    let question: String
    let options: [String]
    /// Index de la bonne réponse dans `options`.
    let answer: Int
    /// Réponse courte, affichée dans le fil récapitulatif.
    let short: String
    let explanation: String
}

struct DailyQuiz: Codable, Hashable {
    /// Le « fil du jour », révélé à la fin du questionnaire.
    let thread: String
    let questions: [Question]
}

/// Les questionnaires, embarqués dans `quizzes.json` (clés AAAA-MM-JJ).
/// Le questionnaire de repli sert pour aujourd'hui quand la date n'y figure pas.
struct QuizCatalog: Decodable {
    let fallback: DailyQuiz
    let quizzes: [String: DailyQuiz]

    static let shared: QuizCatalog = {
        guard let url = Bundle.main.url(forResource: "quizzes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(QuizCatalog.self, from: data)
        else { fatalError("quizzes.json introuvable ou invalide") }
        return catalog
    }()

    func quiz(for date: String) -> DailyQuiz? {
        quizzes[date] ?? (date == DateKey.today ? fallback : nil)
    }

    /// Dates qui ont un questionnaire, jusqu'à aujourd'hui (toujours incluse, avec le repli au besoin).
    var availableDates: [String] {
        Set(quizzes.keys.filter { $0 <= DateKey.today }).union([DateKey.today]).sorted()
    }
}
