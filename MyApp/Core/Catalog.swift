import Foundation

// MARK: - Calendar helpers

enum DayClock {
    /// Local calendar day number, so "today" flips at the player's midnight.
    static func day(_ d: Date) -> Int {
        Calendar.current.ordinality(of: .day, in: .era, for: d) ?? Int(d.timeIntervalSince1970 / 86_400)
    }

    static func nextMidnight(after d: Date) -> Date {
        let start = Calendar.current.startOfDay(for: d)
        return Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
    }
}

// MARK: - Chefs (collectible cards)

enum Rarity: Int, CaseIterable {
    case common, rare, epic, legendary

    var name: String {
        switch self {
        case .common: return "عادي"
        case .rare: return "نادر"
        case .epic: return "ملحمي"
        case .legendary: return "أسطوري"
        }
    }

    var tint: UInt32 {
        switch self {
        case .common: return 0x9CA3AF
        case .rare: return 0x3B82F6
        case .epic: return 0xA855F7
        case .legendary: return 0xF59E0B
        }
    }

    /// Section profit bonus per chef level (1.0 = +100%).
    var sectionPerLevel: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.5
        case .epic: return 2.0
        case .legendary: return 0
        }
    }
}

enum ChefPerk {
    case section(Int)
    case allProfit, vip, offline, tap, cheap, stars
}

struct ChefDef: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let rarity: Rarity
    let perk: ChefPerk

    var sectionIndex: Int? {
        if case .section(let i) = perk { return i }
        return nil
    }
}

enum ChestKind: Int, CaseIterable, Identifiable {
    case wood, silver, gold

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .wood: return "صندوق خشب"
        case .silver: return "صندوق فضة"
        case .gold: return "صندوق دهب"
        }
    }

    var cards: Int {
        switch self {
        case .wood: return 5
        case .silver: return 12
        case .gold: return 30
        }
    }

    /// Drop weights for common, rare, epic, legendary.
    var weights: [Double] {
        switch self {
        case .wood: return [75, 20, 4.5, 0.5]
        case .silver: return [60, 28, 10, 2]
        case .gold: return [45, 33, 17, 5]
        }
    }

    /// One card in the chest is at least this rarity.
    var guaranteed: Rarity {
        switch self {
        case .wood: return .common
        case .silver: return .rare
        case .gold: return .epic
        }
    }

    var price: Int {
        switch self {
        case .wood: return 25
        case .silver: return 75
        case .gold: return 200
        }
    }

    var tint: UInt32 {
        switch self {
        case .wood: return 0x9A5B2E
        case .silver: return 0x94A3B8
        case .gold: return 0xF59E0B
        }
    }
}

// MARK: - Research (permanent upgrades bought with gold liras)

struct ResearchDef: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let base: Double
    let growth: Double
    let maxLevel: Int

    func cost(_ level: Int) -> Int { Int((base * pow(growth, Double(level))).rounded()) }
}

// MARK: - Achievements

struct AchievementDef: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let reward: Int
    let check: (GameState) -> Bool
}

// MARK: - Daily missions

enum MissionKind: Int, Codable, CaseIterable {
    case taps, sellers, earn, vip, rushPlays, rushScore, spin

    var icon: String {
        switch self {
        case .taps: return "👆"
        case .sellers: return "👨‍🍳"
        case .earn: return "💰"
        case .vip: return "🤵"
        case .rushPlays: return "⏱️"
        case .rushScore: return "🥙"
        case .spin: return "🎡"
        }
    }
}

struct Mission: Codable, Identifiable {
    var id: Int
    var kind: MissionKind
    var target: Double
    var reward: Int
    var claimed: Bool = false

    var text: String {
        switch kind {
        case .taps: return "اضغط على الفلافل \(Int(target)) ضغطة"
        case .sellers: return "وظّف \(Int(target)) بيّاع جديد"
        case .earn: return "اربح \(Fmt.money(target)) اليوم"
        case .vip: return "اخدم \(Int(target)) زباين VIP"
        case .rushPlays: return "العب الطلبيات السريعة \(Int(target)) مرات"
        case .rushScore: return "جهّز \(Int(target)) طلبيات بجولة وحدة"
        case .spin: return "لفّ دولاب الحظ مرة"
        }
    }
}

/// Today's counters that missions measure. Reset at local midnight.
struct DailyCounters: Codable {
    var taps: Double = 0
    var sellers: Double = 0
    var earned: Double = 0
    var vips: Double = 0
    var rushPlays: Double = 0
    var rushBest: Double = 0
    var spins: Double = 0

