import Foundation
import SwiftUI

// MARK: - Tolerant decoding helpers

/// A string coding key so decoders can read any field by name.
struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(_ s: String) { stringValue = s }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

extension KeyedDecodingContainer where K == AnyKey {
    /// Decodes `key` or returns `def` when the field is missing or malformed.
    func v<T: Decodable>(_ key: String, _ def: T) -> T {
        (try? decodeIfPresent(T.self, forKey: AnyKey(key))) ?? def
    }

    func opt<T: Decodable>(_ key: String) -> T? {
        try? decodeIfPresent(T.self, forKey: AnyKey(key))
    }

    /// Integers may arrive as 5 or 5.0.
    func int(_ key: String, _ def: Int) -> Int {
        if let i = try? decodeIfPresent(Int.self, forKey: AnyKey(key)) { return i }
        if let d = try? decodeIfPresent(Double.self, forKey: AnyKey(key)), d.isFinite { return Int(d) }
        return def
    }

    func intOpt(_ key: String) -> Int? {
        if let i = try? decodeIfPresent(Int.self, forKey: AnyKey(key)) { return i }
        if let d = try? decodeIfPresent(Double.self, forKey: AnyKey(key)), d.isFinite { return Int(d) }
        return nil
    }

    func dbl(_ key: String, _ def: Double) -> Double {
        if let d = try? decodeIfPresent(Double.self, forKey: AnyKey(key)) { return d }
        return def
    }

    func dblOpt(_ key: String) -> Double? {
        try? decodeIfPresent(Double.self, forKey: AnyKey(key))
    }
}

enum AddressForm: String, Codable {
    case m, f
}

/// Gendered text: a plain JSON string or { "m": …, "f": … }.
struct GText: Decodable {
    var m: String = ""
    var f: String = ""

    init(_ s: String) {
        m = s
        f = s
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let s = try? single.decode(String.self) {
            m = s
            f = s
            return
        }
        let c = try decoder.container(keyedBy: AnyKey.self)
        m = c.v("m", "")
        f = c.v("f", m)
        if m.isEmpty { m = f }
    }

    func s(_ form: AddressForm) -> String { form == .f ? f : m }
}

// MARK: - Economy

struct TierRow: Decodable {
    var baseCost: Double = 5
    var growth: Double = 1.1
    var baseCycleSec: Double = 1
    var baseRevenue: Double = 1
    var managerMult: Double = 100

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        baseCost = c.dbl("baseCost", baseCost)
        growth = c.dbl("growth", growth)
        baseCycleSec = c.dbl("baseCycleSec", baseCycleSec)
        baseRevenue = c.dbl("baseRevenue", baseRevenue)
        managerMult = c.dbl("managerMult", managerMult)
    }
}

struct LevelCapRow: Decodable {
    var fromCity = 1
    var toCity = 24
    var cap = 100

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        fromCity = c.int("fromCity", 1)
        toCity = c.int("toCity", 24)
        cap = c.int("cap", 100)
    }
}

struct OfflineDef: Decodable {
    var baseCapHours: Double = 3
    var maxCapHours: Double = 16
    var baseEff: Double = 0.5
    var minGapSec: Double = 60
    var doubleGoldPerHour: Double = 10
    var doubleMin: Double = 5
    var doubleMax: Double = 160

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        baseCapHours = c.dbl("baseCapHours", baseCapHours)
        maxCapHours = c.dbl("maxCapHours", maxCapHours)
        baseEff = c.dbl("baseEff", baseEff)
        minGapSec = c.dbl("minGapSec", minGapSec)
        doubleGoldPerHour = c.dbl("doubleGoldPerHour", doubleGoldPerHour)
        doubleMin = c.dbl("doubleMin", doubleMin)
        doubleMax = c.dbl("doubleMax", doubleMax)
    }
}

