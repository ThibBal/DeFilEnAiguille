import Foundation

/// Reconnaît une réponse tapée « à peu près » juste : sans tenir compte des accents, de la casse,
/// de la ponctuation ni des articles, avec une petite tolérance de fautes de frappe.
enum AnswerMatcher {
    private static let articles: Set<String> = ["le", "la", "les", "l", "un", "une", "the", "de", "du", "des", "d"]

    /// Vrai si `input` correspond à l'une des réponses acceptées (`correct`) plus nettement qu'à n'importe
    /// laquelle des mauvaises propositions (`wrong`) : « Louis XVI » n'est pas pris pour « Louis XVIII ».
    static func matches(_ input: String, correct: [String], wrong: [String]) -> Bool {
        let typed = Array(normalized(input))
        guard typed.count >= 2 else { return false }
        let bestCorrect = correct
            .map { Array(normalized($0)) }
            .filter { !$0.isEmpty }
            .compactMap { candidate -> Int? in
                let d = distance(typed, candidate)
                return d <= tolerance(candidate.count) ? d : nil
            }
            .min()
        guard let bestCorrect else { return false }
        let bestWrong = wrong.map { distance(typed, Array(normalized($0))) }.min() ?? Int.max
        return bestCorrect < bestWrong
    }

    /// Minuscules, sans accents ni ponctuation, articles retirés, mots collés : « L'Île de la Cité » → « ilecite ».
    static func normalized(_ s: String) -> String {
        let folded = s
            .replacingOccurrences(of: "œ", with: "oe").replacingOccurrences(of: "Œ", with: "oe")
            .replacingOccurrences(of: "æ", with: "ae").replacingOccurrences(of: "Æ", with: "ae")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
        var tokens: [String] = []
        var current = ""
        for ch in folded {
            if ch.isLetter || ch.isNumber {
                current.append(ch)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens.filter { !articles.contains($0) }.joined()
    }

    /// Nombre de fautes de frappe toléré selon la longueur de la réponse attendue.
    private static func tolerance(_ length: Int) -> Int {
        length <= 3 ? 0 : (length <= 8 ? 1 : 2)
    }

    /// Distance de Damerau-Levenshtein restreinte : une insertion, une suppression, une substitution
    /// ou l'inversion de deux lettres voisines comptent pour 1.
    private static func distance(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous2 = [Int](repeating: 0, count: b.count + 1)
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    current[j] = min(current[j], previous2[j - 2] + 1)
                }
            }
            (previous2, previous, current) = (previous, current, previous2)
        }
        return previous[b.count]
    }
}
