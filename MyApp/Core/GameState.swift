import Foundation

struct LineState: Codable {
    /// Number of sellers working in this section (0 = section locked).
    var owned: Int = 0
    var hasManager: Bool = false
    var cycleStart: Date? = nil
}

struct GameState: Codable {
    // MARK: Current run (reset by إعادة الافتتاح)
    var money: Double = 0
    var lifetimeEarnings: Double = 0
    var lines: [LineState] = Array(repeating: LineState(), count: GameData.businesses.count)
    var purchased: Set<String> = []
    var branchesOwned: Int = 0
    var tapLevel: Int = 0
    var autoLevel: Int = 0
    var shareLevel: Int = 0

    // MARK: Kept forever
    var totalSold: Double = 0
    var stallName: String = ""
    var totalTaps: Int = 0
    var lastSaved: Date = Date()
    var createdAt: Date = Date()
    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var notificationsOn: Bool = true
    var notificationsAsked: Bool = false
    var whatsNewSeen: Int = 0
    var boostUntil: Date? = nil
    var boostFactor: Double = 1
    var megaBoostUntil: Date? = nil

    // Prestige
    var stars: Double = 0
    var pastEarnings: Double = 0
    var prestigeCount: Int = 0

    // Gold liras, chefs, research, achievements
    var liras: Int = 0
    var lirasEarned: Int = 0
    var chests: [Int] = Array(repeating: 0, count: ChestKind.allCases.count)
    var chestsOpened: Int = 0
    var chefLevel: [Int] = Array(repeating: 0, count: Catalog.chefs.count)
    var chefCards: [Int] = Array(repeating: 0, count: Catalog.chefs.count)
    var research: [Int] = Array(repeating: 0, count: Catalog.research.count)
    var achievements: Set<String> = []

    // Daily
    var loginDay: Int = 0
    var loginStreak: Int = 0
    var bestStreak: Int = 0
    var counterDay: Int = 0
    var daily = DailyCounters()
    var missions: [Mission] = []
    var missionBonusClaimed: Bool = false
    var freeSpinDay: Int = 0
    var dishIndex: Int = -1
    var tickets: Int = 3
    var ticketStamp: Date = Date()
    var bestRush: Int = 0

    // Stats
    var sellersHired: Int = 0
    var vipsClaimed: Int = 0
    var missionsDone: Int = 0
    var rushPlays: Int = 0

    init() {}

    enum CodingKeys: String, CodingKey {
        case money, lifetimeEarnings, lines, purchased, branchesOwned, tapLevel, autoLevel, shareLevel
        case totalSold, stallName, totalTaps, lastSaved, createdAt, soundOn, hapticsOn,
             notificationsOn, notificationsAsked, whatsNewSeen, boostUntil, boostFactor, megaBoostUntil
        case stars, pastEarnings, prestigeCount
        case liras, lirasEarned, chests, chestsOpened, chefLevel, chefCards, research, achievements
        case loginDay, loginStreak, bestStreak, counterDay, daily, missions, missionBonusClaimed,
             freeSpinDay, dishIndex, tickets, ticketStamp, bestRush
        case sellersHired, vipsClaimed, missionsDone, rushPlays
    }

