import Foundation

/// City goals and stars, story triggers, graduation, licences and branches (GDD 3.2–3.5, 6.19).
extension GameStore {
    /// Goal types whose systems exist in this build. Others are hidden until their system ships.
    static let builtGoalTypes: Set<String> = [
        "unlockStation", "stationLevel", "allStationsLevel", "hireManager", "managersCount", "earnCash",
        "incomeRate", "buyUpgrades", "customersServed", "tapCook", "specialCustomers", "collectVault",
        "branchCollect", "twistMetric", "equipChefs", "chefTagMatch", "startResearch", "researchLevels",
        "sendSupplyRun", "supplyReturns", "heritageItems", "choiceEvents", "rushRounds", "dailyOrders", "leagueRep",
    ]

    func goalSupported(_ g: GoalDef) -> Bool { GameStore.builtGoalTypes.contains(g.type) }

    var supportedGoals: [GoalDef] { city.goals.filter { goalSupported($0) } }

    var supportedStars: Int { supportedGoals.reduce(0) { $0 + $1.stars } }

    func isClaimed(_ g: GoalDef) -> Bool { s.city.goalsClaimed.contains(g.id) }

    var visibleGoals: [GoalDef] {
        Array(supportedGoals.filter { !isClaimed($0) }.prefix(3))
    }

    var goalStripVisible: Bool { s.ftue.done || s.ftue.step >= 7 }

    func goalScope(_ g: GoalDef) -> String {
        if let sc = g.scope { return sc }
        switch g.type {
        case "collectVault", "branchCollect", "startResearch", "researchLevels", "sendSupplyRun", "supplyReturns",
             "heritageItems", "choiceEvents", "rushRounds", "dailyOrders", "leagueRep": return "slot"
        default: return "city"
        }
    }

    func slotMetric(_ type: String) -> Double {
        switch type {
        case "collectVault": return Double(s.stats.vaultCollects)
        case "branchCollect": return Double(s.stats.branchCollects)
        case "startResearch": return Double(s.research.started)
        case "researchLevels": return Double(s.research.completed)
        case "sendSupplyRun": return Double(s.supply.sent)
        case "supplyReturns": return Double(s.supply.returned)
        case "heritageItems": return Double(s.supply.newItems)
        case "choiceEvents": return metric("choices")
        case "rushRounds": return metric("rushRounds")
        case "dailyOrders": return metric("dailyOrders")
        case "leagueRep": return metric("rep")
        default: return 0
        }
    }

    func goalProgress(_ g: GoalDef) -> (cur: Double, target: Double) {
        let p = g.params
        switch g.type {
        case "unlockStation":
            let lv = city.stationIndex(id: p.stationId ?? "").map { s.city.stations[$0].level } ?? 0
            return (lv >= 1 ? 1 : 0, 1)
        case "stationLevel":
            let lv = city.stationIndex(id: p.stationId ?? "").map { s.city.stations[$0].level } ?? 0
            return (Double(lv), Double(p.level ?? 1))
        case "allStationsLevel":
            return (Double(minStationLevel), Double(p.level ?? 1))
        case "hireManager":
            let m = city.stationIndex(id: p.stationId ?? "").map { s.city.stations[$0].managed } ?? false
            return (m ? 1 : 0, 1)
        case "managersCount":
            return (Double(managersCount), Double(p.count ?? 1))
        case "earnCash":
            return (s.city.lifetimeEarned / scale, p.amountBase ?? 1)
        case "incomeRate":
            return (totalIncome(active: false) / scale, p.amountBase ?? 1)
        case "buyUpgrades":
            return (Double(s.city.upgradesBought.count), Double(p.count ?? 1))
        case "customersServed":
            return (s.city.counters["customers"] ?? 0, Double(p.count ?? 1))
        case "tapCook":
            return (s.city.counters["tapCook"] ?? 0, Double(p.count ?? 1))
        case "specialCustomers":
            return (s.city.counters["specials"] ?? 0, Double(p.count ?? 1))
        case "collectVault", "branchCollect", "startResearch", "researchLevels", "sendSupplyRun", "supplyReturns",
             "heritageItems", "choiceEvents", "rushRounds", "dailyOrders", "leagueRep":
            let base = s.city.goalBaselines[g.id] ?? slotMetric(g.type)
            return (max(0, slotMetric(g.type) - base), p.amount ?? Double(p.count ?? 1))
        case "equipChefs":
            return (Double(s.chefs.equipped.count), Double(p.count ?? 1))
        case "chefTagMatch":
            let n = s.chefs.equipped.filter { !chefStations($0).isEmpty }.count
            return (Double(n), Double(p.count ?? 1))
        case "twistMetric":
            return (s.city.counters[p.metric ?? ""] ?? 0, p.amount ?? 1)
        default:
            return (0, 1)
        }
    }

