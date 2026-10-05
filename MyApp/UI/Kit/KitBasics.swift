import SwiftUI
import UIKit

// MARK: - Typography

extension Font {
    /// The game's chunky display type: Baloo Bhaijaan 2 (OFL) for headings, numbers and buttons,
    /// Cairo (OFL) for lighter text. Both cover Arabic and Latin.
    static func game(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        switch weight {
        case .black, .heavy:
            return .custom("BalooBhaijaan2-ExtraBold", size: size)
        case .bold, .semibold:
            return .custom("BalooBhaijaan2-Bold", size: size)
        default:
            return .custom("Cairo-SemiBold", size: size)
        }
    }

    /// Body copy (descriptions, dialogue).
    static func body(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Cairo-Bold" : "Cairo-SemiBold", size: size)
    }
}

/// Small text with a dark outline so it reads on any art (labels on icons, badges).
struct OutlinedText: View {
    let text: String
    var size: CGFloat = 14
    var color: Color = .white
    var outline: Color = Brand.outline

    var body: some View {
        let base = Text(text).font(.game(size, .black))
        ZStack {
            ForEach(0..<8, id: \.self) { k in
                let a = Double(k) / 8 * 2 * Double.pi
                base.foregroundColor(outline)
                    .offset(x: CGFloat(cos(a)) * 1.6, y: CGFloat(sin(a)) * 1.6)
            }
            base.foregroundColor(color)
        }
    }
}

// MARK: - Art

/// A 3D icon from the Fluent emoji art pack (see ThirdParty/LICENSE-fluentui-emoji.txt).
struct ArtIcon: View {
    let key: String
    var size: CGFloat = 44
    var shadow = true

    init(_ key: String, size: CGFloat = 44, shadow: Bool = true) {
        self.key = key
        self.size = size
        self.shadow = shadow
    }

    var body: some View {
        Group {
            if UIImage(named: key) != nil {
                Image(key)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: shadow ? Color.black.opacity(0.35) : .clear, radius: size * 0.06, y: size * 0.05)
    }
}

// MARK: - Buttons

enum ChunkyColor {
    case gold, green, red, blue, purple, wood, gray

    var top: Color {
        switch self {
        case .gold: return Brand.goldLight
        case .green: return Color(hex: 0x7EE07A)
        case .red: return Color(hex: 0xFF7A5C)
        case .blue: return Color(hex: 0x6CB8FF)
        case .purple: return Color(hex: 0xC59BFF)
        case .wood: return Brand.woodLight
        case .gray: return Color(hex: 0x8A7A6E)
        }
    }

    var bottom: Color {
        switch self {
        case .gold: return Brand.gold
        case .green: return Color(hex: 0x34B04A)
        case .red: return Color(hex: 0xE0472C)
        case .blue: return Color(hex: 0x2F84E0)
        case .purple: return Color(hex: 0x8B4FE0)
        case .wood: return Brand.wood
        case .gray: return Color(hex: 0x5E5048)
        }
    }

    var edge: Color {
        switch self {
        case .gold: return Brand.goldDeep
        case .green: return Color(hex: 0x1F7A33)
        case .red: return Color(hex: 0x9E2A16)
        case .blue: return Color(hex: 0x1C5BA6)
        case .purple: return Color(hex: 0x5B2CA6)
        case .wood: return Brand.woodDark
        case .gray: return Color(hex: 0x3C322C)
        }
    }

    var text: Color {
        switch self {
        case .gold: return Brand.outline
        default: return .white
        }
    }
}

/// Supercell-style button: glossy face, darker bottom edge, sinks when pressed.
struct ChunkyStyle: ButtonStyle {
    var color: ChunkyColor = .gold
    var radius: CGFloat = 14
    var depth: CGFloat = 5
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        let c = enabled ? color : .gray
        let pressed = configuration.isPressed && enabled
        return configuration.label
            .foregroundColor(c.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minHeight: 40)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0)],
                                             startPoint: .top, endPoint: .center))
                        .padding(3)
                }
            )
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Brand.outline.opacity(0.55), lineWidth: 1.5))
            .offset(y: pressed ? depth - 1 : 0)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(c.edge)
                    .offset(y: depth)
            )
            .padding(.bottom, depth)
            .opacity(enabled ? 1 : 0.85)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressed)
    }
}

