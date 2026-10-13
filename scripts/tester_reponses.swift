// Vérifie que la saisie libre accepte les bonnes réponses (avec variantes et fautes de frappe)
// et refuse les mauvaises propositions, pour tous les questionnaires de content/quizzes/.
// Lancer : scripts/tester_reponses.sh
import Foundation

struct Q: Decodable {
    let options: [String]
    let answer: Int
    let short: String
    let accept: [String]?
}
struct Quiz: Decodable { let questions: [Q] }

let dossier = URL(fileURLWithPath: CommandLine.arguments[1])
let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }
var echecs = 0
var total = 0

func verifier(_ ok: Bool, _ message: @autoclosure () -> String) {
    total += 1
    if !ok { echecs += 1; print("ÉCHEC : \(message())") }
}

for fichier in fichiers {
    let quiz = try JSONDecoder().decode(Quiz.self, from: Data(contentsOf: fichier))
    for (n, q) in quiz.questions.enumerated() {
        let nom = "\(fichier.deletingPathExtension().lastPathComponent) question \(n + 1)"
        let bonne = q.options[q.answer]
        let fausses = q.options.enumerated().filter { $0.offset != q.answer }.map(\.element)
        let acceptees = [bonne, q.short] + (q.accept ?? [])
        func ok(_ s: String) -> Bool { AnswerMatcher.matches(s, correct: acceptees, wrong: fausses) }

        for a in acceptees {
            verifier(ok(a), "« \(a) » devrait être accepté (\(nom))")
            verifier(ok(a.uppercased()), "« \(a.uppercased()) » devrait être accepté (\(nom))")
            verifier(ok("  \(a.lowercased()) "), "« \(a.lowercased()) » devrait être accepté (\(nom))")
            let sansAccents = a.folding(options: .diacriticInsensitive, locale: nil)
            verifier(ok(sansAccents), "« \(sansAccents) » devrait être accepté (\(nom))")
            // une lettre en moins au milieu, si le mot est assez long pour la tolérance
            let lettres = Array(AnswerMatcher.normalized(a))
            if lettres.count >= 5 {
                var faute = lettres
                faute.remove(at: lettres.count / 2)
                verifier(ok(String(faute)), "la faute de frappe « \(String(faute)) » devrait être acceptée (\(nom))")
            }
        }
        for f in fausses {
            verifier(!ok(f), "« \(f) » ne devrait pas être accepté (\(nom))")
        }
        for a in ["", "x", "je ne sais pas", "Napoléon"] {
            verifier(!ok(a), "« \(a) » ne devrait pas être accepté (\(nom))")
        }
    }
}
print(echecs == 0 ? "OK : \(total) vérifications sur \(fichiers.count) questionnaires" : "\(echecs) échec(s) sur \(total) vérifications")
exit(echecs == 0 ? 0 : 1)