    func goalDone(_ g: GoalDef) -> Bool {
        let pr = goalProgress(g)
        return pr.cur >= pr.target - 1e-9
    }

    func goalFraction(_ g: GoalDef) -> Double {
        let pr = goalProgress(g)
        guard pr.target > 0 else { return 1 }
        return min(1, max(0, pr.cur / pr.target))
    }

    func goalText(_ g: GoalDef) -> String {
        var text = t(g.text)
        let p = g.params
        let n = p.level ?? p.count ?? Int(p.amount ?? 0)
        text = text.replacingOccurrences(of: "{n}", with: Num.int(n))
        if let a = p.amountBase {
            text = text.replacingOccurrences(of: "{amount}", with: Num.big(a * scale))
        } else if let a = p.amount {
            text = text.replacingOccurrences(of: "{amount}", with: Num.big(a * scale))
        }
        if let sid = p.stationId, let i = city.stationIndex(id: sid) {
            text = text.replacingOccurrences(of: "{station}", with: t(city.stations[i].name))
        }
        return text
    }

    func goalProgressText(_ g: GoalDef) -> String {
        let pr = goalProgress(g)
        switch g.type {
        case "unlockStation", "hireManager":
            return goalDone(g) ? "✓" : ""
        case "earnCash", "incomeRate":
            return Num.fracBig(min(pr.cur, pr.target) * scale, pr.target * scale)
        case "twistMetric":
            let metric = g.params.metric ?? ""
            if metric.hasSuffix("Base") {
                return Num.fracBig(min(pr.cur, pr.target) * scale, pr.target * scale)
            }
            return Num.fracBig(min(pr.cur, pr.target), pr.target)
        default:
            return Num.fracBig(min(pr.cur, pr.target), pr.target)
        }
    }

    func goalArt(_ g: GoalDef) -> String {
        let p = g.params
        switch g.type {
        case "unlockStation", "stationLevel":
            if let sid = p.stationId, let i = city.stationIndex(id: sid) { return city.stations[i].art }
            return "food_falafel"
        case "hireManager":
            if let sid = p.stationId, let i = city.stationIndex(id: sid) { return city.stations[i].managerArt }
            return "ppl_man_cook"
        case "managersCount": return "ppl_cook"
        case "allStationsLevel": return "ui_bar_chart"
        case "earnCash": return city.currency.art
        case "incomeRate": return "ui_chart_up"
        case "buyUpgrades": return "ui_sparkles"
        case "customersServed": return "ppl_person"
        case "tapCook": return "ppl_waving_hand"
        case "specialCustomers": return "ui_glowing_star"
        case "collectVault": return "ui_money_bag"
        case "branchCollect": return "bld_classical_building"
        case "equipChefs", "chefTagMatch": return "ppl_cook"
        case "startResearch", "researchLevels": return "ui_notebook"
        case "sendSupplyRun", "supplyReturns": return "veh_tractor"
        case "heritageItems": return "ui_old_key"
        case "twistMetric":
            for d in city.twists { return twistArt(d.type) }
            return "ui_sparkles"
        default: return "ui_star"
        }
    }

    /// Records slot baselines for goals that just became visible.
    func refreshGoalSlots() {
        guard goalStripVisible else { return }
        for g in visibleGoals where goalScope(g) == "slot" && s.city.goalBaselines[g.id] == nil {
            s.city.goalBaselines[g.id] = slotMetric(g.type)
        }
    }

    func checkGoalChimes() {
        guard goalStripVisible else { return }
        for g in visibleGoals where !readyGoals.contains(g.id) && goalDone(g) {
            readyGoals.insert(g.id)
            SFX.correct.play(volume: 0.7)
            Haptic.tap()
        }
    }

    var claimableGoals: Int { visibleGoals.filter { goalDone($0) }.count }

    func xpForGoal(_ g: GoalDef) -> Int {
        let x = econ.xp.perStar * Double(g.stars) * (1 + econ.xp.cityBonusPerIndex * Double(city.index - 1))
        return Int(x.rounded())
    }