struct FreshDoughDef: Decodable {
    var minGapHours: Double = 24
    var minutesPerDay: Double = 30
    var maxDays: Double = 3
    var mult: Double = 2

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        minGapHours = c.dbl("minGapHours", minGapHours)
        minutesPerDay = c.dbl("minutesPerDay", minutesPerDay)
        maxDays = c.dbl("maxDays", maxDays)
        mult = c.dbl("mult", mult)
    }
}

struct BoostsDef: Decodable {
    var rushHourMult: Double = 2
    var rushWindows: [[Int]] = [[12, 14], [19, 22]]
    var frenzyMult: Double = 5
    var frenzySec: Double = 60
    var activeCap: Double = 50
    var dayCap: Double = 5

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        rushHourMult = c.dbl("rushHourMult", rushHourMult)
        rushWindows = c.v("rushWindows", rushWindows)
        frenzyMult = c.dbl("frenzyMult", frenzyMult)
        frenzySec = c.dbl("frenzySec", frenzySec)
        activeCap = c.dbl("activeCap", activeCap)
        dayCap = c.dbl("dayCap", dayCap)
    }
}

struct BranchesDef: Decodable {
    var goldPerDayBase: Double = 0.5
    var goldPerLevel: Double = 0.2
    var softcapKnee: Double = 10
    var softcapCoef: Double = 2
    var safeCapHours: Double = 8
    var incomePerBranch: Double = 0.1
    var incomePerLevel: Double = 0.02
    var maxLevel: Int = 10
    var upgradeCosts: [Int] = [20, 45, 80, 125, 180, 245, 320, 405, 500, 605]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        goldPerDayBase = c.dbl("goldPerDayBase", goldPerDayBase)
        goldPerLevel = c.dbl("goldPerLevel", goldPerLevel)
        softcapKnee = c.dbl("softcapKnee", softcapKnee)
        softcapCoef = c.dbl("softcapCoef", softcapCoef)
        safeCapHours = c.dbl("safeCapHours", safeCapHours)
        incomePerBranch = c.dbl("incomePerBranch", incomePerBranch)
        incomePerLevel = c.dbl("incomePerLevel", incomePerLevel)
        maxLevel = c.int("maxLevel", maxLevel)
        upgradeCosts = c.v("upgradeCosts", upgradeCosts)
    }
}

struct XPDef: Decodable {
    var perStar: Double = 10
    var cityBonusPerIndex: Double = 0.1
    var stationMilestone: Int = 2
    var stationUnlock: Int = 4
    var managerHire: Int = 2
    var graduationPerIndex: Int = 50
    var special: Int = 2

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        perStar = c.dbl("perStar", perStar)
        cityBonusPerIndex = c.dbl("cityBonusPerIndex", cityBonusPerIndex)
        stationMilestone = c.int("stationMilestone", stationMilestone)
        stationUnlock = c.int("stationUnlock", stationUnlock)
        managerHire = c.int("managerHire", managerHire)
        graduationPerIndex = c.int("graduationPerIndex", graduationPerIndex)
        special = c.int("special", special)
    }
}

struct EconomyDef: Decodable {
    var cityTiers: [TierRow] = []
    var stationMilestones: [Int] = [10, 25, 50, 100, 150, 200, 250, 300, 350, 400]
    var allStationMilestones: [Int] = [25, 50, 100, 150, 200, 250, 300, 400]
    var milestoneMult: Double = 2
    var cycleFloorSec: Double = 0.5
    var levelCaps: [LevelCapRow] = []
    var upgradeMult: Double = 3
    var cityStartCashBase: Double = 50
    var offline = OfflineDef()
    var freshDough = FreshDoughDef()
    var boosts = BoostsDef()
    var branches = BranchesDef()
    var xp = XPDef()

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        cityTiers = c.v("cityTiers", cityTiers)
        stationMilestones = c.v("stationMilestones", stationMilestones)
        allStationMilestones = c.v("allStationMilestones", allStationMilestones)
        milestoneMult = c.dbl("milestoneMult", milestoneMult)
        cycleFloorSec = c.dbl("cycleFloorSec", cycleFloorSec)
        levelCaps = c.v("levelCaps", levelCaps)
        upgradeMult = c.dbl("upgradeMult", upgradeMult)
        cityStartCashBase = c.dbl("cityStartCashBase", cityStartCashBase)
        offline = c.v("offline", offline)
        freshDough = c.v("freshDough", freshDough)
        boosts = c.v("boosts", boosts)
        branches = c.v("branches", branches)
        xp = c.v("xp", xp)
    }

    func tier(_ i: Int) -> TierRow {
        guard !cityTiers.isEmpty else { return TierRow() }
        return cityTiers[max(0, min(cityTiers.count - 1, i))]
    }
}

