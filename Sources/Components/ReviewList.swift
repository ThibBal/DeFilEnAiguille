import SwiftUI

/// Détail d'un questionnaire terminé : chaque question, la réponse donnée et la bonne, les points gagnés.
/// Partagé entre l'écran de fin de partie et la revue de l'historique.
struct ReviewList: View {
    let items: [ReviewItem]
    /// Points de chaque question, dans le même ordre que `items`.
    let points: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                let earned = i < points.count ? points[i] : 0
                HStack(alignment: .top, spacing: 16) {
                    VerticalThread(state: earned > 0 ? .right : .wrong, last: i == items.count - 1, top: 3)
                    VStack(alignment: .leading, spacing: 0) {
                        LabelText("Question \(i + 1)", size: 12)
                        Text(item.question)
                            .font(AppFont.serif(23)).exactLineHeight(28).foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
                        answer(item, points: earned).padding(.top, 10)
                    }
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private func answer(_ item: ReviewItem, points: Int) -> some View {
        if let mine = item.mine {
            VStack(alignment: .leading, spacing: 4) {
                (Text("Votre réponse · ").font(AppFont.sans(14)).foregroundColor(Palette.muted)
                    + Text(mine).font(AppFont.sans(16)).strikethrough().foregroundColor(Palette.wrongInk))
                (Text("Bonne réponse · ").font(AppFont.sans(14)).foregroundColor(Palette.muted)
                    + Text(item.right).font(AppFont.sans(16)).foregroundColor(Palette.ink))
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                (Text(item.right).font(AppFont.sans(16)).foregroundColor(Palette.ink)
                    + Text(" · bonne réponse").font(AppFont.sans(14)).foregroundColor(Palette.muted))
                if let method = Scoring.method(points: points) {
                    Text("\(points) point\(points > 1 ? "s" : "") · \(method)")
                        .font(AppFont.sans(14)).foregroundColor(Palette.muted)
                }
            }
        }
    }
}
