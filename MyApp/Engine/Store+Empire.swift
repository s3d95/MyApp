import Foundation

/// Empire level, XP and level rewards (GDD 4).
extension GameStore {
    /// Systems that exist in this build (their unlocks are announced at level-up).
    static let builtSystems: Set<String> = ["kitchen", "goals", "managers", "specials", "upgrades", "rushHours",
                                            "vault", "map", "branchUpgrades", "chefs", "chests", "shop", "chefSkills",
                                            "research", "supply", "heritage", "crafting", "timeWarpShop",
                                            "daily", "calendar", "streak"]

    func systemName(_ id: String) -> String {
        switch id {
        case "managers": return "المعلّمين"
        case "specials": return "الزباين المميّزين"
        case "upgrades": return "الترقيات"
        case "rushHours": return "ساعات الذروة"
        case "vault": return "الخزنة"
        case "map": return "الخريطة والفروع"
        case "branchUpgrades": return "تكبير الفروع"
        case "chefs": return "الطبّاخين"
        case "calendar": return "الروزنامة"
        case "streak": return "السلسلة"
        case "heritage": return "صندوق التراث"
        case "crafting": return "صنع التراث"
        case "chefSkills": return "مهارات الطبّاخين"
        case "timeWarpShop": return "رزم الوقت بالدكان"
        case "shop": return "الدكان"
        case "research": return "دفتر ستّي"
        case "supply": return "رحلات التوريد"
        case "daily": return "طلبات اليوم"
        default: return id
        }
    }

    func xpNeed(_ level: Int) -> Int { max(1, Rules.xpToNext(level, curve: cat.levels.xpCurve)) }

    var xpProgress: Double { Double(s.empire.xp) / Double(xpNeed(level)) }

    func title(for level: Int) -> String {
        let row = cat.levels.titles.filter { $0.level <= level }.max { $0.level < $1.level }
        return row.map { t($0.name) } ?? "بيّاع عالبسطة"
    }

    var currentTitle: String { title(for: level) }

    func addXP(_ n: Int) {
        guard n > 0 else { return }
        s.empire.xp += n
        s.empire.totalXp += n
        var extraXP = 0
        while s.empire.xp >= xpNeed(s.empire.level) {
            s.empire.xp -= xpNeed(s.empire.level)
            let from = s.empire.level
            s.empire.level += 1
            let lv = s.empire.level
            var info = pendingLevelUp ?? LevelUpInfo(from: from, to: lv, rewards: [], unlocks: [], title: nil)
            info.to = lv
            let rewards = cat.levelRow(lv)?.rewards ?? (lv > 100 ? cat.levels.beyond100Rewards : [Reward(type: "gold", amount: 25)])
            for r in rewards {
                if r.type == "xp" {
                    extraXP += Int(r.amount)
                    continue
                }
                if let line = applyReward(r) { info.rewards.append(line) }
            }
            for u in cat.levelRow(lv)?.unlocks ?? [] where u.type == "system" {
                if let id = u.id, GameStore.builtSystems.contains(id) { info.unlocks.append(systemName(id)) }
            }
            if cat.levels.titles.contains(where: { $0.level == lv }) { info.title = title(for: lv) }
            pendingLevelUp = info
        }
        if extraXP > 0 { addXP(extraXP) }
    }

    /// Queues the merged level-up modal (called after each action burst).
    func flushLevelUp() {
        guard let info = pendingLevelUp else { return }
        pendingLevelUp = nil
        enqueue(.levelUp(info))
        Feedback.play(.t2)
        if s.legacy.eligible && !s.legacy.claimed && info.to >= 2 { enqueue(.legacy) }
        if !s.settings.addressAsked && info.to >= 2 { enqueue(.address) }
        save()
    }

    func chestArt(_ kind: String) -> String { "ui_gift" }

    func chestName(_ kind: String) -> String {
        switch kind {
        case "gold": return "صندوق ذهب"
        case "silver": return "صندوق فضّة"
        default: return "صندوق خشب"
        }
    }

    /// The only place rewards are granted. Returns a display line.
    @discardableResult
    func applyReward(_ r: Reward) -> RewardLine? {
        let n = Int(r.amount.rounded())
        switch r.type {
        case "gold":
            s.wallet.gold += n
            return RewardLine(art: "ui_coin", amount: "+" + Num.int(n), caption: "ذهب")
        case "zaatar":
            s.wallet.zaatar += n
            return RewardLine(art: "food_herb", amount: "+" + Num.int(n), caption: "زعتر ذهبي")
        case "chest":
            let kind = r.id ?? "wood"
            addChest(kind, max(1, n))
            return RewardLine(art: chestArt(kind), amount: "×" + Num.int(max(1, n)), caption: chestName(kind))
        case "timeWarpMin":
            s.wallet.timeWarps.append(n)
            return RewardLine(art: "ui_hourglass", amount: Num.dur(Double(n) * 60), caption: "رزمة وقت")
        case "chefCards":
            let count = max(1, n)
            if let id = r.id, let c = cat.chef(id) {
                addCards(id, count)
                return RewardLine(art: c.art, amount: "+" + Num.int(count), caption: t(c.name))
            }
            if unlocked("chefs"), let id = grantRandomCards(rarity: Rarity(rawValue: r.rarity ?? "common") ?? .common, count: count),
               let c = cat.chef(id) {
                return RewardLine(art: c.art, amount: "+" + Num.int(count), caption: t(c.name))
            }
            s.wallet.pendingChefCards += count
            return RewardLine(art: "ppl_cook", amount: "+" + Num.int(count), caption: "كروت طبّاخين")
        case "heritageItem", "heritageCase":
            let count = r.type == "heritageCase" ? 3 * max(1, n) : max(1, n)
            if let id = r.id, let item = cat.item(id) {
                addItem(id)
                return RewardLine(art: item.art, amount: "+1", caption: t(item.name))
            }
            var rr = Seed.rng("heritageReward", ["\(s.supply.runCounter)", "\(s.chefs.cardCounter)"], player: s.meta.seed)
            s.supply.runCounter += 1
            var last: HeritageItemDef? = nil
            let floor = r.type == "heritageCase" ? Rarity.rare : (Rarity(rawValue: r.rarity ?? "common") ?? .common)
            for _ in 0..<count {
                if let item = rollItem(floor, &rr) {
                    addItem(item.id)
                    last = item
                }
            }
            return RewardLine(art: last?.art ?? "ui_old_key", amount: "+" + Num.int(count), caption: last.map { t($0.name) } ?? "قطعة تراث")
        case "tickets":
            s.wallet.tickets = min(9, s.wallet.tickets + max(1, n))
            return RewardLine(art: "ui_admission_tickets", amount: "+" + Num.int(max(1, n)), caption: "تذاكر")
        case "freezes":
            s.wallet.freezes = min(freezeCap, s.wallet.freezes + max(1, n))
            return RewardLine(art: "ui_snowflake", amount: "+" + Num.int(max(1, n)), caption: "تجميدة")
        case "seasonPoints", "rep":
            bump(r.type, r.amount)
            return nil
        case "cosmetic":
            bump("cosmetic." + (r.id ?? ""), 1)
            return RewardLine(art: "ui_artist_palette", amount: "", caption: "ديكور جديد")
        case "incomeMin":
            let amount = r.amount * 60 * totalIncome(active: false)
            credit(amount, station: nil, at: now())
            return RewardLine(art: city.currency.art, amount: "+" + Num.big(amount), caption: currencyName)
        default:
            return nil
        }
    }

    var pendingChestCount: Int { chestCount }
}
