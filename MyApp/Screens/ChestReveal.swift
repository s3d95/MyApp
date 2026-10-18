import SwiftUI
import UIKit

/// Four-beat chest reveal (GDD S11): build-up, burst, card cascade, collect. A tap skips a beat.
struct ChestRevealModal: View {
    @EnvironmentObject var store: GameStore
    let result: ChestResult
    @State private var beat = 0
    @State private var shown = 0
    @State private var shake = false
    @State private var flash = 0.0
    @State private var glowOn = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture { skip() }
            if beat >= 2 {
                Rays(color: result.best.color)
                    .frame(width: 440, height: 440)
                    .opacity(0.55)
                    .allowsHitTesting(false)
            }
            VStack(spacing: 14) {
                Ribbon(text: store.chestName(result.kind), color: ribbonColor, size: 20)
                if beat < 2 {
                    ChestArt(kind: result.kind, size: 150)
                        .rotationEffect(.degrees(shake ? 7 : -7))
                        .shadow(color: glowOn ? result.best.color : Color.black.opacity(0.4), radius: beat == 1 ? 44 : 16)
                        .scaleEffect(beat == 1 ? 1.25 : 1)
                        .onTapGesture { skip() }
                } else {
                    cards
                }
                if beat >= 2 {
                    HStack(spacing: 6) {
                        ArtIcon("ui_coin", size: 30)
                        OutlinedText(text: "+" + Num.int(result.gold) + " ذهب", size: 18, color: Brand.goldLight)
                    }
                    .opacity(shown >= result.stacks.count ? 1 : 0)
                }
                if beat == 3 {
                    ChunkyButton(title: "خذ", color: .green, sound: .cash) { collect() }
                        .frame(width: 200)
                        .transition(.scale)
                } else if store.s.chefs.revealViews > 3 {
                    Button("تخطّي الكل") { showAll() }
                        .font(.body(13, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            Color.white
                .opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear(perform: run)
    }

    private var ribbonColor: Color {
        switch result.kind {
        case "gold": return Brand.goldDeep
        case "silver": return Color(hex: 0x6E7F8F)
        default: return Brand.wood
        }
    }

    private var cards: some View {
        let cols = Array(repeating: GridItem(.fixed(104), spacing: 8), count: min(3, max(1, result.stacks.count)))
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(Array(result.stacks.enumerated()), id: \.element.id) { k, st in
                if k < shown {
                    RevealCard(stack: st)
                } else {
                    Color.clear.frame(width: 100, height: 150)
                }
            }
        }
        .onTapGesture { skip() }
    }

    private func run() {
        SFX.tick.play()
        withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.3)) { glowOn = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { burst() }
    }

    private func burst() {
        guard beat == 0 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { beat = 1 }
        flash = 0.85
        withAnimation(.easeOut(duration: 0.35)) { flash = 0 }
        Feedback.play(result.best == .legendary || result.kind == "gold" ? .t3 : .t2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { cascade() }
    }

    private func cascade() {
        guard beat < 2 else { return }
        withAnimation(.easeOut(duration: 0.2)) { beat = 2 }
        for k in 0..<result.stacks.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26 * Double(k)) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { shown = max(shown, k + 1) }
                SFX.pop.play()
                Haptic.click()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26 * Double(result.stacks.count) + 0.3) {
            withAnimation(.spring()) { beat = max(beat, 3) }
        }
    }

    private func skip() {
        switch beat {
        case 0: burst()
        case 1, 2: showAll()
        default: collect()
        }
    }

    private func showAll() {
        flash = 0
        withAnimation(.easeOut(duration: 0.2)) {
            shown = result.stacks.count
            beat = 3
        }
    }

    private func collect() {
        Feedback.play(.t1, fromAnchor: nil, at: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY),
                      art: "ui_coin", to: "pill.gold", amount: Double(result.gold))
        store.closeModal()
        store.evaluateFtue()
    }
}

struct RevealCard: View {
    @EnvironmentObject var store: GameStore
    let stack: ChestStack
    @State private var flipped = false

    var body: some View {
        let c = store.cat.chef(stack.chefId)
        VStack(spacing: 4) {
            RarityFrame(rarity: stack.rarity, art: c?.art ?? "ppl_cook", size: 76)
            Text(c.map { store.t($0.name) } ?? "")
                .font(.game(12, .black))
                .foregroundColor(Brand.cream)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .frame(height: 30)
            Text("+" + Num.int(stack.cards) + " كرت")
                .font(.game(13, .black))
                .foregroundColor(stack.rarity.color)
            if stack.isNew {
                Tag(text: "جديد!", color: Brand.red, textColor: .white)
            }
        }
        .padding(6)
        .frame(width: 100)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.45)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(stack.rarity.color, lineWidth: 2))
        .rotation3DEffect(.degrees(flipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
        .onAppear {
            let d: Double
            switch stack.rarity {
            case .common: d = 0.35
            case .rare: d = 0.5
            case .epic: d = 0.65
            case .legendary: d = 0.8
            }
            withAnimation(.easeOut(duration: d)) { flipped = true }
        }
    }
}
