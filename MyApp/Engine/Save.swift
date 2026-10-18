import Foundation

// Save model (GDD 7.1). Every field has a default and decodes tolerantly, so updates never wipe a save.
// Decoders live in extensions so the memberwise/default initializers stay available.

struct StationState: Codable, Equatable {
    var level = 0
    var managed = false
    var progress: Double = 0
    var cooking = false
    var lifetimeEarned: Double = 0
    var milestonesSeen = 0
}

extension StationState {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", level)
        managed = c.v("managed", managed)
        progress = c.dbl("progress", progress)
        cooking = c.v("cooking", cooking)
        lifetimeEarned = c.dbl("lifetimeEarned", lifetimeEarned)
        milestonesSeen = c.int("milestonesSeen", milestonesSeen)
    }
}

struct TwistSave: Codable {
    var chainStock: [Double] = []
    var busWaveLeft: Double = 0
    var busHandledId = 0
    var portDockId = 0
    var portUnits: Double = 0
    var portTarget: Double = 0
    var portLoaded = false
    var deliveryQueue = 0
    var deliveryClock: Double = 0
    var deliveryOut: [Double] = []
    var extraScooters = 0
    var dispatcher = false
}

extension TwistSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        chainStock = c.v("chainStock", chainStock)
        busWaveLeft = c.dbl("busWaveLeft", busWaveLeft)
        busHandledId = c.int("busHandledId", busHandledId)
        portDockId = c.int("portDockId", portDockId)
        portUnits = c.dbl("portUnits", portUnits)
        portTarget = c.dbl("portTarget", portTarget)
        portLoaded = c.v("portLoaded", portLoaded)
        deliveryQueue = c.int("deliveryQueue", deliveryQueue)
        deliveryClock = c.dbl("deliveryClock", deliveryClock)
        deliveryOut = c.v("deliveryOut", deliveryOut)
        extraScooters = c.int("extraScooters", extraScooters)
        dispatcher = c.v("dispatcher", dispatcher)
    }
}

struct CitySave: Codable {
    var cityId = "jerusalem"
    var stations: [StationState] = []
    var cash: Double = 50
    var lifetimeEarned: Double = 0
    var upgradesBought: [String] = []
    var counters: [String: Double] = [:]
    var openedAt: Double = 0
    var goalsClaimed: [String] = []
    var goalBaselines: [String: Double] = [:]
    var stars = 0
    var scenesSeen: [String] = []
    var twist = TwistSave()
}

extension CitySave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        cityId = c.v("cityId", cityId)
        stations = c.v("stations", stations)
        cash = c.dbl("cash", cash)
        lifetimeEarned = c.dbl("lifetimeEarned", lifetimeEarned)
        upgradesBought = c.v("upgradesBought", upgradesBought)
        counters = c.v("counters", counters)
        openedAt = c.dbl("openedAt", openedAt)
        goalsClaimed = c.v("goalsClaimed", goalsClaimed)
        goalBaselines = c.v("goalBaselines", goalBaselines)
        stars = c.int("stars", stars)
        scenesSeen = c.v("scenesSeen", scenesSeen)
        twist = c.v("twist", twist)
    }
}

struct BranchSave: Codable {
    var level = 0
    var crowned = false
    var stars = 0
    var finalIncome: Double = 0
    var lifetimeEarned: Double = 0
    var graduatedAt: Double = 0
}

extension BranchSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", level)
        crowned = c.v("crowned", crowned)
        stars = c.int("stars", stars)
        finalIncome = c.dbl("finalIncome", finalIncome)
        lifetimeEarned = c.dbl("lifetimeEarned", lifetimeEarned)
        graduatedAt = c.dbl("graduatedAt", graduatedAt)
    }
}

struct MetaSave: Codable {
    var saveVersion = 1
    var playerSeed = "0"
    var createdAt: Double = 0
    var lastTrustedWall: Double = 0
    var lastUptime: Double = 0
    var bootTime: Double = 0
    var lastActiveTick: Double = 0
    var lastProcessedDay = 0
    var clockFrozen = false
}

extension MetaSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        saveVersion = c.int("saveVersion", saveVersion)
        playerSeed = c.v("playerSeed", playerSeed)
        createdAt = c.dbl("createdAt", createdAt)
        lastTrustedWall = c.dbl("lastTrustedWall", lastTrustedWall)
        lastUptime = c.dbl("lastUptime", lastUptime)
        bootTime = c.dbl("bootTime", bootTime)
        lastActiveTick = c.dbl("lastActiveTick", lastActiveTick)
        lastProcessedDay = c.int("lastProcessedDay", lastProcessedDay)
        clockFrozen = c.v("clockFrozen", clockFrozen)
    }

    var seed: UInt64 { UInt64(playerSeed) ?? 0x5EED }
}

struct SettingsSave: Codable {
    var sfx = true
    var haptics = true
    var notifications = true
    var reduceMotion = false
    var arabicDigits = false
    var address: AddressForm = .m
    var addressAsked = false
    var stallName = "بسطة ستّي"
}