// MARK: - Cities

struct Reward: Decodable {
    var type: String = ""
    var id: String? = nil
    var amount: Double = 1
    var value: Double? = nil
    var rarity: String? = nil

    init(type: String, id: String? = nil, amount: Double = 1, rarity: String? = nil) {
        self.type = type
        self.id = id
        self.amount = amount
        self.rarity = rarity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        type = c.v("type", "")
        id = c.opt("id")
        amount = c.dbl("amount", 1)
        value = c.dblOpt("value")
        rarity = c.opt("rarity")
    }
}

struct CurrencyDef: Decodable {
    var name = GText("جنيه")
    var symbol = ""
    var art = "ui_dollar"

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        name = c.v("name", name)
        symbol = c.v("symbol", "")
        art = c.v("art", art)
    }
}

struct PaletteDef: Decodable {
    var skyTop = "#33172E"
    var skyMid = "#6E2F4A"
    var sunset = "#D9714A"
    var glow = "#FFB36B"
    var accent = "#F9B233"

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        skyTop = c.v("skyTop", skyTop)
        skyMid = c.v("skyMid", skyMid)
        sunset = c.v("sunset", sunset)
        glow = c.v("glow", glow)
        accent = c.v("accent", accent)
    }

    var sky: [Color] { [Color(hexString: skyTop), Color(hexString: skyMid), Color(hexString: sunset), Color(hexString: glow)] }
    var accentColor: Color { Color(hexString: accent) }
}

struct StationDef: Decodable, Identifiable {
    var id = ""
    var key = ""
    var name = GText("")
    var art = "food_falafel"
    var tier = 0
    var cuisine = ""
    var category = ""
    var weather = "none"
    var managerName: GText? = nil
    var managerArt = "ppl_man_cook"

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        key = c.v("key", "")
        name = c.v("name", GText(key))
        art = c.v("art", art)
        tier = c.int("tier", 0)
        cuisine = c.v("cuisine", "")
        category = c.v("category", "")
        weather = c.v("weather", "none")
        managerName = c.opt("managerName")
        managerArt = c.v("managerArt", managerArt)
    }
}

struct UpgradeDef: Decodable, Identifiable {
    var id = ""
    var target = "all"
    var mult: Double = 3
    var priceBase: Double = 0
    var name = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        target = c.v("target", "all")
        mult = c.dbl("mult", 3)
        priceBase = c.dbl("priceBase", 0)
        name = c.v("name", GText(id))
    }
}

struct GoalParams: Decodable {
    var stationId: String? = nil
    var level: Int? = nil
    var count: Int? = nil
    var amountBase: Double? = nil
    var amount: Double? = nil
    var metric: String? = nil

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        stationId = c.opt("stationId")
        level = c.intOpt("level")
        count = c.intOpt("count")
        amountBase = c.dblOpt("amountBase")
        amount = c.dblOpt("amount")
        metric = c.opt("metric")
    }
}

