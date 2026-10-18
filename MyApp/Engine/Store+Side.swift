import Foundation

enum SideRef: Hashable {
    case contract(String)
    case event
}

struct ReleaseInfo: Identifiable {
    let id: String
    let contractId: String
    let isNew: Bool
    let day: Int
}

/// Side kitchens (GDD 2.13, 6.9, 6.10): catering contracts and the weekend venue share one small engine.
extension GameStore {
    var sideEcon: SideEconomyDef { cat.side }

    // MARK: Access

    func side(_ r: SideRef) -> SideKitchenSave? {
        switch r {
        case .contract(let id): return s.contracts.active.first { $0.defId == id }
        case .event: return s.event.kitchen
        }
    }

    func setSide(_ r: SideRef, _ k: SideKitchenSave) {
        switch r {
        case .contract(let id):
            if let i = s.contracts.active.firstIndex(where: { $0.defId == id }) { s.contracts.active[i] = k }
        case .event:
            s.event.kitchen = k
        }
    }

    var sideRefs: [SideRef] {
        var list = s.contracts.active.map { SideRef.contract($0.defId) }
        if s.event.kitchen != nil { list.append(.event) }
        return list
    }

    func sideStations(_ r: SideRef) -> [SideStationDef] {
        switch r {
        case .contract(let id):
            guard let d = cat.contract(id) else { return [] }
            return d.rules.contains("oneStation") ? Array(d.stations.prefix(1)) : d.stations
        case .event:
            return cat.theme(s.event.themeId)?.stations ?? []
        }
    }

    func sideRules(_ r: SideRef) -> [String] {
        if case .contract(let id) = r { return cat.contract(id)?.rules ?? [] }
        return []
    }

    func sideTitle(_ r: SideRef) -> String {
        switch r {
        case .contract(let id): return cat.contract(id).map { t($0.title) } ?? ""
        case .event: return cat.theme(s.event.themeId).map { t($0.name) } ?? ""
        }
    }

    func sideArt(_ r: SideRef) -> String {
        switch r {
        case .contract(let id): return cat.contract(id)?.art ?? "ui_clipboard"
        case .event: return cat.theme(s.event.themeId)?.art ?? "ui_party_popper"
        }
    }

    func sideCashArt(_ r: SideRef) -> String {
        if case .event = r { return cat.theme(s.event.themeId)?.cash.art ?? "ui_money_bag" }
        return "ui_money_bag"
    }

    func grade(for level: Int) -> GradeDef? {
        sideEcon.grades.filter { $0.minLevel <= level }.max { $0.minLevel < $1.minLevel }
    }

    func gradeDef(_ id: Int) -> GradeDef? { sideEcon.grades.first { $0.id == id } }

    // MARK: Economy

    func sideRow(_ r: SideRef, _ i: Int) -> TierRow {
        let defs = sideStations(r)
        guard i < defs.count else { return TierRow() }
        return sideEcon.tier(defs[i].tier)
    }

    func sideSpeed(_ k: SideKitchenSave, _ r: SideRef, _ i: Int) -> Double {
        let ms = Rules.milestonesReached(sideEcon.milestones, level: k.stations[i].level, cap: sideEcon.cap)
        let fast = sideRules(r).contains("fastCheap") ? 2.0 : 1.0
        return pow(2, Double(ms)) * fast * (1 + researchValue("speedPct"))
    }

    func sideCycle(_ k: SideKitchenSave, _ r: SideRef, _ i: Int) -> Double {
        max(econ.cycleFloorSec, sideRow(r, i).baseCycleSec / sideSpeed(k, r, i))
    }

