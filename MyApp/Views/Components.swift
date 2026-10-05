import SwiftUI

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PriceButton: View {
    let title: String
    let price: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .opacity(0.85)
                Text(price)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(enabled ? .white : Theme.muted.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: enabled ? [Color(hex: 0x22C55E), Color(hex: 0x15803D)]
                                                         : [Theme.disabled, Theme.disabled],
                                         startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}

struct BigButtonLabel: View {
    let text: String
    var enabled: Bool = true

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundColor(enabled ? Color(hex: 0x2A1608) : Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: enabled ? [Brand.goldLight, Brand.gold]
                                                         : [Theme.disabled, Theme.disabled],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(enabled ? Brand.outline.opacity(0.7) : Color.clear, lineWidth: 2))
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(enabled ? Brand.goldDeep : Color.clear)
                .offset(y: 4))
            .padding(.bottom, 4)
    }
}

struct EmojiBubble: View {
    let emoji: String
    let tint: Color
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.45)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 1.5)
            Text(emoji).font(.system(size: size * 0.5))
        }
        .frame(width: size, height: size)
    }
}

struct PulseRing: View {
    @State private var on = false

    var body: some View {
        Circle()
            .stroke(Theme.gold, lineWidth: 2.5)
            .scaleEffect(on ? 1.12 : 0.96)
            .opacity(on ? 0.15 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { on = true }
            }
            .allowsHitTesting(false)
    }
}

struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(Theme.cream)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.08)))
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Brand.titleFill)
                .shadow(color: Brand.outline.opacity(0.9), radius: 0, x: 0, y: 2)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModalCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 14) { content }
                .padding(22)
                .frame(maxWidth: 340)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Theme.gold.opacity(0.35), lineWidth: 1))
                .padding(24)
        }
    }
}

/// Button that spends gold liras.
struct GoldButton: View {
    let title: String
    let cost: Int
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .opacity(0.85)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("🪙 \(cost)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(enabled ? Color(hex: 0x2A1608) : Theme.muted.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: enabled ? [Color(hex: 0xFDE047), Color(hex: 0xEAB308)]
                                                         : [Theme.disabled, Theme.disabled],
                                         startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}

/// Plain call-to-action button with a solid color.
struct ActionButton: View {
    let title: String
    var tint: Color = Color(hex: 0x22C55E)
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(enabled ? .white : Theme.muted.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(enabled ? tint : Theme.disabled))
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}

struct ProgressBar: View {
    let value: Double
    var tint: Color = Theme.gold
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.35))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * CGFloat(min(1, max(0, value)))))
                    .opacity(value > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
    }
}

/// Horizontal row of selectable chips, used as sub-tabs.
struct SegmentChips<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let title: (T) -> String
    var badge: (T) -> Bool = { _ in false }
    @EnvironmentObject var game: Game

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    chip(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func chip(_ item: T) -> some View {
        let on = selection == item
        return Button {
            selection = item
            if game.s.hapticsOn { Feedback.light() }
        } label: {
            Text(title(item))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(on ? Color(hex: 0x2A1608) : Theme.cream)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Capsule().fill(on ? Theme.gold : Color.white.opacity(0.07)))
                .overlay(Group {
                    if badge(item) {
                        Circle().fill(Theme.red).frame(width: 8, height: 8).offset(x: -2, y: 2)
                    }
                }, alignment: .topTrailing)
        }
        .buttonStyle(PressableStyle())
    }
}

/// A drawn treasure chest tinted by its kind.
struct ChestIcon: View {
    let kind: ChestKind
    var size: CGFloat = 54
    var open: Bool = false

    var body: some View {
        let tint = Color(hex: kind.tint)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size * 0.6)
                .offset(y: size * 0.16)
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(1), tint.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 1.06, height: size * 0.34)
                .rotationEffect(.degrees(open ? -24 : 0), anchor: .bottomLeading)
                .offset(y: open ? -size * 0.36 : -size * 0.2)
            Rectangle()
                .fill(Color.black.opacity(0.22))
                .frame(width: size * 0.13, height: size * 0.6)
                .offset(y: size * 0.16)
            Circle()
                .fill(Theme.gold)
                .frame(width: size * 0.2, height: size * 0.2)
                .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                .offset(y: size * 0.02)
        }
        .frame(width: size * 1.1, height: size)
        .shadow(color: tint.opacity(0.55), radius: 8)
    }
}

/// Small pill with the gold lira balance.
struct LiraChip: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🪙").font(.system(size: 12))
            Text(Fmt.number(Double(amount)))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(Theme.lira)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.lira.opacity(0.12)))
        .overlay(Capsule().stroke(Theme.lira.opacity(0.35), lineWidth: 1))
    }
}

struct CardTitle: View {
    let icon: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.system(size: 20))
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Spacer()
            if let t = trailing {
                Text(t)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
            }
        }
    }
}
