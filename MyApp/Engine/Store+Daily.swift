import Foundation

/// Daily and weekly orders, the 28-day calendar, the streak and tickets (GDD 6.4, 6.5).
extension GameStore {
    var qx: QuestsFile { cat.quests }
    var cx: CalendarFile { cat.calendar }

    /// Consecutive number of the game day (04:00 boundary), safe across time zones.
    func dayNumber(_ t: Double) -> Int { Int(floor((Clock.midnight(t - 4 * 3600) + 43_200) / 86_400)) }

    var dayNum: Int { dayNumber(now()) }

    /// Weeks start on Monday 04:00 (day number 4 was Monday 5 January 1970).
    var weekNum: Int { Int(floor(Double(dayNum - 4) / 7)) }

    func metric(_ m: String) -> Double { s.metrics[m] ?? 0 }

    func bump(_ m: String, _ v: Double = 1) { s.metrics[m, default: 0] += v }

    var band: Int {
        if let i = qx.bands.firstIndex(where: { level >= $0.minLevel && level <= $0.maxLevel }) { return i }
        return max(0, qx.bands.count - 1)
    }

    func template(_ id: String) -> QuestTemplate? {
        qx.daily.first { $0.id == id } ?? qx.weekly.first { $0.id == id }
    }

    func questTarget(_ q: QuestTemplate) -> Double {
        q.targets.count > band ? q.targets[band] : (q.targets.first ?? 1)
    }

    func templateEligible(_ q: QuestTemplate) -> Bool {
        if let sys = q.requiresSystem {
            guard GameStore.builtSystems.contains(sys), unlocked(sys) else { return false }
        }
        if level < q.minLevel { return false }
        switch q.eligibility {
        case "always": return true
        case "goalsRemaining": return Double(visibleGoals.filter { !goalDone($0) }.count) >= questTarget(q)
        case "researchSlotFree": return freeResearchSlots > 0 || (nextResearchEnd.map { $0 - now() < 6 * 3600 } ?? false)
        case "stationBelowCap": return s.city.stations.contains { $0.level > 0 && $0.level < cap }
        case "unmanagedStation": return s.city.stations.contains { $0.level > 0 && !$0.managed }
        case "chestInInventory": return chestCount > 0
        case "upgradeWithin30Min":
            guard let u = nextUpgrades.first else { return false }
            return upgradePrice(u) <= 30 * 60 * max(1, totalIncome(active: false))
        case "chefUpgradable": return anyChefCanLevel
        case "starsRemaining": return supportedStars - s.city.stars >= 5
        default: return false
        }
    }

    func makeOrder(_ q: QuestTemplate) -> OrderSave {
        var o = OrderSave()
        s.daily.orderCounter += 1
        o.uid = "o\(s.daily.orderCounter)"
        o.templateId = q.id
        o.target = questTarget(q)
        if q.metric == "earnMinutes" {
            o.rate = max(1, totalIncome(active: false))
            o.baseline = metric("earned")
        } else {
            o.baseline = metric(q.metric)
        }
        return o
    }

    func orderProgress(_ o: OrderSave) -> Double {
        guard let q = template(o.templateId) else { return 0 }
        if q.metric == "earnMinutes" { return max(0, (metric("earned") - o.baseline) / (o.rate * 60)) }
        return max(0, metric(q.metric) - o.baseline)
    }

    func orderDone(_ o: OrderSave) -> Bool { orderProgress(o) >= o.target - 1e-9 }

    func orderText(_ o: OrderSave) -> String {
        guard let q = template(o.templateId) else { return "" }
        return t(q.text).replacingOccurrences(of: "{n}", with: Num.int(Int(o.target)))
    }

    // MARK: Rollover

    func dailyRollover() {
        marketGifts()
        guard unlocked("daily") else { return }
        let d = dayNum
        processStreak(today: d)
        if s.daily.day != d {
            s.daily.day = d
            s.daily.rerolls = 0
            s.daily.bonusClaimed = false
            var picked: [String] = []
            var list: [OrderSave] = []
            for diff in ["easy", "medium", "hard"] {
                var pool = qx.daily.filter { $0.difficulty == diff && !picked.contains($0.id) && templateEligible($0) }
                if pool.isEmpty { pool = qx.daily.filter { !picked.contains($0.id) && templateEligible($0) } }
                guard !pool.isEmpty else { continue }
                var r = Seed.rng("orders", ["\(d)", diff], player: s.meta.seed)
                let q = pool[r.int(pool.count)]
                picked.append(q.id)
                list.append(makeOrder(q))
            }
            s.daily.orders = list
        }
        let w = weekNum
        if s.daily.week != w {
            s.daily.week = w
            s.daily.weeklyBonusClaimed = false
            var pool = qx.weekly.filter { templateEligible($0) }
            var list: [OrderSave] = []
            var r = Seed.rng("weekly", ["\(w)"], player: s.meta.seed)
            for _ in 0..<3 where !pool.isEmpty {
                let q = pool.remove(at: r.int(pool.count))
                list.append(makeOrder(q))
            }
            s.daily.weekly = list
        }
    }

