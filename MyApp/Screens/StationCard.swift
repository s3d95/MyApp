import SwiftUI

struct StationCard: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let st = store.station(i)
        Group {
            if st.level == 0 {
                LockedStationCard(i: i)
            } else {
                OpenStationCard(i: i)
            }
        }
        .fxAnchor("station.\(i).card")
    }
}

private struct CardBackground: View {
    var gold = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x5C321C), Color(hex: 0x45241A)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(gold ? Brand.gold : Brand.gold.opacity(0.22), lineWidth: gold ? 2 : 1))
            .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
    }
}

struct OpenStationCard: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let def = store.city.stations[i]
        let st = store.station(i)
        let atCap = st.level >= store.cap
        HStack(spacing: 10) {
            DishButton(i: i)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(store.t(def.name))
                        .font(.game(16, .black))
                        .foregroundColor(Brand.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if st.managed {
                        ArtIcon(def.managerArt, size: 20, shadow: false)
                    }
                    TwistChips(i: i)
                }
                Text("مستوى " + Num.int(st.level) + "/" + Num.int(store.cap))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.75))
                milestoneBar(st: st)
                incomeLine
            }
            Spacer(minLength: 2)
            VStack(spacing: 4) {
                if atCap {
                    Tag(text: "مكتمل", color: Brand.gold)
                        .padding(.vertical, 8)
                } else {
                    BuyButton(i: i)
                }
                ManagerSlot(i: i)
            }
            .frame(width: 108)
        }
        .padding(10)
        .background(CardBackground(gold: atCap))
    }

    private func milestoneBar(st: StationState) -> some View {
        let next = store.nextStationMilestone(i)
        let prev = Rules.previousMilestone(store.econ.stationMilestones, level: st.level, cap: store.cap)
        let frac: Double
        let label: String
        if let n = next {
            frac = Double(st.level - prev) / Double(max(1, n - prev))
            label = Num.int(st.level) + "/" + Num.int(n) + " " + (store.milestoneIsSpeed(i, count: store.stationMilestones(i) + 1) ? "سرعة ×2" : "ربح ×2")
        } else {
            frac = 1
            label = "كل المراحل"
        }
        return FancyBar(value: frac, tint: frac > 0.8 ? Brand.goldLight : Brand.gold, height: 13, label: label)
    }

    @ViewBuilder
    private var incomeLine: some View {
        if let out = store.chainOutputOf(i) {
            Text("بيموّن " + store.t(store.city.stations[out].name))
                .font(.game(12, .bold))
                .foregroundColor(Brand.teal)
        } else {
            let st = store.station(i)
            let inc = store.income(i, at: store.now(), active: true)
            HStack(spacing: 4) {
                Text(Num.big(inc) + "/ث")
                    .font(.game(13, .black).monospacedDigit())
                    .foregroundColor(Theme.money)
                if !st.managed && !st.cooking && store.oven?.station != i {
                    Text("دقّ للطبخ")
                        .font(.body(10, bold: true))
                        .foregroundColor(Brand.goldLight.opacity(0.85))
                }
            }
        }
    }
}

/// Dish on a plate with the cook ring; tap to cook (unmanaged) or to catch the oven tray.
struct DishButton: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let def = store.city.stations[i]
        let st = store.station(i)
        let tray = store.oven?.station == i
        let fast = store.effCycle(i) < 0.6
        let showRing = st.managed || st.cooking
        let idle = !st.managed && !st.cooking && !tray
        Button {
            store.tapCook(i)
        } label: {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Brand.cream, Color(hex: 0xE8D2B0)], center: .center, startRadius: 2, endRadius: 34))
                    .frame(width: 62, height: 62)
                    .overlay(Circle().stroke(Brand.outline.opacity(0.5), lineWidth: 2))
                if showRing {
                    Circle()
                        .trim(from: 0, to: fast ? 1 : CGFloat(st.progress))
                        .stroke(fast ? Brand.goldLight : Brand.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 70, height: 70)
                }
                if tray {
                    Circle()
                        .fill(RadialGradient(colors: [Color.white.opacity(0.9), Brand.gold.opacity(0)], center: .center,
                                             startRadius: 2, endRadius: 44))
                        .frame(width: 86, height: 86)
                }
                ArtIcon(def.art, size: 48)
                if tray {
                    Text("دقّ!")
                        .font(.game(12, .black))
                        .foregroundColor(Brand.outline)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(Brand.goldLight))
                        .offset(y: 30)
                }
            }
            .frame(width: 72, height: 72)
            .modifier(Pulse(active: idle || tray, amount: tray ? 0.12 : 0.05))
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("station.\(i).cook")
    }
}