    // Tolerant decoding so older saves keep loading after new fields are added.
    // A field that fails to decode falls back to its default instead of losing the whole save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var d = GameState()
        func get<T: Decodable>(_ key: CodingKeys, _ value: inout T) {
            if let v = try? c.decodeIfPresent(T.self, forKey: key) { value = v }
        }
        get(.money, &d.money)
        get(.lifetimeEarnings, &d.lifetimeEarnings)
        get(.lines, &d.lines)
        get(.purchased, &d.purchased)
        get(.branchesOwned, &d.branchesOwned)
        get(.tapLevel, &d.tapLevel)
        get(.autoLevel, &d.autoLevel)
        get(.shareLevel, &d.shareLevel)
        get(.totalSold, &d.totalSold)
        get(.stallName, &d.stallName)
        get(.totalTaps, &d.totalTaps)
        get(.lastSaved, &d.lastSaved)
        get(.createdAt, &d.createdAt)
        get(.soundOn, &d.soundOn)
        get(.hapticsOn, &d.hapticsOn)
        get(.notificationsOn, &d.notificationsOn)
        get(.notificationsAsked, &d.notificationsAsked)
        get(.whatsNewSeen, &d.whatsNewSeen)
        d.boostUntil = try? c.decodeIfPresent(Date.self, forKey: .boostUntil)
        get(.boostFactor, &d.boostFactor)
        d.megaBoostUntil = try? c.decodeIfPresent(Date.self, forKey: .megaBoostUntil)
        get(.stars, &d.stars)
        get(.pastEarnings, &d.pastEarnings)
        get(.prestigeCount, &d.prestigeCount)
        get(.liras, &d.liras)
        get(.lirasEarned, &d.lirasEarned)
        get(.chests, &d.chests)
        get(.chestsOpened, &d.chestsOpened)
        get(.chefLevel, &d.chefLevel)
        get(.chefCards, &d.chefCards)
        get(.research, &d.research)
        get(.achievements, &d.achievements)
        get(.loginDay, &d.loginDay)
        get(.loginStreak, &d.loginStreak)
        get(.bestStreak, &d.bestStreak)
        get(.counterDay, &d.counterDay)
        get(.daily, &d.daily)
        get(.missions, &d.missions)
        get(.missionBonusClaimed, &d.missionBonusClaimed)
        get(.freeSpinDay, &d.freeSpinDay)
        get(.dishIndex, &d.dishIndex)
        get(.tickets, &d.tickets)
        get(.ticketStamp, &d.ticketStamp)
        get(.bestRush, &d.bestRush)
        get(.sellersHired, &d.sellersHired)
        get(.vipsClaimed, &d.vipsClaimed)
        get(.missionsDone, &d.missionsDone)
        get(.rushPlays, &d.rushPlays)

        d.lines = GameState.fit(d.lines, GameData.businesses.count, LineState())
        for i in d.lines.indices { d.lines[i].owned = min(max(0, d.lines[i].owned), GameData.maxSellers) }
        if d.lines[0].owned == 0 { d.lines[0].owned = 1 }
        d.chests = GameState.fit(d.chests, ChestKind.allCases.count, 0)
        d.chefLevel = GameState.fit(d.chefLevel, Catalog.chefs.count, 0).map { min(max(0, $0), Catalog.maxChefLevel) }
        d.chefCards = GameState.fit(d.chefCards, Catalog.chefs.count, 0)
        d.research = GameState.fit(d.research, Catalog.research.count, 0)
        for (k, r) in Catalog.research.enumerated() { d.research[k] = min(max(0, d.research[k]), r.maxLevel) }
        d.branchesOwned = min(d.branchesOwned, GameData.branches.count)
        d.tapLevel = min(d.tapLevel, GameData.maxTapLevel)
        d.autoLevel = min(d.autoLevel, GameData.maxAutoLevel)
        d.shareLevel = min(d.shareLevel, GameData.maxShareLevel)
        if d.dishIndex >= GameData.businesses.count { d.dishIndex = -1 }
        self = d
    }

    private static func fit<T>(_ a: [T], _ n: Int, _ fill: T) -> [T] {
        if a.count >= n { return Array(a.prefix(n)) }
        return a + Array(repeating: fill, count: n - a.count)
    }
}

// MARK: - Rules

extension GameState {
    static func fresh() -> GameState {
        var g = GameState()
        g.lines[0].owned = 1
        return g
    }

    var displayName: String { stallName.isEmpty ? "بسطتي" : stallName }

    var totalSellers: Int { lines.reduce(0) { $0 + $1.owned } }

    var stage: Int {
        var r = 0
        for (k, t) in GameData.stageThresholds.enumerated() where totalSellers >= t { r = k }
        return r
    }

    var allTimeEarnings: Double { pastEarnings + lifetimeEarnings }

