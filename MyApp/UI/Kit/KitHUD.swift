import SwiftUI

/// Currency counter for the top bar. Pops when coins fly into it (anchor id = `anchor`).
struct CurrencyPill: View {
    let icon: String
    let text: String
    var anchor: String? = nil
    var tint: Color = Brand.cream
    var onPlus: (() -> Void)? = nil
    @ObservedObject private var fx = FX.shared

    var body: some View {
        HStack(spacing: 4) {
            ArtIcon(icon, size: 26)
                .padding(.leading, -6)
            Text(text)
                .font(.game(15, .black).monospacedDigit())
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let plus = onPlus {
                Button {
                    Haptic.tap()
                    SFX.pop.play(volume: 0.6)
                    plus()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color(hex: 0x34B04A)))
                        .overlay(Circle().stroke(Brand.outline.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, onPlus == nil ? 10 : 4)
        .frame(height: 30)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(Capsule().stroke(Brand.gold.opacity(0.35), lineWidth: 1))
        .bump(on: anchor.map { fx.landed[$0, default: 0] } ?? 0)
        .modifier(OptionalAnchor(id: anchor))
    }
}

private struct OptionalAnchor: ViewModifier {
    let id: String?

    func body(content: Content) -> some View {
        if let id = id {
            content.fxAnchor(id)
        } else {
            content
        }
    }
}

/// Player avatar with an XP ring and the level number, top-left of the HUD.
struct LevelBadge: View {
    let level: Int
    let progress: Double
    var avatar: String = "ppl_cook"

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Brand.woodLight, Brand.woodDark], startPoint: .top, endPoint: .bottom))
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                .stroke(Brand.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)
            ArtIcon(avatar, size: 34, shadow: false)
            Text("\(level)")
                .font(.game(11, .black))
                .foregroundColor(Brand.outline)
                .frame(minWidth: 20, minHeight: 20)
                .background(Circle().fill(Brand.titleFill))
                .overlay(Circle().stroke(Brand.outline, lineWidth: 1.5))
                .offset(x: 17, y: 17)
        }
        .frame(width: 46, height: 46)
        .overlay(Circle().stroke(Brand.outline, lineWidth: 2))
    }
}

/// Floating round side button with a 3D icon, an optional timer/label and a red dot.
struct SideButton: View {
    let icon: String
    var label: String? = nil
    var badge = false
    var count: Int? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.tap()
            SFX.pop.play(volume: 0.6)
            action()
        } label: {
            VStack(spacing: 1) {
                ArtIcon(icon, size: 34)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.black.opacity(0.45)))
                    .overlay(Circle().stroke(Brand.gold.opacity(0.55), lineWidth: 1.5))
                if let l = label {
                    OutlinedText(text: l, size: 10)
                        .lineLimit(1)
                }
            }
            .overlay(Group {
                if badge || (count ?? 0) > 0 { RedDot(count: count).offset(x: 4, y: -2) }
            }, alignment: .topTrailing)
        }
        .buttonStyle(PressScaleStyle())
    }
}
