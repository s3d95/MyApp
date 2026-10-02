import SwiftUI

struct ShopView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let count = GameData.businesses.count
        let firstLocked = game.s.lines.firstIndex(where: { $0.owned == 0 }) ?? count
        let lastVisible = min(firstLocked, count - 1)

        VStack(spacing: 10) {
            StallView().padding(.horizontal, 16)

            HStack {
                Text("الأقسام")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Spacer()
                BuyModePicker()
            }
            .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(0...lastVisible, id: \.self) { i in
                        BusinessRow(index: i)
                    }
                    if lastVisible + 1 < count {
                        MysteryRow()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

struct BuyModePicker: View {
    @EnvironmentObject var game: Game

    var body: some View {
        HStack(spacing: 4) {
            ForEach(BuyMode.allCases, id: \.self) { m in
                Button {
                    game.buyMode = m
                    if game.s.hapticsOn { Feedback.light() }
                } label: {
                    Text(m.label)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(game.buyMode == m ? Color(hex: 0x2A1608) : Theme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(game.buyMode == m ? Theme.gold : Color.white.opacity(0.06)))
                }
            }
        }
    }
}

struct BusinessRow: View {
    @EnvironmentObject var game: Game
    let index: Int

    var body: some View {
        let def = GameData.businesses[index]
        let line = game.s.lines[index]
        if line.owned == 0 {
            lockedRow(def)
        } else {
            ownedRow(def, line)
        }
    }

    private func lockedRow(_ def: BusinessDef) -> some View {
        let price = game.s.cost(index, count: 1)
        return HStack(spacing: 12) {
            ZStack {
                EmojiBubble(emoji: def.emoji, tint: Color(hex: def.tint), size: 62)
                    .saturation(0)
                    .opacity(0.45)
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(def.name)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text("كل وحدة بتربح \(Fmt.money(def.baseRevenue)) كل \(Fmt.duration(def.baseTime))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                PriceButton(title: "افتح القسم", price: Fmt.money(price), enabled: game.s.money >= price) {
                    game.buy(index)
                }
            }
        }
        .card()
    }

    private func ownedRow(_ def: BusinessDef, _ line: LineState) -> some View {
        let now = Date()
        let tint = Color(hex: def.tint)
        let n = game.buyCount(index)
        let price = game.s.cost(index, count: n)
        let idle = !line.hasManager && line.cycleStart == nil

        return HStack(alignment: .center, spacing: 12) {
            Button { game.startLine(index) } label: {
                EmojiBubble(emoji: def.emoji, tint: tint, size: 62)
                    .overlay(Group { if idle { PulseRing().padding(-4) } })
                    .overlay(
                        Text("\(line.owned)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black.opacity(0.75)))
                            .offset(y: 9),
                        alignment: .bottom
                    )
            }
            .buttonStyle(PressableStyle())

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(def.name)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                        .lineLimit(1)
                    if line.hasManager {
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.money)
                    }
                    Spacer(minLength: 4)
                    MilestoneTag(owned: line.owned, next: game.s.nextMilestone(index))
                }

                LineProgressBar(start: line.cycleStart,
                                duration: game.s.cycleTime(index),
                                managed: line.hasManager,
                                revenue: game.s.revenuePerCycle(index, now: now),
                                tint: tint)

                PriceButton(title: "اشتري ×\(n)", price: Fmt.money(price), enabled: game.s.money >= price) {
                    game.buy(index)
                }
            }
        }
        .card()
    }
}

struct LineProgressBar: View {
    let start: Date?
    let duration: Double
    let managed: Bool
    let revenue: Double
    let tint: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: start == nil)) { ctx in
            let fast = managed && duration < 0.3
            let p: CGFloat = fast ? 1 : progress(ctx.date)
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.35))
                        Capsule()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geo.size.width * p))
                        Text(fast ? Fmt.money(revenue / duration) + " /ث" : Fmt.money(revenue))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 26)

                Text(fast ? "⚡" : timeText(ctx.date))
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Theme.muted)
                    .frame(width: 54)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.3)))
            }
        }
    }

    private func progress(_ d: Date) -> CGFloat {
        guard let s = start else { return 0 }
        return CGFloat(min(1, max(0, d.timeIntervalSince(s) / duration)))
    }

    private func timeText(_ d: Date) -> String {
        guard let s = start else { return Fmt.duration(duration) }
        return Fmt.duration(duration - d.timeIntervalSince(s))
    }
}

struct MilestoneTag: View {
    let owned: Int
    let next: Int?

    var body: some View {
        if let next = next {
            let prev = GameData.milestones.last(where: { $0 <= owned }) ?? 0
            let p = CGFloat(owned - prev) / CGFloat(max(1, next - prev))
            HStack(spacing: 4) {
                Text("⚡\(next)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(Theme.gold).frame(width: 36 * min(1, p))
                }
                .frame(width: 36, height: 5)
            }
        } else {
            Text("⚡ MAX")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.gold)
        }
    }
}

struct MysteryRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.06)).frame(width: 62, height: 62)
                Text("❓").font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("قسم سرّي")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text("افتح القسم اللي قبله لتكشفه")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
        }
        .card()
        .opacity(0.6)
    }
}