    mutating func earn(_ v: Double) {
        guard v.isFinite, v > 0 else { return }
        money += v
        lifetimeEarnings += v
        daily.earned += v
    }

    mutating func addLiras(_ n: Int) {
        guard n > 0 else { return }
        liras += n
        lirasEarned += n
    }

    // MARK: Chefs

    func perkLevel(_ perk: ChefPerk) -> Int { chefLevel[Catalog.chefIndex(perk)] }
    var chefsOwned: Int { chefLevel.filter { $0 > 0 }.count }
    var chefLevelsTotal: Int { chefLevel.reduce(0, +) }

    func chefCardsNeeded(_ id: Int) -> Int? {
        let l = chefLevel[id]
        guard l > 0, l < Catalog.maxChefLevel else { return nil }
        return Catalog.chefLevelCards[l - 1]
    }

    func chefCanUpgrade(_ id: Int) -> Bool {
        guard let need = chefCardsNeeded(id) else { return false }
        return chefCards[id] >= need
    }

    var anyChefUpgradable: Bool { Catalog.chefs.contains { chefCanUpgrade($0.id) } }

    // MARK: Milestones

    /// Speed milestones (10/25/50) reached in a section.
    func milestoneCount(_ i: Int) -> Int {
        GameData.milestones.filter { lines[i].owned >= $0 }.count
    }

    func profitMilestones(_ i: Int) -> Int { lines[i].owned / GameData.profitStep }

    /// Next seller count that gives this section a bonus.
    func nextMilestone(_ i: Int) -> Int? {
        let n = lines[i].owned
        if let m = GameData.milestones.first(where: { n < $0 }) { return m }
        let next = (n / GameData.profitStep + 1) * GameData.profitStep
        return next <= GameData.maxSellers ? next : nil
    }

    var minOwned: Int { lines.map { $0.owned }.min() ?? 0 }
    var allSectionsLevel: Int { GameData.allSectionsLevel(minOwned: minOwned) }
    var allSectionsMultiplier: Double { pow(2, Double(allSectionsLevel)) }

    // MARK: Multipliers

    func speedMultiplier(_ i: Int) -> Double {
        var m = pow(GameData.milestoneSpeed, Double(milestoneCount(i)))
        for u in GameData.upgradesBySection[i] where purchased.contains(u.id) { m *= u.speed }
        return m
    }

    func chefSectionMultiplier(_ i: Int) -> Double {
        1 + Catalog.chefs[i].rarity.sectionPerLevel * Double(chefLevel[i])
    }

    var dishMultiplier: Double { 3 }

    /// Everything that only affects one section's price.
    func priceMultiplier(_ i: Int) -> Double {
        var m = pow(2, Double(profitMilestones(i)))
        for u in GameData.upgradesBySection[i] where purchased.contains(u.id) { m *= u.price }
        m *= chefSectionMultiplier(i)
        if dishIndex == i { m *= dishMultiplier }
        return m
    }

    var customersMultiplier: Double {
        var m = 1.0
        for u in GameData.globalUpgrades where purchased.contains(u.id) { m *= u.customers }
        return m
    }

    var branchMultiplier: Double {
        var m = 1.0
        for b in GameData.branches.prefix(branchesOwned) { m += b.bonus }
        return m
    }

    var branchBonusPercent: Int { Int(((branchMultiplier - 1) * 100).rounded()) }

    var starPower: Double { 0.02 * (1 + 0.1 * Double(perkLevel(.stars))) }
    var starMultiplier: Double { 1 + stars * starPower }
    var achievementMultiplier: Double { 1 + 0.02 * Double(achievements.count) }
    var researchMultiplier: Double { 1 + 0.25 * Double(research[Catalog.rProfit]) }
    var grandmaMultiplier: Double { 1 + 0.5 * Double(perkLevel(.allProfit)) }

    /// Bonuses that survive إعادة الافتتاح.
    var permanentMultiplier: Double {
        starMultiplier * achievementMultiplier * researchMultiplier * grandmaMultiplier
    }

