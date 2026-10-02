import Foundation

struct LineState: Codable {
    var owned: Int = 0
    var hasManager: Bool = false
    var cycleStart: Date? = nil
}

struct GameState: Codable {
    var money: Double = 0
    var runEarnings: Double = 0
    var lifetimeEarnings: Double = 0
    var claimedStars: Double = 0
    var lines: [LineState] = Array(repeating: LineState(), count: GameData.businesses.count)
    var purchased: Set<String> = []
    var cityIndex: Int = 0
    var stallName: String = ""
    var totalTaps: Int = 0
    var lastSaved: Date = Date()
    var createdAt: Date = Date()
    var prestigeCount: Int = 0
    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var boostUntil: Date? = nil
    var boostFactor: Double = 1

    init() {}

    enum CodingKeys: String, CodingKey {
        case money, runEarnings, lifetimeEarnings, claimedStars, lines, purchased, cityIndex, stallName,
             totalTaps, lastSaved, createdAt, prestigeCount, soundOn, hapticsOn, boostUntil, boostFactor
    }

    // Tolerant decoding so older saves keep loading after new fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var d = GameState()
        d.money = try c.decodeIfPresent(Double.self, forKey: .money) ?? d.money
        d.runEarnings = try c.decodeIfPresent(Double.self, forKey: .runEarnings) ?? d.runEarnings
        d.lifetimeEarnings = try c.decodeIfPresent(Double.self, forKey: .lifetimeEarnings) ?? d.lifetimeEarnings
        d.claimedStars = try c.decodeIfPresent(Double.self, forKey: .claimedStars) ?? d.claimedStars
        d.lines = try c.decodeIfPresent([LineState].self, forKey: .lines) ?? d.lines
        d.purchased = try c.decodeIfPresent(Set<String>.self, forKey: .purchased) ?? d.purchased
        d.cityIndex = try c.decodeIfPresent(Int.self, forKey: .cityIndex) ?? d.cityIndex
        d.stallName = try c.decodeIfPresent(String.self, forKey: .stallName) ?? d.stallName
        d.totalTaps = try c.decodeIfPresent(Int.self, forKey: .totalTaps) ?? d.totalTaps
        d.lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? d.lastSaved
        d.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? d.createdAt
        d.prestigeCount = try c.decodeIfPresent(Int.self, forKey: .prestigeCount) ?? d.prestigeCount
        d.soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? d.soundOn
        d.hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? d.hapticsOn
        d.boostUntil = try c.decodeIfPresent(Date.self, forKey: .boostUntil)
        d.boostFactor = try c.decodeIfPresent(Double.self, forKey: .boostFactor) ?? d.boostFactor

        let count = GameData.businesses.count
        if d.lines.count > count { d.lines = Array(d.lines.prefix(count)) }
        while d.lines.count < count { d.lines.append(LineState()) }
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
    var cityName: String { GameData.cities[cityIndex % GameData.cities.count] }
    var nextCityName: String { GameData.cities[(cityIndex + 1) % GameData.cities.count] }

    var totalOwned: Int { lines.reduce(0) { $0 + $1.owned } }

    var stage: Int {
        var r = 0
        for (k, t) in GameData.stageThresholds.enumerated() where totalOwned >= t { r = k }
        return r
    }

    mutating func earn(_ v: Double) {
        money += v
        runEarnings += v
        lifetimeEarnings += v
    }

    func milestoneCount(_ i: Int) -> Int {
        GameData.milestones.filter { lines[i].owned >= $0 }.count
    }

    func nextMilestone(_ i: Int) -> Int? {
        GameData.milestones.first(where: { lines[i].owned < $0 })
    }

    func cycleTime(_ i: Int) -> Double {
        GameData.businesses[i].baseTime / pow(2, Double(milestoneCount(i)))
    }

    var starMultiplier: Double { 1 + claimedStars * 0.02 }

    func boost(at now: Date) -> Double {
        if let u = boostUntil, now < u { return boostFactor }
        return 1
    }

    func upgradeMultiplier(_ i: Int) -> Double {
        var m = 1.0
        for u in GameData.upgrades where purchased.contains(u.id) {
            switch u.target {
            case .business(let b) where b == i: m *= u.multiplier
            case .all: m *= u.multiplier
            default: break
            }
        }
        return m
    }

    var tapMultiplier: Double {
        var m = 1.0
        for u in GameData.upgrades where u.target == .tap && purchased.contains(u.id) { m *= u.multiplier }
        return m
    }

    func revenuePerCycle(_ i: Int, now: Date) -> Double {
        GameData.businesses[i].baseRevenue * Double(lines[i].owned)
            * starMultiplier * upgradeMultiplier(i) * boost(at: now)
    }

    func incomePerSecond(now: Date) -> Double {
        var total = 0.0
        for i in lines.indices where lines[i].owned > 0 && lines[i].hasManager {
            total += revenuePerCycle(i, now: now) / cycleTime(i)
        }
        return total
    }

    func tapValue(now: Date) -> Double {
        (starMultiplier * boost(at: now) + incomePerSecond(now: now) * 0.08) * tapMultiplier
    }

    func cost(_ i: Int, count n: Int) -> Double {
        let b = GameData.businesses[i]
        let first = b.baseCost * pow(b.growth, Double(lines[i].owned))
        return first * (pow(b.growth, Double(n)) - 1) / (b.growth - 1)
    }

    func maxAffordable(_ i: Int) -> Int {
        let b = GameData.businesses[i]
        let first = b.baseCost * pow(b.growth, Double(lines[i].owned))
        guard first.isFinite, first > 0, money >= first else { return 0 }
        let n = floor(log(money * (b.growth - 1) / first + 1) / log(b.growth))
        var k = Int(min(max(n, 0), 10_000))
        while k > 0 && cost(i, count: k) > money { k -= 1 }
        return k
    }

    // Prestige: stars come from lifetime earnings; each star = +2% profit forever.
    var potentialStars: Double { floor(10 * (lifetimeEarnings / 1e10).squareRoot()) }
    var starsToGain: Double { max(0, potentialStars - claimedStars) }
    var lifetimeForNextStar: Double { 1e10 * pow((claimedStars + 1) / 10, 2) }
}
