import SwiftData
import SwiftUI

private enum OptionState { case idle, correct, wrong, dim }

/// Joue (ou rejoue) le questionnaire d'une date : 5 questions, puis le résultat et le fil du jour.
struct QuizView: View {
    let date: String
    /// Rejouer : ignore la partie déjà enregistrée.
    let replay: Bool
    let showsBack: Bool
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var quiz: DailyQuiz?
    @State private var saved: Play?
    @State private var loaded = false
    @State private var index = 0
    @State private var picked: Int?
    @State private var choices: [Int] = []

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            if let quiz {
                content(quiz)
            } else if loaded {
                VStack(alignment: .leading) {
                    if showsBack { BackLink() }
                    Text("Pas de questionnaire pour cette date.")
                        .font(AppFont.sans(16)).foregroundStyle(Palette.muted).padding(.top, 24)
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: load)
    }

    /// Charge le questionnaire et la partie enregistrée, sauf si une partie est en cours dans cet écran.
    private func load() {
        guard choices.isEmpty else { return }
        quiz = QuizCatalog.shared.quiz(for: date)
        let existing = try? context.fetch(FetchDescriptor<Play>(predicate: #Predicate { $0.date == date }))
        saved = replay ? nil : existing?.first
        loaded = true
    }

    // MARK: - Contenu

    @ViewBuilder
    private func content(_ quiz: DailyQuiz) -> some View {
        let total = quiz.questions.count
        let sessionDone = index >= total
        let showsResult = sessionDone || (choices.isEmpty && saved != nil)
        let results: [Bool] = choices.isEmpty
            ? (saved?.detail.map { $0.mine == nil } ?? [])
            : choices.enumerated().map { $1 == quiz.questions[$0].answer }
        let answered = picked != nil && !showsResult

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if showsBack { BackLink().padding(.top, -12) }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Wordmark()
                    Spacer(minLength: 0)
                    Text(DateKey.long(date)).font(AppFont.sans(13)).foregroundStyle(Palette.muted)
                }
                if showsResult {
                    resultView(quiz, results: results)
                } else {
                    questionView(quiz, results: results, answered: answered)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            if answered || showsResult {
                Group {
                    if showsResult {
                        CtaButton(title: "Voir l'historique", action: onFinish)
                    } else {
                        CtaButton(title: index == total - 1 ? "Voir mon fil" : "Question suivante", action: next)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(Palette.paper)
            }
        }
    }

    private func questionView(_ quiz: DailyQuiz, results: [Bool], answered: Bool) -> some View {
        let total = quiz.questions.count
        let q = quiz.questions[min(index, total - 1)]
        let states: [KnotState] = (0..<total).map { n in
            n < results.count ? (results[n] ? .right : .wrong) : (n == index ? .current : .todo)
        }
        return VStack(alignment: .leading, spacing: 0) {
            ProgressThread(states: states, label: "Question \(index + 1) sur \(total)").padding(.top, 28)
            LabelText("Question \(index + 1) sur \(total)").padding(.top, 28)
            Text(q.question)
                .font(AppFont.serif(32)).exactLineHeight(36)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { k, text in
                    let state: OptionState = !answered ? .idle : (k == q.answer ? .correct : (k == picked ? .wrong : .dim))
                    OptionRow(letter: String("ABCD".map { $0 }[k]), text: text, state: state) { pick(k, q) }
                }
            }
            .padding(.top, 26)
            if answered {
                Text(q.explanation)
                    .font(AppFont.sans(15)).exactLineHeight(22)
                    .foregroundStyle(Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)
            }
        }
    }

    private func resultView(_ quiz: DailyQuiz, results: [Bool]) -> some View {
        let total = quiz.questions.count
        let score = results.filter { $0 }.count
        let thread = saved?.title ?? quiz.thread
        return VStack(alignment: .leading, spacing: 0) {
            LabelText("Questionnaire terminé").padding(.top, 40)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(score)").font(AppFont.serif(88)).foregroundStyle(Palette.ink)
                Text("sur \(total)").font(AppFont.serif(32)).foregroundStyle(Palette.muted)
            }
            .padding(.top, 8)
            Text(thread).font(AppFont.serifItalic(28)).foregroundStyle(Palette.ink).padding(.top, 28)
            Text("Le fil du jour").font(AppFont.sans(15)).foregroundStyle(Palette.muted).padding(.top, 6)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(quiz.questions.enumerated()), id: \.offset) { n, item in
                    let right = n < results.count ? results[n] : false
                    HStack(alignment: .top, spacing: 16) {
                        VerticalThread(state: right ? .right : .wrong, last: n == total - 1)
                        Text(item.short)
                            .font(AppFont.sans(18)).foregroundStyle(Palette.ink)
                            .padding(.bottom, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.short), \(right ? "bonne" : "mauvaise") réponse")
                }
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Actions

    private func pick(_ k: Int, _ q: Question) {
        guard picked == nil else { return }
        picked = k
        choices.append(k)
    }

    private func next() {
        guard let quiz else { return }
        if index == quiz.questions.count - 1 {
            History.save(date: date, quiz: quiz, picked: choices, in: context)
        }
        index += 1
        picked = nil
    }
}

private struct OptionRow: View {
    let letter: String
    let text: String
    let state: OptionState
    let action: () -> Void

    var body: some View {
        let style = Self.colors(state)
        Button(action: action) {
            HStack(spacing: 14) {
                Text(letter).font(AppFont.serif(20)).foregroundStyle(Palette.muted).frame(width: 18, alignment: .leading)
                Text(text).font(AppFont.sans(17)).foregroundStyle(style.text)
                    .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                if state == .correct {
                    Image(systemName: "checkmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.accent)
                } else if state == .wrong {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.bad)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(minHeight: 54)
            .background(style.bg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style.border, style: StrokeStyle(lineWidth: 1.5, dash: state == .wrong ? [6, 4] : []))
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(state == .idle)
        .accessibilityLabel("\(letter). \(text)")
    }

    private static func colors(_ s: OptionState) -> (border: Color, bg: Color, text: Color) {
        switch s {
        case .correct: (Palette.accent, Palette.accentSoft, Palette.ink)
        case .wrong: (Palette.bad, Palette.wrongBg, Palette.wrongInk)
        case .dim: (Palette.dimBorder, .clear, Palette.muted)
        case .idle: (Palette.border, Palette.card, Palette.ink)
        }
    }
}