    func sideIncome(_ k: SideKitchenSave, _ r: SideRef, _ i: Int, active: Bool) -> Double {
        guard i < k.stations.count, k.stations[i].level > 0 else { return 0 }
        let defs = sideStations(r)
        guard i < defs.count else { return 0 }
        let row = sideRow(r, i)
        let minLv = k.stations.map { $0.level }.min() ?? 0
        let allMs = Rules.milestonesReached(sideEcon.allMilestones, level: minLv, cap: sideEcon.cap)
        var upg = 1.0
        for j in k.upgrades where j == 2 || j == i { upg *= econ.upgradeMult }
        var chef = 1.0
        if !sideRules(r).contains("chefsOff") {
            for id in s.chefs.equipped {
                guard let c = cat.chef(id) else { continue }
                chef += chefBonus(id) * factor(c, cuisine: defs[i].cuisine, category: defs[i].category)
            }
        }
        var boostKey = "eventIncomePct"
        if case .contract = r { boostKey = "contractIncomePct" }
        let boost = 1 + researchValue(boostKey) + heritageBonus("sideIncomePct")
        var m = upg * pow(2, Double(allMs)) * chef * boost
        if active { m *= activeMult }
        return Double(k.stations[i].level) * row.baseRevenue * m * sideSpeed(k, r, i) / row.baseCycleSec
    }

    func factor(_ c: ChefDef, cuisine: String, category: String) -> Double {
        let cu = c.cuisine == "any" || c.cuisine == cuisine
        let ca = c.category == "any" || c.category == category
        if cu && ca { return chefRules.bothMatchFactor }
        return (cu || ca) ? 1 : 0
    }

    func sideTotalIncome(_ r: SideRef) -> Double {
        guard let k = side(r) else { return 0 }
        return k.stations.indices.reduce(0.0) { $0 + sideIncome(k, r, $1, active: false) }
    }

    func advanceSides(dt: Double, foreground: Bool) {
        for r in sideRefs {
            guard var k = side(r) else { continue }
            for i in k.stations.indices {
                var st = k.stations[i]
                guard st.level > 0, st.managed || st.cooking else { continue }
                let T = sideCycle(k, r, i)
                st.progress += dt / T
                var done = 0
                if st.managed {
                    done = Int(floor(st.progress))
                    st.progress -= Double(done)
                } else if st.progress >= 1 {
                    done = 1
                    st.progress = 0
                    st.cooking = false
                }
                k.stations[i] = st
                if done > 0 {
                    let pay = sideIncome(k, r, i, active: foreground) * T * Double(done)
                    k.cash += pay
                    k.lifetime += pay
                }
            }
            setSide(r, k)
        }
    }

    /// Offline catch-up for side kitchens (managed stations, at vault efficiency, capped by the vault window).
    func sideOffline(window: Double) -> [String] {
        var lines: [String] = []
        for r in sideRefs {
            guard var k = side(r) else { continue }
            var earned = 0.0
            for i in k.stations.indices where k.stations[i].managed && k.stations[i].level > 0 {
                earned += sideIncome(k, r, i, active: false) * window
            }
            earned *= vaultEff
            if earned > 0 {
                k.cash += earned
                k.lifetime += earned
                lines.append(sideTitle(r) + " +" + Num.big(earned))
            }
            setSide(r, k)
        }
        return lines
    }

    func sideBuyPlan(_ r: SideRef, _ i: Int) -> BuyPlan {
        guard let k = side(r), i < k.stations.count else { return BuyPlan(count: 0, cost: 0, affordable: false, atCap: true) }
        let row = sideRow(r, i)
        let cheap = sideRules(r).contains("fastCheap") ? 0.5 : 1.0
        let lv = k.stations[i].level
        if lv == 0 {
            let c = Rules.cost(row, scale: cheap, level: 0, count: 1)
            return BuyPlan(count: 1, cost: c, affordable: k.cash >= c, atCap: false)
        }
        let room = sideEcon.cap - lv
        if room <= 0 { return BuyPlan(count: 0, cost: 0, affordable: false, atCap: true) }
        var n = 1
        switch buyMode {
        case .x1: n = 1
        case .x10: n = min(10, room)
        case .next:
            let target = Rules.nextMilestone(sideEcon.milestones, level: lv, cap: sideEcon.cap) ?? sideEcon.cap
            n = max(1, min(room, target - lv))
        case .max:
            n = max(1, Rules.maxAffordable(row, scale: cheap, level: lv, cash: k.cash, cap: sideEcon.cap))
        }
        let c = Rules.cost(row, scale: cheap, level: lv, count: n)
        return BuyPlan(count: n, cost: c, affordable: k.cash >= c, atCap: false)
    }

