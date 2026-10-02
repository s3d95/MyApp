import SwiftUI

struct ShopView: View {
    @EnvironmentObject var game: Game
    @State private var selected = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                StallView()

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(GameData.businesses) { def in
                        SectionTile(index: def.id, selected: selected == def.id) {
                            selected = def.id
                            game.startLine(def.id)
                            if game.s.hapticsOn { Feedback.light() }
                        }
                    }
                }

                SectionDetail(index: selected)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Grid tile

struct SectionTile: View {
    @EnvironmentObject var game: Game
    let index: Int
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        let def = GameData.businesses[index]
        let line = game.s.lines[index]
        let tint = Color(hex: def.tint)
        let locked = line.owned == 0
        let idle = !locked && !line.hasManager && line.cycleStart == nil
        let canBuy = locked
            ? game.s.money >= def.unlockCost
            : (game.s.remainingSellers(index) > 0 && game.s.money >= game.s.sellerCost(index, count: 1))

        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 4)
                    if !locked {
                        TileRing(start: line.cycleStart, duration: game.s.cycleTime(index), tint: tint)
                    }
                    Text(def.emoji)
                        .font(.system(size: 26))
                        .saturation(locked ? 0 : 1)
                        .opacity(locked ? 0.4 : 1)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 50, height: 50)
                .overlay(Group { if idle { PulseRing().padding(-3) } })

                Text(def.name)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(locked ? Fmt.money(def.unlockCost) : "👨‍🍳 \(line.owned)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(locked && canBuy ? Theme.money : Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selected ? Theme.cardHi : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Theme.gold : Theme.stroke, lineWidth: selected ? 2 : 1))
            .overlay(Group {
                if line.hasManager { Text("👔").font(.system(size: 11)).padding(6) }
            }, alignment: .topLeading)
            .overlay(Group {
                if canBuy { Circle().fill(Theme.money).frame(width: 8, height: 8).padding(8) }
            }, alignment: .topTrailing)
        }
        .buttonStyle(PressableStyle())
    }
}

struct TileRing: View {
    let start: Date?
    let duration: Double
    let tint: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: start == nil)) { ctx in
            Circle()
                .trim(from: 0, to: progress(ctx.date))
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private func progress(_ d: Date) -> CGFloat {
        guard let s = start, duration > 0 else { return 0 }
        return CGFloat(min(1, max(0, d.timeIntervalSince(s) / duration)))
    }
}

// MARK: - Detail panel

struct SectionDetail: View {
    @EnvironmentObject var game: Game
    let index: Int

    var body: some View {
        let def = GameData.businesses[index]
        let line = game.s.lines[index]
        let tint = Color(hex: def.tint)
        let now = Date()
        let unit = game.s.unitPrice(index, now: now)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                EmojiBubble(emoji: def.emoji, tint: tint, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("قسم \(def.name)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Text("\(def.product) · \(Fmt.money(unit))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 4)
                if line.owned > 0 { managerControl(def, line) }
            }

            if line.owned == 0 {
                lockedBody(def)
            } else {
                ownedBody(def, line, tint: tint, unit: unit, now: now)
            }
        }
        .card()
    }

    @ViewBuilder
    private func managerControl(_ def: BusinessDef, _ line: LineState) -> some View {
        if line.hasManager {
            Text("👔 \(def.managerName)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.money)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.money.opacity(0.12)))
        } else {
            PriceButton(title: "وظّف مدير", price: Fmt.money(def.managerCost),
                        enabled: game.s.money >= def.managerCost) {
                game.hire(index)
            }
            .frame(width: 104)
        }
    }

    private func lockedBody(_ def: BusinessDef) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("قسم جديد: كل بيّاع بيبيع \(def.product) بـ \(Fmt.money(def.price)) كل \(Fmt.seconds(def.baseTime)).")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            PriceButton(title: "افتح القسم", price: Fmt.money(def.unlockCost),
                        enabled: game.s.money >= def.unlockCost) {
                game.buy(index)
            }
        }
    }

    private func ownedBody(_ def: BusinessDef, _ line: LineState, tint: Color, unit: Double, now: Date) -> some View {
        let perCycle = Double(line.owned) * unit
        let time = game.s.cycleTime(index)
        let n = game.buyCount(index)
        let price = game.buyPrice(index)
        let maxed = game.s.remainingSellers(index) == 0

        return VStack(alignment: .leading, spacing: 10) {
            Text("👨‍🍳 \(line.owned) بيّاع × \(Fmt.money(unit)) = \(Fmt.money(perCycle)) كل \(Fmt.seconds(time))")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            LineProgressBar(start: line.cycleStart, duration: time, revenue: perCycle,
                            tint: tint, idleHint: line.hasManager ? nil : "اضغط على المربع ليبيعوا")

            if maxed {
                Text("🏆 وصلت الحد الأقصى: \(GameData.maxSellers) بيّاع")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    BuyModePicker()
                    PriceButton(title: "زيد \(n) بيّاع", price: Fmt.money(price), enabled: game.s.money >= price) {
                        game.buy(index)
                    }
                }
                if let next = game.s.nextMilestone(index) {
                    Text("⚡ لما يصيروا \(next) بيّاع، القسم بيصير أسرع 25%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gold.opacity(0.9))
                }
            }
        }
    }
}

struct BuyModePicker: View {
    @EnvironmentObject var game: Game

    var body: some View {
        HStack(spacing: 3) {
            ForEach(BuyMode.allCases, id: \.self) { m in
                Button {
                    game.buyMode = m
                    if game.s.hapticsOn { Feedback.light() }
                } label: {
                    Text(m.label)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(game.buyMode == m ? Color(hex: 0x2A1608) : Theme.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(game.buyMode == m ? Theme.gold : Color.white.opacity(0.06)))
                }
            }
        }
    }
}

struct LineProgressBar: View {
    let start: Date?
    let duration: Double
    let revenue: Double
    let tint: Color
    let idleHint: String?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: start == nil)) { ctx in
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.35))
                        Capsule()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geo.size.width * progress(ctx.date)))
                        Text(start == nil && idleHint != nil ? idleHint! : "+" + Fmt.money(revenue))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 26)

                Text(timeText(ctx.date))
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(Theme.muted)
                    .frame(width: 54)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.3)))
            }
        }
    }

    private func progress(_ d: Date) -> CGFloat {
        guard let s = start, duration > 0 else { return 0 }
        return CGFloat(min(1, max(0, d.timeIntervalSince(s) / duration)))
    }

    private func timeText(_ d: Date) -> String {
        guard let s = start else { return Fmt.seconds(duration) }
        return Fmt.seconds(duration - d.timeIntervalSince(s))
    }
}
