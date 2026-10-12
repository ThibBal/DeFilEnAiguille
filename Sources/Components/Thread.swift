import SwiftUI

enum KnotState { case todo, current, right, wrong }

/// Un nœud du fil : un point par question.
struct Knot: View {
    let state: KnotState

    var body: some View {
        Group {
            switch state {
            case .right:
                Circle().fill(Palette.accent)
            case .wrong:
                Circle().fill(Palette.bad)
            case .current:
                Circle().fill(Palette.paper)
                    .overlay(Circle().strokeBorder(Palette.accent, lineWidth: 2))
                    .overlay(Circle().strokeBorder(Palette.ring, lineWidth: 4).frame(width: 22, height: 22))
            case .todo:
                Circle().fill(Palette.paper)
                    .overlay(Circle().strokeBorder(Palette.dotOff, lineWidth: 1.5))
            }
        }
        .frame(width: 14, height: 14)
    }
}

private struct HLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

/// Segment entre deux nœuds : plein quand il est « cousu », pointillé sinon.
private struct HSegment: View {
    let done: Bool

    var body: some View {
        Group {
            if done {
                Rectangle().fill(Palette.accent).frame(height: 2)
            } else {
                HLine().stroke(Palette.seg, style: StrokeStyle(lineWidth: 2, dash: [4, 4])).frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Barre de progression en fil à N nœuds.
struct ProgressThread: View {
    let states: [KnotState]
    let label: String

    var body: some View {
        let answered = states.filter { $0 == .right || $0 == .wrong }.count
        HStack(spacing: 6) {
            ForEach(Array(states.enumerated()), id: \.offset) { i, state in
                Knot(state: state)
                if i < states.count - 1 { HSegment(done: i < answered) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

/// Colonne verticale « nœud + fil » d'une ligne de récapitulatif.
struct VerticalThread: View {
    let state: KnotState
    let last: Bool
    var top: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            Knot(state: state).padding(.top, top)
            if !last {
                Rectangle().fill(Palette.accent)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .frame(minHeight: 22)
                    .padding(.vertical, 4)
            }
        }
        .frame(width: 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
