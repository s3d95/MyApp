import Foundation

// MARK: - Side kitchens: catering contracts (contracts.json) and the weekend venue (events.json)

struct SideStationDef: Decodable, Identifiable {
    var key = ""
    var name = GText("")
    var art = "food_falafel"
    var tier = 0
    var cuisine = ""
    var category = ""
    var weather = "none"

    var id: String { key }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        key = c.v("key", "")
        name = c.v("name", GText(key))
        art = c.v("art", art)
        tier = c.int("tier", 0)
        cuisine = c.v("cuisine", "")
        category = c.v("category", "")
        weather = c.v("weather", "none")
    }
}

struct PartnerDef: Decodable {
    var nameKey: String? = nil
    var name: GText? = nil
    var art = "ppl_man"
    var share: Double = 0.1
    var gamma: Double = 1

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        nameKey = c.opt("nameKey")
        name = c.opt("name")
        art = c.v("art", art)
        share = c.dbl("share", share)
        gamma = c.dbl("gamma", gamma)
    }
}

struct ContractDef: Decodable, Identifiable {
    var id = ""
    var releaseOrder = 1
    var title = GText("")
    var art = "ui_clipboard"
    var desc = GText("")
    var durationHours: Double = 48
    var stations: [SideStationDef] = []
    var goalsBase: [Double] = [1e9, 1e10, 1e11]
    var partners: [PartnerDef] = []
    var rules: [String] = []
    var goal1: [Reward] = []
    var goal2: [Reward] = []
    var goal3: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        releaseOrder = c.int("releaseOrder", 1)
        title = c.v("title", GText(id))
        art = c.v("art", art)
        desc = c.v("desc", GText(""))
        durationHours = c.dbl("durationHours", 48)
        stations = c.v("stations", [])
        goalsBase = c.v("goalsBase", goalsBase)
        partners = c.v("partners", [])
        rules = c.v("rules", [])
        if let r = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("rewards")) {
            goal1 = r.v("goal1", [])
            goal2 = r.v("goal2", [])
            goal3 = r.v("goal3", [])
        }
    }
}

struct ContractsFile: Decodable {
    var epoch = "2026-01-05"
    var availabilityDays = 7
    var boardMax = 3
    var slotsByLevel: [SlotRow] = []
    var contracts: [ContractDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        if let s = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("schedule")) {
            epoch = s.v("epoch", epoch)
            availabilityDays = s.int("availabilityDays", availabilityDays)
            boardMax = s.int("boardMax", boardMax)
        }
        slotsByLevel = c.v("slotsByLevel", [])
        let list: [ContractDef] = c.v("contracts", [])
        contracts = list.sorted { $0.releaseOrder < $1.releaseOrder }
    }
}

struct NamedArt: Decodable {
    var name = GText("")
    var art = "ui_money_bag"

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        name = c.v("name", GText(""))
        art = c.v("art", art)
    }
}

struct EventThemeDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "ui_party_popper"
    var palette = PaletteDef()
    var cash = NamedArt()
    var tokens = NamedArt()
    var stations: [SideStationDef] = []
    var chefId = ""
    var festivalOnly = false

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        palette = c.v("palette", PaletteDef())
        cash = c.v("eventCash", NamedArt())
        tokens = c.v("tokens", NamedArt())
        stations = c.v("stations", [])
        chefId = c.v("chefId", "")
        festivalOnly = c.v("festivalOnly", false)
    }
}

struct EventMilestoneDef: Decodable {
    var base: Double = 1e4
    var rewards: [Reward] = []
    var unlocksStation: Int? = nil

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        base = c.dbl("base", base)
        rewards = c.v("rewards", [])
        unlocksStation = c.intOpt("unlocksStation")
    }
}

struct RankRewardDef: Decodable {
    var fromRank = 1
    var toRank = 1
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        fromRank = c.int("fromRank", 1)
        toRank = c.int("toRank", 1)
        rewards = c.v("rewards", [])
    }
}

struct EventShopItemDef: Decodable, Identifiable {
    var id = ""
    var reward = Reward(type: "gold")
    var price = 10
    var max = 1

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        reward = c.v("reward", Reward(type: "gold"))
        price = c.int("price", 10)
        max = c.int("max", 1)
    }
}

struct EventsFile: Decodable {
    var rotation: [String] = []
    var milestones: [EventMilestoneDef] = []
    var rankRewards: [RankRewardDef] = []
    var npcCount = 20
    var npcSigma: Double = 0.6
    var tokensPerGold = 5
    var maxGold = 20
    var shop: [EventShopItemDef] = []
    var themes: [EventThemeDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        rotation = c.v("rotation", [])
        milestones = c.v("milestones", [])
        rankRewards = c.v("rankRewards", [])
        npcCount = c.int("npcCount", npcCount)
        npcSigma = c.dbl("npcSigma", npcSigma)
        if let t = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("tokenConversion")) {
            tokensPerGold = t.int("tokensPerGold", tokensPerGold)
            maxGold = t.int("maxGold", maxGold)
        }
        shop = c.v("shop", [])
        themes = c.v("themes", [])
    }
}

struct GradeDef: Decodable {
    var id = 1
    var name = GText("سهل")
    var minLevel = 0
    var targetFactor: Double = 1
    var goldMult: Double = 1
    var xpMult: Double = 1
    var goal1Chest = "wood"

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.int("id", 1)
        name = c.v("name", GText("سهل"))
        minLevel = c.int("minLevel", 0)
        targetFactor = c.dbl("targetFactor", 1)
        goldMult = c.dbl("goldMult", 1)
        xpMult = c.dbl("xpMult", 1)
        goal1Chest = c.v("goal1Chest", "wood")
    }
}

struct SideEconomyDef: Decodable {
    var tiers: [TierRow] = []
    var milestones: [Int] = [10, 25, 50, 75, 100, 125, 150]
    var allMilestones: [Int] = [25, 50, 100, 150]
    var cap = 150
    var startCash: Double = 20
    var upgradeBase: Double = 20000
    var upgradeRatio: Double = 30
    var grades: [GradeDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        tiers = c.v("sideTiers", [])
        milestones = c.v("sideStationMilestones", milestones)
        allMilestones = c.v("sideAllStationMilestones", allMilestones)
        cap = c.int("sideLevelCap", cap)
        startCash = c.dbl("sideStartCash", startCash)
        if let u = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("sideUpgrades")) {
            upgradeBase = u.dbl("base", upgradeBase)
            upgradeRatio = u.dbl("ratio", upgradeRatio)
        }
        grades = c.v("grades", [])
    }

    func tier(_ i: Int) -> TierRow {
        guard !tiers.isEmpty else { return TierRow() }
        return tiers[max(0, min(tiers.count - 1, i))]
    }
}
