import SwiftUI

struct FloatText: Identifiable {
    let id = UUID()
    let text: String
    let point: CGPoint
}

/// The illustrated stall at the top of the shop: tap the falafel to earn.
struct StallView: View {
    @EnvironmentObject var game: Game
    @State private var floats: [FloatText] = []
    @State private var pressed = false
    @State private var autoPress = false
    @State private var size: CGSize = .zero

    var body: some View {
        let stage = game.s.stage
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2E1F4A), Color(hex: 0x7A3B2E), Color(hex: 0xE08A4B)],
                           startPoint: .top, endPoint: .bottom)
            Skyline()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 48)

            VStack(spacing: 0) {
                SignBoard(name: game.s.displayName, stage: stage, city: GameData.homeCity)
                    .padding(.top, 8)
                Awning(a: stage >= 3 ? Color(hex: 0xB91C1C) : Color(hex: 0x15803D), b: Theme.cream)
                    .frame(height: 26)
                    .padding(.top, 6)
                if stage >= 1 {
                    StringLights().padding(.top, 3)
                }
                Spacer()
                CounterView(stage: stage).frame(height: 50)
            }

            FalafelButton(pressed: pressed || autoPress)
                .offset(y: 20)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("hero"))
                        .onChanged { _ in if !pressed { pressed = true } }
                        .onEnded { v in
                            pressed = false
                            tap(at: v.location)
                        }
                )

            if game.s.autoLevel > 0 {
                AutoClickerBadge(level: game.s.autoLevel)
                    .offset(x: 92, y: 18)
            }

            if game.s.totalTaps < 5 {
                HintBubble(text: "اضغط على الفلافل! 👆").offset(y: 84)
            }

            ForEach(floats) { f in
                FloatingLabel(text: f.text).position(f.point)
            }
        }
        .frame(height: 200)
        .background(GeometryReader { g in
            Color.clear
                .onAppear { size = g.size }
                .onChange(of: g.size) { size = $0 }
        })
        .coordinateSpace(name: "hero")
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .onChange(of: game.autoBurst) { burst in
            guard burst.amount > 0, size != .zero else { return }
            addFloat("+" + Fmt.money(burst.amount),
                     at: CGPoint(x: size.width / 2 + CGFloat.random(in: -40...40), y: size.height / 2 - 10))
            autoPress = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { autoPress = false }
        }
    }

    private func tap(at p: CGPoint) {
        let v = game.tapFalafel()
        addFloat("+" + Fmt.money(v), at: CGPoint(x: p.x + CGFloat.random(in: -24...24), y: p.y - 34))
    }

    private func addFloat(_ text: String, at point: CGPoint) {
        let f = FloatText(text: text, point: point)
        floats.append(f)
        if floats.count > 25 { floats.removeFirst(floats.count - 25) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            floats.removeAll { $0.id == f.id }
        }
    }
}

/// Little robot next to the falafel showing the auto clicker is working.
struct AutoClickerBadge: View {
    let level: Int
    @State private var bob = false

    var body: some View {
        VStack(spacing: 2) {
            Text("🤖").font(.system(size: 26))
            Text("\(level)/ث")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: 0x2A1608))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.gold))
        }
        .offset(y: bob ? -3 : 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bob = true }
        }
        .allowsHitTesting(false)
    }
}

struct FalafelButton: View {
    let pressed: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 6)
                .offset(y: 6)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFD08A), Color(hex: 0xE07B24), Color(hex: 0x9A4A12)],
                                     center: .topLeading, startRadius: 4, endRadius: 120))
                .frame(width: 94, height: 94)
            Circle()
                .stroke(Theme.gold.opacity(0.9), lineWidth: 3)
                .frame(width: 94, height: 94)
            Text("🧆").font(.system(size: 52))
        }
        .scaleEffect(pressed ? 0.88 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: pressed)
    }
}

struct FloatingLabel: View {
    let text: String
    @State private var go = false

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundColor(Theme.money)
            .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
            .scaleEffect(go ? 1.15 : 0.8)
            .offset(y: go ? -70 : 0)
            .opacity(go ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.95)) { go = true } }
            .allowsHitTesting(false)
    }
}

struct HintBubble: View {
    let text: String
    @State private var bob = false

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(Color(hex: 0x2A1608))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(Theme.gold))
            .offset(y: bob ? -4 : 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bob = true }
            }
            .allowsHitTesting(false)
    }
}

struct SignBoard: View {
    let name: String
    let stage: Int
    let city: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                if stage >= 4 { Text("👑") }
                Text(name)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x3B2314)))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(stage >= 3 ? Theme.gold : Theme.gold.opacity(0.45), lineWidth: stage >= 3 ? 2 : 1))
            .shadow(color: stage >= 3 ? Theme.gold.opacity(0.6) : .clear, radius: 8)

            Text("\(GameData.stageNames[stage]) · \(city)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: 0x2A1608))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.gold))
        }
        .padding(.horizontal, 20)
    }
}

struct Awning: View {
    let a: Color
    let b: Color
    private let count = 10

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / CGFloat(count)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        Rectangle().fill(i % 2 == 0 ? a : b)
                    }
                }
                .frame(height: max(0, geo.size.height - w / 2))
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        Circle()
                            .fill(i % 2 == 0 ? a : b)
                            .frame(width: w, height: w)
                            .frame(width: w, height: w / 2, alignment: .bottom)
                            .clipped()
                    }
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
        }
    }
}

struct StringLights: View {
    private let colors = [Theme.gold, Color(hex: 0xF87171), Color(hex: 0x86EFAC)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<14, id: \.self) { i in
                Circle()
                    .fill(colors[i % 3])
                    .frame(width: 6, height: 6)
                    .shadow(color: colors[i % 3], radius: 3)
                if i < 13 { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, 14)
    }
}

struct CounterView: View {
    let stage: Int
    private let left = ["🥙", "🥙🍋", "🥙🍋🥯", "🥙🍋🌯", "🌯🍰☕"]
    private let right = ["🫒", "🫒🧅", "🫒🧅🍅", "🍅🫒🧅", "🧆🫒🍅"]

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(hex: 0x8B5A2B), Color(hex: 0x5C3A1E)], startPoint: .top, endPoint: .bottom)
            Rectangle().fill(Color(hex: 0xB07A45)).frame(height: 6)
            HStack {
                Text(left[min(stage, 4)]).font(.system(size: 22))
                Spacer()
                Text(right[min(stage, 4)]).font(.system(size: 22))
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
        }
    }
}

struct Skyline: View {
    private let heights: [CGFloat] = [34, 58, 44, 72, 0, 50, 66, 40, 56, 30]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(heights.indices, id: \.self) { i in
                if heights[i] == 0 {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Theme.gold.opacity(0.55))
                            .frame(width: 36, height: 36)
                            .frame(height: 18, alignment: .top)
                            .clipped()
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 44, height: 34)
                    }
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: heights[i])
                }
            }
        }
        .padding(.horizontal, 8)
    }
}
