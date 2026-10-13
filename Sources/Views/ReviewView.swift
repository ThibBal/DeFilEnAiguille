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
                    Text("\(play.points) sur \(play.maxPoints)").font(AppFont.serif(28)).foregroundStyle(Palette.ink)
                    ScoreDots(score: play.score, total: items.count)
                }
                .padding(.top, 16)

                ReviewList(items: items, points: play.pointsList).padding(.top, 32)
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
}
