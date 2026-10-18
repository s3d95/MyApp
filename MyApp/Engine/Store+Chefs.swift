import Foundation

struct ChestStack: Identifiable {
    let id = UUID()
    let chefId: String
    let cards: Int
    let rarity: Rarity
    let isNew: Bool
}

struct ChestResult: Identifiable {
    let id = UUID()
    let kind: String
    let stacks: [ChestStack]
    let gold: Int

    var best: Rarity { stacks.map { $0.rarity }.max { $0.rank < $1.rank } ?? .common }
}

struct StallOffer: Identifiable {
    let slot: Int
    let chefId: String
    let rarity: Rarity
    let cards: Int
    let price: Int

    var id: Int { slot }
}

/// Chefs, chests and the daily chef stall (GDD 6.1).
extension GameStore {
    var chefRules: ChefRulesDef { cat.chefs.rules }

    var chefSlots: Int {
        guard unlocked("chefs") else { return 0 }
        return chefRules.slotsByLevel.filter { $0.level <= level }.map { $0.slots }.max() ?? 1
    }

    var nextChefSlotLevel: Int? { chefRules.slotsByLevel.first { $0.level > level }?.level }

    var chestPoolChefs: [ChefDef] { cat.chefs.chefs.filter { $0.source == "chest" } }

    /// Chefs shown in the collection: the chest pool plus any exclusive the player owns.
    var collectionChefs: [ChefDef] {
        cat.chefs.chefs.filter { $0.source == "chest" || s.chefs.owned[$0.id] != nil }
            .sorted { ($0.rarity.rank, $0.id) > ($1.rarity.rank, $1.id) }
    }

    func chefBonus(_ id: String) -> Double {
        guard let c = cat.chef(id), let own = s.chefs.owned[id] else { return 0 }
        let base = chefRules.rarityBase[c.rarityRaw] ?? 0.25
        let boost = (1 + researchValue("chefBonusPct")) * (1 + heritageBonus("chefBonusPct"))
        return base * (1 + chefRules.perLevel * Double(own.level - 1)) * boost
    }

    func matchFactor(_ c: ChefDef, _ d: StationDef) -> Double {
        let cu = c.cuisine == "any" || c.cuisine == d.cuisine
        let ca = c.category == "any" || c.category == d.category
        if cu && ca { return chefRules.bothMatchFactor }
        return (cu || ca) ? 1 : 0
    }

    /// Category 3: 1 + Σ matching chef bonuses.
    func chefMult(_ i: Int) -> Double {
        guard !s.chefs.equipped.isEmpty else { return 1 }
        let d = city.stations[i]
        var m = 1.0
        for id in s.chefs.equipped {
            guard let c = cat.chef(id) else { continue }
            m += chefBonus(id) * matchFactor(c, d)
        }
        return m
    }

    /// Stations of the current city a chef boosts.
    func chefStations(_ id: String) -> [Int] {
        guard let c = cat.chef(id) else { return [] }
        return city.stations.indices.filter { matchFactor(c, city.stations[$0]) > 0 }
    }

    func isEquipped(_ id: String) -> Bool { s.chefs.equipped.contains(id) }

    var anyChefCanLevel: Bool { s.chefs.owned.keys.contains { canLevelUp($0) } }

    func equip(_ id: String) {
        guard s.chefs.owned[id] != nil, !isEquipped(id) else { return }
        guard s.chefs.equipped.count < chefSlots else {
            showToast("الخانات مليانة، شيل طبّاخ أوّل", art: "ppl_cook")
            Feedback.error()
            return
        }
        s.chefs.equipped.append(id)
        Feedback.play(.t1, fromAnchor: "chef.card." + id, art: cat.chef(id)?.art, to: "chef.slot.\(s.chefs.equipped.count - 1)",
                      amount: 1, label: "+" + Num.percent(chefBonus(id)))
        evaluateFtue()
        save()
    }

    func unequip(_ id: String) {
        s.chefs.equipped.removeAll { $0 == id }
        Feedback.play(.t0)
        save()
    }

