import Foundation
import Observation

/// Les questionnaires disponibles : ceux embarqués dans l'app (`quizzes.json`, secours hors ligne),
/// complétés par ceux téléchargés depuis GitHub Pages et gardés sur l'appareil.
/// Une date absente n'a pas de questionnaire : aujourd'hui, l'écran l'indique.
@Observable
final class QuizStore {
    /// Site publié par `.github/workflows/contenu.yml` : `index.json` et `quizzes/AAAA-MM-JJ.json`.
    static let baseURL = URL(string: "https://thibbal.github.io/DeFilEnAiguille/")!

    private(set) var quizzes: [String: DailyQuiz]
    private(set) var isRefreshing = false
    /// Vrai si la dernière vérification a échoué (hors ligne, serveur injoignable).
    private(set) var lastRefreshFailed = false

    private let cacheDirectory: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        cacheDirectory = support.appendingPathComponent("Quizzes", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        Self.resetCacheIfAppUpdated(cacheDirectory)
        var all = Self.bundled()
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "json" {
            let date = file.deletingPathExtension().lastPathComponent
            if Self.isDateKey(date), let data = try? Data(contentsOf: file),
               let quiz = try? JSONDecoder().decode(DailyQuiz.self, from: data), quiz.isValid {
                all[date] = quiz
            }
        }
        quizzes = all
    }

    func quiz(for date: String) -> DailyQuiz? { quizzes[date] }

    /// Dates qui ont un questionnaire, jusqu'à aujourd'hui.
    var availableDates: [String] {
        quizzes.keys.filter { $0 <= DateKey.today }.sorted()
    }

    /// Télécharge l'index, puis les questionnaires qu'on n'a pas encore et ceux des 7 derniers jours,
    /// d'aujourd'hui et à venir (pour qu'une correction publiée récemment soit prise en compte).
    @MainActor
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let index = try JSONDecoder().decode(Index.self, from: await Self.download("index.json"))
            let recent = DateKey.offset(days: -7)
            let wanted = index.dates.filter { Self.isDateKey($0) && (quizzes[$0] == nil || $0 >= recent) }
            let downloaded = await withTaskGroup(of: (String, Data)?.self) { group in
                for date in wanted {
                    group.addTask {
                        guard let data = try? await Self.download("quizzes/\(date).json") else { return nil }
                        return (date, data)
                    }
                }
                var results: [(String, Data)] = []
                for await item in group { if let item { results.append(item) } }
                return results
            }
            for (date, data) in downloaded {
                guard let quiz = try? JSONDecoder().decode(DailyQuiz.self, from: data), quiz.isValid else { continue }
                try? data.write(to: cacheDirectory.appendingPathComponent("\(date).json"), options: .atomic)
                if quizzes[date] != quiz { quizzes[date] = quiz }
            }
            lastRefreshFailed = wanted.count > downloaded.count
        } catch {
            lastRefreshFailed = true
        }
    }

    // MARK: - Détails

    private struct Index: Decodable { let dates: [String] }
    private struct Bundled: Decodable { let quizzes: [String: DailyQuiz] }

    private static func bundled() -> [String: DailyQuiz] {
        guard let url = Bundle.main.url(forResource: "quizzes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundled = try? JSONDecoder().decode(Bundled.self, from: data)
        else { return [:] }
        return bundled.quizzes.filter { $0.value.isValid }
    }

    private static func isDateKey(_ s: String) -> Bool {
        s.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    /// Une nouvelle version de l'app embarque des questionnaires plus récents que le cache : on le vide.
    private static func resetCacheIfAppUpdated(_ directory: URL) {
        let info = Bundle.main.infoDictionary
        let version = "\(info?["CFBundleShortVersionString"] ?? "")-\(info?["CFBundleVersion"] ?? "")"
        let key = "quizCacheAppVersion"
        guard UserDefaults.standard.string(forKey: key) != version else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        files.forEach { try? FileManager.default.removeItem(at: $0) }
        UserDefaults.standard.set(version, forKey: key)
    }

    /// L'index est toujours redemandé au serveur ; les questionnaires suivent le cache HTTP (10 minutes).
    private static func download(_ path: String) async throws -> Data {
        let request = URLRequest(url: baseURL.appendingPathComponent(path),
                                 cachePolicy: path == "index.json" ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy,
                                 timeoutInterval: 10)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return data
    }
}
