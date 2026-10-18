import Foundation

// MARK: - Content (league.json)

struct LeagueTierDef: Decodable {
    var id = 1
    var name = GText("")
    var art = "bld_tent"
    var promote = 10
    var demote = 5
    var q: Double = 1

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.int("id", 1)
        name = c.v("name", GText(""))
        art = c.v("art", art)
        promote = c.int("promote", promote)
        demote = c.int("demote", demote)
        q = c.dbl("q", q)
    }
}

struct LeagueRewardDef: Decodable {
    var fromRank = 1
    var toRank = 1
    var goldBase = 5
    var goldPerTier = 0
    var chest: String? = nil
    var chestFromTier6: String? = nil

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        fromRank = c.int("fromRank", 1)
        toRank = c.int("toRank", 1)
        goldBase = c.int("goldBase", 5)
        goldPerTier = c.int("goldPerTier", 0)
        chest = c.opt("chest")
        chestFromTier6 = c.opt("chestFromTier6")
    }
}

struct LeagueNameDef: Decodable {
    var key = ""
    var name = GText("")
    var archetype = "steady"

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        key = c.v("key", "")
        name = c.v("name", GText(key))
        archetype = c.v("archetype", archetype)
    }
}

struct LeagueFile: Decodable {
    var unlockLevel = 12
    var groupSize = 30
    var defaultBaseline: Double = 1400
    var firstWeekQ: Double = 0.35
    var sigma: Double = 0.45
    var noiseDaily: Double = 0.03
    var tiers: [LeagueTierDef] = []
    var archetypes: [(id: String, weight: Double)] = [("steady", 0.4), ("earlyBird", 0.15), ("weekendBurst", 0.2),
                                                     ("closer", 0.15), ("sprinter", 0.1)]
    var rewards: [LeagueRewardDef] = []
    var promotionRewards: [Reward] = []
    var rep: [String: Double] = [:]
    var fixedNames: [LeagueNameDef] = []
    var prefixes: [GText] = []
    var suffixes: [GText] = []
    var avatars: [String] = ["food_falafel"]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        unlockLevel = c.int("unlockLevel", unlockLevel)
        groupSize = c.int("groupSize", groupSize)
        defaultBaseline = c.dbl("defaultBaseline", defaultBaseline)
        firstWeekQ = c.dbl("firstWeekQ", firstWeekQ)
        sigma = c.dbl("sigma", sigma)
        noiseDaily = c.dbl("noiseDaily", noiseDaily)
        tiers = c.v("tiers", [])
        rewards = c.v("rewards", [])
        promotionRewards = c.v("promotionRewards", [])
        rep = c.v("repSources", [:])
        if let n = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("names")) {
            fixedNames = n.v("fixed", [])
            prefixes = n.v("prefixes", [])
            suffixes = n.v("suffixes", [])
        }
        avatars = c.v("avatars", avatars)
    }
}

// MARK: - Engine (GDD 6.7)

struct LeagueRow: Identifiable {
    let id: String
    let name: String
    let art: String
    let score: Int
    let isPlayer: Bool
}

struct LeagueNPC {
    let key: String
    let name: String
    let art: String
    let archetype: String
    let final: Double
}

extension GameStore {
    var lg: LeagueFile { cat.league }

    var leagueTier: LeagueTierDef? {
        let t = max(1, min(lg.tiers.count, s.league.tier))
        return lg.tiers.first { $0.id == t }
    }

    func rep(_ key: String, _ times: Double = 1) {
        guard unlocked("league"), let v = lg.rep[key] else { return }
        bump("rep", v * times)
    }

    var leagueScore: Int { max(0, Int(metric("rep") - s.league.startRep)) }

    /// Fraction of the league week elapsed (Monday 04:00 → Monday 04:00).
    func weekFraction(at t: Double) -> Double {
        let d = dayNumber(t)
        let weekStart = 4 + Int(floor(Double(d - 4) / 7)) * 7
        let sod = Clock.secondsOfDay(t)
        let intoDay = (sod - 4 * 3600 + 86400).truncatingRemainder(dividingBy: 86400) / 86400
        return min(1, max(0, (Double(d - weekStart) + intoDay) / 7))
    }

    func leagueRollover() {
        guard unlocked("league") else { return }
        let w = weekNum
        if s.league.week == 0 {
            s.league.week = w
            s.league.tier = 1
            s.league.startRep = metric("rep")
            s.league.trial = true
            s.league.joinFraction = weekFraction(at: now())
            return
        }
        guard s.league.week != w else { return }
        finishLeagueWeek()
        s.league.week = w
        s.league.startRep = metric("rep")
        s.league.trial = false
        s.league.joinFraction = 0
    }

