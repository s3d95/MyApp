import Foundation

// MARK: - Daily and weekly orders (quests.json), calendar and streak (calendar.json)

struct BandDef: Decodable {
    var id = 1
    var minLevel = 0
    var maxLevel = 999

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.int("id", 1)
        minLevel = c.int("minLevel", 0)
        maxLevel = c.int("maxLevel", 999)
    }
}

struct QuestTemplate: Decodable, Identifiable {
    var id = ""
    var text = GText("")
    var metric = ""
    var difficulty = "easy"
    var targets: [Double] = [1]
    var eligibility = "always"
    var requiresSystem: String? = nil
    var minLevel = 0

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        text = c.v("text", GText(""))
        metric = c.v("metric", "")
        difficulty = c.v("difficulty", "easy")
        targets = c.v("targets", [1])
        eligibility = c.v("eligibility", "always")
        if let cond = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("condition")) {
            requiresSystem = cond.opt("requiresSystem")
            minLevel = cond.int("minLevel", 0)
        }
    }
}

struct QuestsFile: Decodable {
    var unlockLevel = 9
    var bands: [BandDef] = []
    var dailyReward: [Reward] = []
    var dailyBonus: [Reward] = []
    var weeklyReward: [Reward] = []
    var weeklyBonus: [Reward] = []
    var rerollFree = 1
    var rerollCost = 5
    var rerollMax = 3
    var daily: [QuestTemplate] = []
    var weekly: [QuestTemplate] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        unlockLevel = c.int("unlockLevel", 9)
        bands = c.v("bands", [])
        dailyReward = c.v("dailyReward", [])
        dailyBonus = c.v("dailyBonus", [])
        weeklyReward = c.v("weeklyReward", [])
        weeklyBonus = c.v("weeklyBonus", [])
        if let r = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("reroll")) {
            rerollFree = r.int("freePerDay", 1)
            rerollCost = r.int("cost", 5)
            rerollMax = r.int("maxPerDay", 3)
        }
        daily = c.v("daily", [])
        weekly = c.v("weekly", [])
    }
}

struct CalendarDayDef: Decodable {
    var day = 1
    var rewards: [Reward] = []
    var big = false

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        day = c.int("day", 1)
        rewards = c.v("rewards", [])
        big = c.v("big", false)
    }
}

struct StreakMilestoneDef: Decodable {
    var days = 3
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        days = c.int("days", 3)
        rewards = c.v("rewards", [])
    }
}

struct CalendarFile: Decodable {
    var unlockLevel = 9
    var days: [CalendarDayDef] = []
    var goldScalePerCycle: Double = 0.1
    var goldScaleMax: Double = 2
    var milestones: [StreakMilestoneDef] = []
    var freezeCaps: [(level: Int, cap: Int)] = [(9, 2), (45, 3)]
    var freezePrice = 50
    var repairOrders = 6
    var repairDays = 2
    var repairBonusDays = 2

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        unlockLevel = c.int("unlockLevel", 9)
        days = c.v("days", [])
        goldScalePerCycle = c.dbl("goldScalePerCycle", goldScalePerCycle)
        goldScaleMax = c.dbl("goldScaleMax", goldScaleMax)
        if let st = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("streak")) {
            milestones = st.v("milestones", [])
            let caps: [SlotRowCap] = st.v("freezeCaps", [])
            if !caps.isEmpty { freezeCaps = caps.map { ($0.level, $0.cap) } }
            freezePrice = st.int("freezePrice", freezePrice)
            if let r = try? st.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("repair")) {
                repairOrders = r.int("orders", repairOrders)
                repairDays = r.int("days", repairDays)
                repairBonusDays = r.int("bonusDays", repairBonusDays)
            }
        }
    }
}

struct SlotRowCap: Decodable {
    var level = 0
    var cap = 2

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", 0)
        cap = c.int("cap", 2)
    }
}
