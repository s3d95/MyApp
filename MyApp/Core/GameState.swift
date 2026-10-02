import Foundation

struct LineState: Codable {
    /// Number of sellers working in this section (0 = section locked).
    var owned: Int = 0
    var hasManager: Bool = false
    var cycleStart: Date? = nil
}

struct GameState: Codable {
    var money: Double = 0
    var lifetimeEarnings: Double = 0
    var totalSold: Double = 0
    var lines: [LineState] = Array(repeating: LineState(), count: GameData.businesses.count)
    var purchased: Set<String> = []
    var branchesOwned: Int = 0
    var tapLevel: Int = 0
    var autoLevel: Int = 0
    var stallName: String = ""
    var totalTaps: Int = 0
    var lastSaved: Date = Date()
    var createdAt: Date = Date()
    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var boostUntil: Date? = nil
    var boostFactor: Double = 1

    init() {}

    enum CodingKeys: String, CodingKey {
        case money, lifetimeEarnings, totalSold, lines, purchased, branchesOwned, tapLevel, autoLevel,
             stallName, totalTaps, lastSaved, createdAt, soundOn, hapticsOn, boostUntil, boostFactor
    }

    // Tolerant decoding so older saves keep loading after new fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var d = GameState()
        d.money = try c.decodeIfPresent(Double.self, forKey: .money) ?? d.money
        d.lifetimeEarnings = try c.decodeIfPresent(Double.self, forKey: .lifetimeEarnings) ?? d.lifetimeEarnings
        d.totalSold = try c.decodeIfPresent(Double.self, forKey: .totalSold) ?? d.totalSold
        d.lines = try c.decodeIfPresent([LineState].self, forKey: .lines) ?? d.lines
        d.purchased = try c.decodeIfPresent(Set<String>.self, forKey: .purchased) ?? d.purchased
        d.branchesOwned = try c.decodeIfPresent(Int.self, forKey: .branchesOwned) ?? d.branchesOwned
        d.tapLevel = try c.decodeIfPresent(Int.self, forKey: .tapLevel) ?? d.tapLevel
        d.autoLevel = try c.decodeIfPresent(Int.self, forKey: .autoLevel) ?? d.autoLevel
        d.stallName = try c.decodeIfPresent(String.self, forKey: .stallName) ?? d.stallName
        d.totalTaps = try c.decodeIfPresent(Int.self, forKey: .totalTaps) ?? d.totalTaps
        d.lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? d.lastSaved
        d.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? d.createdAt
        d.soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? d.soundOn
        d.hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? d.hapticsOn
        d.boostUntil = try c.decodeIfPresent(Date.self, forKey: .boostUntil)
        d.boostFactor = try c.decodeIfPresent(Double.self, forKey: .boostFactor) ?? d.boostFactor

        let count = GameData.businesses.count
        if d.lines.count > count { d.lines = Array(d.lines.prefix(count)) }
        while d.lines.count < count { d.lines.append(LineState()) }
        for i in d.lines.indices { d.lines[i].owned = min(d.lines[i].owned, GameData.maxSellers) }
        d.branchesOwned = min(d.branchesOwned, GameData.branches.count)
        d.tapLevel = min(d.tapLevel, GameData.maxTapLevel)
        d.autoLevel = min(d.autoLevel, GameData.maxAutoLevel)
        self = d
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

    mutating func earn(_ v: Double) {
        money += v
        lifetimeEarnings += v
    }

    // MARK: Speed & price

    func milestoneCount(_ i: Int) -> Int {
        GameData.milestones.filter { lines[i].owned >= $0 }.count
    }

    func nextMilestone(_ i: Int) -> Int? {
        GameData.milestones.first(where: { lines[i].owned < $0 })
    }

    func speedMultiplier(_ i: Int) -> Double {
        var m = pow(GameData.milestoneSpeed, Double(milestoneCount(i)))
        for u in GameData.upgrades where u.section == i && purchased.contains(u.id) { m *= u.speed }
        return m
    }

    func priceMultiplier(_ i: Int) -> Double {
        var m = 1.0
        for u in GameData.upgrades where u.section == i && purchased.contains(u.id) { m *= u.price }
        return m
    }

    var customersMultiplier: Double {
        var m = 1.0
        for u in GameData.upgrades where u.section == nil && purchased.contains(u.id) { m *= u.customers }
        return m
    }

    var branchMultiplier: Double { 1 + Double(branchesOwned) * GameData.branchBonus }

    /// Total bonus from ads and branches, shown as a percentage in the UI.
    var globalBonusPercent: Int { Int(((customersMultiplier * branchMultiplier - 1) * 100).rounded()) }

    func boost(at now: Date) -> Double {
        if let u = boostUntil, now < u { return boostFactor }
        return 1
    }

    func cycleTime(_ i: Int) -> Double {
        GameData.businesses[i].baseTime / speedMultiplier(i)
    }

    /// Price of one item including every bonus.
    func unitPrice(_ i: Int, now: Date) -> Double {
        GameData.businesses[i].price * priceMultiplier(i) * customersMultiplier * branchMultiplier * boost(at: now)
    }

    /// Money from one cycle: every seller sells one item.
    func revenuePerCycle(_ i: Int, now: Date) -> Double {
        Double(lines[i].owned) * unitPrice(i, now: now)
    }

    // MARK: Tapping

    func tapValue(now: Date) -> Double { Double(1 + tapLevel) * boost(at: now) }
    var autoRate: Double { Double(autoLevel) }

    var nextTapCost: Double? { tapLevel < GameData.maxTapLevel ? GameData.tapCost(tapLevel) : nil }
    var nextAutoCost: Double? { autoLevel < GameData.maxAutoLevel ? GameData.autoCost(autoLevel) : nil }

    func incomePerSecond(now: Date) -> Double {
        var total = autoRate * tapValue(now: now)
        for i in lines.indices where lines[i].owned > 0 && lines[i].hasManager {
            total += revenuePerCycle(i, now: now) / cycleTime(i)
        }
        return total
    }

    // MARK: Buying sellers

    func remainingSellers(_ i: Int) -> Int { max(0, GameData.maxSellers - lines[i].owned) }

    func sellerCost(_ i: Int, count n: Int) -> Double {
        let b = GameData.businesses[i]
        let first = b.sellerBase * pow(b.growth, Double(max(0, lines[i].owned - 1)))
        return (first * (pow(b.growth, Double(n)) - 1) / (b.growth - 1)).rounded()
    }

    func maxAffordableSellers(_ i: Int) -> Int {
        var k = 0
        while k < remainingSellers(i) && sellerCost(i, count: k + 1) <= money { k += 1 }
        return k
    }

    var nextBranch: BranchDef? {
        branchesOwned < GameData.branches.count ? GameData.branches[branchesOwned] : nil
    }
}