    func sideStationLocked(_ r: SideRef, _ i: Int) -> Bool {
        guard case .event = r, let k = side(r) else { return false }
        for (idx, m) in cat.events.milestones.enumerated() where m.unlocksStation == i {
            return k.reached <= idx
        }
        return false
    }

    func sideBuy(_ r: SideRef, _ i: Int) {
        guard !sideStationLocked(r, i), var k = side(r) else {
            Feedback.error()
            return
        }
        let plan = sideBuyPlan(r, i)
        guard plan.count > 0, plan.affordable else {
            Feedback.error()
            return
        }
        k.cash -= plan.cost
        k.stations[i].level += plan.count
        bump("levelsBought", Double(plan.count))
        setSide(r, k)
        Feedback.play(.t0)
    }

    func sideManagerCost(_ r: SideRef, _ i: Int) -> Double {
        let row = sideRow(r, i)
        return row.baseCost * row.managerMult * (1 - min(0.9, researchValue("managerCostPct")))
    }

    func sideHire(_ r: SideRef, _ i: Int) {
        guard !sideRules(r).contains("noManagers"), var k = side(r), k.stations[i].level > 0, !k.stations[i].managed else { return }
        let c = sideManagerCost(r, i)
        guard k.cash >= c else {
            Feedback.error()
            return
        }
        k.cash -= c
        k.stations[i].managed = true
        k.stations[i].cooking = true
        setSide(r, k)
        Feedback.play(.t1)
    }

    func sideTap(_ r: SideRef, _ i: Int) {
        guard var k = side(r), i < k.stations.count, k.stations[i].level > 0, !k.stations[i].managed, !k.stations[i].cooking else { return }
        k.stations[i].cooking = true
        k.stations[i].progress = 0
        setSide(r, k)
        bump("tapCooks")
        s.stats.taps += 1
        Feedback.play(.t0)
    }

    func sideUpgradePrice(_ j: Int) -> Double { sideEcon.upgradeBase * pow(sideEcon.upgradeRatio, Double(j)) }

    func sideBuyUpgrade(_ r: SideRef, _ j: Int) {
        guard !sideRules(r).contains("noUpgrades"), var k = side(r), !k.upgrades.contains(j) else { return }
        let p = sideUpgradePrice(j)
        guard k.cash >= p else {
            Feedback.error()
            return
        }
        k.cash -= p
        k.upgrades.append(j)
        setSide(r, k)
        Feedback.play(.t1)
        SFX.upgrade.play()
    }

    func newSideKitchen(defId: String, kind: String, stations n: Int, hours: Double) -> SideKitchenSave {
        var k = SideKitchenSave()
        k.defId = defId
        k.kind = kind
        k.stations = Array(repeating: StationState(), count: n)
        if n > 0 { k.stations[0].level = 1 }
        k.cash = sideEcon.startCash
        k.startAt = now()
        k.endAt = now() + hours * 3600
        k.grade = grade(for: level)?.id ?? 1
        return k
    }

    // MARK: Contracts (GDD 6.9)

    var contractSlots: Int {
        guard unlocked("contracts") else { return 0 }
        return cat.contracts.slotsByLevel.filter { $0.level <= level }.map { $0.slots }.max() ?? 1
    }

    var contractEpochDay: Int {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let d = f.date(from: cat.contracts.epoch) ?? Date(timeIntervalSince1970: 1_767_571_200)
        return dayNumber(d.timeIntervalSince1970 + 12 * 3600)
    }

    /// Monday "new" release plus Wednesday and Friday reruns, for this week and last week.
    var releases: [ReleaseInfo] {
        let lib = cat.contracts.contracts
        guard !lib.isEmpty else { return [] }
        let week = max(0, (dayNum - contractEpochDay) / 7)
        var out: [ReleaseInfo] = []
        for w in [week - 1, week] where w >= 0 {
            let monday = contractEpochDay + w * 7
            let fresh = lib[w % lib.count]
            out.append(ReleaseInfo(id: "w\(w)-mon", contractId: fresh.id, isNew: true, day: monday))
            let older = lib.filter { $0.releaseOrder < fresh.releaseOrder }
            let pool = older.isEmpty ? lib.filter({ $0.id != fresh.id }) : older
            var r = Seed.rng("contract", ["\(w)"], player: s.meta.seed)
            var list = pool
            for (k, off) in [2, 4].enumerated() where !list.isEmpty {
                let pick = list.remove(at: r.int(list.count))
                out.append(ReleaseInfo(id: "w\(w)-\(k)", contractId: pick.id, isNew: false, day: monday + off))
            }
        }
        return out
    }