struct GoalDef: Decodable, Identifiable {
    var id = ""
    var type = ""
    var params = GoalParams()
    var stars = 1
    var scope: String? = nil
    var text = GText("")
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        type = c.v("type", "")
        params = c.v("params", GoalParams())
        stars = c.int("stars", 1)
        scope = c.opt("scope")
        text = c.v("text", GText(""))
        rewards = c.v("rewards", [])
    }
}

/// Parameters of every twist type in one tolerant bag (GDD 3.6, SCHEMA 0.8).
struct TwistParams: Decodable {
    var inputStation: String? = nil
    var outputStation: String? = nil
    var ratio: Double = 1
    var outputMult: Double = 3
    var stockCapMin: Double = 60
    var station: String? = nil
    var windowSec: Double = 30
    var perfectMult: Double = 3
    var minCycleSec: Double = 2
    var intervalMin: Double = 20
    var waveMult: Double = 4
    var waveSec: Double = 60
    var stations: [String] = []
    var startHour: Int = 20
    var endHour: Int = 2
    var nightMult: Double = 3
    var intervalHours: Int = 4
    var dockHours: Int = 3
    var targetMin: Double = 30
    var rewardMin: Double = 90
    var offlineRewardFrac: Double = 0.5
    var tripMin: Double = 6
    var scooters: Int = 2
    var queueMax: Int = 5
    var extraScooterCostsBase: [Double] = []
    var dispatcherCostBase: Double = 0
    var hotProb: Double = 0.45
    var coldProb: Double = 0.15
    var rainProb: Double = 0.1
    var hotDayStations: [String] = []
    var coldDayStations: [String] = []
    var rainDayStations: [String] = []
    var mult: Double = 2.5
    var loungeStation: String? = nil
    var specialIntervalMult: Double = 0.5
    var vipShare: Double = 0.6
    var vipTierWeights: [Double] = [0.6, 0.3, 0.1]
    var vipTipMin: Double = 20
    var levelPerTier: Int = 40

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        inputStation = c.opt("inputStation")
        outputStation = c.opt("outputStation")
        ratio = c.dbl("ratio", ratio)
        outputMult = c.dbl("outputMult", outputMult)
        stockCapMin = c.dbl("stockCapMin", stockCapMin)
        station = c.opt("station")
        windowSec = c.dbl("windowSec", windowSec)
        perfectMult = c.dbl("perfectMult", perfectMult)
        minCycleSec = c.dbl("minCycleSec", minCycleSec)
        intervalMin = c.dbl("intervalMin", intervalMin)
        waveMult = c.dbl("waveMult", waveMult)
        waveSec = c.dbl("waveSec", waveSec)
        stations = c.v("stations", stations)
        startHour = c.int("startHour", startHour)
        endHour = c.int("endHour", endHour)
        nightMult = c.dbl("nightMult", nightMult)
        intervalHours = c.int("intervalHours", intervalHours)
        dockHours = c.int("dockHours", dockHours)
        targetMin = c.dbl("targetMin", targetMin)
        rewardMin = c.dbl("rewardMin", rewardMin)
        offlineRewardFrac = c.dbl("offlineRewardFrac", offlineRewardFrac)
        tripMin = c.dbl("tripMin", tripMin)
        scooters = c.int("scooters", scooters)
        queueMax = c.int("queueMax", queueMax)
        extraScooterCostsBase = c.v("extraScooterCostsBase", extraScooterCostsBase)
        dispatcherCostBase = c.dbl("dispatcherCostBase", dispatcherCostBase)
        hotProb = c.dbl("hotProb", hotProb)
        coldProb = c.dbl("coldProb", coldProb)
        rainProb = c.dbl("rainProb", rainProb)
        hotDayStations = c.v("hotDayStations", hotDayStations)
        coldDayStations = c.v("coldDayStations", coldDayStations)
        rainDayStations = c.v("rainDayStations", rainDayStations)
        mult = c.dbl("mult", mult)
        loungeStation = c.opt("loungeStation")
        specialIntervalMult = c.dbl("specialIntervalMult", specialIntervalMult)
        vipShare = c.dbl("vipShare", vipShare)
        vipTierWeights = c.v("vipTierWeights", vipTierWeights)
        vipTipMin = c.dbl("vipTipMin", vipTipMin)
        levelPerTier = c.int("levelPerTier", levelPerTier)
    }
}