    func value(_ k: MissionKind) -> Double {
        switch k {
        case .taps: return taps
        case .sellers: return sellers
        case .earn: return earned
        case .vip: return vips
        case .rushPlays: return rushPlays
        case .rushScore: return rushBest
        case .spin: return spins
        }
    }
}

// MARK: - Lucky wheel

enum WheelPrize: Int, CaseIterable {
    case cashSmall, liraSmall, woodChest, cashBig, liraMid, boost, silverChest, jackpot

    var weight: Double {
        switch self {
        case .cashSmall: return 22
        case .liraSmall: return 20
        case .woodChest: return 14
        case .cashBig: return 12
        case .liraMid: return 12
        case .boost: return 10
        case .silverChest: return 6
        case .jackpot: return 4
        }
    }

    var emoji: String {
        switch self {
        case .cashSmall: return "💵"
        case .liraSmall: return "🪙"
        case .woodChest: return "📦"
        case .cashBig: return "💰"
        case .liraMid: return "🪙"
        case .boost: return "⚡"
        case .silverChest: return "🎁"
        case .jackpot: return "💎"
        }
    }

    var short: String {
        switch self {
        case .cashSmall: return "10 دقايق"
        case .liraSmall: return "5"
        case .woodChest: return "خشب"
        case .cashBig: return "ساعة"
        case .liraMid: return "15"
        case .boost: return "×2"
        case .silverChest: return "فضة"
        case .jackpot: return "50"
        }
    }

    var tint: UInt32 {
        switch self {
        case .cashSmall: return 0x15803D
        case .liraSmall: return 0xB45309
        case .woodChest: return 0x7C2D12
        case .cashBig: return 0x166534
        case .liraMid: return 0xC2410C
        case .boost: return 0x1D4ED8
        case .silverChest: return 0x475569
        case .jackpot: return 0x7E22CE
        }
    }
}

// MARK: - Daily login track (7-day cycle)

struct LoginReward {
    let liras: Int
    let chest: ChestKind?
    let boostMinutes: Int

    var icon: String {
        if let c = chest {
            switch c {
            case .wood: return "📦"
            case .silver: return "🎁"
            case .gold: return "👑"
            }
        }
        if boostMinutes > 0 { return "⚡" }
        return "🪙"
    }

    var text: String {
        var parts: [String] = []
        if let c = chest { parts.append(c.name) }
        if liras > 0 { parts.append("\(liras) ليرة") }
        if boostMinutes > 0 { parts.append("أرباح ×2 لمدة \(boostMinutes / 60) ساعة") }
        return parts.joined(separator: " + ")
    }
}

// MARK: - Deterministic-free helpers

enum Pick {
    static func weighted(_ weights: [Double]) -> Int {
        let total = weights.reduce(0, +)
        var r = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            if r < w { return i }
            r -= w
        }
        return weights.count - 1
    }

    /// Rounds a target to two significant digits so mission goals look tidy.
    static func tidy(_ v: Double) -> Double {
        guard v >= 100 else { return v.rounded() }
        let p = pow(10, floor(log10(v)) - 1)
        return (v / p).rounded() * p
    }
}

// MARK: - Catalog tables

