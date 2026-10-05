import SwiftUI
import UIKit

/// Coordinate space of the root game view; FX positions are expressed in it.
let gameSpace = "game"

/// Records the frames of views marked with `.fxAnchor(id)` so effects can fly between them.
struct FXAnchorKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Marks this view as a source or target for effects (e.g. the coins pill in the header).
    func fxAnchor(_ id: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: FXAnchorKey.self, value: [id: g.frame(in: .named(gameSpace))])
        })
    }
}

struct FlyingItem: Identifiable {
    let id = UUID()
    let art: String
    let from: CGPoint
    let to: CGPoint
    let delay: Double
    let size: CGFloat
}

struct FXLabel: Identifiable {
    let id = UUID()
    let text: String
    let at: CGPoint
    let color: Color
    let size: CGFloat
}

struct Burst: Identifiable {
    let id = UUID()
    let at: CGPoint
    let born: Date
    let pieces: [ConfettiPiece]
}

struct ConfettiPiece {
    let vx: CGFloat
    let vy: CGFloat
    let spin: Double
    let color: Color
    let w: CGFloat
    let h: CGFloat
}

/// Central effects dispatcher. Screens call it; `FXOverlay` at the root draws everything.
final class FX: ObservableObject {
    static let shared = FX()

    @Published var flying: [FlyingItem] = []
    @Published var labels: [FXLabel] = []
    @Published var bursts: [Burst] = []
    /// Bumped when items land on a target so it can pop (keyed by anchor id).
    @Published var landed: [String: Int] = [:]
    var anchors: [String: CGRect] = [:]

    func frame(_ id: String) -> CGRect? { anchors[id] }

    func center(_ id: String) -> CGPoint? {
        guard let f = anchors[id] else { return nil }
        return CGPoint(x: f.midX, y: f.midY)
    }

    /// Sends a stream of 3D items (coins, gems, stars) from one point to an anchor.
    func fly(_ art: String, from: CGPoint, to target: String, count: Int = 8, size: CGFloat = 30) {
        guard let to = center(target) else { return }
        let n = max(1, min(count, 14))
        for k in 0..<n {
            let jitter = CGPoint(x: from.x + CGFloat.random(in: -26...26), y: from.y + CGFloat.random(in: -18...18))
            flying.append(FlyingItem(art: art, from: jitter, to: to, delay: Double(k) * 0.05, size: size))
        }
        let ids = flying.suffix(n).map { $0.id }
        let total = 0.75 + Double(n) * 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            SFX.coin.play(volume: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + total) { [weak self] in
            guard let self = self else { return }
            self.flying.removeAll { ids.contains($0.id) }
            self.landed[target, default: 0] += 1
            Haptic.tap()
        }
    }

    func fly(_ art: String, fromAnchor source: String, to target: String, count: Int = 8, size: CGFloat = 30) {
        guard let from = center(source) else { return }
        fly(art, from: from, to: target, count: count, size: size)
    }

    func float(_ text: String, at: CGPoint, color: Color = Theme.money, size: CGFloat = 20) {
        let l = FXLabel(text: text, at: at, color: color, size: size)
        labels.append(l)
        if labels.count > 24 { labels.removeFirst(labels.count - 24) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            self?.labels.removeAll { $0.id == l.id }
        }
    }

    func confetti(at: CGPoint, count: Int = 60) {
        let colors = Brand.buntingColors + [Brand.gold, Color.white]
        let pieces = (0..<count).map { _ in
            ConfettiPiece(vx: CGFloat.random(in: -260...260), vy: CGFloat.random(in: -620 ... -220),
                          spin: Double.random(in: -720...720), color: colors.randomElement() ?? Brand.gold,
                          w: CGFloat.random(in: 5...9), h: CGFloat.random(in: 8...14))
        }
        let b = Burst(at: at, born: Date(), pieces: pieces)
        bursts.append(b)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            self?.bursts.removeAll { $0.id == b.id }
        }
    }

    func confettiFromTop() {
        let w = UIScreen.main.bounds.width
        confetti(at: CGPoint(x: w * 0.25, y: 120), count: 45)
        confetti(at: CGPoint(x: w * 0.75, y: 120), count: 45)
    }
}

/// Draws all effects above the game. Put it last in the root ZStack (which uses `gameSpace`).
struct FXOverlay: View {
    @ObservedObject var fx = FX.shared