enum TwistType: String {
    case productionChain, ovenTiming, busWaves, nightMarket, portShipments, deliveryRuns, weatherSwing, vipLounge, unknown
}

struct TwistDef: Decodable {
    var typeRaw = ""
    var params = TwistParams()

    var type: TwistType { TwistType(rawValue: typeRaw) ?? .unknown }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        typeRaw = c.v("type", "")
        params = c.v("params", TwistParams())
    }
}

struct RivalDef: Decodable {
    var name = GText("")
    var art = "ppl_man_cook"

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        name = c.v("name", name)
        art = c.v("art", art)
    }
}

struct CityDef: Decodable, Identifiable {
    var id = ""
    var index = 1
    var name = GText("")
    var region = "palestine"
    var currency = CurrencyDef()
    var landmarkArt = "bld_mosque"
    var decorArts: [String] = []
    var palette = PaletteDef()
    var silhouette = "oldCity"
    var levelCap = 100
    var licenceHours: Double = 0
    var finalGoalBase: Double = 1e10
    var priceScale: Double = 1
    var starsToGraduate = 0
    var stations: [StationDef] = []
    var upgrades: [UpgradeDef] = []
    var goals: [GoalDef] = []
    var twists: [TwistDef] = []
    var rival = RivalDef()
    var chapterId = ""
    var customerArts: [String] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        index = c.int("index", 1)
        name = c.v("name", GText(id))
        region = c.v("region", region)
        currency = c.v("currency", currency)
        landmarkArt = c.v("landmarkArt", landmarkArt)
        decorArts = c.v("decorArts", [])
        palette = c.v("palette", palette)
        silhouette = c.v("silhouette", silhouette)
        levelCap = c.int("levelCap", 100)
        licenceHours = c.dbl("licenceHours", 0)
        finalGoalBase = c.dbl("finalGoalBase", 1e10)
        priceScale = max(1, c.dbl("priceScale", 1))
        stations = c.v("stations", [])
        upgrades = c.v("upgrades", [])
        goals = c.v("goals", [])
        twists = c.v("twists", [])
        rival = c.v("rival", rival)
        chapterId = c.v("chapterId", "")
        customerArts = c.v("customerArts", [])
        let total = goals.reduce(0) { $0 + $1.stars }
        starsToGraduate = c.int("starsToGraduate", Int((0.75 * Double(total)).rounded(.up)))
    }

    var totalStars: Int { goals.reduce(0) { $0 + $1.stars } }

    func stationIndex(key: String) -> Int? { stations.firstIndex { $0.key == key } }
    func stationIndex(id: String) -> Int? { stations.firstIndex { $0.id == id } }

    var regionName: String {
        switch region {
        case "palestine": return "فلسطين"
        case "arab": return "الوطن العربي"
        default: return "العالم"
        }
    }
}

// MARK: - Levels

struct UnlockDef: Decodable {
    var type = ""
    var id: String? = nil
    var value: Int? = nil

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        type = c.v("type", "")
        id = c.opt("id")
        value = c.intOpt("value")
    }
}

struct LevelRow: Decodable {
    var level = 1
    var unlocks: [UnlockDef] = []
    var rewards: [Reward] = []
    var ceremony = false

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", 1)
        unlocks = c.v("unlocks", [])
        rewards = c.v("rewards", [])
        ceremony = c.v("ceremony", false)
    }
}

struct TitleRow: Decodable {
    var level = 1
    var name = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", 1)
        name = c.v("name", GText(""))
    }
}

