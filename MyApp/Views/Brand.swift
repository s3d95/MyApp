import SwiftUI

/// Visual identity taken from the "بسطة فلافل" logo: a sunset market, a wooden stall,
/// string lights, bunting and a bold golden outlined title.
enum Brand {
    // Sky
    static let duskTop = Color(hex: 0x33172E)
    static let duskMid = Color(hex: 0x6E2F4A)
    static let sunset = Color(hex: 0xD9714A)
    static let glow = Color(hex: 0xFFB36B)

    // Wood
    static let woodDark = Color(hex: 0x3E1F10)
    static let wood = Color(hex: 0x6B3A1C)
    static let woodLight = Color(hex: 0x9A5A2A)

    // Title gold and outline
    static let goldLight = Color(hex: 0xFFE38A)
    static let gold = Color(hex: 0xF9B233)
    static let goldDeep = Color(hex: 0xD9801A)
    static let outline = Color(hex: 0x4A230F)

    // Awning, bunting and food accents
    static let awningOrange = Color(hex: 0xF08A24)
    static let awningCream = Color(hex: 0xFFE7B8)
    static let red = Color(hex: 0xD2492A)
    static let teal = Color(hex: 0x2F8F86)
    static let olive = Color(hex: 0x8A9A3B)
    static let cream = Color(hex: 0xFFF4DE)
    static let parsley = Color(hex: 0x4CAF50)
    static let bulb = Color(hex: 0xFFD27A)

    static let buntingColors = [awningOrange, teal, red, olive, awningCream]

    static var sky: LinearGradient {
        LinearGradient(colors: [duskTop, duskMid, sunset, glow], startPoint: .top, endPoint: .bottom)
    }

    static var titleFill: LinearGradient {
        LinearGradient(colors: [goldLight, gold, goldDeep], startPoint: .top, endPoint: .bottom)
    }

    static var woodFill: LinearGradient {
        LinearGradient(colors: [woodLight, wood, woodDark], startPoint: .top, endPoint: .bottom)
    }
}

/// Big outlined title like the logo: golden fill, brown outline, white rim.
struct BrandTitle: View {
    let text: String
    var size: CGFloat = 40

    var body: some View {
        let base = Text(text).font(.system(size: size, weight: .black, design: .rounded))
        ZStack {
            ForEach(0..<12, id: \.self) { k in
                let a = Double(k) / 12 * 2 * Double.pi
                base.foregroundColor(.white)
                    .offset(x: CGFloat(cos(a)) * size * 0.1, y: CGFloat(sin(a)) * size * 0.1)
            }
            ForEach(0..<12, id: \.self) { k in
                let a = Double(k) / 12 * 2 * Double.pi
                base.foregroundColor(Brand.outline)
                    .offset(x: CGFloat(cos(a)) * size * 0.055, y: CGFloat(sin(a)) * size * 0.055)
            }
            base.foregroundStyle(Brand.titleFill)
        }
        .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
    }
}

struct FlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A string sagging across the width, with points along it.
private enum Garland {
    static func y(_ f: CGFloat, sag: CGFloat) -> CGFloat { 4 + 4 * sag * f * (1 - f) }

    static func wire(width w: CGFloat, sag: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 4))
        p.addQuadCurve(to: CGPoint(x: w, y: 4), control: CGPoint(x: w / 2, y: 4 + 2 * sag))
        return p
    }
}

/// Colorful triangle flags swaying on a string, like the stall in the logo.
struct Bunting: View {
    var count = 11
    var sag: CGFloat = 12

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    Garland.wire(width: w, sag: sag)
                        .stroke(Brand.woodDark.opacity(0.85), lineWidth: 1.5)
                    ForEach(0..<count, id: \.self) { i in
                        let f = (CGFloat(i) + 0.5) / CGFloat(count)
                        FlagShape()
                            .fill(Brand.buntingColors[i % Brand.buntingColors.count])
                            .frame(width: 18, height: 22)
                            .overlay(FlagShape().stroke(Color.black.opacity(0.15), lineWidth: 1))
                            .rotationEffect(.degrees(sin(t * 1.6 + Double(i)) * 6), anchor: .top)
                            .position(x: w * f, y: Garland.y(f, sag: sag) + 11)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
    }
}

/// Warm string lights that twinkle at different phases.
struct TwinkleLights: View {
    var count = 14
    var sag: CGFloat = 10

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    Garland.wire(width: w, sag: sag)
                        .stroke(Color.black.opacity(0.55), lineWidth: 1.2)
                    ForEach(0..<count, id: \.self) { i in
                        let f = (CGFloat(i) + 0.5) / CGFloat(count)
                        let glow = 0.65 + 0.35 * sin(t * 2.2 + Double(i) * 1.7)
                        Capsule()
                            .fill(Brand.bulb)
                            .frame(width: 7, height: 10)
                            .shadow(color: Brand.bulb.opacity(glow), radius: CGFloat(7 * glow))
                            .opacity(0.7 + 0.3 * glow)
                            .position(x: w * f, y: Garland.y(f, sag: sag) + 7)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
    }
}

/// Old-city skyline: houses, arches and a dome against the sunset.
struct CitySilhouette: Shape {
    var seed: Int = 0

    func path(in rect: CGRect) -> Path {
        let heights: [CGFloat] = [0.42, 0.6, 0.48, 0.75, 0.55, 0.0, 0.5, 0.68, 0.45, 0.62, 0.38, 0.57]
        let n = heights.count
        let bw = rect.width / CGFloat(n)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for k in 0..<n {
            let h = heights[(k + seed) % n]
            let x0 = rect.minX + CGFloat(k) * bw
            if h == 0 {
                // A dome on a drum.
                let drumTop = rect.maxY - rect.height * 0.45
                p.addLine(to: CGPoint(x: x0, y: drumTop))
                p.addArc(center: CGPoint(x: x0 + bw / 2, y: drumTop), radius: bw / 2,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            } else {
                let top = rect.maxY - rect.height * h
                p.addLine(to: CGPoint(x: x0, y: top))
                p.addLine(to: CGPoint(x: x0 + bw, y: top))
            }
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Full-screen sunset sky with a glowing horizon and two skyline layers.
struct SunsetBackdrop: View {
    var body: some View {
        ZStack {
            Brand.sky
            RadialGradient(colors: [Brand.glow.opacity(0.9), Brand.glow.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.78), startRadius: 10, endRadius: 340)
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .bottom) {
                    CitySilhouette(seed: 3)
                        .fill(Brand.duskMid.opacity(0.55))
                        .frame(height: 210)
                    CitySilhouette(seed: 0)
                        .fill(Brand.duskTop.opacity(0.85))
                        .frame(height: 150)
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .ignoresSafeArea()
    }
}

/// Wooden loading bar with a golden fill and a falafel rolling along it (fills right-to-left).
struct WoodLoadingBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fill = max(h, (w - 8) * min(1, max(0, progress)))
            ZStack {
                Capsule()
                    .fill(Brand.woodFill)
                    .overlay(Capsule().stroke(Brand.outline, lineWidth: 3))
                Capsule()
                    .fill(Brand.titleFill)
                    .overlay(Capsule().fill(Color.white.opacity(0.35)).frame(height: 4).padding(.horizontal, 8).offset(y: -(h - 8) / 4))
                    .frame(width: fill, height: h - 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 4)
                Image("Falafel3D")
                    .resizable()
                    .scaledToFit()
                    .frame(width: h * 1.7, height: h * 1.7)
                    .rotationEffect(.degrees(-Double(progress) * 900))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    .position(x: w - 4 - fill, y: h / 2)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
