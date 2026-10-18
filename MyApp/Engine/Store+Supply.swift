import Foundation

struct SupplyLoot: Identifiable {
    let id = UUID()
    let art: String
    let title: String
    let amount: Int
    let rarity: Rarity
    let isNew: Bool
}

struct SupplyResult: Identifiable {
    let id = UUID()
    let vehicleId: String
    let loot: [SupplyLoot]
    let xp: Int

    var best: Rarity { loot.map { $0.rarity }.max { $0.rank < $1.rank } ?? .common }
}

/// رحلات التوريد and صندوق التراث (GDD 6.3).
extension GameStore {
    var vx: VehiclesFile { cat.vehicles }

    var supplySlots: Int {
        guard unlocked("supply") else { return 0 }
        return vx.slotsByLevel.filter { $0.level <= level }.map { $0.slots }.max() ?? 1
    }

    var freeSupplySlots: Int { max(0, supplySlots - s.supply.slots.count) }

    func launches(_ id: String) -> Int { s.supply.launches[id] ?? 0 }

    func vehicleUnlocked(_ v: VehicleDef) -> Bool {
        guard level >= v.unlockLevel else { return false }
        if let a = v.afterVehicle { return launches(a) >= v.afterLaunches }
        return true
    }

    func vehicleOut(_ id: String) -> Bool { s.supply.slots.contains { $0.vehicleId == id } }

    func vehicleStars(_ id: String) -> Int { vx.starLaunches.filter { launches(id) >= $0 }.count }

    func runDuration(_ v: VehicleDef, _ idx: Int) -> Double {
        let base = v.durationsMin[min(idx, v.durationsMin.count - 1)] * 60
        return base * (1 - min(0.5, researchValue("supplyTimePct"))) * (1 - heritageBonus("supplyTimePct"))
    }

    func runRolls(_ v: VehicleDef, _ idx: Int) -> Int {
        let base = v.rolls[min(idx, v.rolls.count - 1)]
        let extra = vehicleStars(v.id) * Int((Double(base) * vx.starRollsPct).rounded(.up))
        return base + extra
    }

    func sendRun(_ vehicleId: String, durationIdx: Int) {
        guard let v = cat.vehicle(vehicleId), vehicleUnlocked(v), !vehicleOut(vehicleId) else { return }
        guard freeSupplySlots > 0 else {
            showToast("كل الكراجات مشغولة", art: "veh_truck")
            Feedback.error()
            return
        }
        let t = now()
        var slot = SupplySlot()
        slot.runId = UUID().uuidString
        slot.vehicleId = vehicleId
        slot.durationIdx = durationIdx
        slot.sentAt = t
        slot.endAt = t + runDuration(v, durationIdx)
        slot.seed = s.supply.runCounter
        s.supply.runCounter += 1
        s.supply.slots.append(slot)
        s.supply.launches[vehicleId, default: 0] += 1
        s.supply.sent += 1
        bump("runsSent")
        Feedback.play(.t0)
        SFX.whoosh.play()
        evaluateFtue()
        save()
    }

    var runsReady: Int { s.supply.slots.filter { now() >= $0.endAt }.count }

    var nextRunEnd: Double? { s.supply.slots.map { $0.endAt }.min() }

    func rushRunCost(_ sl: SupplySlot) -> Int { max(1, Int(((sl.endAt - now()) / 60 / 6).rounded(.up))) }

    func rushRun(_ runId: String) {
        guard let k = s.supply.slots.firstIndex(where: { $0.runId == runId }) else { return }
        let cost = rushRunCost(s.supply.slots[k])
        guard s.wallet.gold >= cost else {
            Feedback.error()
            return
        }
        s.wallet.gold -= cost
        s.supply.slots[k].endAt = now()
        claimRun(runId)
    }