enum Catalog {
    static let chefs: [ChefDef] = [
        ChefDef(id: 0, name: "عبودي القلّاي", emoji: "👨‍🍳", rarity: .common, perk: .section(0)),
        ChefDef(id: 1, name: "صبحي الفرّان", emoji: "🧔", rarity: .common, perk: .section(1)),
        ChefDef(id: 2, name: "لولو العصّيرة", emoji: "👩‍🍳", rarity: .common, perk: .section(2)),
        ChefDef(id: 3, name: "حسّونة", emoji: "👦", rarity: .common, perk: .section(3)),
        ChefDef(id: 4, name: "شيف رامز", emoji: "🧑‍🍳", rarity: .rare, perk: .section(4)),
        ChefDef(id: 5, name: "نبيل الحلواني", emoji: "👨‍🦰", rarity: .rare, perk: .section(5)),
        ChefDef(id: 6, name: "خالتي سهام", emoji: "👩‍🦱", rarity: .rare, perk: .section(6)),
        ChefDef(id: 7, name: "الشيخ مفلح", emoji: "👳", rarity: .rare, perk: .section(7)),
        ChefDef(id: 8, name: "أبو جميل المشاوي", emoji: "👨‍🦳", rarity: .epic, perk: .section(8)),
        ChefDef(id: 9, name: "ستّ نوال", emoji: "🧕", rarity: .epic, perk: .section(9)),
        ChefDef(id: 10, name: "أبو رامي القطايفي", emoji: "🧓", rarity: .epic, perk: .section(10)),
        ChefDef(id: 11, name: "معلّم الولايم", emoji: "🤴", rarity: .epic, perk: .section(11)),
        ChefDef(id: 12, name: "ستّي أم خليل", emoji: "👵", rarity: .legendary, perk: .allProfit),
        ChefDef(id: 13, name: "الحكواتي", emoji: "🧙‍♂️", rarity: .legendary, perk: .vip),
        ChefDef(id: 14, name: "أبو الدروب", emoji: "🛵", rarity: .legendary, perk: .offline),
        ChefDef(id: 15, name: "المعلّم الكبير", emoji: "👨‍🏫", rarity: .legendary, perk: .tap),
        ChefDef(id: 16, name: "التاجر الشاطر", emoji: "🧑‍💼", rarity: .legendary, perk: .cheap),
        ChefDef(id: 17, name: "النجمة", emoji: "👩‍🎤", rarity: .legendary, perk: .stars),
    ]

    static let maxChefLevel = 10
    /// Spare cards needed to go from level L to L+1 (index L-1).
    static let chefLevelCards = [2, 4, 6, 10, 15, 22, 32, 45, 60]

    static func chefs(of r: Rarity) -> [ChefDef] { chefs.filter { $0.rarity == r } }

    static func chefIndex(_ perk: ChefPerk) -> Int {
        switch perk {
        case .section(let i): return i
        case .allProfit: return 12
        case .vip: return 13
        case .offline: return 14
        case .tap: return 15
        case .cheap: return 16
        case .stars: return 17
        }
    }

    static func perkText(_ c: ChefDef, level: Int) -> String {
        let l = Double(max(1, level))
        switch c.perk {
        case .section(let i):
            let pct = Int((c.rarity.sectionPerLevel * l * 100).rounded())
            return "أرباح \(GameData.businesses[i].name) +\(pct)%"
        case .allProfit: return "كل الأرباح +\(Int(50 * l))%"
        case .vip: return "زباين VIP أكتر ومكافأتهم +\(Int(50 * l))%"
        case .offline: return "أرباح الغياب +\(Int(25 * l))%"
        case .tap: return "قوة الضغطة +\(Int(100 * l))%"
        case .cheap: return "البيّاعين أرخص \(Int((1 - pow(0.97, l)) * 100))%"
        case .stars: return "قوة كل نجمة +\(Int(10 * l))%"
        }
    }

    // Research ids, used as indexes into `GameState.research`.
    static let rProfit = 0, rTap = 1, rOffline = 2, rVIP = 3, rCheap = 4, rStars = 5, rStart = 6, rTickets = 7

    static let research: [ResearchDef] = [
        ResearchDef(id: 0, icon: "🧪", title: "خلطة سرّية", base: 15, growth: 1.25, maxLevel: 100),
        ResearchDef(id: 1, icon: "✋", title: "إيد ذهب", base: 10, growth: 1.3, maxLevel: 30),
        ResearchDef(id: 2, icon: "🌙", title: "نومة هنية", base: 20, growth: 1.35, maxLevel: 16),
        ResearchDef(id: 3, icon: "🤵", title: "زباين أوفياء", base: 15, growth: 1.3, maxLevel: 20),
        ResearchDef(id: 4, icon: "🤝", title: "مفاوض شاطر", base: 25, growth: 1.35, maxLevel: 20),
        ResearchDef(id: 5, icon: "⭐", title: "صيت واسع", base: 30, growth: 1.35, maxLevel: 30),
        ResearchDef(id: 6, icon: "💼", title: "رأس مال", base: 20, growth: 1.6, maxLevel: 10),
        ResearchDef(id: 7, icon: "🎟️", title: "تذاكر زيادة", base: 25, growth: 1.8, maxLevel: 5),
    ]

