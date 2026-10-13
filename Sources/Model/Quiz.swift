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

extension DailyQuiz {
    /// Garde-fou pour les questionnaires reçus ou lus sur disque : 5 questions, 4 options, une bonne réponse valide.
    var isValid: Bool {
        questions.count == 5 && questions.allSatisfy { $0.options.count == 4 && $0.options.indices.contains($0.answer) }
    }
}
