import Foundation
import SwiftUI

struct BuyPlan {
    var count: Int
    var cost: Double
    var affordable: Bool
    var atCap: Bool
}

/// The kitchen engine (GDD 2): levels, income, tap-to-cook, managers, cash upgrades.
extension GameStore {
    var econ: EconomyDef { cat.economy }
    var cap: Int { city.levelCap }
    var scale: Double { city.priceScale }

    func row(_ i: Int) -> TierRow { econ.tier(city.stations[i].tier) }

    func station(_ i: Int) -> StationState { s.city.stations[i] }

    var minStationLevel: Int { s.city.stations.map { $0.level }.min() ?? 0 }

    var allMilestones: Int { Rules.milestonesReached(econ.allStationMilestones, level: minStationLevel, cap: cap) }

    var nextAllMilestone: Int? { Rules.nextMilestone(econ.allStationMilestones, level: minStationLevel, cap: cap) }

    func stationMilestones(_ i: Int) -> Int {
        Rules.milestonesReached(econ.stationMilestones, level: s.city.stations[i].level, cap: cap)
    }

    func nextStationMilestone(_ i: Int) -> Int? {
        Rules.nextMilestone(econ.stationMilestones, level: s.city.stations[i].level, cap: cap)
    }

    func upgradeMult(_ i: Int) -> Double {
        let key = city.stations[i].key
        var m = 1.0
        for u in city.upgrades where (u.target == key || u.target == "all") && s.city.upgradesBought.contains(u.id) {
            m *= u.mult
        }
        return m
    }

    var branchMult: Double {
        let b = econ.branches
        let levels = s.branches.values.reduce(0) { $0 + $1.level }
        return 1 + b.incomePerBranch * Double(s.branches.count) + b.incomePerLevel * Double(levels)
    }

    var zaatarMult: Double { pow(1.05, Double(s.wallet.zaatar)) }

    /// Categories 5–8: branches, research, Golden Za'atar, heritage.
    var permMult: Double {
        branchMult * (1 + researchValue("cityIncomePct")) * zaatarMult * (1 + heritageBonus("cityIncomePct"))
    }

    func speedMult(_ i: Int) -> Double {
        pow(econ.milestoneMult, Double(stationMilestones(i))) * (1 + researchValue("speedPct"))
    }

    /// Price scale for station levels (research "مورّد أمين", floor 0.5).
    var stationCostScale: Double { scale * max(0.5, 1 - researchValue("stationCostPct")) }

    func effCycle(_ i: Int) -> Double {
        max(econ.cycleFloorSec, row(i).baseCycleSec / speedMult(i))
    }

    /// Rush hour, frenzy, fresh dough and other foreground boosts (category 11), capped.
    var activeMult: Double {
        var m = 1.0
        for b in s.boosts where b.left > 0 && b.scope.isEmpty { m *= b.mult }
        if isRushHour { m *= econ.boosts.rushHourMult + researchValue("rushHourAdd") }
        return min(econ.boosts.activeCap, m)
    }

    func activeMult(for i: Int) -> Double {
        var m = activeMult * twistActive(i)
        let d = city.stations[i]
        for b in s.boosts where b.left > 0 && !b.scope.isEmpty {
            if b.scope == "cat:" + d.category || b.scope == "cui:" + d.cuisine { m *= b.mult }
        }
        return min(econ.boosts.activeCap, m)
    }

    var isRushHour: Bool {
        guard unlocked("rushHours") else { return false }
        let h = Clock.hourMinute(now()).h
        return econ.boosts.rushWindows.contains { $0.count == 2 && h >= $0[0] && h < $0[1] }
    }

    func profitMult(_ i: Int, at t: Double, active: Bool) -> Double {
        var m = upgradeMult(i) * pow(econ.milestoneMult, Double(allMilestones)) * permMult * twistProfit(i, at: t) * chefMult(i)
        if active { m *= activeMult(for: i) }
        return m
    }

    /// Cash per second for station i (0 for a production-chain input, which feeds another station).
    func income(_ i: Int, at t: Double, active: Bool) -> Double {
        let st = s.city.stations[i]
        guard st.level > 0, !isChainInput(i) else { return 0 }
        let r = row(i)
        return Double(st.level) * r.baseRevenue * profitMult(i, at: t, active: active) * speedMult(i) / r.baseCycleSec
    }

    /// Total city income per second. `active` adds category 11 (foreground only).
    func totalIncome(active: Bool, managedOnly: Bool = false) -> Double {
        let t = now()
        var sum = 0.0
        for i in s.city.stations.indices {
            if managedOnly && !s.city.stations[i].managed { continue }
            sum += income(i, at: t, active: active)
        }
        return sum
    }

