import Foundation

// MARK: - Deterministic randomness (GDD 7.2)

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1).
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(UInt64(1) << 53)
    }

    mutating func int(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        return Int(next() % UInt64(n))
    }

    /// Picks an index by weights.
    mutating func weighted(_ weights: [Double]) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        var r = unit() * total
        for (i, w) in weights.enumerated() {
            r -= w
            if r < 0 { return i }
        }
        return max(0, weights.count - 1)
    }
}

enum Seed {
    static func fnv1a(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 0x100000001b3
        }
        return h
    }

    /// `rng(purpose, parts…)` mixed with the player seed.
    static func rng(_ purpose: String, _ parts: [String], player: UInt64) -> SplitMix64 {
        SplitMix64(seed: fnv1a(([purpose] + parts).joined(separator: "|")) ^ player)
    }

    /// Shared across players (global calendar content).
    static func shared(_ purpose: String, _ parts: [String]) -> SplitMix64 {
        SplitMix64(seed: fnv1a(([purpose] + parts).joined(separator: "|")))
    }
}

// MARK: - Time

enum Clock {
    private static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US_POSIX")
        c.timeZone = TimeZone.current
        return c
    }()

    // Rules ask for the hour and the game day many times per tick; cache them per second.
    private static var dayKey = Int.min
    private static var dayVal = 0
    private static var hmKey = Int.min
    private static var hmVal = (h: 0, m: 0, s: 0)

    /// Game day starts at 04:00 local, as yyyyMMdd.
    static func gameDay(_ t: Double) -> Int {
        let key = Int(floor(t))
        if key == dayKey { return dayVal }
        let d = Date(timeIntervalSince1970: t - 4 * 3600)
        let c = cal.dateComponents([.year, .month, .day], from: d)
        let v = (c.year ?? 2000) * 10000 + (c.month ?? 1) * 100 + (c.day ?? 1)
        dayKey = key
        dayVal = v
        return v
    }

    /// Local hour (0–23), minute and second.
    static func hourMinute(_ t: Double) -> (h: Int, m: Int, s: Int) {
        let key = Int(floor(t))
        if key == hmKey { return hmVal }
        let c = cal.dateComponents([.hour, .minute, .second], from: Date(timeIntervalSince1970: t))
        let v = (h: c.hour ?? 0, m: c.minute ?? 0, s: c.second ?? 0)
        hmKey = key
        hmVal = v
        return v
    }

    /// Seconds since local midnight.
    static func secondsOfDay(_ t: Double) -> Double {
        let d = Date(timeIntervalSince1970: t)
        let start = cal.startOfDay(for: d)
        return d.timeIntervalSince(start)
    }

    /// Unix time of local midnight for the day containing t.
    static func midnight(_ t: Double) -> Double {
        cal.startOfDay(for: Date(timeIntervalSince1970: t)).timeIntervalSince1970
    }

    static func now() -> Double { Date().timeIntervalSince1970 }

    /// Monotonic seconds since boot, including time asleep (unlike `systemUptime`).
    static func uptime() -> Double { Double(clock_gettime_nsec_np(CLOCK_MONOTONIC)) / 1_000_000_000 }

    /// kern.boottime, used to tell a reboot from a clock change (GDD 7.3).
    static func bootTime() -> Double {
        var tv = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        let r = sysctl(&mib, 2, &tv, &size, nil, 0)
        return r == 0 ? Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000 : 0
    }
}

// MARK: - Economy rules (GDD 2)

enum Rules {
    /// Cost of the next k levels from level n.
    static func cost(_ row: TierRow, scale: Double, level n: Int, count k: Int) -> Double {
        guard k > 0 else { return 0 }
        let r = row.growth
        let first = scale * row.baseCost * pow(r, Double(n))
        if abs(r - 1) < 1e-9 { return first * Double(k) }
        return first * (pow(r, Double(k)) - 1) / (r - 1)
    }

    /// Max affordable levels with `cash`, clamped to [0, cap − n].
    static func maxAffordable(_ row: TierRow, scale: Double, level n: Int, cash: Double, cap: Int) -> Int {
        let room = max(0, cap - n)
        guard room > 0, cash > 0 else { return 0 }
        let r = row.growth
        let first = scale * row.baseCost * pow(r, Double(n))
        guard first > 0 else { return room }
        var k = Int(floor(log(1 + cash * (r - 1) / first) / log(r)))
        k = max(0, min(room, k))
        while k > 0 && cost(row, scale: scale, level: n, count: k) > cash { k -= 1 }
        return k
    }

    static func milestonesReached(_ list: [Int], level: Int, cap: Int) -> Int {
        list.filter { $0 <= cap && $0 <= level }.count
    }

    static func nextMilestone(_ list: [Int], level: Int, cap: Int) -> Int? {
        list.first { $0 <= cap && $0 > level }
    }

    static func previousMilestone(_ list: [Int], level: Int, cap: Int) -> Int {
        list.filter { $0 <= cap && $0 <= level }.last ?? 0
    }

    /// XP needed to go from level L to L+1 (GDD 4.2).
    static func xpToNext(_ level: Int, curve: XPCurve) -> Int {
        if level >= 100 { return Int(curve.after100) }
        let raw = curve.a * pow(Double(max(1, level)), curve.p) / curve.roundTo
        return Int(curve.roundTo * raw.rounded())
    }

    /// Branch gold per day before and after the soft cap (GDD 3.5).
    static func branchGoldPerDay(levels: [Int], def: BranchesDef) -> Double {
        let total = levels.reduce(0.0) { $0 + def.goldPerDayBase * (1 + def.goldPerLevel * Double($1)) }
        if total <= def.softcapKnee { return total }
        return def.softcapKnee + def.softcapCoef * sqrt(total - def.softcapKnee)
    }
}