    var body: some View {
        ZStack {
            ForEach(fx.flying) { item in
                FlyingItemView(item: item)
            }
            ForEach(fx.labels) { l in
                FXLabelView(label: l)
            }
            if !fx.bursts.isEmpty {
                ConfettiCanvas(bursts: fx.bursts)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct FlyingItemView: View {
    let item: FlyingItem
    @State private var t: CGFloat = 0

    var body: some View {
        ArtIcon(item.art, size: item.size)
            .modifier(CurveMove(t: t, from: item.from, to: item.to))
            .scaleEffect(1 - 0.35 * t)
            .onAppear {
                withAnimation(.easeIn(duration: 0.7).delay(item.delay)) { t = 1 }
            }
    }
}

/// Moves along a quadratic curve that arcs upward, driven by an animatable `t`.
private struct CurveMove: GeometryEffect {
    var t: CGFloat
    let from: CGPoint
    let to: CGPoint

    var animatableData: CGFloat {
        get { t }
        set { t = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let ctrl = CGPoint(x: (from.x + to.x) / 2 + (from.x - to.x) * 0.3, y: min(from.y, to.y) - 120)
        let u = 1 - t
        let x = u * u * from.x + 2 * u * t * ctrl.x + t * t * to.x
        let y = u * u * from.y + 2 * u * t * ctrl.y + t * t * to.y
        return ProjectionTransform(CGAffineTransform(translationX: x - size.width / 2, y: y - size.height / 2))
    }
}

private struct FXLabelView: View {
    let label: FXLabel
    @State private var go = false

    var body: some View {
        OutlinedText(text: label.text, size: label.size, color: label.color)
            .scaleEffect(go ? 1.1 : 0.6)
            .opacity(go ? 0 : 1)
            .position(x: label.at.x, y: label.at.y - (go ? 70 : 0))
            .onAppear { withAnimation(.easeOut(duration: 1.0)) { go = true } }
    }
}

private struct ConfettiCanvas: View {
    let bursts: [Burst]

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { gc, _ in
                for b in bursts {
                    let age = CGFloat(ctx.date.timeIntervalSince(b.born))
                    guard age < 2.2 else { continue }
                    let fade = Double(max(0, 1 - age / 2.2))
                    for p in b.pieces {
                        let x = b.at.x + p.vx * age
                        let y = b.at.y + p.vy * age + 700 * age * age
                        var r = gc
                        r.translateBy(x: x, y: y)
                        r.rotate(by: .degrees(p.spin * Double(age)))
                        r.opacity = fade
                        r.fill(Path(CGRect(x: -p.w / 2, y: -p.h / 2, width: p.w, height: p.h)), with: .color(p.color))
                    }
                }
            }
        }
    }
}

// MARK: - Reusable effect modifiers

/// A diagonal light sweep that crosses the view every few seconds (for "ready" buttons).
struct Shine: ViewModifier {
    var active = true
    var period: Double = 2.6

    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if active {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                        GeometryReader { g in
                            let phase = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
                            let x = CGFloat(phase * 3 - 1) * g.size.width
                            LinearGradient(colors: [Color.white.opacity(0), Color.white.opacity(0.45), Color.white.opacity(0)],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: g.size.width * 0.35)
                                .rotationEffect(.degrees(20))
                                .offset(x: x)
                        }
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
        )
    }
}

/// Gentle breathing scale to draw the eye.
struct Pulse: ViewModifier {
    var active = true
    var amount: CGFloat = 0.06
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && on ? 1 + amount : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

/// Horizontal shake for errors; animate `trigger` up by 1 to shake once.
struct Shake: GeometryEffect {
    var trigger: CGFloat

    var animatableData: CGFloat {
        get { trigger }
        set { trigger = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(trigger * .pi * 4), y: 0))
    }
}

/// Pops a view briefly whenever `value` changes (counters, landed coins).
struct BumpOnChange<V: Equatable>: ViewModifier {
    let value: V
    @State private var bump = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(bump ? 1.18 : 1)
            .onChange(of: value) { _ in
                withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { bump = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bump = false }
                }
            }
    }
}

/// Rotating sun rays behind rewards and level-ups.
struct Rays: View {
    var color: Color = Brand.gold
    var count = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let angle = ctx.date.timeIntervalSinceReferenceDate * 18
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = max(size.width, size.height)
                for k in 0..<count {
                    let a0 = (Double(k) / Double(count)) * 2 * Double.pi + angle * Double.pi / 180
                    let a1 = a0 + Double.pi / Double(count) * 0.8
                    var p = Path()
                    p.move(to: c)
                    p.addLine(to: CGPoint(x: c.x + r * CGFloat(cos(a0)), y: c.y + r * CGFloat(sin(a0))))
                    p.addLine(to: CGPoint(x: c.x + r * CGFloat(cos(a1)), y: c.y + r * CGFloat(sin(a1))))
                    p.closeSubpath()
                    gc.fill(p, with: .radialGradient(Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                                                       center: c, startRadius: 0, endRadius: r * 0.5))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func shine(_ active: Bool = true) -> some View { modifier(Shine(active: active)) }
    func pulse(_ active: Bool = true, amount: CGFloat = 0.06) -> some View { modifier(Pulse(active: active, amount: amount)) }
    func bump<V: Equatable>(on value: V) -> some View { modifier(BumpOnChange(value: value)) }
}
