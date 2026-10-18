import SwiftUI

/// Regular polygon with a flat top, used for rare (6 sides) and epic (8 sides) frames.
struct PolygonShape: Shape {
    var sides: Int

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        let offset = Double.pi / Double(sides)
        for k in 0..<sides {
            let a = Double(k) / Double(sides) * 2 * Double.pi - Double.pi / 2 + offset
            let pt = CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Scalloped badge for legendary frames.
struct ScallopShape: Shape {
    var bumps = 12

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.86
        var p = Path()
        let steps = bumps * 12
        for k in 0...steps {
            let a = Double(k) / Double(steps) * 2 * Double.pi
            let rr = inner + (r - inner) * CGFloat(abs(sin(a * Double(bumps) / 2)))
            let pt = CGPoint(x: c.x + rr * CGFloat(cos(a)), y: c.y + rr * CGFloat(sin(a)))
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return Color(hex: 0x9A6A3F)
        case .rare: return Color(hex: 0x2FA59A)
        case .epic: return Color(hex: 0x9B5DE5)
        case .legendary: return Brand.gold
        }
    }

    var dark: Color {
        switch self {
        case .common: return Color(hex: 0x5A3A20)
        case .rare: return Color(hex: 0x17625B)
        case .epic: return Color(hex: 0x5B2C9E)
        case .legendary: return Brand.goldDeep
        }
    }
}

/// Chef portrait in a frame whose shape and colour show the rarity (GDD 1.5).
struct RarityFrame: View {
    let rarity: Rarity
    let art: String
    var size: CGFloat = 64
    var dimmed = false

    var body: some View {
        ZStack {
            frame(fill: true)
            frame(fill: false)
            ArtIcon(art, size: size * 0.66)
                .saturation(dimmed ? 0 : 1)
                .opacity(dimmed ? 0.35 : 1)
            if rarity == .epic || rarity == .legendary {
                gems
            }
        }
        .frame(width: size, height: size)
        .shine(rarity == .legendary && !dimmed)
    }

    @ViewBuilder
    private func frame(fill: Bool) -> some View {
        let grad = LinearGradient(colors: [rarity.color.opacity(dimmed ? 0.35 : 0.9), rarity.dark.opacity(dimmed ? 0.4 : 1)],
                                  startPoint: .top, endPoint: .bottom)
        switch rarity {
        case .common:
            if fill {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).fill(grad)
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).stroke(Brand.outline, lineWidth: 2.5)
            }
        case .rare:
            if fill { PolygonShape(sides: 6).fill(grad) } else { PolygonShape(sides: 6).stroke(Brand.outline, lineWidth: 2.5) }
        case .epic:
            if fill { PolygonShape(sides: 8).fill(grad) } else { PolygonShape(sides: 8).stroke(Brand.outline, lineWidth: 2.5) }
        case .legendary:
            if fill { ScallopShape().fill(grad) } else { ScallopShape().stroke(Brand.outline, lineWidth: 2.5) }
        }
    }

    private var gems: some View {
        let n = rarity == .legendary ? 4 : 2
        return ZStack {
            ForEach(0..<n, id: \.self) { k in
                Circle()
                    .fill(RadialGradient(colors: [Color.white, rarity == .legendary ? Brand.red : Color(hex: 0x6CB8FF)],
                                         center: .topLeading, startRadius: 0, endRadius: size * 0.08))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .overlay(Circle().stroke(Brand.outline, lineWidth: 1))
                    .offset(gemOffset(k, of: n))
            }
        }
    }

    private func gemOffset(_ k: Int, of n: Int) -> CGSize {
        let r = size * 0.47
        let angles: [Double] = n == 2 ? [-90, 90] : [-90, 0, 90, 180]
        let a = angles[k] * Double.pi / 180
        return CGSize(width: r * CGFloat(cos(a)), height: r * CGFloat(sin(a)))
    }
}