    static func researchText(_ id: Int, level: Int) -> String {
        let l = level
        switch id {
        case rProfit: return "كل الأرباح +\(25 * l)%"
        case rTap: return "قوة الضغطة +\(50 * l)%"
        case rOffline: return "المدراء بيشتغلوا وإنت برّا \(Int(GameData.baseOfflineHours) + l) ساعة"
        case rVIP: return "VIP بيجي أسرع \(5 * l)% ومكافأته +\(25 * l)%"
        case rCheap: return "البيّاعين أرخص \(Int(((1 - pow(0.98, Double(l))) * 100).rounded()))%"
        case rStars: return "نجوم الشهرة +\(10 * l)%"
        case rStart: return l == 0 ? "بتبلّش من صفر بعد إعادة الافتتاح" : "بتبلّش بـ \(Fmt.money(startMoney(l))) بعد إعادة الافتتاح"
        case rTickets: return "حد التذاكر \(3 + l)"
        default: return ""
        }
    }

    static func startMoney(_ level: Int) -> Double { level <= 0 ? 0 : pow(10, Double(level + 2)) }

    // MARK: Login track

    static let loginTrack: [LoginReward] = [
        LoginReward(liras: 10, chest: nil, boostMinutes: 0),
        LoginReward(liras: 0, chest: .wood, boostMinutes: 0),
        LoginReward(liras: 20, chest: nil, boostMinutes: 0),
        LoginReward(liras: 0, chest: nil, boostMinutes: 60),
        LoginReward(liras: 0, chest: .silver, boostMinutes: 0),
        LoginReward(liras: 40, chest: nil, boostMinutes: 0),
        LoginReward(liras: 50, chest: .gold, boostMinutes: 0),
    ]

    // MARK: Missions

    static func makeMissions(income: Double) -> [Mission] {
        var pool = MissionKind.allCases.shuffled()
        // The wheel mission is too easy to come up every day.
        if Bool.random(), let k = pool.firstIndex(of: .spin) { pool.remove(at: k) }
        let rewards = [10, 15, 20]
        var list: [Mission] = []
        for (n, kind) in pool.prefix(3).enumerated() {
            let tier = Int.random(in: 0...2)
            let target: Double
            switch kind {
            case .taps: target = [150, 300, 500][tier]
            case .sellers: target = [20, 40, 75][tier]
            case .earn: target = Pick.tidy(max(500, income * [300, 600, 1_200][tier]))
            case .vip: target = [2, 3, 4][tier]
            case .rushPlays: target = [1, 2, 3][tier]
            case .rushScore: target = [5, 8, 12][tier]
            case .spin: target = 1
            }
            list.append(Mission(id: n, kind: kind, target: target, reward: kind == .spin ? 8 : rewards[tier]))
        }
        return list
    }

    // MARK: Rush mini-game

    static let rushIngredients: [(String, String)] = [
        ("🫓", "خبز"), ("🧆", "فلافل"), ("🍅", "بندورة"), ("🥒", "خيار"),
        ("🧅", "بصل"), ("🥬", "خس"), ("🌶️", "شطّة"), ("🍋", "ليمون"),
    ]
    static let rushCustomers = ["👨", "👩", "🧔", "👵", "👴", "👦", "👧", "🧕", "👷", "👮", "🧑‍🎓", "👨‍💼"]
    static let rushSeconds: Double = 30
    static let ticketHours: Double = 1.5

    // MARK: Achievements

