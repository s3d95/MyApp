import SwiftUI

/// Tasks tab (GDD S12–S14): today's orders with the streak, the week, and the 28-day calendar.
struct TasksScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var segment = 0

    var body: some View {
        VStack(spacing: 8) {
            SegmentBar(titles: ["اليوم", "الأسبوع", "الروزنامة"], selection: $segment, dots: dots)
                .padding(.horizontal, 10)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    switch segment {
                    case 0: today
                    case 1: week
                    default: CalendarGrid()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 6)
    }

    private var dots: [Bool] { [todayDot, weekDot, store.calendarReady] }

    private var weekDot: Bool {
        if store.weeklyBonusReady { return true }
        return store.s.daily.weekly.contains { !$0.claimed && store.orderDone($0) }
    }

    private var todayDot: Bool {
        store.dailyBonusReady || store.s.daily.orders.contains { !$0.claimed && store.orderDone($0) }
    }

    private var today: some View {
        VStack(spacing: 10) {
            StreakCard()
            if store.s.daily.repairOld > 0 {
                RepairCard()
            }
            ForEach(store.s.daily.orders) { o in
                OrderCard(order: o, weekly: false)
            }
            BonusCard(weekly: false)
        }
    }

    private var week: some View {
        VStack(spacing: 10) {
            ForEach(store.s.daily.weekly) { o in
                OrderCard(order: o, weekly: true)
            }
            BonusCard(weekly: true)
        }
    }
}

struct StreakCard: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let d = store.s.daily
        WoodPanel(padding: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Brand.glow.opacity(0.8), Brand.red.opacity(0)], center: .center,
                                             startRadius: 2, endRadius: 34))
                        .frame(width: 64, height: 64)
                    ArtIcon("ui_fire", size: 46)
                    OutlinedText(text: Num.int(d.streak), size: 18, color: .white)
                        .offset(y: 16)
                }
                .fxAnchor("streak.flame")
                VStack(alignment: .leading, spacing: 3) {
                    Text("السلسلة: " + Num.int(d.streak) + " يوم")
                        .font(.game(17, .black))
                        .foregroundColor(Brand.goldLight)
                    Text("أحسن سلسلة " + Num.int(d.streakBest) + " · طلب واحد كل يوم بيحميها")
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.75))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 4)
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ArtIcon("ui_snowflake", size: 22)
                        Text(Num.frac(store.s.wallet.freezes, store.freezeCap))
                            .font(.game(13, .black))
                            .foregroundColor(Brand.cream)
                    }
                    if store.s.wallet.freezes < store.freezeCap {
                        Button {
                            store.buyFreeze()
                        } label: {
                            HStack(spacing: 2) {
                                ArtIcon("ui_coin", size: 14, shadow: false)
                                Text(Num.int(store.cx.freezePrice))
                                    .font(.game(11, .black))
                            }
                            .foregroundColor(Brand.outline)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Brand.goldLight))
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
                .fxAnchor("streak.freeze")
            }
        }
    }
}

struct RepairCard: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let d = store.s.daily
        HStack(spacing: 8) {
            ArtIcon("ui_hammer_and_wrench", size: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text("رجّع السلسلة: خلّص " + Num.int(store.cx.repairOrders) + " طلبات خلال يومين")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream)
                FancyBar(value: Double(d.repairProgress) / Double(max(1, store.cx.repairOrders)), tint: Brand.glow, height: 11,
                         label: Num.frac(d.repairProgress, store.cx.repairOrders))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Brand.red.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.glow.opacity(0.7), lineWidth: 1.5))
    }
}

struct OrderCard: View {
    @EnvironmentObject var store: GameStore
    let order: OrderSave
    let weekly: Bool

    var body: some View {
        let done = store.orderDone(order)
        let progress = store.orderProgress(order)
        HStack(spacing: 10) {
            ArtIcon(art, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.orderText(order))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if !order.claimed {
                    FancyBar(value: min(1, progress / max(1, order.target)), tint: done ? Brand.parsley : Brand.gold, height: 12,
                             label: Num.frac(Int(min(progress, order.target)), Int(order.target)))
                }
                HStack(spacing: 6) {
                    rewardChip("ui_coin", weekly ? "10" : "2")
                    rewardChip("ui_sparkles", weekly ? "120" : "30")
                }
            }
            Spacer(minLength: 4)
            if order.claimed {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(Brand.parsley)
            } else if done {
                ChunkyButton(title: "خذ", color: .green, sound: nil) { store.claimOrder(order.uid, weekly: weekly) }
                    .frame(width: 70)
            } else if !weekly && store.rerollsLeft > 0 {
                Button {
                    store.reroll(order.uid)
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .heavy))
                        Text(store.nextRerollCost == 0 ? "ببلاش" : Num.int(store.nextRerollCost))
                            .font(.game(10, .black))
                    }
                    .foregroundColor(Brand.cream)
                    .frame(width: 48, height: 44)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(order.claimed ? 0.18 : 0.32)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(done && !order.claimed ? Brand.gold : Brand.gold.opacity(0.2), lineWidth: done && !order.claimed ? 2 : 1))
        .fxAnchor("order." + order.uid)
    }

    private func rewardChip(_ art: String, _ text: String) -> some View {
        HStack(spacing: 2) {
            ArtIcon(art, size: 14, shadow: false)
            Text(Num.iso(text))
                .font(.game(11, .black))
                .foregroundColor(Brand.goldLight)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.black.opacity(0.35)))
    }

    private var art: String {
        guard let q = store.template(order.templateId) else { return "ui_clipboard" }
        switch q.metric {
        case "levelsBought", "stationMilestones": return "ui_chart_up"
        case "goalsClaimed", "stars": return "ui_star"
        case "specials": return "ui_glowing_star"
        case "runsSent", "runsClaimed": return "veh_tractor"
        case "researchStarted", "researchCompleted": return "ui_notebook"
        case "earnMinutes": return "ui_money_bag"
        case "vaultCollects": return "ui_money_bag"
        case "branchCollects": return "bld_classical_building"
        case "tapCooks": return "food_falafel"
        case "chestsOpened": return "ui_gift"
        case "upgradesBought": return "ui_sparkles"
        case "chefLevelUps": return "ppl_cook"
        case "dailyOrders": return "ui_clipboard"
        case "calendarClaims": return "ui_calendar"
        default: return "ui_clipboard"
        }
    }
}