/// Convenience chunky button with an optional 3D icon and a price line.
struct ChunkyButton: View {
    let title: String
    var icon: String? = nil
    var subtitle: String? = nil
    var color: ChunkyColor = .gold
    var enabled = true
    var sound: SFX? = .tap
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else {
                Haptic.error()
                SFX.error.play(volume: 0.6)
                return
            }
            Haptic.press()
            if let s = sound { s.play() }
            action()
        } label: {
            HStack(spacing: 6) {
                if let i = icon { ArtIcon(i, size: 22, shadow: false) }
                VStack(spacing: 0) {
                    Text(title)
                        .font(.game(subtitle == nil ? 15 : 12, .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let s = subtitle {
                        Text(s)
                            .font(.game(14, .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyStyle(color: color, enabled: enabled))
    }
}

/// Round icon-only button (close, info, settings).
struct RoundIconButton: View {
    let system: String
    var color: ChunkyColor = .red
    var size: CGFloat = 34
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.tap()
            SFX.pop.play(volume: 0.7)
            action()
        } label: {
            Image(systemName: system)
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(LinearGradient(colors: [color.top, color.bottom], startPoint: .top, endPoint: .bottom)))
                .overlay(Circle().stroke(Brand.outline.opacity(0.6), lineWidth: 1.5))
                .background(Circle().fill(color.edge).offset(y: 3))
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Panels and labels

/// Wooden card with a golden inner frame; the base container of every screen.
struct WoodPanel<Content: View>: View {
    var padding: CGFloat = 12
    var highlight = false
    let content: Content

    init(padding: CGFloat = 12, highlight: Bool = false, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.highlight = highlight
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x5C321C), Color(hex: 0x45241A)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(highlight ? Brand.gold : Brand.gold.opacity(0.22), lineWidth: highlight ? 2 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .padding(3)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
    }
}

/// Banner with notched ends, for screen and modal titles.
struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = rect.height * 0.35
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

struct Ribbon: View {
    let text: String
    var color: Color = Brand.red
    var size: CGFloat = 18

    var body: some View {
        OutlinedText(text: text, size: size, color: .white)
            .padding(.horizontal, size * 1.8)
            .padding(.vertical, size * 0.45)
            .background(
                RibbonShape()
                    .fill(LinearGradient(colors: [color.opacity(1), color.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .overlay(RibbonShape().stroke(Brand.outline, lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.35), radius: 3, y: 3)
    }
}

/// Red notification dot, optionally with a count.
struct RedDot: View {
    var count: Int? = nil

    var body: some View {
        Group {
            if let n = count, n > 0 {
                Text(n > 99 ? "99+" : "\(n)")
                    .font(.game(10, .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(Capsule().fill(Brand.red))
                    .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
            } else {
                Circle()
                    .fill(Brand.red)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Small colored capsule label.
struct Tag: View {
    let text: String
    var color: Color = Brand.gold
    var textColor: Color = Brand.outline

    var body: some View {
        Text(text)
            .font(.game(10, .black))
            .foregroundColor(textColor)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }
}

// MARK: - Bars

/// Glossy progress bar with an optional centered label.
struct FancyBar: View {
    let value: Double
    var tint: Color = Brand.gold
    var height: CGFloat = 14
    var label: String? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let v = CGFloat(min(1, max(0, value.isFinite ? value : 0)))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.4))
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(1), tint.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: v > 0 ? max(height, w * v) : 0)
                    .overlay(
                        Capsule().fill(Color.white.opacity(0.35))
                            .frame(height: max(2, height * 0.22))
                            .padding(.horizontal, height * 0.35)
                            .offset(y: -height * 0.2),
                        alignment: .top
                    )
                if let l = label {
                    OutlinedText(text: l, size: max(9, height * 0.62))
                        .frame(maxWidth: .infinity)
                }
            }
            .overlay(Capsule().stroke(Brand.outline.opacity(0.8), lineWidth: 1.5))
        }
        .frame(height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

// MARK: - Modal

/// Centered modal with a ribbon title and a close button; dims and blocks the game behind it.
struct GameModal<Content: View>: View {
    let title: String
    var onClose: (() -> Void)? = nil
    let content: Content
    @State private var appeared = false

    init(title: String, onClose: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture { onClose?() }
            VStack(spacing: 0) {
                Ribbon(text: title)
                    .zIndex(1)
                    .offset(y: 14)
                VStack(spacing: 12) { content }
                    .padding(.top, 26)
                    .padding([.horizontal, .bottom], 18)
                    .frame(maxWidth: 360)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: 0x6A3A20), Color(hex: 0x4A2718)],
                                                 startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Brand.gold, lineWidth: 2.5))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Brand.outline.opacity(0.6), lineWidth: 2).padding(4))
                    .overlay(Group {
                        if let close = onClose {
                            RoundIconButton(system: "xmark", action: close)
                                .offset(x: 10, y: -10)
                        }
                    }, alignment: .topTrailing)
            }
            .padding(.horizontal, 20)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { appeared = true }
            SFX.whoosh.play(volume: 0.5)
        }
    }
}
