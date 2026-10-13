import SwiftData
import SwiftUI

private enum OptionState { case idle, correct, wrong, dim }

/// Où en est le joueur sur la question affichée : texte saisi, indice et propositions affichés, résultat.
private struct Attempt {
    var typed = ""
    var hintShown = false
    var choicesShown = false
    var wrongTries = 0
    /// Dernier texte refusé, affiché sous le champ.
    var lastWrong: String?
    var outcome: Outcome?
}

/// Facteur de durée de l'animation « le fil passe » (1 = vitesse normale).
private let flightSpeed = 1.0

/// Joue (ou rejoue) le questionnaire d'une date : 5 questions, puis le résultat et le fil du jour.
/// Entre deux questions, la bonne réponse voyage le long d'un fil jusqu'au mot qui la reprend.
struct QuizView: View {
    let date: String
    /// Rejouer : ignore la partie déjà enregistrée.
    let replay: Bool
    let showsBack: Bool
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(QuizStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var quiz: DailyQuiz?
    @State private var saved: Play?
    @State private var loaded = false
    @State private var index = 0
    @State private var attempt = Attempt()
    @State private var outcomes: [Outcome] = []
    @FocusState private var focused: Bool

    // Animation « le fil passe »
    @State private var outgoing: (index: Int, attempt: Attempt)?
    @State private var outgoingOpacity = 1.0
    @State private var incomingOpacity = 1.0
    @State private var flight: (src: CGRect, dst: CGRect, text: String)?
    @State private var flightProgress: CGFloat = 0
    @State private var flightOpacity = 1.0
    @State private var linkPhase: LinkPhase = .rest
    @State private var shownOptions = 4
    @State private var animating = false
    @State private var frames: [String: CGRect] = [:]

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
        guard outcomes.isEmpty else { return }
        quiz = store.quiz(for: date)
        let existing = try? context.fetch(FetchDescriptor<Play>(predicate: #Predicate { $0.date == date }))
        saved = replay ? nil : existing?.first
        loaded = true
    }

    // MARK: - Contenu

    @ViewBuilder
    private func content(_ quiz: DailyQuiz) -> some View {
        let total = quiz.questions.count
        let sessionDone = index >= total
        let showsResult = sessionDone || (outcomes.isEmpty && saved != nil)
        let pointsList: [Int] = outcomes.isEmpty ? (saved?.pointsList ?? []) : outcomes.map(\.points)
        let results = pointsList.map { $0 > 0 }
        let answered = attempt.outcome != nil && !showsResult
        let typing = attempt.outcome == nil && !attempt.choicesShown && !showsResult
        let canSubmit = !attempt.typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if showsBack { BackLink().padding(.top, -12) }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Wordmark()
                    Spacer(minLength: 0)
                    Text(DateKey.long(date)).font(AppFont.sans(13)).foregroundStyle(Palette.muted)
                }
                if showsResult {
                    resultView(quiz, pointsList: pointsList)
                } else {
                    let states: [KnotState] = (0..<total).map { n in
                        n < results.count ? (results[n] ? .right : .wrong) : (n == index ? .current : .todo)
                    }
                    ProgressThread(states: states, label: "Question \(index + 1) sur \(total)").padding(.top, 28)
                    ZStack(alignment: .top) {
                        questionBlock(quiz, index: min(index, total - 1), attempt: attempt, isOutgoing: false)
                            .opacity(incomingOpacity)
                        if let outgoing {
                            questionBlock(quiz, index: outgoing.index, attempt: outgoing.attempt, isOutgoing: true)
                                .opacity(outgoingOpacity)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .coordinateSpace(name: "content")
            .overlay(alignment: .topLeading) {
                if let flight {
                    FlightView(progress: flightProgress, src: flight.src, dst: flight.dst, text: flight.text)
                        .opacity(flightOpacity)
                }
            }
            .onPreferenceChange(AnchorFrames.self) { frames = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if showsResult || (answered && !animating) || (typing && !animating) {
                Group {
                    if showsResult {
                        CtaButton(title: "Voir l'historique", action: onFinish)
                    } else if answered {
                        CtaButton(title: index == total - 1 ? "Voir mon fil" : "Question suivante") { next(quiz) }
                    } else {
                        Button(action: submit) { CtaLabel(title: "Valider") }
                            .buttonStyle(PressableStyle())
                            .disabled(!canSubmit)
                            .opacity(canSubmit ? 1 : 0.4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(Palette.paper)
            }
        }
    }

    /// Une question : étiquette, texte, zone de réponse, puis points et explication une fois répondue.
    private func questionBlock(_ quiz: DailyQuiz, index i: Int, attempt a: Attempt, isOutgoing: Bool) -> some View {
        let total = quiz.questions.count
        let q = quiz.questions[i]
        return VStack(alignment: .leading, spacing: 0) {
            LabelText("Question \(i + 1) sur \(total)").padding(.top, 28)
            QuestionText(
                text: q.question,
                link: q.link,
                phase: isOutgoing ? .rest : linkPhase,
                reportsDestination: !isOutgoing
            )
            .padding(.top, 10)
            answerArea(q, attempt: a, isOutgoing: isOutgoing).padding(.top, 26)
            if let outcome = a.outcome {
                Text(pointsText(outcome))
                    .font(AppFont.sansSemi(15))
                    .foregroundStyle(outcome.isRight ? Palette.accent : Palette.muted)
                    .padding(.top, 20)
                Text(q.explanation)
                    .font(AppFont.sans(15)).exactLineHeight(22)
                    .foregroundStyle(Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
        }
    }

    private func pointsText(_ outcome: Outcome) -> String {
        guard outcome.isRight, let method = Scoring.method(points: outcome.points) else { return "0 point · mauvaise réponse" }
        return "+\(outcome.points) point\(outcome.points > 1 ? "s" : "") · \(method)"
    }

    @ViewBuilder
    private func answerArea(_ q: Question, attempt a: Attempt, isOutgoing: Bool) -> some View {
        if let outcome = a.outcome {
            if outcome.viaChoices {
                optionList(q, picked: outcome.picked, isOutgoing: isOutgoing)
            } else {
                OptionRow(letter: nil, text: q.options[q.answer], state: .correct, reportsSource: isOutgoing) {}
            }
        } else if a.choicesShown {
            VStack(alignment: .leading, spacing: 16) {
                HintCard(text: q.hint)
                optionList(q, picked: nil, isOutgoing: false)
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Votre réponse", text: $attempt.typed, prompt: Text("Votre réponse").foregroundColor(Palette.muted))
                    .font(AppFont.sans(18)).foregroundStyle(Palette.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(submit)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(focused ? Palette.ink : Palette.border, lineWidth: 1.5))
                    .accessibilityLabel("Votre réponse")
                if let wrong = a.lastWrong {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                        Text("« \(wrong) » n'est pas la bonne réponse.").font(AppFont.sans(15))
                    }
                    .foregroundStyle(Palette.wrongInk)
                    .accessibilityElement(children: .combine)
                }
                if a.hintShown {
                    HintCard(text: q.hint)
                    OutlineButton(title: "Afficher les propositions", systemImage: "list.bullet", action: showChoices)
                } else {
                    OutlineButton(title: "Indice", systemImage: "lightbulb", action: showHint)
                }
            }
            .opacity(shownOptions > 0 ? 1 : 0)
            .allowsHitTesting(!animating)
        }
    }

    private func optionList(_ q: Question, picked p: Int?, isOutgoing: Bool) -> some View {
        let answered = p != nil
        return VStack(spacing: 10) {
            ForEach(Array(q.options.enumerated()), id: \.offset) { k, text in
                let state: OptionState = !answered ? .idle : (k == q.answer ? .correct : (k == p ? .wrong : .dim))
                OptionRow(
                    letter: String("ABCD".map { $0 }[k]),
                    text: text,
                    state: state,
                    reportsSource: isOutgoing && k == q.answer
                ) { pick(k) }
                .opacity(isOutgoing || k < shownOptions ? 1 : 0)
                .allowsHitTesting(!isOutgoing && !animating)
            }
        }
    }

    private func resultView(_ quiz: DailyQuiz, pointsList: [Int]) -> some View {
        let total = quiz.questions.count
        let points = pointsList.reduce(0, +)
        let thread = saved?.title ?? quiz.thread
        return VStack(alignment: .leading, spacing: 0) {
            LabelText("Questionnaire terminé").padding(.top, 40)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(points)").font(AppFont.serif(88)).foregroundStyle(Palette.ink)
                Text("sur \(Scoring.maxPoints(questions: total))").font(AppFont.serif(32)).foregroundStyle(Palette.muted)
            }
            .padding(.top, 8)
            Text(thread).font(AppFont.serifItalic(28)).foregroundStyle(Palette.ink).padding(.top, 28)
            Text("Le fil du jour").font(AppFont.sans(15)).foregroundStyle(Palette.muted).padding(.top, 6)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(quiz.questions.enumerated()), id: \.offset) { n, item in
                    let earned = n < pointsList.count ? pointsList[n] : 0
                    HStack(alignment: .top, spacing: 16) {
                        VerticalThread(state: earned > 0 ? .right : .wrong, last: n == total - 1)
                        Text(item.short)
                            .font(AppFont.sans(18)).foregroundStyle(Palette.ink)
                            .padding(.bottom, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(earned) pt\(earned > 1 ? "s" : "")")
                            .font(AppFont.sans(14)).foregroundStyle(Palette.muted)
                            .padding(.top, 3)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.short), \(earned > 0 ? "bonne" : "mauvaise") réponse, \(earned) point\(earned > 1 ? "s" : "")")
                }
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Actions

    private var currentQuestion: Question? {
        quiz.map { $0.questions[min(index, $0.questions.count - 1)] }
    }

    /// Valide le texte saisi : bonne réponse (5 points, ou 3 si l'indice a été vu), sinon l'indice s'affiche,
    /// et au deuxième échec les propositions.
    private func submit() {
        guard let q = currentQuestion, attempt.outcome == nil, !animating else { return }
        let text = attempt.typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if q.accepts(text) {
            resolve(Outcome(points: attempt.hintShown ? Scoring.withHint : Scoring.withoutHint,
                            wrongAnswer: nil, viaChoices: false, picked: nil))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            attempt.lastWrong = text
            attempt.typed = ""
            attempt.hintShown = true
            attempt.wrongTries += 1
            if attempt.wrongTries >= 2 { showChoices() }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    private func showHint() { attempt.hintShown = true }

    private func showChoices() {
        attempt.hintShown = true
        attempt.choicesShown = true
        focused = false
    }

    /// Choix d'une proposition : 1 point si c'est la bonne.
    private func pick(_ k: Int) {
        guard let q = currentQuestion, attempt.outcome == nil, !animating else { return }
        let right = k == q.answer
        resolve(Outcome(points: right ? Scoring.withChoices : 0, wrongAnswer: right ? nil : q.options[k],
                        viaChoices: true, picked: k))
    }

    private func resolve(_ outcome: Outcome) {
        attempt.outcome = outcome
        outcomes.append(outcome)
        focused = false
    }

    private func next(_ quiz: DailyQuiz) {
        let total = quiz.questions.count
        if index == total - 1 {
            History.save(date: date, quiz: quiz, outcomes: outcomes, in: context)
            index += 1
            attempt = Attempt()
            return
        }
        guard !reduceMotion, quiz.questions[index + 1].link != nil, attempt.outcome != nil else {
            index += 1
            attempt = Attempt()
            Task { @MainActor in focused = true }
            return
        }
        // Le fil passe : l'ancienne question reste affichée le temps du vol, la nouvelle s'installe dessous.
        let q = quiz.questions[index]
        outgoing = (index, attempt)
        outgoingOpacity = 1
        incomingOpacity = 0
        flightProgress = 0
        flightOpacity = 1
        linkPhase = .hidden
        shownOptions = 0
        animating = true
        index += 1
        attempt = Attempt()
        Task { await runFlight(text: q.options[q.answer]) }
    }

    @MainActor
    private func runFlight(text: String) async {
        func pause(_ ms: Int) async { try? await Task.sleep(for: .milliseconds(Int(Double(ms) * flightSpeed))) }

        await pause(80) // laisse la nouvelle question se mettre en page, pour mesurer le mot visé
        guard let src = frames["src"], let dst = frames["dst"] else {
            finishFlight()
            return
        }
        flight = (src, dst, text)
        withAnimation(.easeOut(duration: 0.25 * flightSpeed)) { outgoingOpacity = 0 }
        await pause(300)
        withAnimation(.easeOut(duration: 0.35 * flightSpeed)) { incomingOpacity = 1 }
        withAnimation(.easeInOut(duration: 0.7 * flightSpeed)) { flightProgress = 1 }
        await pause(700)
        linkPhase = .glow
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.3 * flightSpeed)) { flightOpacity = 0 }
        for k in 1...4 {
            await pause(70)
            withAnimation(.easeOut(duration: 0.3 * flightSpeed)) { shownOptions = k }
        }
        await pause(250)
        linkPhase = .rest
        finishFlight()
    }

    private func finishFlight() {
        incomingOpacity = 1
        linkPhase = .rest
        shownOptions = 4
        outgoing = nil
        flight = nil
        animating = false
        focused = true
    }
}

private struct OptionRow: View {
    let letter: String?
    let text: String
    let state: OptionState
    var reportsSource = false
    let action: () -> Void

    var body: some View {
        let style = Self.colors(state)
        Button(action: action) {
            HStack(spacing: 14) {
                if let letter {
                    Text(letter).font(AppFont.serif(20)).foregroundStyle(Palette.muted).frame(width: 18, alignment: .leading)
                }
                label(style.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(letter.map { "\($0). \(text)" } ?? text)
    }

    @ViewBuilder
    private func label(_ color: Color) -> some View {
        let t = Text(text).font(AppFont.sans(17)).foregroundStyle(color).multilineTextAlignment(.leading)
        if reportsSource {
            t.reportFrame("src", in: "content")
        } else {
            t
        }
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

/// Indice affiché sous le champ de saisie.
private struct HintCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabelText("Indice", size: 12)
            Text(text).font(AppFont.sans(16)).foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.border, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}

/// Bouton secondaire à contour, 50 pt de haut.
private struct OutlineButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage).font(.system(size: 15, weight: .medium))
                Text(title).font(AppFont.sansSemi(16))
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.border, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }
}
