import SwiftUI

struct RewardItem: Identifiable {
    let id = UUID()
    let art: String
    let amount: String
    var caption: String? = nil
    var glow: Color = Brand.gold
}

/// Celebration screen: title ribbon, rotating rays, items popping in one by one, collect button.
struct RewardReveal: View {
    let title: String
    var subtitle: String? = nil
    let items: [RewardItem]
    var buttonTitle = "استلم"
    let onCollect: () -> Void

    @State private var shown = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.75 : 0).ignoresSafeArea()
            VStack(spacing: 18) {
                Ribbon(text: title, color: Brand.red, size: 22)
                    .scaleEffect(appeared ? 1 : 0.4)
                if let s = subtitle {
                    Text(s)
                        .font(.game(15, .bold))
                        .foregroundColor(Brand.cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                ZStack {
                    Rays()
                        .frame(width: 340, height: 340)
                        .opacity(appeared ? 1 : 0)
                    itemsGrid
                }
                .frame(height: 260)
                ChunkyButton(title: buttonTitle, color: .green, sound: .cash) {
                    onCollect()
                }
                .frame(width: 220)
                .opacity(shown >= items.count ? 1 : 0.0)
                .disabled(shown < items.count)
            }
        }
        .onAppear(perform: start)
    }

    private var itemsGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(96), spacing: 10), count: min(3, max(1, items.count)))
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { k, item in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [item.glow.opacity(0.55), item.glow.opacity(0)],
                                                 center: .center, startRadius: 2, endRadius: 46))
                            .frame(width: 92, height: 92)
                        ArtIcon(item.art, size: 62)
                    }
                    OutlinedText(text: item.amount, size: 17, color: Brand.goldLight)
                    if let c = item.caption {
                        Text(c)
                            .font(.game(11, .bold))
                            .foregroundColor(Brand.cream.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .scaleEffect(k < shown ? 1 : 0.2)
                .opacity(k < shown ? 1 : 0)
            }
        }
    }

    private func start() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { appeared = true }
        SFX.reward.play()
        Haptic.success()
        FX.shared.confettiFromTop()
        for k in 0..<items.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(k) * 0.22) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { shown = k + 1 }
                SFX.pop.play()
                Haptic.click()
            }
        }
    }
}

/// Pulsing hand that points at the next thing to tap during the tutorial.
struct TutorialHand: View {
    @State private var push = false

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 44))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            .offset(x: push ? -4 : 6, y: push ? -4 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { push = true }
            }
            .allowsHitTesting(false)
    }
}

/// Speech bubble from a character for tutorial and story lines.
struct StoryBubble: View {
    let character: String
    let name: String
    let text: String
    var onNext: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ArtIcon(character, size: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.game(13, .black))
                    .foregroundColor(Brand.goldDeep)
                Text(text)
                    .font(.game(14, .bold))
                    .foregroundColor(Brand.outline)
                    .fixedSize(horizontal: false, vertical: true)
                if let next = onNext {
                    HStack {
                        Spacer()
                        Button {
                            Haptic.tap()
                            SFX.tap.play()
                            next()
                        } label: {
                            Text("كمّل ◀︎")
                                .font(.game(13, .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(hex: 0x34B04A)))
                        }
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Brand.cream))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Brand.outline, lineWidth: 2))
        }
        .padding(.horizontal, 12)
    }
}
