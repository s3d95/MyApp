import Foundation

// MARK: - Research (research.json)

struct NodeReq: Decodable {
    var nodeId = ""
    var level = 1

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        nodeId = c.v("nodeId", "")
        level = c.int("level", 1)
    }
}

struct ResearchNodeDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var branch = "kitchen"
    var art = "ui_notebook"
    var effectType = ""
    var perLevel: Double = 0
    var maxLevel = 1
    var unlockLevel = 7
    var requires: [NodeReq] = []
    var timeMult: Double = 1
    var costMin: Double = 2
    var desc = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        branch = c.v("branch", branch)
        art = c.v("art", art)
        if let e = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("effect")) {
            effectType = e.v("type", "")
            perLevel = e.dbl("perLevel", 0)
        }
        maxLevel = c.int("maxLevel", 1)
        unlockLevel = c.int("unlockLevel", 7)
        requires = c.v("requires", [])
        timeMult = c.dbl("timeMult", 1)
        costMin = c.dbl("costMin", 2)
        desc = c.v("desc", GText(""))
    }
}

struct ResearchFile: Decodable {
    var baseMinutes: Double = 10
    var growth: Double = 1.5
    var capHours: Double = 24
    var costFloorFracOfFinal: Double = 1e-6
    var slotsByLevel: [SlotRow] = []
    var nodes: [ResearchNodeDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        baseMinutes = c.dbl("baseMinutes", baseMinutes)
        growth = c.dbl("growth", growth)
        capHours = c.dbl("capHours", capHours)
        costFloorFracOfFinal = c.dbl("costFloorFracOfFinal", costFloorFracOfFinal)
        slotsByLevel = c.v("slotsByLevel", [])
        nodes = c.v("nodes", [])
    }
}

// MARK: - Supply runs and heritage (vehicles.json, heritage.json)

struct VehicleDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "veh_tractor"
    var tier = 0
    var unlockLevel = 8
    var afterVehicle: String? = nil
    var afterLaunches = 0
    var durationsMin: [Double] = [20, 60, 120]
    var rolls: [Int] = [2, 3, 4]
    var rarityWeights: [String: Double] = [:]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        tier = c.int("tier", 0)
        unlockLevel = c.int("unlockLevel", 8)
        if let a = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("unlockAfter")) {
            afterVehicle = a.opt("vehicleId")
            afterLaunches = a.int("launches", 0)
        }
        durationsMin = c.v("durationsMin", durationsMin)
        rolls = c.v("rolls", rolls)
        rarityWeights = c.v("rarityWeights", [:])
    }
}

struct VehiclesFile: Decodable {
    var slotsByLevel: [SlotRow] = []
    var starLaunches: [Int] = [4, 10, 25]
    var starRollsPct: Double = 0.15
    var star3CommonToEpic: Double = 0.02
    var rollKinds: [String: Double] = ["heritage": 0.7, "chefCards": 0.2, "gold": 0.07, "woodChest": 0.03]
    var cardsPerRarity: [String: Int] = ["common": 3, "rare": 2, "epic": 1, "legendary": 1]
    var goldPerRarity: [String: Int] = ["common": 2, "rare": 4, "epic": 7, "legendary": 10]
    var unownedItemWeight: Double = 2
    var vehicles: [VehicleDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        slotsByLevel = c.v("slotsByLevel", [])
        starLaunches = c.v("starLaunches", starLaunches)
        starRollsPct = c.dbl("starRollsPct", starRollsPct)
        star3CommonToEpic = c.dbl("star3CommonToEpic", star3CommonToEpic)
        rollKinds = c.v("rollKinds", rollKinds)
        cardsPerRarity = c.v("cardsPerRarity", cardsPerRarity)
        goldPerRarity = c.v("goldPerRarity", goldPerRarity)
        unownedItemWeight = c.dbl("unownedItemWeight", unownedItemWeight)
        vehicles = c.v("vehicles", [])
    }
}

struct HeritageSetDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var art = "ui_old_key"
    var bonusType = ""
    var bonusBase: Double = 0
    var itemIds: [String] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        if let b = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("bonus")) {
            bonusType = b.v("type", "")
            bonusBase = b.dbl("base", 0)
        }
        itemIds = c.v("itemIds", [])
    }
}

struct HeritageItemDef: Decodable, Identifiable {
    var id = ""
    var setId = ""
    var name = GText("")
    var art = "ui_old_key"
    var rarityRaw = "common"
    var desc = GText("")

    var rarity: Rarity { Rarity(rawValue: rarityRaw) ?? .common }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        setId = c.v("setId", "")
        name = c.v("name", GText(id))
        art = c.v("art", art)
        rarityRaw = c.v("rarity", "common")
        desc = c.v("desc", GText(""))
    }
}

struct HeritageFile: Decodable {
    var copiesToLevel: [Int] = [2, 3, 4, 5]
    var maxLevel = 5
    var setLevelFactor: Double = 0.5
    var craftUnlockLevel = 19
    var salvage: [String: Int] = ["common": 1, "rare": 3, "epic": 8, "legendary": 20]
    var craftCost: [String: Int] = ["common": 10, "rare": 30, "epic": 80, "legendary": 200]
    var sets: [HeritageSetDef] = []
    var items: [HeritageItemDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        copiesToLevel = c.v("copiesToLevel", copiesToLevel)
        maxLevel = c.int("maxLevel", maxLevel)
        setLevelFactor = c.dbl("setLevelFactor", setLevelFactor)
        if let cr = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("craft")) {
            craftUnlockLevel = cr.int("unlockLevel", craftUnlockLevel)
            salvage = cr.v("salvage", salvage)
            craftCost = cr.v("cost", craftCost)
        }
        sets = c.v("sets", [])
        items = c.v("items", [])
    }
}