    func processStreak(today: Int) {
        if s.daily.lastRolledDay == 0 {
            s.daily.lastRolledDay = today
            return
        }
        guard today > s.daily.lastRolledDay else { return }
        var d = s.daily.lastRolledDay
        var steps = 0
        while d < today && steps < 60 {
            if s.daily.streak > 0 && s.daily.streakLastDay < d {
                if s.wallet.freezes > 0 {
                    s.wallet.freezes -= 1
                    s.daily.streakLastDay = d
                } else {
                    s.daily.repairOld = s.daily.streak
                    s.daily.repairUntil = today + cx.repairDays - 1
                    s.daily.repairProgress = 0
                    s.daily.streak = 0
                }
            }
            d += 1
            steps += 1
        }
        s.daily.lastRolledDay = today
        if s.daily.repairOld > 0 && today > s.daily.repairUntil { s.daily.repairOld = 0 }
    }

    // MARK: Claims

    func claimOrder(_ uid: String, weekly: Bool) {
        var list = weekly ? s.daily.weekly : s.daily.orders
        guard let k = list.firstIndex(where: { $0.uid == uid }), !list[k].claimed, orderDone(list[k]) else { return }
        list[k].claimed = true
        if weekly { s.daily.weekly = list } else { s.daily.orders = list }
        let rewards = weekly ? qx.weeklyReward : qx.dailyReward
        var lines: [String] = []
        for r in rewards {
            if r.type == "xp" { addXP(Int(r.amount)); continue }
            if let l = applyReward(r), r.type == "gold" { lines.append(l.amount) }
        }
        if !weekly {
            bump("dailyOrders")
            streakOrderDone()
        }
        Feedback.play(.t1, fromAnchor: "order." + uid, art: "ui_coin", to: "pill.gold", amount: 10,
                      label: (lines.first ?? "") + " ذهب")
        save()
    }

    var dailyBonusReady: Bool {
        !s.daily.orders.isEmpty && s.daily.orders.allSatisfy { $0.claimed } && !s.daily.bonusClaimed
    }

    var weeklyBonusReady: Bool {
        !s.daily.weekly.isEmpty && s.daily.weekly.allSatisfy { $0.claimed } && !s.daily.weeklyBonusClaimed
    }

    func claimBonus(weekly: Bool) {
        guard weekly ? weeklyBonusReady : dailyBonusReady else { return }
        if weekly { s.daily.weeklyBonusClaimed = true } else { s.daily.bonusClaimed = true }
        var items: [RewardLine] = []
        for r in weekly ? qx.weeklyBonus : qx.dailyBonus {
            if r.type == "xp" {
                addXP(Int(r.amount))
                items.append(RewardLine(art: "ui_sparkles", amount: "+" + Num.int(Int(r.amount)), caption: "خبرة"))
                continue
            }
            if let l = applyReward(r) { items.append(l) }
        }
        enqueue(.rewards(title: weekly ? "جايزة الأسبوع!" : "خلّصت طلبات اليوم!", lines: items))
        Feedback.play(.t2)
        save()
    }

    var rerollsLeft: Int { max(0, qx.rerollMax - s.daily.rerolls) }

    var nextRerollCost: Int { s.daily.rerolls < qx.rerollFree ? 0 : qx.rerollCost }

    func reroll(_ uid: String) {
        guard rerollsLeft > 0, let k = s.daily.orders.firstIndex(where: { $0.uid == uid && !$0.claimed }),
              let old = template(s.daily.orders[k].templateId) else { return }
        let cost = nextRerollCost
        guard s.wallet.gold >= cost else {
            Feedback.error()
            return
        }
        let used = s.daily.orders.map { $0.templateId }
        var pool = qx.daily.filter { $0.difficulty == old.difficulty && !used.contains($0.id) && templateEligible($0) }
        if pool.isEmpty { pool = qx.daily.filter { !used.contains($0.id) && templateEligible($0) } }
        guard !pool.isEmpty else {
            showToast("ما في طلبات تانية هسّا", art: "ui_clipboard")
            return
        }
        s.wallet.gold -= cost
        s.daily.rerolls += 1
        var r = Seed.rng("ordersReroll", ["\(dayNum)", "\(s.daily.rerolls)"], player: s.meta.seed)
        s.daily.orders[k] = makeOrder(pool[r.int(pool.count)])
        Feedback.play(.t0)
        save()
    }

