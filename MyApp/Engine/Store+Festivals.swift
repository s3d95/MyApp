import Foundation

// MARK: - Content (festivals.json, happenings.json inspector)

struct MonthDay: Decodable {
    var month = 1
    var day = 1

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        month = c.int("month", 1)
        day = c.int("day", 1)
    }
}

struct ActiveWindowDef: Decodable {
    var kind = "fixed"
    var startOffsetMin: Double = 0
    var endOffsetMin: Double = 0
    var startHour: Double = 0
    var endHour: Double = 0
    var mult: Double = 1
    var replacesRushHour: String? = nil

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        kind = c.v("kind", kind)
        startOffsetMin = c.dbl("startOffsetMin", 0)
        endOffsetMin = c.dbl("endOffsetMin", 0)
        startHour = c.dbl("startHour", 0)
        endHour = c.dbl("endHour", 0)
        mult = c.dbl("mult", 1)
        replacesRushHour = c.opt("replacesRushHour")
    }
}

struct CollectibleDef: Decodable {
    var id = ""
    var name = GText("")
    var art = "ui_lantern"
    var count = 30
    var rawMilestones: [CollectibleMilestone] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        count = c.int("count", 30)
        rawMilestones = c.v("milestones", [])
    }
}

struct CollectibleMilestone: Decodable {
    var count = 10
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        count = c.int("count", 10)
        rewards = c.v("rewards", [])
    }
}

struct FestivalDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "ui_party_popper"
    var hijri = false
    var start = MonthDay()
    var end = MonthDay()
    var extraEndDays = 0
    var effects: [EffectDef] = []
    var windows: [ActiveWindowDef] = []
    var dailyClaim: [Reward] = []
    var collectible: CollectibleDef? = nil
    var storySceneId: String? = nil
    var neutralName = GText("أيام البركة")
    var eveDays = 0
    var eventThemeId: String? = nil
    var happeningTag: String? = nil
    /// Art keys hung over the street while the festival (or its eve) is on.
    var decor: [String] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        neutralName = c.v("neutralName", neutralName)
        eveDays = c.int("eveDays", 0)
        eventThemeId = c.opt("eventThemeId")
        happeningTag = c.opt("happeningTag")
        decor = c.v("decor", [])
        art = c.v("art", art)
        hijri = c.v("calendar", "gregorian") == "hijri"
        start = c.v("start", MonthDay())
        end = c.v("end", MonthDay())
        extraEndDays = c.int("extraEndDays", 0)
        effects = c.v("effects", [])
        windows = c.v("activeWindows", [])
        dailyClaim = c.v("dailyClaim", [])
        collectible = c.opt("collectible")
        storySceneId = c.opt("storySceneId")
    }
}

struct FestivalsFile: Decodable {
    var lat: Double = 31.78
    var lon: Double = 35.23
    var quietDates: [String] = []
    var festivals: [FestivalDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        if let r = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("sunsetRef")) {
            lat = r.dbl("lat", lat)
            lon = r.dbl("lon", lon)
        }
        quietDates = c.v("quietDates", [])
        festivals = c.v("festivals", [])
    }
}

struct InspectorCheckDef: Decodable {
    var id = ""
    var name = GText("")
    var full: Double = 2.5
    var partial: Double = 1.5

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        full = c.dbl("full", 2.5)
        partial = c.dbl("partial", 1.5)
    }
}

struct InspectorBandDef: Decodable {
    var minScore: Double = 0
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        minScore = c.dbl("minScore", 0)
        rewards = c.v("rewards", [])
    }
}

struct InspectorFile: Decodable {
    var intervalDays: [Double] = [4, 6, 8]
    var hourRange: [Double] = [10, 20]
    var warningHours: Double = 12
    var checks: [InspectorCheckDef] = []
    var bands: [InspectorBandDef] = []
    var xpPerPoint: Double = 4
    var repPerPoint: Double = 2

    init() {}

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: AnyKey.self)
        guard let c = try? root.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("inspector")) else { return }
        intervalDays = c.v("intervalDays", intervalDays)
        hourRange = c.v("hourRange", hourRange)
        warningHours = c.dbl("warningHours", warningHours)
        checks = c.v("checks", [])
        bands = c.v("rewardBands", [])
        xpPerPoint = c.dbl("xpPerPoint", xpPerPoint)
        repPerPoint = c.dbl("repPerPoint", repPerPoint)
    }
}

struct InspectorResult {
    var checks: [(name: String, points: Double)]
    var score: Double
    var lines: [RewardLine]
}

// MARK: - Festivals (GDD 6.11)

extension GameStore {
    var fx_: FestivalsFile { cat.festivals }