struct XPCurve: Decodable {
    var a: Double = 15
    var p: Double = 1.36
    var roundTo: Double = 5
    var after100: Double = 8000

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        a = c.dbl("a", a)
        p = c.dbl("p", p)
        roundTo = c.dbl("roundTo", roundTo)
        after100 = c.dbl("after100", after100)
    }
}

struct LevelsDef: Decodable {
    var xpCurve = XPCurve()
    var levels: [LevelRow] = []
    var titles: [TitleRow] = []
    var beyond100Rewards: [Reward] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        xpCurve = c.v("xpCurve", xpCurve)
        levels = c.v("levels", [])
        titles = c.v("titles", [])
        beyond100Rewards = c.v("beyond100Rewards", [])
    }
}

// MARK: - Story

struct CastDef: Decodable {
    var id = ""
    var name = GText("")
    var art = "ppl_person"

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
    }
}

struct SceneLine: Decodable {
    var speaker = "sitti"
    var text = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        speaker = c.v("speaker", speaker)
        text = c.v("text", GText(""))
    }
}

struct SceneDef: Decodable, Identifiable {
    var id = ""
    var trigger = "manual"
    var triggerFrac: Double? = nil
    var triggerTag: String? = nil
    var lines: [SceneLine] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        trigger = c.v("trigger", "manual")
        triggerFrac = c.dblOpt("triggerParam")
        if triggerFrac == nil { triggerTag = c.opt("triggerParam") }
        lines = c.v("lines", [])
    }
}

struct ChapterDef: Decodable {
    var id = ""
    var cityId = ""
    var scenes: [SceneDef] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        cityId = c.v("cityId", "")
        scenes = c.v("scenes", [])
    }
}

struct StoryDef: Decodable {
    var cast: [CastDef] = []
    var chapters: [ChapterDef] = []
    var extraScenes: [SceneDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        cast = c.v("cast", [])
        chapters = c.v("chapters", [])
        extraScenes = c.v("extraScenes", [])
    }
}

// MARK: - FTUE

struct FtueCond: Decodable {
    var type = ""
    var value: Double? = nil
    var id: String? = nil

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        type = c.v("type", "")
        value = c.dblOpt("value")
        id = c.opt("id")
    }
}

struct FtueStepDef: Decodable {
    var id = 0
    var start = FtueCond()
    var anchors: [String] = []
    var soft = false
    var text = GText("")
    var complete = FtueCond()
    var feedback = ""
    var forceSpecialOutcome: String? = nil

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.int("id", 0)
        start = c.v("start", FtueCond())
        anchors = c.v("anchors", [])
        soft = c.v("soft", false)
        text = c.v("text", GText(""))
        complete = c.v("complete", FtueCond())
        feedback = c.v("feedback", "")
        if let script = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("script")) {
            forceSpecialOutcome = script.opt("forceSpecialOutcome")
        }
    }
}

struct FtueDef: Decodable {
    var steps: [FtueStepDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        steps = c.v("steps", [])
    }
}

// MARK: - Catalog

/// All bundled content, decoded once at launch.
final class Catalog {
    let economy: EconomyDef
    let cities: [CityDef]
    let levels: LevelsDef
    let story: StoryDef
    let ftue: FtueDef
    let chefs: ChefsFile
    let research: ResearchFile
    let vehicles: VehiclesFile
    let heritage: HeritageFile
    let quests: QuestsFile
    let calendar: CalendarFile
    private let scenesById: [String: SceneDef]
    private let chefsById: [String: ChefDef]
    private let castById: [String: CastDef]

