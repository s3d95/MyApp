import Foundation

// MARK: - Content (season.json, achievements.json)

struct SeasonTierDef: Decodable {
    var tier = 1
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        tier = c.int("tier", 1)
        rewards = c.v("rewards", [])
    }
}

struct SeasonThemeDef: Decodable {
    var index = 0
    var id = ""
    var name = GText("")
    var art = "ui_calendar"
    var chefId = ""

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        index = c.int("index", 0)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        chefId = c.v("chefId", "")
    }
}

struct SeasonFile: Decodable {
    var unlockLevel = 16
    var epoch = "2026-01-05"
    var lengthDays = 42
    var pointsPerTier = 140
    var tiers: [SeasonTierDef] = []
    var overflowPer = 300
    var overflowRewards: [Reward] = []
    var overflowMax = 10
    var lateJoinerMaxMult: Double = 2
    var points: [String: Double] = [:]
    var caps: [String: Double] = [:]
    var themes: [SeasonThemeDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        unlockLevel = c.int("unlockLevel", unlockLevel)
        epoch = c.v("epoch", epoch)
        lengthDays = c.int("lengthDays", lengthDays)
        pointsPerTier = c.int("pointsPerTier", pointsPerTier)
        tiers = c.v("tiers", [])
        if let o = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("overflow")) {
            overflowPer = o.int("pointsPer", overflowPer)
            overflowRewards = o.v("rewards", [])
            overflowMax = o.int("max", overflowMax)
        }
        lateJoinerMaxMult = c.dbl("lateJoinerMaxMult", lateJoinerMaxMult)
        if let p = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("points")) {
            for k in p.allKeys {
                if let row = try? p.nestedContainer(keyedBy: AnyKey.self, forKey: k) {
                    points[k.stringValue] = row.dbl("amount", 0)
                    if let cap = row.dblOpt("dailyCap") { caps[k.stringValue] = cap }
                }
            }
        }
        themes = c.v("themes", [])
    }
}

struct AchFamilyDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "ui_trophy"
    var metric = ""
    var tiers: [Double] = []
    var desc = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        metric = c.v("metric", "")
        tiers = c.v("tiers", [])
        desc = c.v("desc", GText(""))
    }
}

struct AchTierReward: Decodable {
    var gold = 5
    var xp = 20

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        gold = c.int("gold", 5)
        xp = c.int("xp", 20)
    }
}

struct AchievementsFile: Decodable {
    var tierRewards: [AchTierReward] = []
    var families: [AchFamilyDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        tierRewards = c.v("tierRewards", [])
        families = c.v("families", [])
    }
}

// MARK: - Season pass (GDD 6.8)

extension GameStore {
    var sx: SeasonFile { cat.season }

    var seasonEpochDay: Int {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let d = f.date(from: sx.epoch) ?? Date(timeIntervalSince1970: 1_767_571_200)
        return dayNumber(d.timeIntervalSince1970 + 12 * 3600)
    }

    var seasonIndex: Int { max(0, (dayNum - seasonEpochDay) / max(1, sx.lengthDays)) }

    var seasonDaysLeft: Int { sx.lengthDays - (dayNum - seasonEpochDay) % max(1, sx.lengthDays) }

    var seasonTheme: SeasonThemeDef? {
        guard !sx.themes.isEmpty else { return nil }
        return sx.themes[seasonIndex % sx.themes.count]
    }

    var seasonTier: Int { min(sx.tiers.count, Int(s.season.points) / max(1, sx.pointsPerTier)) }

    func seasonPoint(_ key: String, _ times: Double = 1) {
        guard unlocked("season"), let v = sx.points[key] else { return }
        seasonRollover()
        var amount = v * times * s.season.lateMult
        if let cap = sx.caps[key] {
            if s.season.capDay != dayNum {
                s.season.capDay = dayNum
                s.season.capUsed = [:]
            }
            let used = s.season.capUsed[key] ?? 0
            amount = min(amount, max(0, cap - used))
            s.season.capUsed[key] = used + amount
        }
        guard amount > 0 else { return }
        s.season.points += amount
    }

    func seasonRollover() {
        guard unlocked("season") else { return }
        let idx = seasonIndex
        if s.season.index == -1 || s.season.index != idx {
            if s.season.index >= 0 { autoClaimSeason() }
            s.season = SeasonSave()
            s.season.index = idx
            let left = Double(seasonDaysLeft)
            s.season.lateMult = left < Double(sx.lengthDays) ? min(sx.lateJoinerMaxMult, Double(sx.lengthDays) / max(1, left)) : 1
            if s.stats.graduations >= 0 && idx > 0 { bump("seasonsStarted") }
        }
    }