    func npcs(week: Int, tier: Int) -> [LeagueNPC] {
        let tierDef = lg.tiers.first { $0.id == tier }
        let finals = s.league.finals.suffix(2)
        let base = finals.isEmpty ? lg.defaultBaseline : finals.reduce(0, +) / Double(finals.count)
        let q = s.league.trial ? lg.firstWeekQ : (tierDef?.q ?? 1)
        let remaining = s.league.trial ? max(0.15, 1 - s.league.joinFraction) : 1
        let line = max(50, base * q * remaining)
        var r = Seed.rng("league", ["\(week)", "\(tier)"], player: s.meta.seed)
        let n = max(1, lg.groupSize - 1)
        var z: [Double] = []
        for _ in 0..<n {
            let u1 = max(1e-9, r.unit())
            let u2 = r.unit()
            z.append(sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2))
        }
        z.sort(by: >)
        let promote = tierDef?.promote ?? 10
        let p = min(n - 1, max(0, tier >= lg.tiers.count ? 4 : promote - 1))
        var names = lg.fixedNames.map { (key: $0.key, name: t($0.name), arch: $0.archetype) }
        for a in lg.prefixes {
            for b in lg.suffixes where names.count < 200 {
                names.append((key: t(a) + t(b), name: t(a) + " " + t(b), arch: ""))
            }
        }
        var out: [LeagueNPC] = []
        var used = Set<Int>()
        for i in 0..<n {
            var k = r.int(max(1, names.count))
            var guardCount = 0
            while used.contains(k) && guardCount < 400 {
                k = (k + 1) % max(1, names.count)
                guardCount += 1
            }
            used.insert(k)
            let nm = names.isEmpty ? (key: "npc\(i)", name: "مطعم", arch: "") : names[k]
            var arch = nm.arch
            if arch.isEmpty { arch = lg.archetypes[r.weighted(lg.archetypes.map { $0.weight })].id }
            let art = lg.avatars.isEmpty ? "food_falafel" : lg.avatars[r.int(lg.avatars.count)]
            out.append(LeagueNPC(key: nm.key, name: nm.name, art: art, archetype: arch,
                                 final: line * exp(lg.sigma * (z[i] - z[p]))))
        }
        return out
    }

    func curve(_ arch: String, _ x: Double) -> Double {
        switch arch {
        case "earlyBird": return pow(min(1, 1.6 * x), 0.8)
        case "weekendBurst": return x < 0.43 ? 0.6 * x : 0.258 + 0.742 * (x - 0.43) / 0.57
        case "closer": return x * x
        case "sprinter": return 1 - (1 - x) * (1 - x)
        default: return x
        }
    }

    var leagueRows: [LeagueRow] {
        let x = weekFraction(at: now())
        let day = dayNum
        var rows: [LeagueRow] = []
        for (i, n) in npcs(week: s.league.week, tier: s.league.tier).enumerated() {
            var r = Seed.rng("leagueNoise", ["\(s.league.week)", "\(i)", "\(day)"], player: s.meta.seed)
            let noise = 1 + lg.noiseDaily * (r.unit() * 2 - 1)
            let shown = Int((n.final * curve(n.archetype, x) * noise).rounded())
            rows.append(LeagueRow(id: n.key + "\(i)", name: n.name, art: n.art, score: max(0, shown), isPlayer: false))
        }
        rows.append(LeagueRow(id: "player", name: s.settings.stallName, art: "ppl_cook", score: leagueScore, isPlayer: true))
        return rows.sorted { $0.score > $1.score }
    }

    var leagueRank: Int { (leagueRows.firstIndex { $0.isPlayer } ?? 0) + 1 }

    func finishLeagueWeek() {
        let tier = s.league.tier
        let score = leagueScore
        let finals = npcs(week: s.league.week, tier: tier).map { Int($0.final.rounded()) }
        let rank = 1 + finals.filter { $0 > score }.count
        let def = lg.tiers.first { $0.id == tier }
        var lines: [RewardLine] = []
        if let rw = lg.rewards.first(where: { rank >= $0.fromRank && rank <= $0.toRank }) {
            let gold = rw.goldBase + rw.goldPerTier * tier
            s.wallet.gold += gold
            lines.append(RewardLine(art: "ui_coin", amount: Num.plus(Num.int(gold)), caption: "ذهب"))
            if let chest = tier >= 6 ? (rw.chestFromTier6 ?? rw.chest) : rw.chest {
                addChest(chest)
                lines.append(RewardLine(art: "ui_gift", amount: "×1", caption: chestName(chest)))
            }
        }
        var title = "خلص أسبوع الدوري: المركز " + Num.int(rank)
        if score > 0 {
            if rank <= (def?.promote ?? 0) && tier < lg.tiers.count {
                s.league.tier = tier + 1
                for r in lg.promotionRewards { if let l = applyReward(r) { lines.append(l) } }
                title = "طلعت درجة بالدوري!"
                seasonPoint("leaguePromotion")
                s.metrics["bestLeagueTier"] = max(metric("bestLeagueTier"), Double(tier + 1))
            } else if tier > 1 && rank > lg.groupSize - (def?.demote ?? 0) {
                s.league.tier = tier - 1
            }
            s.league.finals.append(Double(score))
            if s.league.finals.count > 2 { s.league.finals.removeFirst(s.league.finals.count - 2) }
        }
        addXP(50 + 10 * tier)
        seasonPoint("leagueWeek")
        enqueue(.rewards(title: title, lines: lines))
        save()
    }

    func tierName(_ id: Int) -> String {
        lg.tiers.first { $0.id == id }.map { t($0.name) } ?? ""
    }

    var leagueTimeLeft: Double {
        let x = weekFraction(at: now())
        return max(0, (1 - x) * 7 * 86400)
    }
}