    var board: [ReleaseInfo] {
        let d = dayNum
        let activeIds = Set(s.contracts.active.map { $0.defId })
        let avail = releases.filter {
            d >= $0.day && d < $0.day + cat.contracts.availabilityDays && !s.contracts.startedReleases.contains($0.id)
                && !activeIds.contains($0.contractId)
        }
        return Array(avail.suffix(cat.contracts.boardMax).reversed())
    }

    func startContract(_ rel: ReleaseInfo) {
        guard unlocked("contracts"), let def = cat.contract(rel.contractId) else { return }
        guard s.contracts.active.count < contractSlots else {
            showToast("كل خانات الطلبيات مليانة", art: "ui_clipboard")
            Feedback.error()
            return
        }
        let n = def.rules.contains("oneStation") ? 1 : def.stations.count
        let hours = def.rules.contains("noManagers") ? 48 : def.durationHours
        let k = newSideKitchen(defId: def.id, kind: "contract", stations: n, hours: hours)
        s.contracts.active.append(k)
        s.contracts.startedReleases.append(rel.id)
        if s.contracts.startedReleases.count > 40 { s.contracts.startedReleases.removeFirst(10) }
        Feedback.play(.t1)
        sheet = .side(.contract(def.id))
        save()
    }

    func contractTarget(_ k: SideKitchenSave, _ goal: Int) -> Double {
        guard let def = cat.contract(k.defId), goal < def.goalsBase.count else { return .infinity }
        var t = def.goalsBase[goal] * (gradeDef(k.grade)?.targetFactor ?? 1)
        if def.rules.contains("noManagers") { t *= 0.3 }
        if def.rules.contains("oneStation") { t *= 0.05 }
        return t
    }

    func partnerShare(_ k: SideKitchenSave, at t: Double) -> [Double] {
        guard let def = cat.contract(k.defId) else { return [] }
        let g3 = contractTarget(k, 2)
        let frac = min(1, max(0, (t - k.startAt) / max(1, k.endAt - k.startAt)))
        return def.partners.map { $0.share * g3 * pow(frac, $0.gamma) }
    }

    func delivered(_ k: SideKitchenSave) -> Double {
        k.lifetime + partnerShare(k, at: now()).reduce(0, +)
    }

    func checkContracts() {
        let tNow = now()
        for k0 in s.contracts.active {
            var k = k0
            guard let def = cat.contract(k.defId) else { continue }
            let g = gradeDef(k.grade)
            while k.reached < 3 && delivered(k) >= contractTarget(k, k.reached) {
                k.reached += 1
                var lines: [RewardLine] = []
                let xpMult = g?.xpMult ?? 1
                switch k.reached {
                case 1:
                    for var r in def.goal1 {
                        if r.type == "gold" { r.amount = (r.amount * (g?.goldMult ?? 1)).rounded() }
                        if r.type == "chest" { r.id = g?.goal1Chest ?? r.id }
                        if let l = applyReward(r) { lines.append(l) }
                    }
                    addXP(Int(50 * xpMult))
                    rep("contractGoal1")
                    seasonPoint("contractGoal1")
                case 2:
                    if s.contracts.zaatarIds.contains(def.id) {
                        s.wallet.gold += 50
                        lines.append(RewardLine(art: "ui_coin", amount: "+50", caption: "ذهب"))
                    } else {
                        s.contracts.zaatarIds.append(def.id)
                        if let l = applyReward(Reward(type: "zaatar", amount: 1)) { lines.append(l) }
                    }
                    addXP(Int(100 * xpMult))
                    rep("contractGoal2")
                    seasonPoint("contractGoal2")
                default:
                    for r in def.goal3 { if let l = applyReward(r) { lines.append(l) } }
                    addXP(Int(200 * xpMult))
                    rep("contractGoal3")
                    seasonPoint("contractGoal3")
                }
                bump("contractGoals")
                enqueue(.rewards(title: t(def.title) + ": هدف " + Num.int(k.reached), lines: lines))
                Feedback.play(k.reached == 3 ? .t2 : .t1)
            }
            if let i = s.contracts.active.firstIndex(where: { $0.defId == k.defId }) { s.contracts.active[i] = k }
            if k.reached >= 3 || tNow >= k.endAt {
                s.contracts.active.removeAll { $0.defId == k.defId }
                if k.reached >= 3 { bump("contractsCompleted") }
                if case .side(let r)? = sheet, r == .contract(k.defId) { sheet = nil }
                showToast("خلصت طلبية " + t(def.title) + " · " + Num.frac(k.reached, 3) + " أهداف", art: def.art)
                save()
            }
        }
    }

