import SwiftUI

/// Pie wedge between two angles measured clockwise from the top.
struct WheelSlice: Shape {
    let start: Double
    let end: Double

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: c)
        let steps = 24
        for k in 0...steps {
            let a = (start + (end - start) * Double(k) / Double(steps)) * .pi / 180
            p.addLine(to: CGPoint(x: c.x + r * CGFloat(sin(a)), y: c.y - r * CGFloat(cos(a))))
        }
        p.closeSubpath()
        return p
    }
}

struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct WheelDisc: View {
    let size: CGFloat

    var body: some View {
        let prizes = WheelPrize.allCases
        let seg = 360.0 / Double(prizes.count)
        let r = size / 2
        ZStack {
            ForEach(prizes, id: \.rawValue) { p in
                let k = Double(p.rawValue)
                WheelSlice(start: k * seg, end: (k + 1) * seg)
                    .fill(Color(hex: p.tint))
                WheelSlice(start: k * seg, end: (k + 1) * seg)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            }
            ForEach(prizes, id: \.rawValue) { p in
                let mid = (Double(p.rawValue) + 0.5) * seg
                let a = mid * .pi / 180
                VStack(spacing: 0) {
                    Text(p.emoji).font(.system(size: 26))
                    Text(p.short)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 1)
                }
                .rotationEffect(.degrees(mid))
                .position(x: r + r * 0.66 * CGFloat(sin(a)), y: r - r * 0.66 * CGFloat(cos(a)))
            }
            Circle().stroke(Theme.gold, lineWidth: 6)
            ForEach(0..<16, id: \.self) { k in
                let a = Double(k) * 22.5 * .pi / 180
                Circle()
                    .fill(k % 2 == 0 ? Color.white : Theme.gold)
                    .frame(width: 7, height: 7)
                    .position(x: r + (r - 3) * CGFloat(sin(a)), y: r - (r - 3) * CGFloat(cos(a)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct WheelView: View {
    @EnvironmentObject var game: Game
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var result: String?
    @State private var resultPrize: WheelPrize?
    @State private var bounce = false

    private let size: CGFloat = 290

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { if !spinning { close() } }

            VStack(spacing: 16) {
                Text("🎡 دولاب الحظ")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text("لفّة ببلاش كل يوم. ممكن تربح ليرات، صناديق، مصاري أو ×2 أرباح!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                ZStack(alignment: .top) {
                    WheelDisc(size: size)
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: Theme.gold.opacity(0.4), radius: 18)
                    Circle()
                        .fill(RadialGradient(colors: [Theme.gold, Color(hex: 0xB45309)], center: .center,
                                             startRadius: 2, endRadius: 30))
                        .frame(width: 54, height: 54)
                        .overlay(Text("🧆").font(.system(size: 28)))
                        .offset(y: size / 2 - 27)
                    PointerShape()
                        .fill(Color.white)
                        .frame(width: 30, height: 34)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .offset(y: -14)
                }
                .frame(width: size, height: size)
                .environment(\.layoutDirection, .leftToRight)

                resultView
                    .frame(height: 54)

                spinButton

                Button { close() } label: {
                    Text("رجوع")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 8)
                }
                .disabled(spinning)
                .opacity(spinning ? 0.4 : 1)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var resultView: some View {
        if let text = result, let p = resultPrize {
            HStack(spacing: 8) {
                Text(p.emoji).font(.system(size: 28))
                Text(text)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(Theme.lira)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .scaleEffect(bounce ? 1 : 0.6)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        } else {
            Text(spinning ? "🤞 ..." : " ")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
        }
    }

    private var spinButton: some View {
        let free = game.freeSpinReady
        let enabled = !spinning && (free || game.s.liras >= Game.spinCost)
        return Button { spin() } label: {
            BigButtonLabel(text: free ? "لفّ ببلاش! 🎉" : "لفّ بـ \(Game.spinCost) 🪙", enabled: enabled)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .frame(maxWidth: 320)
    }

    private func spin() {
        guard !spinning, let r = game.spinWheel() else { return }
        spinning = true
        result = nil
        resultPrize = nil
        bounce = false
        let count = Double(WheelPrize.allCases.count)
        let seg = 360.0 / count
        let jitter = Double.random(in: -seg * 0.3...seg * 0.3)
        var desired = -(Double(r.prize.rawValue) * seg + seg / 2 + jitter)
        desired = desired.truncatingRemainder(dividingBy: 360)
        if desired < 0 { desired += 360 }
        let base = rotation + 360 * 6
        let turns = ((base - desired) / 360).rounded(.up)
        let target = turns * 360 + desired
        if game.s.hapticsOn { Feedback.medium() }
        withAnimation(.timingCurve(0.12, 0.75, 0.2, 1, duration: 4.2)) { rotation = target }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            spinning = false
            result = r.text
            resultPrize = r.prize
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { bounce = true }
            if game.s.hapticsOn { Feedback.success() }
            if game.s.soundOn { Feedback.click() }
        }
    }

    private func close() {
        withAnimation { game.showWheel = false }
    }
}
