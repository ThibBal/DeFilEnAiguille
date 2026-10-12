import SwiftData
import SwiftUI

/// Revue d'un questionnaire passé, question par question, avec la possibilité de le rejouer.
struct ReviewView: View {
    let date: String
    @Query private var plays: [Play]

    init(date: String) {
        self.date = date
        _plays = Query(filter: #Predicate<Play> { $0.date == date })
    }

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            if let play = plays.first {
                content(play)
            } else {
                VStack(alignment: .leading) {
                    BackLink()
                    Text("Ce questionnaire n'est pas disponible.")
                        .font(AppFont.sans(16)).foregroundStyle(Palette.muted).padding(.top, 24)
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ play: Play) -> some View {
        let items = play.detail
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackLink().padding(.top, 0)
                LabelText(DateKey.full(date)).padding(.top, 20)
                Text(play.title)
                    .font(AppFont.serifItalic(38)).exactLineHeight(41).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8).accessibilityAddTraits(.isHeader)
                HStack(spacing: 12) {
                    Text("\(play.score) sur \(items.count)").font(AppFont.serif(28)).foregroundStyle(Palette.ink)
                    ScoreDots(score: play.score, total: items.count)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                        HStack(alignment: .top, spacing: 16) {
                            VerticalThread(state: item.mine == nil ? .right : .wrong, last: i == items.count - 1, top: 3)
                            VStack(alignment: .leading, spacing: 0) {
                                LabelText("Question \(i + 1)", size: 12)
                                Text(item.question)
                                    .font(AppFont.serif(23)).exactLineHeight(28).foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
                                answer(item).padding(.top, 10)
                            }
                            .padding(.bottom, 28)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(value: Route.play(date, replay: true)) { CtaLabel(title: "Rejouer") }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 24).padding(.bottom, 16)
                .background(Palette.paper)
        }
    }

    @ViewBuilder
    private func answer(_ item: ReviewItem) -> some View {
        if let mine = item.mine {
            VStack(alignment: .leading, spacing: 4) {
                (Text("Votre réponse · ").font(AppFont.sans(14)).foregroundColor(Palette.muted)
                    + Text(mine).font(AppFont.sans(16)).strikethrough().foregroundColor(Palette.wrongInk))
                (Text("Bonne réponse · ").font(AppFont.sans(14)).foregroundColor(Palette.muted)
                    + Text(item.right).font(AppFont.sans(16)).foregroundColor(Palette.ink))
            }
        } else {
            (Text(item.right).font(AppFont.sans(16)).foregroundColor(Palette.ink)
                + Text(" · bonne réponse").font(AppFont.sans(14)).foregroundColor(Palette.muted))
        }
    }
}