    var contractsDot: Bool {
        guard unlocked("contracts") else { return false }
        return !board.isEmpty && s.contracts.active.count < contractSlots
    }

    // MARK: Weekend venue (GDD 6.10)

    var eventLive: Bool {
        guard unlocked("events") else { return false }
        let weekStart = 4 + weekNum * 7
        return dayNum >= weekStart + 3
    }

    func themeFor(week: Int) -> EventThemeDef? {
        let rot = cat.events.rotation
        guard !rot.isEmpty else { return nil }
        let id = rot[((week % rot.count) + rot.count) % rot.count]
        let prevId = rot[(((week - 1) % rot.count) + rot.count) % rot.count]
        if id == prevId, let next = cat.theme(rot[(((week + 1) % rot.count) + rot.count) % rot.count]) { return next }
        return cat.theme(id)
    }

    var eventEndAt: Double { now() + (1 - weekFraction(at: now())) * 7 * 86400 }

    func eventTick() {
        guard unlocked("events") else { return }
        let w = weekNum
        if s.event.kitchen != nil && s.event.week != w { finishEvent() }
        guard eventLive, s.event.week != w || s.event.kitchen == nil, s.event.finishedWeek != w else { return }
        guard let theme = themeFor(week: w) else { return }
        s.event.week = w
        s.event.themeId = theme.id
        s.event.tokens = 0
        s.event.shop = [:]
        var k = newSideKitchen(defId: theme.id, kind: "event", stations: theme.stations.count, hours: 96)
        k.endAt = eventEndAt
        s.event.kitchen = k
        if isForeground { showToast("مهرجان الويكند بلّش: " + t(theme.name), art: theme.art) }
    }

    func eventTarget(_ k: SideKitchenSave, _ m: Int) -> Double {
        guard m < cat.events.milestones.count else { return .infinity }
        return cat.events.milestones[m].base * (gradeDef(k.grade)?.targetFactor ?? 1)
    }

    func checkEvent() {
        guard var k = s.event.kitchen else { return }
        let ms = cat.events.milestones
        while k.reached < ms.count && k.lifetime >= eventTarget(k, k.reached) {
            let m = ms[k.reached]
            k.reached += 1
            var lines: [RewardLine] = []
            for var r in m.rewards {
                if r.type == "eventTokens" {
                    s.event.tokens += Int(r.amount)
                    lines.append(RewardLine(art: cat.theme(s.event.themeId)?.tokens.art ?? "ui_star", amount: Num.plus(Num.int(Int(r.amount))),
                                            caption: cat.theme(s.event.themeId).map { t($0.tokens.name) } ?? ""))
                    continue
                }
                if r.type == "chefCards" && r.id == "themeChef" { r.id = cat.theme(s.event.themeId)?.chefId }
                if let l = applyReward(r) { lines.append(l) }
            }
            let final = k.reached == ms.count
            addXP(final ? 100 : 30)
            rep(final ? "eventMilestoneFinal" : "eventMilestone")
            seasonPoint("eventMilestone")
            bump("eventMilestones")
            enqueue(.rewards(title: "المهرجان: مرحلة " + Num.int(k.reached), lines: lines))
            Feedback.play(final ? .t2 : .t1)
        }
        s.event.kitchen = k
    }