    static let achievements: [AchievementDef] = {
        var list: [AchievementDef] = []
        func add(_ id: String, _ icon: String, _ title: String, _ detail: String, _ tier: Int,
                 _ check: @escaping (GameState) -> Bool) {
            list.append(AchievementDef(id: id, icon: icon, title: title, detail: detail,
                                       reward: min(60, 5 + tier * 5), check: check))
        }

        let earnSteps: [(Double, String)] = [
            (1e3, "أول ألف"), (1e5, "مية ألف"), (1e6, "مليونير"), (1e8, "مية مليون"),
            (1e9, "مليارديير"), (1e11, "مية مليار"), (1e12, "تريليونير"), (1e14, "ملك السوق"),
            (1e15, "حوت الاقتصاد"), (1e18, "أسطورة المال"), (1e21, "خزنة ما بتخلص"),
            (1e24, "بنك الفلافل"), (1e27, "إمبراطور الذهب"), (1e30, "ما في أغنى منك"),
        ]
        for (k, e) in earnSteps.enumerated() {
            add("earn_\(k)", "💰", e.1, "اربح \(Fmt.money(e.0)) بكل الأوقات", k) { $0.allTimeEarnings >= e.0 }
        }

        let sellerSteps = [25, 100, 250, 500, 1_000, 2_000, 4_000]
        for (k, n) in sellerSteps.enumerated() {
            add("sellers_\(k)", "👨‍🍳", "فريق \(n)", "وصّل عدد البيّاعين لـ \(n)", k) { $0.totalSellers >= n }
        }

        for b in GameData.businesses {
            add("sec100_\(b.id)", b.emoji, "معلّم \(b.name)", "100 بيّاع بقسم \(b.name)", 2) { $0.lines[b.id].owned >= 100 }
        }
        for b in GameData.businesses {
            add("sec300_\(b.id)", b.emoji, "أسطورة \(b.name)", "300 بيّاع بقسم \(b.name)", 6) { $0.lines[b.id].owned >= 300 }
        }

        let tapSteps = [100, 1_000, 10_000, 50_000, 100_000]
        for (k, n) in tapSteps.enumerated() {
            add("taps_\(k)", "👆", "\(Fmt.number(Double(n))) ضغطة", "اضغط على الفلافل \(Fmt.number(Double(n))) مرة", k) { $0.totalTaps >= n }
        }

        let prestigeSteps = [1, 3, 5, 10, 25, 50]
        for (k, n) in prestigeSteps.enumerated() {
            add("prestige_\(k)", "🔄", "افتتاح رقم \(n)", "اعمل إعادة افتتاح \(n) مرات", k + 1) { $0.prestigeCount >= n }
        }

        let starSteps: [Double] = [10, 100, 1_000, 10_000, 100_000, 1_000_000]
        for (k, n) in starSteps.enumerated() {
            add("stars_\(k)", "⭐", "\(Fmt.number(n)) نجمة", "جمّع \(Fmt.number(n)) نجمة شهرة", k + 1) { $0.stars >= n }
        }

        let streakSteps = [3, 7, 14, 30, 60, 100]
        for (k, n) in streakSteps.enumerated() {
            add("streak_\(k)", "🔥", "\(n) يوم ورا بعض", "افتح اللعبة \(n) يوم ورا بعض", k + 1) { $0.bestStreak >= n }
        }

        let missionSteps = [10, 50, 100, 300, 1_000]
        for (k, n) in missionSteps.enumerated() {
            add("missions_\(k)", "📋", "\(n) مهمة", "خلّص \(n) مهمة يومية", k) { $0.missionsDone >= n }
        }

        let vipSteps = [10, 50, 200, 1_000]
        for (k, n) in vipSteps.enumerated() {
            add("vip_\(k)", "🤵", "\(n) زبون VIP", "اخدم \(n) زبون VIP", k) { $0.vipsClaimed >= n }
        }

        let chefSteps = [3, 6, 12, 18]
        for (k, n) in chefSteps.enumerated() {
            add("chefs_\(k)", "🧑‍🍳", "\(n) طبّاخين", "جمّع \(n) طبّاخين مختلفين", k + 1) { $0.chefsOwned >= n }
        }

        let chefLevelSteps = [25, 50, 100, 180]
        for (k, n) in chefLevelSteps.enumerated() {
            add("cheflv_\(k)", "🎖️", "مطبخ محترف \(k + 1)", "مجموع مستويات الطبّاخين \(n)", k + 2) { $0.chefLevelsTotal >= n }
        }

        let rushSteps = [5, 10, 15, 20, 30]
        for (k, n) in rushSteps.enumerated() {
            add("rush_\(k)", "⏱️", "\(n) طلبيات", "جهّز \(n) طلبيات بجولة وحدة", k) { $0.bestRush >= n }
        }

        let branchSteps = [12, 24, 36]
        let branchTitles = ["كل فلسطين", "كل الوطن العربي", "حول العالم"]
        for (k, n) in branchSteps.enumerated() {
            add("branch_\(k)", "🏙️", branchTitles[k], "افتح \(n) فرع", k * 2 + 2) { $0.branchesOwned >= n }
        }

        let chestSteps = [10, 50, 200]
        for (k, n) in chestSteps.enumerated() {
            add("chests_\(k)", "📦", "\(n) صندوق", "افتح \(n) صندوق", k + 1) { $0.chestsOpened >= n }
        }

        let allSteps = [1, 3, 5]
        for (k, n) in allSteps.enumerated() {
            add("all_\(k)", "🏆", "كل الأقسام \(k + 1)", "حقّق \(n) أهداف \"كل الأقسام\"", k * 2 + 2) { $0.allSectionsLevel >= n }
        }
        return list
    }()
}