    // MARK: Advancing

    func advanceKitchen(dt: Double, at t: Double, foreground: Bool) {
        for i in s.city.stations.indices {
            var st = s.city.stations[i]
            guard st.level > 0, st.managed || st.cooking else { continue }
            if oven?.station == i && !st.managed { continue }
            let T = effCycle(i)
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
            s.city.stations[i] = st
            if done > 0 { completeCycles(i, count: done, at: t, foreground: foreground) }
        }
    }

    func completeCycles(_ i: Int, count: Int, at t: Double, foreground: Bool) {
        let T = effCycle(i)
        let payout = income(i, at: t, active: foreground) * T
        let n = Double(count)
        s.city.counters["customers", default: 0] += n
        s.stats.customers += n
        portCycles(i, count: count)
        if foreground, oven == nil, let p = ovenParams, city.stationIndex(key: p.station ?? "") == i, T >= p.minCycleSec {
            if count > 1 { credit(payout * Double(count - 1), station: i, at: t) }
            oven = OvenTray(station: i, payout: payout, deadline: t + p.windowSec, window: p.windowSec)
            Feedback.play(.t0)
            return
        }
        credit(payout * n, station: i, at: t)
        if foreground && !s.city.stations[i].managed {
            let last = lastCycleFeedback[i] ?? 0
            if t - last > 0.25 {
                lastCycleFeedback[i] = t
                Feedback.play(.t1, fromAnchor: "station.\(i).cook", art: city.currency.art, to: "pill.cash",
                              amount: 1, label: "+" + Num.big(payout * n))
            }
        }
    }

    func credit(_ amount: Double, station i: Int?, at t: Double) {
        guard amount > 0, amount.isFinite else { return }
        s.city.cash += amount
        s.city.lifetimeEarned += amount
        s.metrics["earned", default: 0] += amount
        if let i = i {
            s.city.stations[i].lifetimeEarned += amount
            twistMetricsOnCredit(i, amount: amount, at: t)
        }
    }

    // MARK: Actions

    func tapCook(_ i: Int) {
        guard s.city.stations.indices.contains(i) else { return }
        if let o = oven, o.station == i {
            collectOven(perfect: true)
            return
        }
        var st = s.city.stations[i]
        guard st.level > 0, !st.managed else { return }
        guard !st.cooking else {
            Feedback.play(.t0)
            return
        }
        st.cooking = true
        st.progress = 0
        s.city.stations[i] = st
        let id = city.stations[i].id
        s.ftue.tapCooks[id, default: 0] += 1
        s.city.counters["tapCook", default: 0] += 1
        s.stats.taps += 1
        bump("tapCooks")
        Feedback.play(.t0)
        evaluateFtue()
    }

    func buyPlan(_ i: Int) -> BuyPlan {
        let st = s.city.stations[i]
        let r = row(i)
        let scale = stationCostScale
        if st.level == 0 {
            let c = Rules.cost(r, scale: scale, level: 0, count: 1)
            return BuyPlan(count: 1, cost: c, affordable: s.city.cash >= c, atCap: false)
        }
        let room = cap - st.level
        if room <= 0 { return BuyPlan(count: 0, cost: 0, affordable: false, atCap: true) }
        var k = 1
        switch buyMode {
        case .x1: k = 1
        case .x10: k = min(10, room)
        case .next:
            let target = nextStationMilestone(i) ?? cap
            k = max(1, min(room, target - st.level))
        case .max:
            k = max(1, Rules.maxAffordable(r, scale: scale, level: st.level, cash: s.city.cash, cap: cap))
        }
        let c = Rules.cost(r, scale: scale, level: st.level, count: k)
        return BuyPlan(count: k, cost: c, affordable: s.city.cash >= c, atCap: false)
    }