    init(economy: EconomyDef, cities: [CityDef], levels: LevelsDef, story: StoryDef, ftue: FtueDef, chefs: ChefsFile,
         research: ResearchFile, vehicles: VehiclesFile, heritage: HeritageFile, quests: QuestsFile, calendar: CalendarFile) {
        self.economy = economy
        self.quests = quests
        self.calendar = calendar
        self.chefs = chefs
        self.research = research
        self.vehicles = vehicles
        self.heritage = heritage
        var byId: [String: ChefDef] = [:]
        for c in chefs.chefs { byId[c.id] = c }
        chefsById = byId
        self.cities = cities.sorted { $0.index < $1.index }
        self.levels = levels
        self.story = story
        self.ftue = ftue
        var scenes: [String: SceneDef] = [:]
        for ch in story.chapters {
            for sc in ch.scenes { scenes[sc.id] = sc }
        }
        for sc in story.extraScenes { scenes[sc.id] = sc }
        scenesById = scenes
        var cast: [String: CastDef] = [:]
        for c in story.cast { cast[c.id] = c }
        castById = cast
    }

    static func load() -> Catalog {
        let economy: EconomyDef = decode("economy") ?? EconomyDef()
        let cities: CitiesFile = decode("cities") ?? CitiesFile()
        let levels: LevelsDef = decode("levels") ?? LevelsDef()
        let story: StoryDef = decode("story") ?? StoryDef()
        let ftue: FtueDef = decode("ftue") ?? FtueDef()
        let chefs: ChefsFile = decode("chefs") ?? ChefsFile()
        let research: ResearchFile = decode("research") ?? ResearchFile()
        let vehicles: VehiclesFile = decode("vehicles") ?? VehiclesFile()
        let heritage: HeritageFile = decode("heritage") ?? HeritageFile()
        let quests: QuestsFile = decode("quests") ?? QuestsFile()
        let calendar: CalendarFile = decode("calendar") ?? CalendarFile()
        return Catalog(economy: economy, cities: cities.cities, levels: levels, story: story, ftue: ftue, chefs: chefs,
                       research: research, vehicles: vehicles, heritage: heritage, quests: quests, calendar: calendar)
    }

    private static func decode<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func city(_ id: String) -> CityDef? { cities.first { $0.id == id } }

    func city(index: Int) -> CityDef? { cities.first { $0.index == index } }

    func scene(_ id: String) -> SceneDef? { scenesById[id] }

    func cast(_ id: String) -> CastDef? { castById[id] }

    func chapter(cityId: String) -> ChapterDef? { story.chapters.first { $0.cityId == cityId } }

    func levelRow(_ level: Int) -> LevelRow? { levels.levels.first { $0.level == level } }

    func chef(_ id: String) -> ChefDef? { chefsById[id] }

    func chest(_ id: String) -> ChestDef? { chefs.chests.first { $0.id == id } }

    func node(_ id: String) -> ResearchNodeDef? { research.nodes.first { $0.id == id } }

    func vehicle(_ id: String) -> VehicleDef? { vehicles.vehicles.first { $0.id == id } }

    func item(_ id: String) -> HeritageItemDef? { heritage.items.first { $0.id == id } }
}

struct CitiesFile: Decodable {
    var cities: [CityDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        cities = c.v("cities", [])
    }
}

extension Color {
    /// "#RRGGBB" from content files.
    init(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0x33172E
        self.init(hex: v)
    }
}

// MARK: - Chefs and chests (chefs.json)

enum Rarity: String, CaseIterable {
    case common, rare, epic, legendary

    var rank: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }

    var name: String {
        switch self {
        case .common: return "عادي"
        case .rare: return "نادر"
        case .epic: return "ملحمي"
        case .legendary: return "أسطوري"
        }
    }
}

struct SkillDef: Decodable {
    var type = ""
    var value: String? = nil
    var magnitude: Double = 2
    var durationSec: Double = 180
    var cooldownMin: Double = 45
    var name = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        type = c.v("type", "")
        value = c.opt("value")
        magnitude = c.dbl("magnitude", magnitude)
        durationSec = c.dbl("durationSec", durationSec)
        cooldownMin = c.dbl("cooldownMin", cooldownMin)
        name = c.v("name", GText(""))
    }
}