    func festivalActive(_ f: FestivalDef, at t: Double) -> Bool {
        let base = t - 4 * 3600
        for back in 0...max(0, f.extraEndDays) {
            let d = Date(timeIntervalSince1970: base - Double(back) * 86400)
            let cal = Calendar(identifier: f.hijri ? .islamicUmmAlQura : .gregorian)
            let comps = cal.dateComponents([.month, .day], from: d)
            let x = (comps.month ?? 1) * 100 + (comps.day ?? 1)
            let a = f.start.month * 100 + f.start.day
            let b = f.end.month * 100 + f.end.day
            let inside = a <= b ? (x >= a && x <= b) : (x >= a || x <= b)
            if inside && (back == 0 || f.extraEndDays > 0) { return true }
        }
        return false
    }

    var activeFestivals: [FestivalDef] {
        if let id = demoFestivalId { return fx_.festivals.filter { $0.id == id } }
        let d = dayNum
        if festCacheDay == d { return festCache }
        let list = fx_.festivals.filter { festivalActive($0, at: now()) }
        festCacheDay = d
        festCache = list
        return list
    }

    // MARK: Decorations and "زينة المواسم" (GDD 6.11)

    var decorOn: Bool { s.settings.seasonDecor }

    func festivalName(_ f: FestivalDef) -> String { decorOn ? t(f.name) : t(f.neutralName) }

    func festivalArt(_ f: FestivalDef) -> String { decorOn ? f.art : "ui_sparkles" }

    /// The festival dressing the street today: an active one, or one whose eve has started.
    var decorFestival: FestivalDef? {
        guard decorOn else { return nil }
        let d = dayNum
        if festDecorDay != d || demoFestivalId != nil {
            festDecorDay = d
            let live = activeFestivals.first { !$0.decor.isEmpty }
            festDecorCache = live ?? fx_.festivals.first { f in
                f.eveDays > 0 && !f.decor.isEmpty && festivalActive(f, at: now() + Double(f.eveDays) * 86400)
            }
        }
        return festDecorCache
    }

    var streetDecor: [String] { decorFestival?.decor ?? [] }

    /// Festival that picks the weekend venue theme for the week starting on game day `weekStart`.
    func festivalTheme(weekStart: Int) -> EventThemeDef? {
        guard decorOn else { return nil }
        let key = "\(weekStart)." + (demoFestivalId ?? "")
        if festThemeKey != key {
            festThemeKey = key
            festThemeCache = nil
            let thursday = now() + Double(weekStart + 3 - dayNum) * 86400
            for f in fx_.festivals where demoFestivalId == f.id || (demoFestivalId == nil && festivalActive(f, at: thursday)) {
                let id = cat.events.festivalOverrides.first { $0.festivalId == f.id }?.themeId ?? f.eventThemeId
                if let id = id, cat.theme(id) != nil {
                    festThemeCache = id
                    break
                }
            }
        }
        return festThemeCache.flatMap { cat.theme($0) }
    }

    func festivalChoiceOpen(_ ids: [String]) -> Bool {
        guard decorOn else { return false }
        return activeFestivals.contains { ids.contains($0.id) || ids.contains($0.happeningTag ?? "") }
    }

    /// Festival day effects for a station (part of category 10).
    func festivalDayMult(_ d: StationDef) -> Double {
        var m = 1.0
        for f in activeFestivals {
            for e in f.effects where e.type == "incomeMult" {
                switch e.scopeKind {
                case "category": if d.category == e.scopeValue { m *= e.mult }
                case "cuisine": if d.cuisine == e.scopeValue { m *= e.mult }
                case "weatherTag": if d.weather == e.scopeValue { m *= e.mult }
                default: m *= e.mult
                }
            }
        }
        return m
    }

    var ramadan: Bool { activeFestivals.contains { $0.id == "ramadan" } }