struct BuyButton: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let plan = store.buyPlan(i)
        let modeLabel = store.buyMode == .x1 ? "اشتري" : "اشتري ×" + Num.int(plan.count)
        ChunkyButton(title: modeLabel, subtitle: Num.big(plan.cost), color: plan.affordable ? .green : .gray,
                     enabled: true, sound: nil) {
            store.buy(i)
        }
        .overlay(etaLabel(plan), alignment: .bottom)
        .fxAnchor("station.\(i).buy")
    }

    @ViewBuilder
    private func etaLabel(_ plan: BuyPlan) -> some View {
        if !plan.affordable, let e = store.eta(plan.cost), e > 0, e < 86400 * 3 {
            Text("بعد " + Num.dur(e))
                .font(.body(9, bold: true))
                .foregroundColor(Brand.cream.opacity(0.8))
                .offset(y: 12)
        }
    }
}

struct ManagerSlot: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let st = store.station(i)
        if st.managed {
            Text(store.managerName(i))
                .font(.body(10, bold: true))
                .foregroundColor(Brand.cream.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else if store.unlocked("managers") {
            let cost = store.managerCost(i)
            let ok = store.s.city.cash >= cost
            Button {
                store.hire(i)
            } label: {
                HStack(spacing: 3) {
                    ArtIcon(store.city.stations[i].managerArt, size: 18, shadow: false)
                    VStack(spacing: 0) {
                        Text("وظّف معلّم")
                            .font(.game(10, .black))
                        Text(Num.big(cost))
                            .font(.game(11, .black).monospacedDigit())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(ok ? Brand.teal : Color(hex: 0x5E5048)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Brand.outline.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(PressScaleStyle())
            .fxAnchor("station.\(i).manager")
        }
    }
}

struct TwistChips: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let t = store.now()
        let m = store.twistProfit(i, at: t) * store.twistActive(i)
        if m > 1.001 {
            Text(Num.mult(m))
                .font(.game(10, .black))
                .foregroundColor(Brand.outline)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Capsule().fill(Brand.goldLight))
        }
    }
}

struct LockedStationCard: View {
    @EnvironmentObject var store: GameStore
    let i: Int

    var body: some View {
        let def = store.city.stations[i]
        let plan = store.buyPlan(i)
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 62, height: 62)
                ArtIcon(def.art, size: 46, shadow: false)
                    .saturation(0)
                    .opacity(plan.affordable ? 0.85 : 0.4)
            }
            .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.t(def.name))
                    .font(.game(16, .black))
                    .foregroundColor(Brand.cream.opacity(0.85))
                Text(GameStore.cuisineName(def.cuisine))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.55))
            }
            Spacer(minLength: 2)
            ChunkyButton(title: "افتح بـ", subtitle: Num.big(plan.cost), color: plan.affordable ? .gold : .gray,
                         enabled: true, sound: nil) {
                store.buy(i)
            }
            .frame(width: 108)
            .fxAnchor("station.\(i).buy")
        }
        .padding(10)
        .background(CardBackground().opacity(0.85))
    }
}

extension GameStore {
    static func cuisineName(_ c: String) -> String {
        switch c {
        case "palestinian": return "مطبخ فلسطيني"
        case "levantine": return "مطبخ شامي"
        case "egyptian": return "مطبخ مصري"
        case "gulf": return "مطبخ خليجي"
        case "iraqi": return "مطبخ عراقي"
        case "maghrebi": return "مطبخ مغربي"
        case "turkish": return "مطبخ تركي"
        case "world": return "مطبخ عالمي"
        default: return ""
        }
    }
}