    // MARK: Cards and levels

    func cardsNeeded(_ c: ChefDef, level: Int) -> Int? {
        guard level < chefRules.maxLevel, let list = chefRules.cardsToLevel[c.rarityRaw], level - 1 < list.count else { return nil }
        return list[level - 1]
    }

    func goldNeeded(level: Int) -> Int? {
        guard level < chefRules.maxLevel, level - 1 < chefRules.goldToLevel.count else { return nil }
        return chefRules.goldToLevel[level - 1]
    }

    /// Cards still useful before L10.
    func cardsToMax(_ c: ChefDef, level: Int) -> Int {
        guard let list = chefRules.cardsToLevel[c.rarityRaw] else { return 0 }
        var n = 0
        var l = level
        while l < chefRules.maxLevel && l - 1 < list.count {
            n += list[l - 1]
            l += 1
        }
        return n
    }

    /// Adds cards; the first card unlocks the chef. Returns (isNew, surplus gold).
    @discardableResult
    func addCards(_ id: String, _ n: Int) -> (Bool, Int) {
        guard let c = cat.chef(id), n > 0 else { return (false, 0) }
        var count = n
        var own = s.chefs.owned[id] ?? ChefOwn()
        let isNew = s.chefs.owned[id] == nil
        if isNew { count -= 1 }
        own.cards += count
        let cap = cardsToMax(c, level: own.level)
        var gold = 0
        if own.cards > cap {
            gold = (own.cards - cap) * (chefRules.surplusGold[c.rarityRaw] ?? 1)
            own.cards = cap
        }
        s.chefs.owned[id] = own
        s.wallet.gold += gold
        return (isNew, gold)
    }

    func canLevelUp(_ id: String) -> Bool {
        guard let c = cat.chef(id), let own = s.chefs.owned[id], let cards = cardsNeeded(c, level: own.level),
              let gold = goldNeeded(level: own.level) else { return false }
        return own.cards >= cards && s.wallet.gold >= gold
    }

    func levelUpChef(_ id: String) {
        guard let c = cat.chef(id), var own = s.chefs.owned[id], let cards = cardsNeeded(c, level: own.level),
              let gold = goldNeeded(level: own.level) else { return }
        guard own.cards >= cards, s.wallet.gold >= gold else {
            Feedback.error()
            return
        }
        own.cards -= cards
        own.level += 1
        s.chefs.owned[id] = own
        s.wallet.gold -= gold
        if own.level >= chefRules.maxLevel {
            Feedback.play(.t2)
        } else {
            Feedback.play(.t1, fromAnchor: "chef.levelup", art: "ui_sparkles", to: "chef.levelup", amount: 1,
                          label: "مستوى " + Num.int(own.level))
        }
        save()
    }

    /// Random chef cards of a rarity (rewards, migration of stored cards).
    func grantRandomCards(rarity: Rarity, count: Int) -> String? {
        let pool = chestPoolChefs.filter { $0.rarity == rarity }
        guard !pool.isEmpty, count > 0 else { return nil }
        var r = Seed.rng("cards", ["\(s.chefs.cardCounter)"], player: s.meta.seed)
        s.chefs.cardCounter += 1
        let unowned = pool.filter { s.chefs.owned[$0.id] == nil }
        let pick = (!unowned.isEmpty && r.unit() < 0.5) ? unowned[r.int(unowned.count)] : pool[r.int(pool.count)]
        addCards(pick.id, count)
        return pick.id
    }

    // MARK: Chests

    var chestCount: Int { s.chefs.chests.values.reduce(0, +) }

    func addChest(_ kind: String, _ n: Int = 1) {
        s.chefs.chests[kind, default: 0] += max(1, n)
    }

    /// Moves Phase I stored rewards into the chef inventory.
    func migratePendingRewards() {
        for (k, n) in s.wallet.pendingChests where n > 0 { addChest(k, n) }
        s.wallet.pendingChests = [:]
        if unlocked("chefs") && s.wallet.pendingChefCards > 0 {
            _ = grantRandomCards(rarity: .common, count: s.wallet.pendingChefCards)
            s.wallet.pendingChefCards = 0
        }
    }

