import SwiftUI

/// Colors and landmark that give each city its own look.
struct SceneStyle {
    var sky: [Color]
    var ground: Color
    var landmark: String?
    var awningA: Color = Brand.awningOrange
    var awningB: Color = Brand.awningCream

    static let jerusalem = SceneStyle(sky: [Brand.duskTop, Brand.duskMid, Brand.sunset, Brand.glow],
                                      ground: Color(hex: 0x6B4A33), landmark: "bld_mosque")
}

/// The living street in front of the stall: customers walk in, queue, order, get served and
/// leave with coins popping. Purely cosmetic; its pace follows the restaurant's income.
struct StreetScene: View {
    var style: SceneStyle = .jerusalem
    var title: String
    var dishes: [String]
    var customers: [String] = StreetScene.defaultCustomers
    /// Customers per minute, roughly.
    var rate: Double = 12
    var lights = true

    static let defaultCustomers = ["ppl_man", "ppl_woman", "ppl_old_man", "ppl_old_woman", "ppl_boy",
                                   "ppl_girl", "ppl_woman_headscarf", "ppl_turban", "ppl_man_office",
                                   "ppl_construction", "ppl_beard", "ppl_farmer", "ppl_woman_office"]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            GeometryReader { geo in
                let t = ctx.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    backdrop(geo.size)
                    stall(geo.size)
                    crowd(t: t, size: geo.size)
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Brand.gold.opacity(0.45), lineWidth: 1.5))
    }

    // MARK: Layers

    private func backdrop(_ s: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: style.sky, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Brand.glow.opacity(0.7), Brand.glow.opacity(0)],
                           center: UnitPoint(x: 0.3, y: 0.85), startRadius: 4, endRadius: s.width * 0.6)
            if let l = style.landmark {
                ArtIcon(l, size: 70, shadow: false)
                    .opacity(0.55)
                    .saturation(0.6)
                    .position(x: s.width * 0.2, y: s.height - 78)
            }
            CitySilhouette(seed: 5)
                .fill(Brand.duskTop.opacity(0.55))
                .frame(height: s.height * 0.45)
                .offset(y: -22)
            Rectangle()
                .fill(LinearGradient(colors: [style.ground, style.ground.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .frame(height: 30)
        }
        .frame(width: s.width, height: s.height)
    }

    private func stall(_ s: CGSize) -> some View {
        let w: CGFloat = min(190, s.width * 0.48)
        let h: CGFloat = min(130, s.height * 0.68)
        let x = s.width - w / 2 - 14
        return ZStack(alignment: .top) {
            // Back wall
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Brand.wood, Brand.woodDark], startPoint: .top, endPoint: .bottom))
                .frame(width: w - 16, height: h - 20)
                .offset(y: 18)
            // Posts
            HStack {
                Rectangle().fill(Brand.woodDark).frame(width: 7)
                Spacer()
                Rectangle().fill(Brand.woodDark).frame(width: 7)
            }
            .frame(width: w - 8, height: h)
            // Awning
            ScallopAwning(stripes: 9, a: style.awningA, b: style.awningB)
                .frame(width: w + 10, height: 30)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            if lights {
                TwinkleLights(count: 9, sag: 6)
                    .frame(width: w - 16, height: 20)
                    .offset(y: 30)
            }
            // Sign
            OutlinedText(text: title, size: 13, color: Brand.goldLight)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Brand.woodDark))
                .overlay(Capsule().stroke(Brand.gold, lineWidth: 1.5))
                .offset(y: -14)
            // Counter with today's dishes
            VStack(spacing: 0) {
                HStack(spacing: -4) {
                    ForEach(Array(dishes.prefix(5).enumerated()), id: \.offset) { _, d in
                        ArtIcon(d, size: 30)
                    }
                }
                .offset(y: 6)
                Rectangle()
                    .fill(LinearGradient(colors: [Brand.woodLight, Brand.wood], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: 30)
                    .overlay(Rectangle().fill(Brand.goldLight.opacity(0.35)).frame(height: 3), alignment: .top)
            }
            .offset(y: h - 52)
        }
        .frame(width: w + 10, height: h + 10, alignment: .top)
        .position(x: x, y: s.height - h / 2 - 22)
    }

    // MARK: Customers

    private struct Timing {
        let interval: Double
        let walkIn = 2.6
        let walkOut = 2.4
        let queue = 2
        var lifetime: Double { walkIn + Double(queue) * interval + interval * 0.85 + walkOut }
    }

    private func crowd(t: Double, size s: CGSize) -> some View {
        let tm = Timing(interval: min(6, max(1.3, 60 / max(rate, 1))))
        let counterX = s.width - min(190, s.width * 0.48) - 4
        let groundY = s.height - 40
        let newest = Int(floor(t / tm.interval))
        let oldest = Int(floor((t - tm.lifetime) / tm.interval))
        let ids = Array(max(0, oldest)...max(0, newest))
        return ZStack {
            ForEach(ids, id: \.self) { k in
                customer(k: k, t: t, tm: tm, counterX: counterX, groundY: groundY, width: s.width)
            }
        }
        .frame(width: s.width, height: s.height)
    }

    private func slotX(_ slot: Int, counterX: CGFloat) -> CGFloat { counterX - 22 - CGFloat(slot) * 40 }

    @ViewBuilder
    private func customer(k: Int, t: Double, tm: Timing, counterX: CGFloat, groundY: CGFloat, width: CGFloat) -> some View {
        let spawn = Double(k) * tm.interval
        let e = t - spawn
        let art = customers.isEmpty ? "ppl_man" : customers[abs(k * 7 + 3) % customers.count]
        let dish = dishes.isEmpty ? nil : dishes[abs(k * 5 + 1) % dishes.count]
        let served = tm.walkIn + Double(tm.queue) * tm.interval
        let leave = served + tm.interval * 0.85
        if e >= 0 && e <= tm.lifetime {
            let state = position(e: e, tm: tm, counterX: counterX, width: width)
            let walking = state.walking
            let bob = walking ? -abs(sin(t * 9 + Double(k))) * 3 : 0
            ZStack {
                ArtIcon(art, size: 40)
                if e >= served - tm.interval * 0.6 && e < leave, let d = dish {
                    OrderBubble(dish: d, done: e >= served + tm.interval * 0.45)
                        .offset(x: 6, y: -38)
                }
                if e >= leave && e < leave + 0.9 {
                    let p = (e - leave) / 0.9
                    ArtIcon("ui_coin", size: 20)
                        .offset(y: CGFloat(-30 - p * 34))
                        .opacity(1 - p)
                }
            }
            .position(x: state.x, y: groundY + CGFloat(bob) + (e >= leave ? 10 : 0))
            .zIndex(e >= leave ? 2 : 1)
        }
    }

    private func position(e: Double, tm: Timing, counterX: CGFloat, width: CGFloat) -> (x: CGFloat, walking: Bool) {
        let startX: CGFloat = -30
        if e < tm.walkIn {
            let p = CGFloat(e / tm.walkIn)
            return (startX + (slotX(tm.queue, counterX: counterX) - startX) * p, true)
        }
        let q = e - tm.walkIn
        let total = Double(tm.queue) * tm.interval
        if q < total {
            let step = Int(floor(q / tm.interval))
            let frac = (q - Double(step) * tm.interval) / min(0.6, tm.interval)
            let from = slotX(tm.queue - step, counterX: counterX)
            let to = slotX(tm.queue - step - 1, counterX: counterX)
            let m = CGFloat(min(1, max(0, frac)))
            return (from + (to - from) * m, frac < 1)
        }
        let leave = total + tm.interval * 0.85
        if q < leave {
            return (slotX(0, counterX: counterX), false)
        }
        let p = CGFloat(min(1, (q - leave) / tm.walkOut))
        let from = slotX(0, counterX: counterX)
        return (from + (width + 40 - from) * p, true)
    }
}

/// Speech bubble with the dish a customer ordered; turns into a check when served.
struct OrderBubble: View {
    let dish: String
    let done: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Brand.outline.opacity(0.4), lineWidth: 1))
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Color(hex: 0x2E9E44))
            } else {
                ArtIcon(dish, size: 22, shadow: false)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
}

/// Striped awning with a scalloped bottom edge.
struct ScallopAwning: View {
    var stripes = 9
    var a: Color = Brand.awningOrange
    var b: Color = Brand.awningCream

    var body: some View {
        GeometryReader { g in
            let sw = g.size.width / CGFloat(stripes)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<stripes, id: \.self) { i in
                        Rectangle().fill(i % 2 == 0 ? a : b)
                    }
                }
                .frame(height: max(0, g.size.height - sw / 2))
                HStack(spacing: 0) {
                    ForEach(0..<stripes, id: \.self) { i in
                        Circle()
                            .fill(i % 2 == 0 ? a : b)
                            .frame(width: sw, height: sw)
                            .frame(width: sw, height: sw / 2, alignment: .top)
                            .clipped()
                    }
                }
            }
            .overlay(Rectangle().fill(Brand.outline.opacity(0.35)).frame(height: 2), alignment: .top)
        }
    }
}