    func claimGoal(_ g: GoalDef) {
        guard goalStripVisible, !isClaimed(g), goalDone(g) else { return }
        let tierBefore = stallTier
        let anchor = "goal.\(visibleIndex(of: g) ?? 0).claim"
        s.city.goalsClaimed.append(g.id)
        s.city.stars += g.stars
        s.stats.starsTotal += g.stars
        bump("goalsClaimed")
        bump("stars", Double(g.stars))
        rep("goalStar", Double(g.stars))
        seasonPoint("goalStar", Double(g.stars))
        readyGoals.remove(g.id)
        if g.stars >= 3 {
            Feedback.play(.t2, fromAnchor: anchor, art: "ui_star", to: "pill.stars", amount: 30)
        } else {
            Feedback.play(.t1, fromAnchor: anchor, art: "ui_star", to: "pill.stars", amount: Double(g.stars * 10),
                          label: "+" + Num.int(g.stars) + " ★")
        }
        for r in g.rewards { _ = applyReward(r) }
        addXP(xpForGoal(g))
        if let ch = cat.chapter(cityId: city.id) {
            for sc in ch.scenes where sc.trigger == "manual" && sc.triggerTag == "goal:" + g.id {
                playScene(sc.id)
            }
        }
        if stallTier > tierBefore {
            showToast("البسطة كبرت! شكل جديد", art: "bld_convenience_store")
        }
        if crownEarned && !s.city.goalsClaimed.isEmpty {
            showToast("تاج " + t(city.name) + "! خلّصت كل الأهداف", art: "ui_crown")
        }
        evaluateFtue()
        save()
    }

    func visibleIndex(of g: GoalDef) -> Int? { visibleGoals.firstIndex { $0.id == g.id } }

    /// Stall look 0–8 from the share of stars (GDD 6.20).
    var stallTier: Int {
        let total = max(1, supportedStars)
        return min(8, Int(floor(8 * Double(s.city.stars) / Double(total))))
    }

    // MARK: Story

    func playScene(_ id: String, city cityId: String? = nil) {
        guard !s.city.scenesSeen.contains(id), cat.scene(id) != nil else { return }
        s.city.scenesSeen.append(id)
        enqueue(.story(scene: id, city: cityId ?? city.id))
    }

    func checkStoryTriggers() {
        guard s.ftue.done || s.ftue.step >= 8, let ch = cat.chapter(cityId: city.id) else { return }
        let frac = Double(s.city.stars) / Double(max(1, city.totalStars))
        for sc in ch.scenes where (sc.trigger == "rival" || sc.trigger == "midpoint") && !s.city.scenesSeen.contains(sc.id) {
            let need = sc.triggerFrac ?? (sc.trigger == "rival" ? 0.25 : 0.5)
            if frac >= need { playScene(sc.id) }
        }
    }

    func speaker(_ line: SceneLine, cityId: String) -> (name: String, art: String) {
        switch line.speaker {
        case "player":
            return (s.settings.stallName, "ppl_cook")
        case "rival":
            let c = cat.city(cityId) ?? city
            return (t(c.rival.name), c.rival.art)
        default:
            if let c = cat.cast(line.speaker) { return (t(c.name), c.art) }
            return ("ستّي أم خليل", "ppl_old_woman")
        }
    }

    // MARK: Graduation (GDD 3.5)

    var nextCity: CityDef? { cat.city(index: city.index + 1) }

    func licenceReadyAt(_ next: CityDef) -> Double { s.city.openedAt + next.licenceHours * 3600 }

    var licenceLeft: Double {
        guard let n = nextCity else { return 0 }
        return max(0, licenceReadyAt(n) - now())
    }

    /// Stars needed to graduate: the content value, or 75% of the stars this build can award
    /// (goals of systems that are not built yet are hidden), whichever is lower.
    var starsNeeded: Int {
        min(city.starsToGraduate, Int((0.75 * Double(supportedStars)).rounded(.up)))
    }

    var starsEnough: Bool { s.city.stars >= starsNeeded }

    var canGraduate: Bool {
        starsEnough && licenceLeft <= 0 && nextCity != nil && unlocked("map") && !s.meta.clockFrozen
    }

    var crownEarned: Bool { supportedGoals.allSatisfy { isClaimed($0) } }

    func requestGraduation() {
        guard canGraduate else {
            Feedback.error()
            return
        }
        Feedback.play(.t0)
        enqueue(.graduateConfirm)
    }

