import Foundation

// MARK: - Content (market.json)

struct MarketModDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "ui_party_popper"
    var desc = GText("")
    var weight: Double = 1
    var effects: [EffectDef] = []
    var weekdays: [Int] = []
    var festive = false

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        desc = c.v("desc", GText(""))
        weight = c.dbl("weight", 1)
        effects = c.v("effects", [])
        weekdays = c.v("weekdays", [])
        festive = c.v("festive", false)
    }
}

struct WeatherSeasonDef: Decodable {
    var months: [Int] = []
    var probs: [String: Double] = [:]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        months = c.v("months", [])
        probs = c.v("probs", [:])
    }
}

struct MarketFile: Decodable {
    var unlockLevel = 13
    var perDayDefault = 1
    var perDayFriday = 2
    var cooldownDays = 5
    var modifiers: [MarketModDef] = []
    var seasons: [WeatherSeasonDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        unlockLevel = c.int("unlockLevel", unlockLevel)
        if let p = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("perDay")) {
            perDayDefault = p.int("default", 1)
            perDayFriday = p.int("friday", 2)
        }
        cooldownDays = c.int("cooldownDays", cooldownDays)
        modifiers = c.v("modifiers", [])
        if let w = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("weather")) {
            seasons = w.v("seasons", [])
        }
    }
}

// MARK: - Engine (GDD 6.6)

/// سوق اليوم and الطقس: seeded per game day, so every reopen shows the same day.
extension GameStore {
    var mk: MarketFile { cat.market }

    var marketOn: Bool { unlocked("market") }

    private func rawMarketPicks(_ day: Int, weekday wd: Int) -> [MarketModDef] {
        let pool = mk.modifiers.filter { $0.weekdays.isEmpty || $0.weekdays.contains(wd) }
        guard !pool.isEmpty else { return [] }
        var r = Seed.rng("market", ["\(day)"], player: s.meta.seed)
        var list = pool
        var out: [MarketModDef] = []
        let n = wd == 6 ? mk.perDayFriday : mk.perDayDefault
        for _ in 0..<n where !list.isEmpty {
            let k = r.weighted(list.map { $0.weight })
            out.append(list.remove(at: k))
        }
        return out
    }

    /// Today's modifiers; a modifier picked in the last few days is skipped (cooldown).
    func marketMods(day: Int) -> [MarketModDef] {
        guard marketOn else { return [] }
        let wd = weekday
        var recent = Set<String>()
        for back in 1...max(1, mk.cooldownDays) {
            for m in rawMarketPicks(day - back, weekday: (wd - back % 7 + 13) % 7 + 1) { recent.insert(m.id) }
        }
        let picks = rawMarketPicks(day, weekday: wd)
        let fresh = picks.filter { !recent.contains($0.id) }
        if !fresh.isEmpty { return fresh }
        let pool = mk.modifiers.filter { !recent.contains($0.id) && ($0.weekdays.isEmpty || $0.weekdays.contains(wd)) }
        guard !pool.isEmpty else { return picks }
        var r = Seed.rng("marketAlt", ["\(day)"], player: s.meta.seed)
        return [pool[r.weighted(pool.map { $0.weight })]]
    }

    var todayMods: [MarketModDef] {
        let d = dayNum
        if marketCacheDay == d { return marketCache }
        let m = marketMods(day: d)
        marketCacheDay = d
        marketCache = m
        return m
    }

    func marketEffects(_ type: String) -> [EffectDef] { todayMods.flatMap { $0.effects }.filter { $0.type == type } }

    func marketCost(_ target: String) -> Double {
        marketEffects("costMult").filter { $0.target == target }.reduce(1.0) { $0 * $1.mult }
    }

    func marketDuration(_ target: String) -> Double {
        marketEffects("durationMult").filter { $0.target == target }.reduce(1.0) { $0 * $1.mult }
    }

    var marketRollsMult: Double { marketEffects("rollsMult").reduce(1.0) { $0 * $1.mult } }

    var marketSpecialInterval: Double {
        var m = marketEffects("specialIntervalMult").reduce(1.0) { $0 * $1.mult }
        if globalWeather == .rain { m *= 0.8 }
        return m
    }

    var marketVaultAdd: Double { marketEffects("vaultEffAdd").reduce(0.0) { $0 + $1.add } }

    /// Global weather; a city with the weatherSwing twist uses its own.
    var globalWeather: Weather? {
        guard marketOn else { return nil }
        if let w = cityWeather(day: gameDay) { return w }
        let month = Calendar(identifier: .gregorian).component(.month, from: Date(timeIntervalSince1970: now() - 4 * 3600))
        guard let season = mk.seasons.first(where: { $0.months.contains(month) }) else { return nil }
        var r = Seed.rng("weather", ["global", "\(dayNum)"], player: s.meta.seed)
        let order: [(String, Weather)] = [("sunny", .sunny), ("hot", .hot), ("cold", .cold), ("rainy", .rain)]
        let k = r.weighted(order.map { season.probs[$0.0] ?? 0 })
        return order[k].1
    }

    /// Category 10 for station i: market income modifiers × weather, capped ×5.
    func dayMult(_ i: Int) -> Double {
        let d = city.stations[i]
        guard marketOn else { return min(econ.boosts.dayCap, festivalDayMult(d)) }
        var m = 1.0
        for e in marketEffects("incomeMult") where scopeMatches(e, d) { m *= e.mult }
        if twist(.weatherSwing) == nil, let w = globalWeather {
            if w == .hot && d.weather == "cold" { m *= 1.15 }
            if w == .cold && d.weather == "hot" { m *= 1.15 }
        }
        m *= festivalDayMult(d)
        return min(econ.boosts.dayCap, m)
    }

    func scopeMatches(_ e: EffectDef, _ d: StationDef) -> Bool {
        switch e.scopeKind {
        case "category": return d.category == e.scopeValue
        case "cuisine": return d.cuisine == e.scopeValue
        case "weatherTag": return d.weather == e.scopeValue
        case "station": return d.key == e.scopeValue || d.id == e.scopeValue
        default: return true
        }
    }

    /// The once-a-day gift modifier (ticket on first open).
    func marketGifts() {
        guard marketOn, s.daily.marketGiftDay != dayNum else { return }
        s.daily.marketGiftDay = dayNum
        for e in marketEffects("reward") {
            if let r = e.reward { _ = applyReward(r) }
        }
    }
}