    /// Every lasting bonus on all sections (no temporary boosts).
    var globalMultiplier: Double {
        customersMultiplier * branchMultiplier * allSectionsMultiplier * permanentMultiplier
    }

    /// Total bonus from ads and branches, shown as a percentage in the UI.
    var globalBonusPercent: Int { Int(((customersMultiplier * branchMultiplier - 1) * 100).rounded()) }

    func eventBoost(at now: Date) -> Double {
        if let u = boostUntil, now < u { return boostFactor }
        return 1
    }

    func megaBoostActive(at now: Date) -> Bool {
        if let u = megaBoostUntil, now < u { return true }
        return false
    }

    func boost(at now: Date) -> Double {
        eventBoost(at: now) * (megaBoostActive(at: now) ? 2 : 1)
    }

    func cycleTime(_ i: Int) -> Double {
        GameData.businesses[i].baseTime / speedMultiplier(i)
    }

    /// Price of one item including every bonus.
    func unitPrice(_ i: Int, now: Date) -> Double {
        GameData.businesses[i].price * priceMultiplier(i) * globalMultiplier * boost(at: now)
    }

    /// Money from one cycle: every seller sells one item.
    func revenuePerCycle(_ i: Int, now: Date) -> Double {
        Double(lines[i].owned) * unitPrice(i, now: now)
    }

    // MARK: Tapping

    var tapMultiplier: Double {
        (1 + 0.5 * Double(research[Catalog.rTap])) * (1 + Double(perkLevel(.tap)))
    }

    var shareRate: Double { Double(shareLevel) * GameData.sharePerLevel }

    func managerIncome(now: Date) -> Double {
        let g = globalMultiplier * boost(at: now)
        var total = 0.0
        for i in lines.indices where lines[i].owned > 0 && lines[i].hasManager {
            let b = GameData.businesses[i]
            total += Double(lines[i].owned) * b.price * priceMultiplier(i) * g / cycleTime(i)
        }
        return total
    }

    func tapValue(now: Date) -> Double {
        Double(1 + tapLevel) * tapMultiplier * boost(at: now) + shareRate * managerIncome(now: now)
    }

    var autoRate: Double { Double(autoLevel) }

    var nextTapCost: Double? { tapLevel < GameData.maxTapLevel ? GameData.tapCost(tapLevel) : nil }
    var nextAutoCost: Double? { autoLevel < GameData.maxAutoLevel ? GameData.autoCost(autoLevel) : nil }
    var nextShareCost: Double? { shareLevel < GameData.maxShareLevel ? GameData.shareCost(shareLevel) : nil }

    func incomePerSecond(now: Date) -> Double {
        let m = managerIncome(now: now)
        let tap = Double(1 + tapLevel) * tapMultiplier * boost(at: now) + shareRate * m
        return m + autoRate * tap
    }

    // MARK: Buying sellers

    var costMultiplier: Double {
        pow(0.98, Double(research[Catalog.rCheap])) * pow(0.97, Double(perkLevel(.cheap)))
    }

    func remainingSellers(_ i: Int) -> Int { max(0, GameData.maxSellers - lines[i].owned) }

    private func firstSellerCost(_ i: Int) -> Double {
        let b = GameData.businesses[i]
        return b.sellerBase * pow(b.growth, Double(max(0, lines[i].owned - 1))) * costMultiplier
    }

    func sellerCost(_ i: Int, count n: Int) -> Double {
        let g = GameData.businesses[i].growth
        return (firstSellerCost(i) * (pow(g, Double(n)) - 1) / (g - 1)).rounded()
    }

    func maxAffordableSellers(_ i: Int) -> Int {
        let g = GameData.businesses[i].growth
        let first = firstSellerCost(i)
        guard first.isFinite, first > 0, money >= first else { return 0 }
        var k = Int(floor(log(money * (g - 1) / first + 1) / log(g)))
        k = min(max(0, k), remainingSellers(i))
        while k > 0 && sellerCost(i, count: k) > money { k -= 1 }
        return k
    }

