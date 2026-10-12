import SwiftUI

/// Petite étiquette en capitales espacées.
struct LabelText: View {
    let text: String
    var color: Color = Palette.muted
    var size: CGFloat = 13

    init(_ text: String, color: Color = Palette.muted, size: CGFloat = 13) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text.uppercased()).font(AppFont.sansMedium(size)).tracking(1).foregroundStyle(color)
    }
}

/// Signature de l'application, en haut de chaque écran.
struct Wordmark: View {
    var body: some View {
        Text("De fil en aiguille").font(AppFont.serifItalic(24)).foregroundStyle(Palette.ink)
    }
}

/// Apparence du bouton principal plein, 56 pt de haut.
struct CtaLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppFont.sansSemi(17))
            .foregroundStyle(Palette.paper)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
    }
}

struct CtaButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { CtaLabel(title: title) }.buttonStyle(PressableStyle())
    }
}

/// Léger voile au toucher, comme dans la maquette.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Cinq points : pleins pour les bonnes réponses, vides pour les autres.
struct ScoreDots: View {
    let score: Int?
    var total = 5

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                let on = score != nil && i < (score ?? 0)
                Circle()
                    .fill(on ? Palette.accent : .clear)
                    .overlay(Circle().strokeBorder(on ? Palette.accent : Palette.dotOff, lineWidth: 1.5))
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score == nil ? "Non joué" : "\(score ?? 0) bonnes réponses sur \(total)")
    }
}

/// Lien « < Historique » en haut des écrans ouverts depuis l'historique.
struct BackLink: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium))
                Text("Historique").font(AppFont.sansMedium(15))
            }
            .foregroundStyle(Palette.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Retour à l'historique")
    }
}

extension View {
    /// Hauteur de ligne exacte, comme dans les maquettes (iOS 26 et plus ; avant, l'interligne par défaut).
    @ViewBuilder
    func exactLineHeight(_ points: CGFloat) -> some View {
        if #available(iOS 26, *) {
            self.lineHeight(.exact(points: points))
        } else {
            self
        }
    }
}