    func buy(_ i: Int) {
        let plan = buyPlan(i)
        guard plan.count > 0, plan.affordable else {
            Feedback.error()
            return
        }
        let allBefore = allMilestones
        let before = s.city.stations[i].level
        s.city.cash -= plan.cost
        s.city.stations[i].level += plan.count
        bump("levelsBought", Double(plan.count))
        let after = s.city.stations[i].level
        if before == 0 {
            addXP(econ.xp.stationUnlock)
            Feedback.play(.t1, fromAnchor: "station.\(i).cook", art: city.stations[i].art, to: "station.\(i).cook", amount: 1)
            SFX.upgrade.play()
        }
        let ms = stationMilestones(i)
        let seen = s.city.stations[i].milestonesSeen
        if ms > seen {
            s.city.stations[i].milestonesSeen = ms
            bump("stationMilestones", Double(ms - seen))
            addXP(econ.xp.stationMilestone * (ms - seen))
            let label = milestoneIsSpeed(i, count: ms) ? "سرعة ×2" : "ربح ×2"
            Feedback.play(.t1, fromAnchor: "station.\(i).cook", art: "ui_sparkles", to: "station.\(i).cook", amount: 1, label: label)
        } else if before > 0 {
            Feedback.play(.t0)
        }
        if allMilestones > allBefore {
            Feedback.play(.t2)
            showToast("كل المحطّات " + Num.int(Rules.previousMilestone(econ.allStationMilestones, level: minStationLevel, cap: cap)) + ": ربح ×2 للكل!", art: "ui_sparkles")
        }
        _ = after
        evaluateFtue()
    }

    func milestoneIsSpeed(_ i: Int, count: Int) -> Bool {
        row(i).baseCycleSec / pow(econ.milestoneMult, Double(count)) >= econ.cycleFloorSec
    }

    func managerCost(_ i: Int) -> Double {
        let r = row(i)
        return scale * r.baseCost * r.managerMult * (1 - min(0.9, researchValue("managerCostPct")))
    }

    func managerName(_ i: Int) -> String {
        let d = city.stations[i]
        if let n = d.managerName { return t(n) }
        return "معلّم " + t(d.name)
    }

    func hire(_ i: Int) {
        guard unlocked("managers") else { return }
        var st = s.city.stations[i]
        guard st.level > 0, !st.managed else { return }
        let c = managerCost(i)
        guard s.city.cash >= c else {
            Feedback.error()
            return
        }
        s.city.cash -= c
        st.managed = true
        st.cooking = true
        s.city.stations[i] = st
        addXP(econ.xp.managerHire)
        Feedback.play(.t1, fromAnchor: "station.\(i).manager", art: city.stations[i].managerArt, to: "station.\(i).cook", amount: 1,
                      label: "وظّفت " + managerName(i))
        evaluateFtue()
        save()
    }

    var managersCount: Int { s.city.stations.filter { $0.managed }.count }

    // MARK: Cash upgrades (GDD 2.8)

    func upgradePrice(_ u: UpgradeDef) -> Double { u.priceBase * scale }

    var nextUpgrades: [UpgradeDef] {
        Array(city.upgrades.filter { !s.city.upgradesBought.contains($0.id) }.prefix(3))
    }

    var remainingUpgrades: Int { city.upgrades.filter { !s.city.upgradesBought.contains($0.id) }.count }

    func buyUpgrade(_ u: UpgradeDef) {
        guard unlocked("upgrades"), !s.city.upgradesBought.contains(u.id) else { return }
        let p = upgradePrice(u)
        guard s.city.cash >= p else {
            Feedback.error()
            return
        }
        s.city.cash -= p
        s.city.upgradesBought.append(u.id)
        bump("upgradesBought")
        Feedback.play(.t1, fromAnchor: "upgrade.0.buy", art: "ui_sparkles", to: "pill.cash", amount: 1, label: Num.mult(u.mult))
        SFX.upgrade.play()
        evaluateFtue()
        save()
    }

    func upgradeTargetName(_ u: UpgradeDef) -> String {
        if u.target == "all" { return "كل المحطّات" }
        if let i = city.stationIndex(key: u.target) { return t(city.stations[i].name) }
        return u.target
    }

    func upgradeArt(_ u: UpgradeDef) -> String {
        if let i = city.stationIndex(key: u.target) { return city.stations[i].art }
        return "ui_sparkles"
    }

    // MARK: Time warps (GDD 2.11)

    func useTimeWarp(at index: Int) {
        guard s.wallet.timeWarps.indices.contains(index) else { return }
        let minutes = s.wallet.timeWarps.remove(at: index)
        let amount = Double(minutes) * 60 * totalIncome(active: false, managedOnly: true)
        credit(amount, station: nil, at: now())
        Feedback.play(.t1, fromAnchor: "pill.cash", art: city.currency.art, to: "pill.cash", amount: amount,
                      label: "+" + Num.big(amount))
        showToast("رزمة وقت: " + Num.dur(Double(minutes) * 60) + " دخل", art: "ui_hourglass")
        save()
    }

    /// Seconds until the player can afford `cost` at the current managed income (nil when there is none).
    func eta(_ cost: Double) -> Double? {
        let need = cost - s.city.cash
        if need <= 0 { return 0 }
        let inc = totalIncome(active: true, managedOnly: true)
        guard inc > 0 else { return nil }
        return need / inc
    }
}
