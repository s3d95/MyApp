import Foundation

/// Data-driven first-time experience (GDD 6.18, ftue.json).
extension GameStore {
    /// Steps whose systems exist in this build; the others are skipped.
    static let ftueSupported: Set<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 16, 19]

    var ftueStep: FtueStepDef? {
        guard !s.ftue.done else { return nil }
        return cat.ftue.steps.first { $0.id == s.ftue.step }
    }

    /// The step currently showing its bubble/spotlight.
    var ftueActive: FtueStepDef? { s.ftue.active ? ftueStep : nil }

    func evaluateFtue() {
        for _ in 0..<4 {
            guard !s.ftue.done else { return }
            guard let step = ftueStep else {
                s.ftue.done = true
                return
            }
            if !GameStore.ftueSupported.contains(step.id) {
                advanceFtue()
                continue
            }
            if !s.ftue.active {
                guard ftueStartMet(step) else { return }
                s.ftue.active = true
                s.ftue.startedAt = now()
                s.ftue.bubbleClosed = false
                specialTappedFlag = false
                vaultCollectedFlag = false
                if let f = step.forceSpecialOutcome, let o = SpecialOutcome(rawValue: f), special == nil {
                    spawnSpecial(forced: o)
                }
            }
            guard ftueCompleteMet(step) else { return }
            advanceFtue()
        }
    }

    func advanceFtue() {
        s.ftue.active = false
        s.ftue.bubbleClosed = false
        let next = cat.ftue.steps.map { $0.id }.filter { $0 > s.ftue.step }.min()
        if let n = next {
            s.ftue.step = n
        } else {
            s.ftue.done = true
        }
    }

    func ftueStation(_ id: String?) -> Int? {
        guard let id = id else { return nil }
        return city.stationIndex(id: id)
    }

    func ftueStartMet(_ step: FtueStepDef) -> Bool {
        let c = step.start
        let v = c.value ?? 0
        switch c.type {
        case "firstFrame", "stepDone":
            return true
        case "cashAtLeast":
            return s.city.cash >= v
        case "cashForNextLevel":
            guard let i = ftueStation(c.id) else { return true }
            return s.city.cash >= Rules.cost(row(i), scale: scale, level: s.city.stations[i].level, count: 1)
        case "levelReached":
            return level >= Int(v)
        case "managerAffordable":
            guard let i = ftueStation(c.id) else { return true }
            return unlocked("managers") && (s.city.stations[i].managed || s.city.cash >= managerCost(i))
        case "upgradeAffordable":
            guard unlocked("upgrades") else { return false }
            if !s.city.upgradesBought.isEmpty { return true }
            guard let u = nextUpgrades.first else { return false }
            return s.city.cash >= upgradePrice(u)
        case "relaunchAway":
            return newsInfo != nil && newsAwayGap >= v
        case "graduationReady":
            return canGraduate || s.stats.graduations > 0
        case "afterSec":
            return now() - s.ftue.startedAt >= v
        default:
            return true
        }
    }

    func ftueCompleteMet(_ step: FtueStepDef) -> Bool {
        let c = step.complete
        let v = c.value ?? 1
        switch c.type {
        case "tapCook":
            return Double(s.ftue.tapCooks[c.id ?? "", default: 0]) >= v
        case "cashAtLeast":
            return s.city.cash >= v
        case "stationLevel":
            guard let i = ftueStation(c.id) else { return true }
            return Double(s.city.stations[i].level) >= v
        case "stationUnlocked":
            guard let i = ftueStation(c.id) else { return true }
            return s.city.stations[i].level >= 1
        case "goalClaimed":
            return s.city.goalsClaimed.contains(c.id ?? "") || s.stats.starsTotal > 0
        case "managerHired":
            guard let i = ftueStation(c.id) else { return true }
            return s.city.stations[i].managed
        case "buyMode":
            return buyMode != .x1
        case "specialTapped":
            return specialTappedFlag || (special == nil && s.stats.specials > 0)
        case "upgradeBought":
            return !s.city.upgradesBought.isEmpty
        case "bubbleClosed":
            return s.ftue.bubbleClosed
        case "vaultCollected":
            return vaultCollectedFlag || newsInfo == nil
        case "screenViewed":
            return tab == .map && s.ftue.bubbleClosed
        case "graduated":
            return s.stats.graduations > 0
        default:
            return true
        }
    }

    /// True when the step only shows a bubble (no blocking overlay).
    func ftueIsSoft(_ step: FtueStepDef) -> Bool {
        step.soft || step.anchors.isEmpty || ["bubbleClosed", "screenViewed", "graduated"].contains(step.complete.type)
    }

    func ftueText(_ step: FtueStepDef) -> String { t(step.text) }

    func closeFtueBubble() {
        s.ftue.bubbleClosed = true
        Feedback.play(.t0)
        evaluateFtue()
        save()
    }

    func skipFtueStep() {
        advanceFtue()
        evaluateFtue()
        save()
    }

    func replayTutorialHints() {
        showToast("رح نعيد التلميحات من أوّل وجديد", art: "ppl_old_woman")
    }
}