    var nextBranch: BranchDef? {
        branchesOwned < GameData.branches.count ? GameData.branches[branchesOwned] : nil
    }

    // MARK: Offline & VIP

    var offlineHours: Double { GameData.baseOfflineHours + Double(research[Catalog.rOffline]) }
    var offlineMultiplier: Double { 1 + 0.25 * Double(perkLevel(.offline)) }

    var vipRewardMultiplier: Double {
        (1 + 0.25 * Double(research[Catalog.rVIP])) * (1 + 0.5 * Double(perkLevel(.vip)))
    }

    var vipIntervalFactor: Double {
        1 / (1 + 0.05 * Double(research[Catalog.rVIP]) + 0.1 * Double(perkLevel(.vip)))
    }

    // MARK: Prestige (نجوم الشهرة)

    static let starDivisor = 1e6

    var starGainMultiplier: Double { 1 + 0.1 * Double(research[Catalog.rStars]) }

    var starsEarnable: Double {
        floor(sqrt(max(0, allTimeEarnings) / GameState.starDivisor) * starGainMultiplier)
    }

    var pendingStars: Double { max(0, starsEarnable - stars) }

    /// All-time earnings needed for one more pending star.
    var nextStarAt: Double {
        let target = max(starsEarnable, stars) + 1
        return pow(target / starGainMultiplier, 2) * GameState.starDivisor
    }

    /// Income multiplier you'd have after prestiging now, relative to the current star bonus.
    var prestigeGainRatio: Double {
        (1 + (stars + pendingStars) * starPower) / starMultiplier
    }

    mutating func prestige() {
        stars += pendingStars
        pastEarnings += lifetimeEarnings
        lifetimeEarnings = 0
        money = Catalog.startMoney(research[Catalog.rStart])
        lines = Array(repeating: LineState(), count: GameData.businesses.count)
        lines[0].owned = 1
        purchased = []
        branchesOwned = 0
        tapLevel = 0
        autoLevel = 0
        shareLevel = 0
        prestigeCount += 1
        if dishIndex > 0 { dishIndex = 0 }
    }

    // MARK: Tickets for the rush game

    var maxTickets: Int { 3 + research[Catalog.rTickets] }

    mutating func refillTickets(now: Date) {
        let interval = Catalog.ticketHours * 3600
        guard tickets < maxTickets else {
            ticketStamp = now
            return
        }
        let elapsed = now.timeIntervalSince(ticketStamp)
        guard elapsed >= interval else { return }
        let n = Int(elapsed / interval)
        tickets = min(maxTickets, tickets + n)
        ticketStamp = tickets >= maxTickets ? now : ticketStamp.addingTimeInterval(Double(n) * interval)
    }

    var nextTicketAt: Date? {
        tickets < maxTickets ? ticketStamp.addingTimeInterval(Catalog.ticketHours * 3600) : nil
    }

    // MARK: Daily

    /// Which day of the 7-day login track the next claim (or today's claim) is on.
    func loginTrackIndex(today: Int) -> Int {
        if loginDay == today { return max(0, loginStreak - 1) % 7 }
        if loginDay == today - 1 { return loginStreak % 7 }
        return 0
    }

    func loginPending(today: Int) -> Bool { loginDay != today }

    func missionDone(_ m: Mission) -> Bool { daily.value(m.kind) >= m.target }

    var missionClaimable: Bool { missions.contains { !$0.claimed && missionDone($0) } }

    var missionBonusReady: Bool {
        !missions.isEmpty && !missionBonusClaimed && missions.allSatisfy { $0.claimed }
    }

    func freeSpinReady(today: Int) -> Bool { freeSpinDay != today }

    func researchCost(_ id: Int) -> Int? {
        let r = Catalog.research[id]
        let l = research[id]
        return l < r.maxLevel ? r.cost(l) : nil
    }

    var anyResearchAffordable: Bool {
        Catalog.research.contains { r in
            if let c = researchCost(r.id) { return liras >= c }
            return false
        }
    }
}