    /// Approximate sunset (NOAA) at the reference point, as a Unix time on the day of t.
    func sunset(at t: Double) -> Double {
        let cal = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: t)
        let n = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let g = 2 * Double.pi / 365 * (n - 1)
        let eq = 229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g) - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
        let decl = 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2 * g) + 0.000907 * sin(2 * g)
            - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)
        let lat = fx_.lat * Double.pi / 180
        let zen = 90.833 * Double.pi / 180
        let cosHa = cos(zen) / (cos(lat) * cos(decl)) - tan(lat) * tan(decl)
        let ha = acos(max(-1, min(1, cosHa))) * 180 / Double.pi
        let minutesUTC = 720 - 4 * (fx_.lon - ha) - eq
        var utc = cal
        utc.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        let midnightUTC = utc.startOfDay(for: date).timeIntervalSince1970
        return midnightUTC + minutesUTC * 60
    }

    /// Festival foreground windows (iftar, suhoor), part of category 11.
    var festivalActiveMult: Double {
        var m = 1.0
        let t = now()
        for f in activeFestivals {
            for w in f.windows {
                switch w.kind {
                case "iftar":
                    let ss = sunset(at: t)
                    if t >= ss + w.startOffsetMin * 60 && t <= ss + w.endOffsetMin * 60 { m *= w.mult }
                default:
                    let h = Clock.secondsOfDay(t) / 3600
                    if h >= w.startHour && h < w.endHour { m *= w.mult }
                }
            }
        }
        return m
    }

    var iftarNow: Bool {
        guard ramadan else { return false }
        let t = now()
        let ss = sunset(at: t)
        return t >= ss - 600 && t <= ss + 80 * 60
    }

    func festivalClaimReady(_ f: FestivalDef) -> Bool {
        (!f.dailyClaim.isEmpty || f.collectible != nil) && s.daily.festivalClaims[f.id] != dayNum
    }

    func claimFestival(_ f: FestivalDef) {
        guard festivalClaimReady(f) else { return }
        s.daily.festivalClaims[f.id] = dayNum
        var lines: [RewardLine] = []
        for r in f.dailyClaim { if let l = applyReward(r) { lines.append(l) } }
        if let c = f.collectible {
            let key = "collect." + c.id
            bump(key)
            let n = Int(metric(key))
            lines.append(RewardLine(art: c.art, amount: Num.frac(n, c.count), caption: t(c.name)))
            for m in c.rawMilestones where m.count == n {
                for r in m.rewards { if let l = applyReward(r) { lines.append(l) } }
            }
        }
        bump("festivals")
        enqueue(.rewards(title: t(f.name), lines: lines))
        Feedback.play(.t2)
        save()
    }

    // MARK: Inspector (GDD 6.12)

    var ix: InspectorFile { cat.inspector }

    func scheduleInspector(from t: Double) {
        var r = Seed.rng("inspector", ["\(s.happenings.inspectorVisits)"], player: s.meta.seed)
        let a = ix.intervalDays.first ?? 4
        let c = ix.intervalDays.count > 1 ? ix.intervalDays[1] : 6
        let b = ix.intervalDays.last ?? 8
        let u = r.unit()
        let fc = (c - a) / max(0.001, b - a)
        let days = u < fc ? a + sqrt(u * (b - a) * (c - a)) : b - sqrt((1 - u) * (b - a) * (b - c))
        let lo = ix.hourRange.first ?? 10
        let hi = ix.hourRange.last ?? 20
        let hour = lo + r.unit() * (hi - lo)
        let dayStart = Clock.midnight(t + days * 86400)
        s.happenings.inspectorAt = dayStart + hour * 3600
    }

    var inspectorWarning: Bool {
        guard unlocked("inspector"), s.happenings.inspectorAt > 0 else { return false }
        let left = s.happenings.inspectorAt - now()
        return left > 0 && left < ix.warningHours * 3600
    }

    func tickInspector() {
        guard unlocked("inspector") else { return }
        if s.happenings.inspectorAt <= 0 {
            scheduleInspector(from: now())
            return
        }
        guard now() >= s.happenings.inspectorAt, kitchenVisible else { return }
        let res = inspect()
        s.happenings.inspectorVisits += 1
        scheduleInspector(from: now())
        enqueue(.inspector(score: res.score, lines: res.lines, checks: res.checks.map { $0.name + ": " + String(format: "%.1f", $0.points) }))
        save()
    }

    func inspect() -> InspectorResult {
        let tNow = now()
        var checks: [(name: String, points: Double)] = []
        let open = s.city.stations.filter { $0.level > 0 }.count
        let total = max(1, s.city.stations.count)
        for c in ix.checks {
            var p = 0.0
            switch c.id {
            case "managers":
                let ratio = Double(managersCount) / Double(max(1, open))
                p = ratio >= 1 ? c.full : (ratio >= 0.75 ? c.partial : 0)
            case "chefs":
                p = s.chefs.equipped.count >= max(1, chefSlots) ? c.full : (s.chefs.equipped.isEmpty ? 0 : c.partial)
            case "stall":
                p = stallTier >= 5 ? c.full : (stallTier >= 3 ? c.partial : 0)
            case "customers":
                let n = s.happenings.specialTimes.filter { tNow - $0 < 86400 }.count
                p = n >= 3 ? c.full : (n >= 1 ? c.partial : 0)
            case "vault":
                let age = tNow - s.happenings.lastVaultCollect
                p = age < 12 * 3600 ? c.full : (age < 24 * 3600 ? c.partial : 0)
            default:
                let ratio = Double(open) / Double(total)
                p = ratio >= 1 ? c.full : (ratio >= 0.75 ? c.partial : 0)
            }
            checks.append((name: t(c.name), points: p))
        }
        let score = checks.reduce(0) { $0 + $1.points }
        var lines: [RewardLine] = []
        if let band = ix.bands.filter({ score >= $0.minScore }).max(by: { $0.minScore < $1.minScore }) {
            for r in band.rewards { if let l = applyReward(r) { lines.append(l) } }
        }
        addXP(Int(ix.xpPerPoint * score))
        bump("rep", ix.repPerPoint * score)
        return InspectorResult(checks: checks, score: score, lines: lines)
    }
}