    func eventNPCs() -> [LeagueNPC] {
        guard let k = s.event.kitchen else { return [] }
        let finals = s.event.finals.suffix(2)
        let def8 = eventTarget(k, 7)
        let e = finals.isEmpty ? def8 : exp(finals.map { log(max(1, $0)) }.reduce(0, +) / Double(finals.count))
        var r = Seed.rng("eventNPC", ["\(s.event.week)", s.event.themeId], player: s.meta.seed)
        var out: [LeagueNPC] = []
        let names = lg.fixedNames
        for i in 0..<cat.events.npcCount {
            let u1 = max(1e-9, r.unit())
            let u2 = r.unit()
            let z = sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
            let nm = names.isEmpty ? "مطعم \(i + 1)" : t(names[r.int(names.count)].name)
            let arch = lg.archetypes[r.weighted(lg.archetypes.map { $0.weight })].id
            let art = lg.avatars.isEmpty ? "food_falafel" : lg.avatars[r.int(lg.avatars.count)]
            out.append(LeagueNPC(key: "e\(i)", name: nm, art: art, archetype: arch, final: e * exp(cat.events.npcSigma * z)))
        }
        return out
    }

    var eventRows: [LeagueRow] {
        guard let k = s.event.kitchen else { return [] }
        let x = min(1, max(0, (now() - k.startAt) / max(1, k.endAt - k.startAt)))
        var rows = eventNPCs().map { n in
            LeagueRow(id: n.key, name: n.name, art: n.art, score: Int(n.final * curve(n.archetype, x)), isPlayer: false)
        }
        rows.append(LeagueRow(id: "player", name: s.settings.stallName, art: "ppl_cook", score: Int(k.lifetime), isPlayer: true))
        return rows.sorted { $0.score > $1.score }
    }

    func buyEventItem(_ item: EventShopItemDef) {
        let bought = s.event.shop[item.id] ?? 0
        guard bought < item.max, s.event.tokens >= item.price else {
            Feedback.error()
            return
        }
        s.event.tokens -= item.price
        s.event.shop[item.id] = bought + 1
        var r = item.reward
        if r.type == "chefCards" && r.id == "themeChef" { r.id = cat.theme(s.event.themeId)?.chefId }
        if let l = applyReward(r) {
            Feedback.play(.t1, fromAnchor: "eventShop." + item.id, art: l.art, to: "eventShop." + item.id, amount: 1, label: l.amount)
        }
        save()
    }

    func finishEvent() {
        guard let k = s.event.kitchen else { return }
        let finals = eventNPCs().map { $0.final }
        let score = k.lifetime
        let rank = 1 + finals.filter { $0 > score }.count
        var lines: [RewardLine] = []
        if let rw = cat.events.rankRewards.first(where: { rank >= $0.fromRank && rank <= $0.toRank }) {
            for r in rw.rewards { if let l = applyReward(r) { lines.append(l) } }
        }
        let gold = min(cat.events.maxGold, s.event.tokens / max(1, cat.events.tokensPerGold))
        if gold > 0 {
            s.wallet.gold += gold
            lines.append(RewardLine(art: "ui_coin", amount: Num.plus(Num.int(gold)), caption: "ذهب من التوكنز"))
        }
        if k.reached >= cat.events.milestones.count { bump("eventsMaxed") }
        s.event.finals.append(max(1, score))
        if s.event.finals.count > 2 { s.event.finals.removeFirst(s.event.finals.count - 2) }
        s.event.finishedWeek = s.event.week
        s.event.kitchen = nil
        s.event.tokens = 0
        if case .side(.event)? = sheet { sheet = nil }
        enqueue(.rewards(title: "خلص المهرجان: المركز " + Num.int(rank), lines: lines))
        save()
    }

    var eventCountdown: Double {
        if let k = s.event.kitchen { return max(0, k.endAt - now()) }
        let weekStart = 4 + weekNum * 7
        let daysToThu = Double(weekStart + 3 - dayNum)
        let sod = Clock.secondsOfDay(now())
        let into = (sod - 4 * 3600 + 86400).truncatingRemainder(dividingBy: 86400)
        return max(0, daysToThu * 86400 - into)
    }
}