struct BonusCard: View {
    @EnvironmentObject var store: GameStore
    let weekly: Bool

    var body: some View {
        let list = weekly ? store.s.daily.weekly : store.s.daily.orders
        let done = list.filter { $0.claimed }.count
        let claimed = weekly ? store.s.daily.weeklyBonusClaimed : store.s.daily.bonusClaimed
        let ready = weekly ? store.weeklyBonusReady : store.dailyBonusReady
        HStack(spacing: 10) {
            ChestArt(kind: weekly ? "silver" : "wood", size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(weekly ? "جايزة الأسبوع" : "جايزة اليوم")
                    .font(.game(15, .black))
                    .foregroundColor(Brand.goldLight)
                FancyBar(value: Double(done) / 3, tint: Brand.gold, height: 12, label: Num.frac(done, 3))
            }
            Spacer(minLength: 4)
            if claimed {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(Brand.parsley)
            } else {
                ChunkyButton(title: "افتح", color: ready ? .gold : .gray, sound: nil) { store.claimBonus(weekly: weekly) }
                    .frame(width: 76)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.32)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ready ? Brand.gold : Color.clear, lineWidth: 2))
    }
}

/// 4×7 calendar track; a missed day only pauses it.
struct CalendarGrid: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 10) {
            Text("دورة " + Num.int(store.s.daily.calCycle) + " · يوم " + Num.frac(store.s.daily.calIndex, 28))
                .font(.game(15, .black))
                .foregroundColor(Brand.goldLight)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(1...28, id: \.self) { i in
                    DayCell(day: i)
                }
            }
            if store.calendarReady {
                ChunkyButton(title: "استلم هديّة اليوم", color: .green, sound: nil) { store.claimCalendar() }
                    .fxAnchor("calendar.today")
            } else {
                Text("رجعلنا بكرة لهديّة جديدة")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.7))
            }
        }
    }
}

private struct DayCell: View {
    @EnvironmentObject var store: GameStore
    let day: Int

    var body: some View {
        let def = store.calendarDay(day)
        let current = store.s.daily.calIndex
        let claimed = day < current
        let isToday = day == current && store.calendarReady
        let reward = def?.rewards.first
        VStack(spacing: 2) {
            Text(Num.int(day))
                .font(.game(10, .black))
                .foregroundColor(Brand.cream.opacity(0.7))
            ArtIcon(art(reward), size: def?.big == true ? 34 : 28)
                .opacity(claimed ? 0.45 : 1)
            Text(amount(reward))
                .font(.game(10, .black))
                .foregroundColor(Brand.goldLight)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(RoundedRectangle(cornerRadius: 10).fill(def?.big == true ? Brand.gold.opacity(0.22) : Color.black.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isToday ? Brand.goldLight : Color.clear, lineWidth: 2))
        .overlay(Group {
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Brand.parsley)
                    .padding(3)
            }
        }, alignment: .topTrailing)
        .modifier(Pulse(active: isToday, amount: 0.05))
    }

    private func art(_ r: Reward?) -> String {
        guard let r = r else { return "ui_gift" }
        switch r.type {
        case "gold": return "ui_coin"
        case "tickets": return "ui_admission_tickets"
        case "chest": return "ui_gift"
        case "chefCards": return "ppl_cook"
        case "timeWarpMin": return "ui_hourglass"
        case "heritageItem": return "ui_old_key"
        case "zaatar": return "food_herb"
        case "freezes": return "ui_snowflake"
        default: return "ui_gift"
        }
    }

    private func amount(_ r: Reward?) -> String {
        guard let r = r else { return "" }
        if r.type == "timeWarpMin" { return Num.dur(r.amount * 60) }
        if r.type == "chest" { return store.chestName(r.id ?? "wood").replacingOccurrences(of: "صندوق ", with: "") }
        return "×" + Num.int(Int(r.amount))
    }
}

/// Generic reward celebration (bonus chests, streak milestones, big calendar days).
struct RewardsModal: View {
    @EnvironmentObject var store: GameStore
    let title: String
    let lines: [RewardLine]

    var body: some View {
        RewardReveal(title: title, items: lines.prefix(6).map { RewardItem(art: $0.art, amount: $0.amount, caption: $0.caption) },
                     buttonTitle: "خذ") {
            store.closeModal()
        }
    }
}
