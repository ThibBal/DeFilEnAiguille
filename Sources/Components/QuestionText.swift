import SwiftUI

/// Positions mesurées dans l'espace « content » (source et destination de l'animation).
struct AnchorFrames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func reportFrame(_ id: String, in space: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: AnchorFrames.self, value: [id: g.frame(in: .named(space))])
        })
    }
}

private struct GlueKey: LayoutValueKey { static let defaultValue = false }

extension View {
    /// Colle ce mot au précédent (ponctuation, apostrophe) : pas d'espace entre les deux.
    func glued(_ value: Bool) -> some View { layoutValue(key: GlueKey.self, value: value) }
}

/// Texte qui passe à la ligne mot par mot, pour que le mot repris soit une vue à part.
struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineHeight: CGFloat

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, maxX: CGFloat = 0
        for (i, s) in subviews.enumerated() {
            var size = s.sizeThatFits(.unspecified)
            if size.width > width { size = s.sizeThatFits(ProposedViewSize(width: width, height: nil)) }
            let gap = (i == 0 || s[GlueKey.self]) ? 0 : spacing
            if x > 0 && x + gap + size.width > width {
                x = 0
                y += lineHeight
            } else if x > 0 {
                x += gap
            }
            positions.append(CGPoint(x: x, y: y + (lineHeight - size.height) / 2))
            x += size.width
            maxX = max(maxX, x)
        }
        return (positions, CGSize(width: maxX, height: y + lineHeight))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews, width: bounds.width)
        for (s, p) in zip(subviews, result.positions) {
            s.place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
}

enum LinkPhase: Equatable {
    /// Le mot est invisible : la pastille est en vol vers lui.
    case hidden
    /// La pastille vient de se poser : fond vert pâle et soulignement.
    case glow
    /// Repos : simple soulignement vert.
    case rest
}

/// Le mot (ou groupe de mots) qui reprend la réponse précédente.
struct LinkWord: View {
    let text: String
    let phase: LinkPhase

    var body: some View {
        Text(text)
            .font(AppFont.serif(32))
            .foregroundStyle(Palette.ink)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(phase == .glow ? Palette.accentSoft : .clear)
                    .padding(.horizontal, -3)
            )
            .overlay(alignment: .bottom) {
                Rectangle().fill(Palette.accent).frame(height: 2).offset(y: 1)
            }
            .opacity(phase == .hidden ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: phase)
    }
}

/// Le texte d'une question, avec le passage repris de la réponse précédente mis en valeur.
struct QuestionText: View {
    let text: String
    let link: String?
    let phase: LinkPhase
    /// Mesure la position du mot repris (destination de l'animation).
    var reportsDestination = false

    private struct Part {
        let text: String
        let isLink: Bool
        let glued: Bool
    }

    private var parts: [Part] {
        var parts: [Part] = []
        func words(_ s: Substring, glueFirst: Bool) {
            var first = true
            for w in s.split(whereSeparator: { $0.isWhitespace }) {
                parts.append(Part(text: String(w), isLink: false, glued: first && glueFirst))
                first = false
            }
        }
        guard let link, let r = text.range(of: link) else {
            words(text[...], glueFirst: false)
            return parts
        }
        let before = text[..<r.lowerBound], after = text[r.upperBound...]
        words(before, glueFirst: false)
        parts.append(Part(text: link, isLink: true, glued: !(before.last?.isWhitespace ?? true)))
        words(after, glueFirst: !(after.first?.isWhitespace ?? true))
        return parts
    }

    var body: some View {
        FlowLayout(spacing: 7, lineHeight: 36) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isLink {
                    if reportsDestination {
                        LinkWord(text: part.text, phase: phase).glued(part.glued).reportFrame("dst", in: "content")
                    } else {
                        LinkWord(text: part.text, phase: .rest).glued(part.glued)
                    }
                } else {
                    Text(part.text).font(AppFont.serif(32)).foregroundStyle(Palette.ink).glued(part.glued)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}

/// La réponse qui voyage : une pastille qui suit un fil vert qui se trace jusqu'au mot repris.
struct FlightView: View, Animatable {
    var progress: CGFloat
    let src: CGRect
    let dst: CGRect
    let text: String

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var p0: CGPoint { CGPoint(x: src.midX, y: src.midY) }
    private var p3: CGPoint { CGPoint(x: dst.midX, y: dst.midY) }
    private var p1: CGPoint { CGPoint(x: p0.x + 120, y: p0.y - 40) }
    private var p2: CGPoint { CGPoint(x: p3.x + 110, y: p3.y + 90) }

    private func point(at t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x
        let y = u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: p0)
                path.addCurve(to: p3, control1: p1, control2: p2)
            }
            .trim(from: 0, to: progress)
            .stroke(Palette.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Text(text)
                .font(AppFont.sans(17))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.accent, lineWidth: 1.5))
                .fixedSize()
                .position(point(at: progress))
        }
        .allowsHitTesting(false)
    }
}