struct ChefDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var rarityRaw = "common"
    var art = "ppl_cook"
    var cuisine = ""
    var category = ""
    var source = "chest"
    var skill: SkillDef? = nil
    var bio = GText("")

    var rarity: Rarity { Rarity(rawValue: rarityRaw) ?? .common }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        rarityRaw = c.v("rarity", "common")
        art = c.v("art", art)
        cuisine = c.v("cuisine", "")
        category = c.v("category", "")
        source = c.v("source", "chest")
        skill = c.opt("skill")
        bio = c.v("bio", GText(""))
    }
}

struct ChestDef: Decodable, Identifiable {
    var id = "wood"
    var name = GText("صندوق")
    var art = "ui_gift"
    var stacks = 3
    var cards = 8
    var goldMin = 2
    var goldMax = 5
    var odds: [String: Double] = [:]
    var guarantee: String? = nil
    var price = 50

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", id)
        name = c.v("name", name)
        art = c.v("art", art)
        stacks = c.int("stacks", stacks)
        cards = c.int("cards", cards)
        goldMin = c.int("goldMin", goldMin)
        goldMax = c.int("goldMax", goldMax)
        odds = c.v("odds", odds)
        guarantee = c.opt("guarantee")
        price = c.int("price", price)
    }
}

struct StallOfferDef: Decodable {
    var slot = 1
    var rarity = "common"
    var cards = 10
    var price = 20
    var weekdays: [Int] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        slot = c.int("slot", slot)
        rarity = c.v("rarity", rarity)
        cards = c.int("cards", cards)
        price = c.int("price", price)
        weekdays = c.v("weekdays", [])
    }
}

struct SlotRow: Decodable {
    var level = 4
    var slots = 1

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", level)
        slots = c.int("slots", slots)
    }
}

struct ChefRulesDef: Decodable {
    var rarityBase: [String: Double] = ["common": 0.25, "rare": 0.5, "epic": 1, "legendary": 2]
    var perLevel: Double = 0.25
    var maxLevel = 10
    var bothMatchFactor: Double = 1.5
    var cardsToLevel: [String: [Int]] = [:]
    var goldToLevel: [Int] = [5, 10, 20, 35, 50, 75, 100, 150, 200]
    var surplusGold: [String: Int] = ["common": 1, "rare": 3, "epic": 8, "legendary": 20]
    var slotsByLevel: [SlotRow] = []
    var pityLegendary = 12
    var pityEpicSilver = 5
    var newChefStackChance: Double = 0.35
    var stackWeights: [String: Double] = ["common": 1, "rare": 0.5, "epic": 0.2, "legendary": 0.08]
    var dailyStall: [StallOfferDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        rarityBase = c.v("rarityBase", rarityBase)
        perLevel = c.dbl("perLevel", perLevel)
        maxLevel = c.int("maxLevel", maxLevel)
        bothMatchFactor = c.dbl("bothMatchFactor", bothMatchFactor)
        cardsToLevel = c.v("cardsToLevel", cardsToLevel)
        goldToLevel = c.v("goldToLevel", goldToLevel)
        surplusGold = c.v("surplusGold", surplusGold)
        slotsByLevel = c.v("slotsByLevel", [])
        if let pity = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("pity")) {
            pityLegendary = pity.int("legendaryAfterChests", pityLegendary)
            pityEpicSilver = pity.int("epicAfterSilver", pityEpicSilver)
        }
        newChefStackChance = c.dbl("newChefStackChance", newChefStackChance)
        stackWeights = c.v("stackWeights", stackWeights)
        dailyStall = c.v("dailyStall", [])
    }
}

struct ChefsFile: Decodable {
    var chefs: [ChefDef] = []
    var chests: [ChestDef] = []
    var rules = ChefRulesDef()

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        chefs = c.v("chefs", [])
        chests = c.v("chests", [])
        rules = c.v("rules", ChefRulesDef())
    }
}