extension SettingsSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        sfx = c.v("sfx", sfx)
        haptics = c.v("haptics", haptics)
        notifications = c.v("notifications", notifications)
        reduceMotion = c.v("reduceMotion", reduceMotion)
        arabicDigits = c.v("arabicDigits", arabicDigits)
        address = c.v("address", address)
        addressAsked = c.v("addressAsked", addressAsked)
        stallName = c.v("stallName", stallName)
    }
}

struct FtueSave: Codable {
    /// Id of the next (or current) step.
    var step = 1
    var active = false
    var startedAt: Double = 0
    var done = false
    var tapCooks: [String: Int] = [:]
    var bubbleClosed = false
    var seenTwists: [String] = []
    var seenUnlocks: [String] = []
}

extension FtueSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        step = c.int("step", step)
        active = c.v("active", active)
        startedAt = c.dbl("startedAt", startedAt)
        done = c.v("done", done)
        tapCooks = c.v("tapCooks", tapCooks)
        bubbleClosed = c.v("bubbleClosed", bubbleClosed)
        seenTwists = c.v("seenTwists", seenTwists)
        seenUnlocks = c.v("seenUnlocks", seenUnlocks)
    }
}

struct EmpireSave: Codable {
    var level = 1
    var xp = 0
    var totalXp = 0
}

extension EmpireSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", level)
        xp = c.int("xp", xp)
        totalXp = c.int("totalXp", totalXp)
    }
}

struct WalletSave: Codable {
    var gold = 0
    var zaatar = 0
    var timeWarps: [Int] = []
    var pendingChests: [String: Int] = [:]
    var pendingChefCards = 0
    var pendingHeritage = 0
    var vaultDoubleDay = 0
    var warpDay = 0
    var warpBuys = 0
}

extension WalletSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        gold = c.int("gold", gold)
        zaatar = c.int("zaatar", zaatar)
        timeWarps = c.v("timeWarps", timeWarps)
        pendingChests = c.v("pendingChests", pendingChests)
        pendingChefCards = c.int("pendingChefCards", pendingChefCards)
        pendingHeritage = c.int("pendingHeritage", pendingHeritage)
        vaultDoubleDay = c.int("vaultDoubleDay", vaultDoubleDay)
        warpDay = c.int("warpDay", warpDay)
        warpBuys = c.int("warpBuys", warpBuys)
    }
}

struct BranchSafeSave: Codable {
    var stored: Double = 0
    var lastAccrual: Double = 0
}

extension BranchSafeSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        stored = c.dbl("stored", stored)
        lastAccrual = c.dbl("lastAccrual", lastAccrual)
    }
}

struct HappeningsSave: Codable {
    var specialCounter = 0
    var activeSinceSpecial: Double = 0
    var nextSpecialAt: Double = 0
}

extension HappeningsSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        specialCounter = c.int("specialCounter", specialCounter)
        activeSinceSpecial = c.dbl("activeSinceSpecial", activeSinceSpecial)
        nextSpecialAt = c.dbl("nextSpecialAt", nextSpecialAt)
    }
}

struct BoostSave: Codable, Identifiable {
    var kind = ""
    var mult: Double = 1
    var left: Double = 0
    /// "" = every station; "cat:<category>" or "cui:<cuisine>" = matching stations only.
    var scope = ""

    var id: String { kind }
}

extension BoostSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        kind = c.v("kind", kind)
        mult = c.dbl("mult", mult)
        left = c.dbl("left", left)
        scope = c.v("scope", scope)
    }
}

struct StatsSave: Codable {
    var taps = 0
    var customers: Double = 0
    var specials = 0
    var vaultCollects = 0
    var branchCollects = 0
    var starsTotal = 0
    var graduations = 0
    var lifetimeCashEvents = 0
}

extension StatsSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        taps = c.int("taps", taps)
        customers = c.dbl("customers", customers)
        specials = c.int("specials", specials)
        vaultCollects = c.int("vaultCollects", vaultCollects)
        branchCollects = c.int("branchCollects", branchCollects)
        starsTotal = c.int("starsTotal", starsTotal)
        graduations = c.int("graduations", graduations)
        lifetimeCashEvents = c.int("lifetimeCashEvents", lifetimeCashEvents)
    }
}

struct LegacySave: Codable {
    var checked = false
    var eligible = false
    var claimed = false
    var chefGranted = false
    var v2StallName = ""
    var prestigeCount = 0
}

extension LegacySave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        checked = c.v("checked", checked)
        eligible = c.v("eligible", eligible)
        claimed = c.v("claimed", claimed)
        chefGranted = c.v("chefGranted", chefGranted)
        v2StallName = c.v("v2StallName", v2StallName)
        prestigeCount = c.int("prestigeCount", prestigeCount)
    }
}

struct NotifSave: Codable {
    var asked = 0
    var granted = false
}

extension NotifSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        asked = c.int("asked", asked)
        granted = c.v("granted", granted)
    }
}

struct ChefOwn: Codable {
    var level = 1
    var cards = 0
}

extension ChefOwn {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        level = c.int("level", level)
        cards = c.int("cards", cards)
    }
}