    func seasonTierReady(_ tier: Int) -> Bool { tier <= seasonTier && !s.season.claimed.contains(tier) }

    var seasonDot: Bool { unlocked("season") && (1...max(1, seasonTier)).contains { seasonTierReady($0) } }

    func seasonRewards(_ tier: Int) -> [Reward] {
        (sx.tiers.first { $0.tier == tier }?.rewards ?? []).map { r in
            var r = r
            if r.type == "chefCards" && r.id == "seasonChef" { r.id = seasonTheme?.chefId }
            return r
        }
    }

    func claimSeason(_ tier: Int) {
        guard seasonTierReady(tier) else { return }
        s.season.claimed.append(tier)
        var lines: [RewardLine] = []
        for r in seasonRewards(tier) {
            if let l = applyReward(r) { lines.append(l) }
        }
        if tier == sx.tiers.count { bump("seasonsCompleted") }
        if tier % 25 == 0 {
            enqueue(.rewards(title: "الموسم: درجة " + Num.int(tier) + "!", lines: lines))
            Feedback.play(.t2)
        } else {
            Feedback.play(.t1, fromAnchor: "season.tier.\(tier)", art: lines.first?.art ?? "ui_gift", to: "pill.gold", amount: 10,
                          label: lines.first.map { $0.amount + " " + $0.caption } ?? "")
        }
        save()
    }

    func autoClaimSeason() {
        for t in 1...max(1, seasonTier) where seasonTierReady(t) {
            s.season.claimed.append(t)
            for r in seasonRewards(t) { _ = applyReward(r) }
        }
    }

    // MARK: Achievements (GDD 6.14)

    var ax: AchievementsFile { cat.achievements }

    func statValue(_ id: String) -> Double {
        switch id {
        case "tapCooks": return Double(s.stats.taps)
        case "customers": return s.stats.customers
        case "starsEarned": return Double(s.stats.starsTotal)
        case "citiesGraduated": return Double(s.stats.graduations)
        case "crowns": return Double(s.branches.values.filter { $0.crowned }.count)
        case "empireLevel": return Double(level)
        case "chefsOwned": return Double(s.chefs.owned.count)
        case "chefsAtMax": return Double(s.chefs.owned.values.filter { $0.level >= chefRules.maxLevel }.count)
        case "bestChefLevel": return Double(s.chefs.owned.values.map { $0.level }.max() ?? 0)
        case "researchLevels": return Double(s.research.completed)
        case "runsClaimed": return Double(s.supply.returned)
        case "heritageUnique": return Double(uniqueItems)
        case "setsCompleted": return Double(hx.sets.filter { setComplete($0) }.count)
        case "bestLeagueTier": return Double(max(s.league.tier, Int(metric("bestLeagueTier"))))
        case "bestStreak": return Double(s.daily.streakBest)
        case "zaatar": return Double(s.wallet.zaatar)
        case "branchLevels": return Double(s.branches.values.reduce(0) { $0 + $1.level })
        case "karma": return Double(s.happenings.karma)
        case "specials": return Double(s.stats.specials)
        case "choices": return metric("choices")
        default: return metric(id)
        }
    }

    func achTier(_ f: AchFamilyDef) -> Int { s.achievements[f.id] ?? 0 }

    func achReady(_ f: AchFamilyDef) -> Bool {
        let t = achTier(f)
        return t < f.tiers.count && statValue(f.metric) >= f.tiers[t]
    }

    var achDot: Bool { ax.families.contains { achReady($0) } }

    func claimAch(_ f: AchFamilyDef) {
        guard achReady(f) else { return }
        let t = achTier(f)
        s.achievements[f.id] = t + 1
        let rw = t < ax.tierRewards.count ? ax.tierRewards[t] : nil
        s.wallet.gold += rw?.gold ?? 5
        addXP(rw?.xp ?? 20)
        Feedback.play(.t1, fromAnchor: "ach." + f.id, art: "ui_coin", to: "pill.gold", amount: Double(rw?.gold ?? 5),
                      label: Num.plus(Num.int(rw?.gold ?? 5)) + " ذهب")
        save()
    }
}