    // MARK: Streak

    func streakOrderDone() {
        let d = dayNum
        if s.daily.repairOld > 0 && d <= s.daily.repairUntil {
            s.daily.repairProgress += 1
            if s.daily.repairProgress >= cx.repairOrders {
                s.daily.streak = max(s.daily.streak, s.daily.repairOld + cx.repairBonusDays)
                s.daily.repairOld = 0
                showToast("رجعت السلسلة! " + Num.int(s.daily.streak) + " يوم", art: "ui_fire")
            }
        }
        guard s.daily.streakLastDay != d else { return }
        s.daily.streak += 1
        s.daily.streakLastDay = d
        s.daily.streakBest = max(s.daily.streakBest, s.daily.streak)
        for m in cx.milestones where s.daily.streak >= m.days && !s.daily.milestonesClaimed.contains(m.days) {
            s.daily.milestonesClaimed.append(m.days)
            var items: [RewardLine] = []
            for r in m.rewards { if let l = applyReward(r) { items.append(l) } }
            enqueue(.rewards(title: "سلسلة " + Num.int(m.days) + " يوم!", lines: items))
        }
        Feedback.play(.t1, fromAnchor: "streak.flame", art: "ui_fire", to: "streak.flame", amount: 1,
                      label: "سلسلة " + Num.int(s.daily.streak))
    }

    var freezeCap: Int { cx.freezeCaps.filter { $0.level <= level }.map { $0.cap }.max() ?? 2 }

    func buyFreeze() {
        guard s.wallet.freezes < freezeCap, s.wallet.gold >= cx.freezePrice else {
            Feedback.error()
            return
        }
        s.wallet.gold -= cx.freezePrice
        s.wallet.freezes += 1
        Feedback.play(.t1, fromAnchor: "streak.freeze", art: "ui_snowflake", to: "streak.freeze", amount: 1, label: "+1 تجميدة")
        save()
    }

    // MARK: Calendar

    var calendarReady: Bool { unlocked("calendar") && s.daily.calLastDay != dayNum }

    func calendarDay(_ i: Int) -> CalendarDayDef? { cx.days.first { $0.day == i } }

    func claimCalendar() {
        guard calendarReady, let def = calendarDay(s.daily.calIndex) else { return }
        s.daily.calLastDay = dayNum
        let scale = min(cx.goldScaleMax, 1 + cx.goldScalePerCycle * Double(s.daily.calCycle - 1))
        var items: [RewardLine] = []
        for var r in def.rewards {
            if r.type == "gold" { r.amount = (r.amount * scale).rounded() }
            if let l = applyReward(r) { items.append(l) }
        }
        addXP(15)
        bump("calendarClaims")
        rep("calendar")
        seasonPoint("calendar")
        let big = def.big || def.day == 28
        s.daily.calIndex += 1
        if s.daily.calIndex > 28 {
            s.daily.calIndex = 1
            s.daily.calCycle += 1
        }
        if big {
            enqueue(.rewards(title: "يوم " + Num.int(def.day) + " بالروزنامة!", lines: items))
            Feedback.play(.t2)
        } else {
            Feedback.play(.t1, fromAnchor: "calendar.today", art: items.first?.art ?? "ui_coin", to: "pill.gold", amount: 10,
                          label: items.first.map { $0.amount + " " + $0.caption } ?? "")
        }
        save()
    }

    // MARK: Tickets (rush minigame currency)

    var ticketCap: Int { level >= 35 ? 4 : 3 }

    func tickTickets(at time: Double) {
        guard unlocked("rush"), !s.meta.clockFrozen else { return }
        if s.wallet.tickets >= ticketCap {
            s.wallet.ticketAt = time
            return
        }
        if s.wallet.ticketAt <= 0 { s.wallet.ticketAt = time }
        while time - s.wallet.ticketAt >= 3 * 3600 && s.wallet.tickets < ticketCap {
            s.wallet.tickets += 1
            s.wallet.ticketAt += 3 * 3600
        }
    }

    var tasksDot: Bool {
        guard unlocked("daily") else { return false }
        if calendarReady || dailyBonusReady || weeklyBonusReady || seasonDot || achDot { return true }
        return s.daily.orders.contains { !$0.claimed && orderDone($0) } || s.daily.weekly.contains { !$0.claimed && orderDone($0) }
    }
}