    func claimRun(_ runId: String) {
        guard let k = s.supply.slots.firstIndex(where: { $0.runId == runId }), now() >= s.supply.slots[k].endAt,
              let v = cat.vehicle(s.supply.slots[k].vehicleId) else { return }
        let sl = s.supply.slots.remove(at: k)
        var r = Seed.rng("supplyRoll", ["\(sl.seed)"], player: s.meta.seed)
        var loot: [SupplyLoot] = []
        let rolls = runRolls(v, sl.durationIdx)
        var weights = Rarity.allCases.map { v.rarityWeights[$0.rawValue] ?? 0 }
        if vehicleStars(v.id) >= 3 {
            let shift = vx.star3CommonToEpic * weights.reduce(0, +)
            weights[0] = max(0, weights[0] - shift)
            weights[2] += shift
        }
        let kinds = ["heritage", "chefCards", "gold", "woodChest"]
        let kindW = kinds.map { vx.rollKinds[$0] ?? 0 }
        for _ in 0..<rolls {
            var rar = Rarity.allCases[r.weighted(weights)]
            if rar != .legendary && r.unit() < researchValue("supplyRarityUpPct") {
                rar = Rarity.allCases[rar.rank + 1]
            }
            var kind = kinds[r.weighted(kindW)]
            if kind == "woodChest" && sl.durationIdx == 0 { kind = "heritage" }
            switch kind {
            case "chefCards":
                let n = vx.cardsPerRarity[rar.rawValue] ?? 1
                if let id = grantRandomCards(rarity: rar, count: n), let c = cat.chef(id) {
                    loot.append(SupplyLoot(art: c.art, title: t(c.name), amount: n, rarity: rar, isNew: false))
                }
            case "gold":
                let g = vx.goldPerRarity[rar.rawValue] ?? 2
                s.wallet.gold += g
                loot.append(SupplyLoot(art: "ui_coin", title: "ذهب", amount: g, rarity: rar, isNew: false))
            case "woodChest":
                addChest("wood")
                loot.append(SupplyLoot(art: "ui_gift", title: "صندوق خشب", amount: 1, rarity: .common, isNew: false))
            default:
                if let item = rollItem(rar, &r) {
                    let isNew = addItem(item.id)
                    loot.append(SupplyLoot(art: item.art, title: t(item.name), amount: 1, rarity: item.rarity, isNew: isNew))
                }
            }
        }
        let xpBase = [10, 20, 40][min(2, sl.durationIdx)]
        let xp = Int((Double(xpBase) * (1 + 0.25 * Double(v.tier))).rounded())
        addXP(xp)
        s.supply.returned += 1
        bump("runsClaimed")
        let result = SupplyResult(vehicleId: v.id, loot: loot, xp: xp)
        enqueue(.supply(result))
        save()
    }

    // MARK: Heritage

    var hx: HeritageFile { cat.heritage }

    func copies(_ id: String) -> Int { s.supply.heritage[id] ?? 0 }

    func itemLevel(_ id: String) -> Int {
        var c = copies(id)
        guard c > 0 else { return 0 }
        c -= 1
        var lv = 1
        for need in hx.copiesToLevel where c >= need && lv < hx.maxLevel {
            c -= need
            lv += 1
        }
        return lv
    }

    var copiesToMax: Int { 1 + hx.copiesToLevel.reduce(0, +) }

    func rollItem(_ rar: Rarity, _ r: inout SplitMix64) -> HeritageItemDef? {
        var pool = hx.items.filter { $0.rarity == rar }
        if pool.isEmpty { pool = hx.items }
        guard !pool.isEmpty else { return nil }
        let w = pool.map { copies($0.id) == 0 ? vx.unownedItemWeight : 1 }
        return pool[r.weighted(w)]
    }

    /// Adds one copy. Copies past L5 become craft points. Returns true for a new item.
    @discardableResult
    func addItem(_ id: String) -> Bool {
        guard let item = cat.item(id) else { return false }
        let isNew = copies(id) == 0
        if copies(id) >= copiesToMax {
            s.supply.craftPoints += hx.salvage[item.rarityRaw] ?? 1
        } else {
            s.supply.heritage[id, default: 0] += 1
        }
        if isNew { s.supply.newItems += 1 }
        return isNew
    }

    func setComplete(_ set: HeritageSetDef) -> Bool { set.itemIds.allSatisfy { copies($0) > 0 } }

    func setMinLevel(_ set: HeritageSetDef) -> Int { set.itemIds.map { itemLevel($0) }.min() ?? 0 }

    func setStrength(_ set: HeritageSetDef) -> Double {
        guard setComplete(set) else { return 0 }
        return set.bonusBase * (1 + hx.setLevelFactor * Double(setMinLevel(set) - 1))
    }

    func heritageBonus(_ type: String) -> Double {
        hx.sets.filter { $0.bonusType == type }.reduce(0.0) { $0 + setStrength($1) }
    }

    var uniqueItems: Int { s.supply.heritage.values.filter { $0 > 0 }.count }

    func craftCost(_ item: HeritageItemDef) -> Int { hx.craftCost[item.rarityRaw] ?? 10 }

    func craft(_ id: String) {
        guard level >= hx.craftUnlockLevel, let item = cat.item(id), copies(id) < copiesToMax else { return }
        let cost = craftCost(item)
        guard s.supply.craftPoints >= cost else {
            Feedback.error()
            return
        }
        s.supply.craftPoints -= cost
        let isNew = addItem(id)
        Feedback.play(isNew ? .t2 : .t1, fromAnchor: "heritage." + id, art: item.art, to: "heritage." + id, amount: 1,
                      label: t(item.name))
        save()
    }

    func bonusText(_ type: String, _ v: Double) -> String {
        switch type {
        case "cityIncomePct": return "دخل المدن +" + Num.percent(v)
        case "vaultCapHours": return "الخزنة +" + String(format: "%.1f", v) + "س"
        case "chefBonusPct": return "قوّة الطبّاخين +" + Num.percent(v)
        case "specialRewardPct": return "هدايا الزباين المميّزين +" + Num.percent(v)
        case "supplyTimePct": return "الرحلات أسرع " + Num.percent(v)
        case "researchTimePct": return "الأبحاث أسرع " + Num.percent(v)
        case "sideIncomePct": return "دخل الطلبيات والمهرجان +" + Num.percent(v)
        case "branchGoldPct": return "ذهب الفروع +" + Num.percent(v)
        default: return ""
        }
    }
}