    func rollRarity(_ odds: [String: Double], _ r: inout SplitMix64) -> Rarity {
        let order = Rarity.allCases
        let w = order.map { odds[$0.rawValue] ?? 0 }
        return order[r.weighted(w)]
    }

    func rollChest(_ kind: String, scriptedChef: String? = nil) -> ChestResult {
        guard let def = cat.chest(kind) else { return ChestResult(kind: kind, stacks: [], gold: 0) }
        var r = Seed.rng("chest", ["\(s.chefs.openCounter)"], player: s.meta.seed)
        s.chefs.openCounter += 1
        let n = max(1, def.stacks)
        var rarities = (0..<n).map { _ in rollRarity(def.odds, &r) }
        if def.guarantee == "rare" && !rarities.contains(where: { $0.rank >= 1 }) { rarities[0] = .rare }
        if def.guarantee == "epic" && !rarities.contains(where: { $0.rank >= 2 }) { rarities[0] = .epic }
        if kind != "wood" {
            if s.chefs.pityLegend >= chefRules.pityLegendary && !rarities.contains(.legendary) { rarities[n - 1] = .legendary }
            if kind == "silver" && s.chefs.pitySilverEpic >= chefRules.pityEpicSilver && !rarities.contains(where: { $0.rank >= 2 }) {
                rarities[0] = .epic
            }
            s.chefs.pityLegend = rarities.contains(.legendary) ? 0 : s.chefs.pityLegend + 1
            if kind == "silver" {
                s.chefs.pitySilverEpic = rarities.contains(where: { $0.rank >= 2 }) ? 0 : s.chefs.pitySilverEpic + 1
            }
        }
        if scriptedChef != nil { rarities[0] = .common }
        let weights = rarities.map { chefRules.stackWeights[$0.rawValue] ?? 1 }
        let sum = max(0.0001, weights.reduce(0, +))
        var sizes = weights.map { max(1, Int((Double(def.cards) * $0 / sum).rounded())) }
        let diff = def.cards - sizes.reduce(0, +)
        if diff != 0, let big = sizes.indices.max(by: { sizes[$0] < sizes[$1] }) {
            sizes[big] = max(1, sizes[big] + diff)
        }
        var stacks: [ChestStack] = []
        var picked = Set<String>()
        for k in 0..<n {
            let rar = rarities[k]
            var id: String
            if k == 0, let sc = scriptedChef {
                id = sc
            } else {
                let pool = chestPoolChefs.filter { $0.rarity == rar }
                guard !pool.isEmpty else { continue }
                let unowned = pool.filter { s.chefs.owned[$0.id] == nil && !picked.contains($0.id) }
                if !unowned.isEmpty && r.unit() < chefRules.newChefStackChance {
                    id = unowned[r.int(unowned.count)].id
                } else {
                    let open = pool.filter { (s.chefs.owned[$0.id]?.level ?? 0) < chefRules.maxLevel }
                    let list = open.isEmpty ? pool : open
                    id = list[r.int(list.count)].id
                }
            }
            picked.insert(id)
            let res = addCards(id, sizes[k])
            stacks.append(ChestStack(chefId: id, cards: sizes[k], rarity: cat.chef(id)?.rarity ?? rar, isNew: res.0))
        }
        let gold = def.goldMin + r.int(max(1, def.goldMax - def.goldMin + 1))
        s.wallet.gold += gold
        return ChestResult(kind: kind, stacks: stacks, gold: gold)
    }

    func openChest(_ kind: String) {
        guard (s.chefs.chests[kind] ?? 0) > 0 else { return }
        s.chefs.chests[kind, default: 0] -= 1
        if s.chefs.chests[kind] == 0 { s.chefs.chests[kind] = nil }
        var scripted: String? = nil
        if kind == "wood" && s.chefs.ftueChestGiven && !s.chefs.ftueChestOpened {
            s.chefs.ftueChestOpened = true
            scripted = "samiFryer"
        }
        let result = rollChest(kind, scriptedChef: scripted)
        s.chefs.revealViews += 1
        enqueue(.chest(result))
        save()
    }

