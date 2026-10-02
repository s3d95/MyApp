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
                    .fill(LinearGradient(colors: enabled ? [Color(hex: 0xFCD34D), Color(hex: 0xF59E0B)]
                                                         : [Theme.disabled, Theme.disabled],
                                         startPoint: .top, endPoint: .bottom))
            )
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
                .foregroundColor(Theme.cream)
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