    func graduate() {
        guard canGraduate, let next = nextCity else { return }
        let from = city
        let crowned = crownEarned
        var b = BranchSave()
        b.level = crowned ? 1 : 0
        b.crowned = crowned
        b.stars = s.city.stars
        b.finalIncome = totalIncome(active: false)
        b.lifetimeEarned = s.city.lifetimeEarned
        b.graduatedAt = now()
        s.branches[from.id] = b
        if crowned { s.wallet.zaatar += 1 }
        s.stats.graduations += 1
        rep("graduation")
        if !modals.isEmpty && modals[0].id == "gradConfirm" { modals.removeFirst() }
        if let fin = cat.chapter(cityId: from.id)?.scenes.first(where: { $0.trigger == "finale" }) {
            playScene(fin.id, city: from.id)
        }
        enqueue(.graduation(from: from.id, to: next.id))
        addXP(econ.xp.graduationPerIndex * from.index)
        openCity(next.id, at: now(), firstEver: false)
        Feedback.play(.t3)
        evaluateFtue()
        save()
    }

    func openCity(_ id: String, at t: Double, firstEver: Bool) {
        guard let c = cat.city(id) else { return }
        var cs = CitySave()
        cs.cityId = id
        cs.stations = Array(repeating: StationState(), count: c.stations.count)
        if !cs.stations.isEmpty { cs.stations[0].level = 1 }
        cs.cash = econ.cityStartCashBase * c.priceScale
        cs.openedAt = t
        let head = min(cs.stations.count, Int(researchValue("startStations")))
        for k in 0..<head { cs.stations[k].level = max(cs.stations[k].level, 10) }
        cs.twist.chainStock = Array(repeating: 0, count: c.twists.filter { $0.type == .productionChain }.count)
        s.city = cs
        cityCache = c
        chainSigma = []
        oven = nil
        special = nil
        readyGoals = []
        if let arrival = cat.chapter(cityId: id)?.scenes.first(where: { $0.trigger == "arrival" }) {
            if firstEver {
                s.city.scenesSeen.append(arrival.id)
            } else {
                playScene(arrival.id)
            }
        }
        for d in c.twists where !s.ftue.seenTwists.contains(d.typeRaw) {
            s.ftue.seenTwists.append(d.typeRaw)
            enqueue(.unlock("twist." + d.typeRaw))
        }
    }

    // MARK: Branches and the branch safe

    var branchGoldPerDay: Double {
        let base = s.branches.values.reduce(0.0) { $0 + econ.branches.goldPerDayBase * (1 + econ.branches.goldPerLevel * Double($1.level)) }
        let total = base * (1 + researchValue("branchGoldPct")) * (1 + heritageBonus("branchGoldPct"))
        let b = econ.branches
        return total <= b.softcapKnee ? total : b.softcapKnee + b.softcapCoef * sqrt(total - b.softcapKnee)
    }

    var safeCap: Double { branchGoldPerDay / 24 * (econ.branches.safeCapHours + researchValue("branchCapHours")) }

    var safeFill: Double {
        guard safeCap > 0 else { return 0 }
        return min(1, s.branchSafe.stored / safeCap)
    }

    func accrueBranchSafe(until t: Double) {
        if s.branchSafe.lastAccrual == 0 || s.branches.isEmpty {
            s.branchSafe.lastAccrual = t
            return
        }
        let dt = t - s.branchSafe.lastAccrual
        guard dt > 0 else { return }
        s.branchSafe.lastAccrual = t
        s.branchSafe.stored = min(safeCap, s.branchSafe.stored + branchGoldPerDay / 86400 * dt)
    }

    func collectSafe() {
        let g = Int(floor(s.branchSafe.stored))
        guard g >= 1 else {
            showToast("الخزنة لسّا فاضية، استنّى شوي", art: "bld_classical_building")
            return
        }
        s.branchSafe.stored -= Double(g)
        s.wallet.gold += g
        s.stats.branchCollects += 1
        bump("branchCollects")
        Feedback.play(.t1, fromAnchor: "safe.collect", art: "ui_coin", to: "pill.gold", amount: Double(g),
                      label: "+" + Num.int(g) + " ذهب")
        save()
    }

    func branchUpgradeCost(_ level: Int) -> Int? {
        let costs = econ.branches.upgradeCosts
        guard level < econ.branches.maxLevel, level < costs.count else { return nil }
        return costs[level]
    }

    func upgradeBranch(_ id: String) {
        guard unlocked("branchUpgrades"), var b = s.branches[id], let cost = branchUpgradeCost(b.level) else { return }
        guard s.wallet.gold >= cost else {
            Feedback.error()
            return
        }
        s.wallet.gold -= cost
        b.level += 1
        s.branches[id] = b
        let tierLevels: Set<Int> = [1, 2, 3, 5, 7, 10]
        if tierLevels.contains(b.level) {
            Feedback.play(.t2)
        } else {
            Feedback.play(.t1, fromAnchor: "branch.upgrade", art: "ui_sparkles", to: "branch.upgrade", amount: 1)
        }
        save()
    }
}
