import Foundation

/// دفتر ستّي: timed research with global effects (GDD 6.2).
extension GameStore {
    var researchSlots: Int {
        guard unlocked("research") else { return 0 }
        return cat.research.slotsByLevel.filter { $0.level <= level }.map { $0.slots }.max() ?? 1
    }

    func researchLevel(_ id: String) -> Int { s.research.levels[id] ?? 0 }

    /// Σ perLevel × level over every node with this effect type.
    func researchValue(_ type: String) -> Double {
        var v = 0.0
        for n in cat.research.nodes where n.effectType == type {
            v += n.perLevel * Double(researchLevel(n.id))
        }
        return v
    }

    func nodeOpen(_ n: ResearchNodeDef) -> Bool {
        guard level >= n.unlockLevel else { return false }
        return n.requires.allSatisfy { researchLevel($0.nodeId) >= $0.level }
    }

    func nodeBusy(_ id: String) -> Bool { s.research.slots.contains { $0.nodeId == id } }

    /// Level the node would reach with the next start (counting one already running).
    func nextResearchLevel(_ n: ResearchNodeDef) -> Int { researchLevel(n.id) + 1 }

    func researchCost(_ n: ResearchNodeDef, level l: Int) -> Double {
        let m = n.costMin * Double(l)
        let inc = totalIncome(active: false)
        let floor = city.finalGoalBase * scale * cat.research.costFloorFracOfFinal * m
        return max(inc * 60 * m, floor) * marketCost("research")
    }

    func researchDuration(_ n: ResearchNodeDef, level l: Int) -> Double {
        let r = cat.research
        let base = min(r.capHours * 3600, r.baseMinutes * 60 * n.timeMult * pow(r.growth, Double(l - 1)))
        let cut = (1 - min(0.6, researchValue("researchTimePct"))) * (1 - heritageBonus("researchTimePct"))
        return max(30, base * cut * marketDuration("research"))
    }

    var freeResearchSlots: Int { max(0, researchSlots - s.research.slots.count) }

    func startResearch(_ id: String) {
        guard let n = cat.node(id), nodeOpen(n), !nodeBusy(id), researchLevel(id) < n.maxLevel else { return }
        guard freeResearchSlots > 0 else {
            showToast("الدفتر مشغول، استنّى البحث يخلص", art: "ui_notebook")
            Feedback.error()
            return
        }
        let l = nextResearchLevel(n)
        let cost = researchCost(n, level: l)
        guard s.city.cash >= cost else {
            Feedback.error()
            return
        }
        s.city.cash -= cost
        let t = now()
        var slot = ResearchSlot()
        slot.nodeId = id
        slot.level = l
        slot.startAt = t
        slot.endAt = t + researchDuration(n, level: l)
        s.research.slots.append(slot)
        s.research.started += 1
        bump("researchStarted")
        Feedback.play(.t0)
        SFX.upgrade.play()
        evaluateFtue()
        save()
    }

    /// Applies finished research immediately (it counts offline too); the claim only gives XP.
    func tickResearch(at time: Double) {
        guard !s.meta.clockFrozen else { return }
        for k in s.research.slots.indices where !s.research.slots[k].applied && time >= s.research.slots[k].endAt {
            let sl = s.research.slots[k]
            s.research.levels[sl.nodeId] = max(researchLevel(sl.nodeId), sl.level)
            s.research.slots[k].applied = true
            s.research.completed += 1
            bump("researchCompleted")
            rep("researchLevel")
            seasonPoint("researchLevel")
            if isForeground, let n = cat.node(sl.nodeId) {
                showToast("دفتر ستّي: خلص بحث \"" + t(n.name) + "\"", art: n.art)
            }
        }
    }

    var researchReady: Bool { s.research.slots.contains { $0.applied } }

    func claimResearch(_ nodeId: String) {
        guard let k = s.research.slots.firstIndex(where: { $0.nodeId == nodeId && $0.applied }) else { return }
        let sl = s.research.slots.remove(at: k)
        addXP(10 + 2 * sl.level)
        Feedback.play(.t1, fromAnchor: "research.slot." + nodeId, art: "ui_sparkles", to: "hud.level", amount: 10,
                      label: Num.plus(Num.int(10 + 2 * sl.level)) + " خبرة")
        save()
    }

    func researchRushCost(_ sl: ResearchSlot) -> Int { max(1, Int(((sl.endAt - now()) / 60 / 6).rounded(.up))) }

    func rushResearch(_ nodeId: String) {
        guard let k = s.research.slots.firstIndex(where: { $0.nodeId == nodeId && !$0.applied }) else { return }
        let cost = researchRushCost(s.research.slots[k])
        guard s.wallet.gold >= cost else {
            Feedback.error()
            return
        }
        s.wallet.gold -= cost
        s.research.slots[k].endAt = now()
        tickResearch(at: now())
        claimResearch(nodeId)
    }

    var nextResearchEnd: Double? { s.research.slots.filter { !$0.applied }.map { $0.endAt }.min() }

    /// Effect value without a sign; the content text carries "+" or "−".
    func researchEffectText(_ n: ResearchNodeDef, level l: Int) -> String {
        let v = n.perLevel * Double(l)
        switch n.effectType {
        case "vaultCapHours", "branchCapHours": return Num.int(Int(v)) + "س"
        case "frenzySec": return Num.int(Int(v)) + "ث"
        case "rushHourAdd": return Num.iso(String(format: "%.1f", v))
        case "startStations": return Num.int(Int(v)) + " محطّات"
        default: return Num.percent(v)
        }
    }

    func researchDesc(_ n: ResearchNodeDef) -> String {
        let cur = researchLevel(n.id)
        var text = t(n.desc)
        let now = researchEffectText(n, level: cur)
        let next = researchEffectText(n, level: min(n.maxLevel, cur + 1))
        text = text.replacingOccurrences(of: "+{v}", with: Num.plus(now)).replacingOccurrences(of: "+{next}", with: Num.plus(next))
        text = text.replacingOccurrences(of: "{v}", with: now).replacingOccurrences(of: "{next}", with: next)
        return text
    }

    static func branchName(_ b: String) -> String {
        switch b {
        case "kitchen": return "المطبخ"
        case "customers": return "الزباين"
        case "vault": return "الخزنة والوقت"
        default: return "الإمبراطورية"
        }
    }
}