struct ChefsSave: Codable {
    var owned: [String: ChefOwn] = [:]
    var equipped: [String] = []
    var chests: [String: Int] = [:]
    var openCounter = 0
    var pityLegend = 0
    var pitySilverEpic = 0
    var revealViews = 0
    var skillReadyAt: [String: Double] = [:]
    var stallDay = 0
    var stallBought: [Int] = []
    var ftueChestGiven = false
    var ftueChestOpened = false
    var cardCounter = 0
}

extension ChefsSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        owned = c.v("owned", owned)
        equipped = c.v("equipped", equipped)
        chests = c.v("chests", chests)
        openCounter = c.int("openCounter", openCounter)
        pityLegend = c.int("pityLegend", pityLegend)
        pitySilverEpic = c.int("pitySilverEpic", pitySilverEpic)
        revealViews = c.int("revealViews", revealViews)
        skillReadyAt = c.v("skillReadyAt", skillReadyAt)
        stallDay = c.int("stallDay", stallDay)
        stallBought = c.v("stallBought", stallBought)
        ftueChestGiven = c.v("ftueChestGiven", ftueChestGiven)
        ftueChestOpened = c.v("ftueChestOpened", ftueChestOpened)
        cardCounter = c.int("cardCounter", cardCounter)
    }
}

struct ResearchSlot: Codable {
    var nodeId = ""
    var level = 1
    var startAt: Double = 0
    var endAt: Double = 0
    var applied = false
}

extension ResearchSlot {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        nodeId = c.v("nodeId", nodeId)
        level = c.int("level", level)
        startAt = c.dbl("startAt", startAt)
        endAt = c.dbl("endAt", endAt)
        applied = c.v("applied", applied)
    }
}

struct ResearchSave: Codable {
    var levels: [String: Int] = [:]
    var slots: [ResearchSlot] = []
    var started = 0
    var completed = 0
}

extension ResearchSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        levels = c.v("levels", levels)
        slots = c.v("slots", slots)
        started = c.int("started", started)
        completed = c.int("completed", completed)
    }
}

struct SupplySlot: Codable {
    var runId = ""
    var vehicleId = ""
    var durationIdx = 0
    var sentAt: Double = 0
    var endAt: Double = 0
    var seed = 0
}

extension SupplySlot {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        runId = c.v("runId", runId)
        vehicleId = c.v("vehicleId", vehicleId)
        durationIdx = c.int("durationIdx", durationIdx)
        sentAt = c.dbl("sentAt", sentAt)
        endAt = c.dbl("endAt", endAt)
        seed = c.int("seed", seed)
    }
}

struct SupplySave: Codable {
    var launches: [String: Int] = [:]
    var slots: [SupplySlot] = []
    var heritage: [String: Int] = [:]
    var craftPoints = 0
    var runCounter = 0
    var sent = 0
    var returned = 0
    var newItems = 0
}

extension SupplySave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        launches = c.v("launches", launches)
        slots = c.v("slots", slots)
        heritage = c.v("heritage", heritage)
        craftPoints = c.int("craftPoints", craftPoints)
        runCounter = c.int("runCounter", runCounter)
        sent = c.int("sent", sent)
        returned = c.int("returned", returned)
        newItems = c.int("newItems", newItems)
    }
}

struct GameSave: Codable {
    var meta = MetaSave()
    var settings = SettingsSave()
    var ftue = FtueSave()
    var empire = EmpireSave()
    var wallet = WalletSave()
    var city = CitySave()
    var branches: [String: BranchSave] = [:]
    var branchSafe = BranchSafeSave()
    var happenings = HappeningsSave()
    var boosts: [BoostSave] = []
    var stats = StatsSave()
    var legacy = LegacySave()
    var notif = NotifSave()
    var chefs = ChefsSave()
    var research = ResearchSave()
    var supply = SupplySave()

    static let key = "basta.save.v3"
    static let backupKey = "basta.save.v3.bak"
    static let v2Key = "falafel.save.v2"
}

extension GameSave {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: AnyKey.self)
        meta = c.v("meta", meta)
        settings = c.v("settings", settings)
        ftue = c.v("ftue", ftue)
        empire = c.v("empire", empire)
        wallet = c.v("wallet", wallet)
        city = c.v("city", city)
        branches = c.v("branches", branches)
        branchSafe = c.v("branchSafe", branchSafe)
        happenings = c.v("happenings", happenings)
        boosts = c.v("boosts", boosts)
        stats = c.v("stats", stats)
        legacy = c.v("legacy", legacy)
        notif = c.v("notif", notif)
        chefs = c.v("chefs", chefs)
        research = c.v("research", research)
        supply = c.v("supply", supply)
    }

    static func load() -> GameSave? {
        let d = UserDefaults.standard
        for k in [key, backupKey] {
            if let data = d.data(forKey: k), let s = try? JSONDecoder().decode(GameSave.self, from: data) {
                return s
            }
        }
        return nil
    }

    func write(backup: Bool = false) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: GameSave.key)
        if backup { UserDefaults.standard.set(data, forKey: GameSave.backupKey) }
    }
}