    func buyChest(_ kind: String) {
        guard let def = cat.chest(kind) else { return }
        guard s.wallet.gold >= def.price else {
            Feedback.error()
            showToast("الذهب مش كافي. اجمع من الفروع والمستويات", art: "ui_coin")
            return
        }
        s.wallet.gold -= def.price
        addChest(kind)
        openChest(kind)
    }

    // MARK: Daily chef stall (بسطة الطبّاخين)

    var weekday: Int {
        Calendar(identifier: .gregorian).component(.weekday, from: Date(timeIntervalSince1970: now() - 4 * 3600))
    }

    var stallOffers: [StallOffer] {
        let day = gameDay
        let wd = weekday
        var out: [StallOffer] = []
        for o in chefRules.dailyStall where o.weekdays.isEmpty || o.weekdays.contains(wd) {
            let rar = Rarity(rawValue: o.rarity) ?? .common
            let pool = chestPoolChefs.filter { $0.rarity == rar }
            guard !pool.isEmpty else { continue }
            var r = Seed.rng("stall", ["\(day)", "\(o.slot)"], player: s.meta.seed)
            let chef = pool[r.int(pool.count)]
            out.append(StallOffer(slot: o.slot, chefId: chef.id, rarity: rar, cards: o.cards, price: o.price))
        }
        return out
    }

    func stallBought(_ slot: Int) -> Bool { s.chefs.stallDay == gameDay && s.chefs.stallBought.contains(slot) }

    func buyStall(_ offer: StallOffer) {
        guard !stallBought(offer.slot) else { return }
        guard s.wallet.gold >= offer.price else {
            Feedback.error()
            return
        }
        if s.chefs.stallDay != gameDay {
            s.chefs.stallDay = gameDay
            s.chefs.stallBought = []
        }
        s.wallet.gold -= offer.price
        s.chefs.stallBought.append(offer.slot)
        let res = addCards(offer.chefId, offer.cards)
        let name = cat.chef(offer.chefId).map { t($0.name) } ?? ""
        Feedback.play(res.0 ? .t2 : .t1, fromAnchor: "stall.\(offer.slot)", art: cat.chef(offer.chefId)?.art, to: "tab.chefs",
                      amount: Double(offer.cards), label: "+" + Num.int(offer.cards) + " " + name)
        save()
    }

    // MARK: Skills (L22)

    func skillReadyIn(_ id: String) -> Double { max(0, (s.chefs.skillReadyAt[id] ?? 0) - now()) }

    func activateSkill(_ id: String) {
        guard unlocked("chefSkills"), isEquipped(id), let c = cat.chef(id), let sk = c.skill, skillReadyIn(id) <= 0 else {
            Feedback.error()
            return
        }
        s.chefs.skillReadyAt[id] = now() + sk.cooldownMin * 60
        switch sk.type {
        case "categoryBoost":
            addBoost("skill." + id, mult: sk.magnitude, seconds: sk.durationSec, scope: "cat:" + (sk.value ?? ""))
        case "cuisineBoost":
            addBoost("skill." + id, mult: sk.magnitude, seconds: sk.durationSec, scope: "cui:" + (sk.value ?? ""))
        case "allBoost":
            addBoost("skill." + id, mult: sk.magnitude, seconds: sk.durationSec)
        case "instantIncome":
            let amount = sk.magnitude * 60 * totalIncome(active: false)
            credit(amount, station: nil, at: now())
        case "spawnSpecial":
            if special == nil { spawnSpecial(forced: nil) }
        case "frenzy":
            addBoost("frenzy", mult: econ.boosts.frenzyMult, seconds: econ.boosts.frenzySec)
        default:
            break
        }
        Feedback.play(.t2)
        showToast(t(c.name) + ": " + t(sk.name), art: c.art)
        save()
    }
}
