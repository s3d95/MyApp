import Foundation

/// A food section of the stall. Each seller (بيّاع) sells one item per cycle.
struct BusinessDef: Identifiable {
    let id: Int
    let name: String
    let product: String
    let emoji: String
    let price: Double
    let baseTime: Double
    let unlockCost: Double
    let sellerBase: Double
    let growth: Double
    let managerCost: Double
    let managerName: String
    let managerEmoji: String
    let tint: UInt32
}

/// One-time upgrade. `section == nil` means it applies to the whole stall.
struct UpgradeDef: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let cost: Double
    let section: Int?
    let speed: Double
    let price: Double
    let customers: Double
}

struct BranchDef {
    let city: String
    let cost: Double
    /// Added to the branch multiplier, so 0.10 means +10% on all profit.
    let bonus: Double
    let region: Int
}

enum GameData {
    /// Sellers per section are effectively uncapped; costs grow exponentially long before this.
    static let maxSellers = 10_000
    /// Reaching these seller counts speeds a section up by `milestoneSpeed` each.
    static let milestones = [10, 25, 50]
    static let milestoneSpeed = 1.25
    /// From 100 sellers on, every 100 more doubles the section's profit.
    static let profitStep = 100

    static let stageThresholds = [0, 10, 40, 100, 200, 600, 1500]
    static let stageNames = ["بسطة", "كشك", "محل", "مطعم", "سلسلة مطاعم", "إمبراطورية", "علامة عالمية"]

    static let maxTapLevel = 25
    static let maxAutoLevel = 25
    static let maxShareLevel = 10
    /// Each "ضغطة البركة" level adds this share of income per second to every tap.
    static let sharePerLevel = 0.005
    static func tapCost(_ level: Int) -> Double { (40 * pow(1.5, Double(level))).rounded() }
    static func autoCost(_ level: Int) -> Double { (250 * pow(1.6, Double(level))).rounded() }
    static func shareCost(_ level: Int) -> Double { (50_000 * pow(6, Double(level))).rounded() }

    static let baseOfflineHours: Double = 8
    static let homeCity = "القدس"

    static let regionNames = ["فلسطين", "الوطن العربي", "العالم"]

    static let businesses: [BusinessDef] = [
        BusinessDef(id: 0, name: "فلافل", product: "سندويشة فلافل", emoji: "🧆",
                    price: 7, baseTime: 4, unlockCost: 0, sellerBase: 12, growth: 1.07,
                    managerCost: 500, managerName: "أبو العبد", managerEmoji: "👨‍🍳", tint: 0xD97706),
        BusinessDef(id: 1, name: "كعك بالسمسم", product: "كعكة بالبيض والزعتر", emoji: "🥯",
                    price: 10, baseTime: 5, unlockCost: 300, sellerBase: 60, growth: 1.07,
                    managerCost: 2_500, managerName: "أبو صالح", managerEmoji: "🧔", tint: 0xB45309),
        BusinessDef(id: 2, name: "ليمون بالنعنع", product: "كاسة ليمون ونعنع", emoji: "🍋",
                    price: 12, baseTime: 4, unlockCost: 1_500, sellerBase: 250, growth: 1.07,
                    managerCost: 10_000, managerName: "أم سليم", managerEmoji: "👩‍🍳", tint: 0xCA8A04),
        BusinessDef(id: 3, name: "حمص وفول", product: "صحن حمص وفول", emoji: "🥣",
                    price: 22, baseTime: 6, unlockCost: 6_000, sellerBase: 1_000, growth: 1.07,
                    managerCost: 40_000, managerName: "الحجة فاطمة", managerEmoji: "🧕", tint: 0x65A30D),
        BusinessDef(id: 4, name: "شاورما", product: "سندويشة شاورما", emoji: "🌯",
                    price: 30, baseTime: 6, unlockCost: 25_000, sellerBase: 4_000, growth: 1.07,
                    managerCost: 150_000, managerName: "أبو خليل", managerEmoji: "👨‍🦱", tint: 0xEA580C),
        BusinessDef(id: 5, name: "كنافة", product: "صحن كنافة نابلسية", emoji: "🍰",
                    price: 45, baseTime: 8, unlockCost: 100_000, sellerBase: 15_000, growth: 1.07,
                    managerCost: 500_000, managerName: "أبو سمير", managerEmoji: "👴", tint: 0xDC2626),
        BusinessDef(id: 6, name: "مسخّن", product: "صدر مسخّن", emoji: "🍗",
                    price: 75, baseTime: 10, unlockCost: 400_000, sellerBase: 60_000, growth: 1.07,
                    managerCost: 2_000_000, managerName: "أم يوسف", managerEmoji: "👵", tint: 0x16A34A),
        BusinessDef(id: 7, name: "منسف", product: "سدر منسف", emoji: "🍛",
                    price: 150, baseTime: 15, unlockCost: 1_500_000, sellerBase: 220_000, growth: 1.07,
                    managerCost: 7_000_000, managerName: "أبو ماهر", managerEmoji: "🧓", tint: 0x92400E),
        BusinessDef(id: 8, name: "مشاوي", product: "سيخ مشاوي مشكّل", emoji: "🍢",
                    price: 320, baseTime: 18, unlockCost: 8_000_000, sellerBase: 1_100_000, growth: 1.07,
                    managerCost: 30_000_000, managerName: "أبو جميل", managerEmoji: "🧑‍🍳", tint: 0xB91C1C),
        BusinessDef(id: 9, name: "مقلوبة", product: "قدرة مقلوبة", emoji: "🍲",
                    price: 700, baseTime: 22, unlockCost: 50_000_000, sellerBase: 6_000_000, growth: 1.07,
                    managerCost: 150_000_000, managerName: "أم محمد", managerEmoji: "🧕", tint: 0x7C3AED),
        BusinessDef(id: 10, name: "قطايف", product: "صينية قطايف", emoji: "🥟",
                    price: 1_600, baseTime: 26, unlockCost: 350_000_000, sellerBase: 35_000_000, growth: 1.07,
                    managerCost: 1_000_000_000, managerName: "أبو رامي", managerEmoji: "👨‍🦳", tint: 0x0891B2),
        BusinessDef(id: 11, name: "وليمة عرس", product: "وليمة عرس كاملة", emoji: "🎉",
                    price: 4_000, baseTime: 32, unlockCost: 2_500_000_000, sellerBase: 220_000_000, growth: 1.07,
                    managerCost: 7_000_000_000, managerName: "الحاج عبدالله", managerEmoji: "👳", tint: 0xDB2777),
    ]

    private static let branchData: [(String, Double, Int)] = [
        ("رام الله", 50_000, 0), ("بيت لحم", 150_000, 0), ("نابلس", 400_000, 0), ("الخليل", 1_000_000, 0),
        ("جنين", 2_500_000, 0), ("طولكرم", 5_000_000, 0), ("أريحا", 9_000_000, 0), ("غزة", 15_000_000, 0),
        ("يافا", 25_000_000, 0), ("حيفا", 40_000_000, 0), ("عكا", 60_000_000, 0), ("الناصرة", 90_000_000, 0),
        ("عمّان", 2.5e8, 1), ("بيروت", 6e8, 1), ("دمشق", 1.5e9, 1), ("القاهرة", 4e9, 1),
        ("بغداد", 1e10, 1), ("الرياض", 2.5e10, 1), ("الكويت", 6e10, 1), ("الدوحة", 1.5e11, 1),
        ("دبي", 4e11, 1), ("تونس", 1e12, 1), ("الجزائر", 2.5e12, 1), ("الرباط", 6e12, 1),
        ("إسطنبول", 2e13, 2), ("لندن", 6e13, 2), ("باريس", 2e14, 2), ("برلين", 6e14, 2),
        ("مدريد", 2e15, 2), ("روما", 6e15, 2), ("موسكو", 2e16, 2), ("نيويورك", 6e16, 2),
        ("تورونتو", 2e17, 2), ("ساو باولو", 6e17, 2), ("طوكيو", 2e18, 2), ("سيدني", 6e18, 2),
    ]
    static let regionBonus = [0.10, 0.25, 0.50]
    static let branches: [BranchDef] = branchData.map {
        BranchDef(city: $0.0, cost: $0.1, bonus: regionBonus[$0.2], region: $0.2)
    }

    /// Per-section upgrade ladder: (title, cost × sellerBase, speed, price).
    private static let sectionLadder: [(String, Double, Double, Double)] = [
        ("معدات أسرع", 30, 1.2, 1),
        ("جودة أعلى", 120, 1, 1.2),
        ("خط تحضير تاني", 400, 1.3, 1),
        ("مكونات بلدي", 5_000, 1, 1.5),
        ("تغليف فخم", 100_000, 1, 2),
        ("وصفة ستّي السرية", 5_000_000, 1, 3),
        ("مطبخ أوتوماتيك", 100_000_000, 1.5, 1),
    ]

    private static let globalAds: [(String, String, Double, Double)] = [
        ("دعاية على فيسبوك", "📣", 3_000, 1.10),
        ("يافطة مضوّية", "💡", 20_000, 1.10),
        ("خدمة توصيل", "🛵", 150_000, 1.15),
        ("تطبيق طلبات", "📱", 1_000_000, 1.20),
        ("إعلان بالتلفزيون", "📺", 8_000_000, 1.25),
        ("لوحة على الأوتوستراد", "🛣️", 6e7, 1.25),
        ("رعاية فريق كرة", "⚽", 5e8, 1.30),
        ("مشهور على تيك توك", "🎬", 5e9, 1.35),
        ("مسلسل رمضاني", "🌙", 5e10, 1.40),
        ("مهرجان الفلافل", "🎪", 6e11, 1.50),
        ("دعاية بالمطارات", "✈️", 8e12, 1.50),
        ("قناة طبخ عالمية", "📡", 1e14, 1.75),
        ("ماركة عالمية مسجّلة", "🌍", 2e15, 2.00),
    ]

    static let upgrades: [UpgradeDef] = {
        var list: [UpgradeDef] = []
        for b in businesses {
            for (k, step) in sectionLadder.enumerated() {
                let detail: String
                if step.2 > 1 {
                    detail = "سرعة \(b.name) +\(Int(((step.2 - 1) * 100).rounded()))%"
                } else if step.3 >= 2 {
                    detail = "سعر \(b.product) ×\(Int(step.3))"
                } else {
                    detail = "سعر \(b.product) +\(Int(((step.3 - 1) * 100).rounded()))%"
                }
                list.append(UpgradeDef(id: "b\(b.id)_\(k)", title: step.0, detail: detail,
                                       icon: b.emoji, cost: b.sellerBase * step.1, section: b.id,
                                       speed: step.2, price: step.3, customers: 1))
            }
        }
        for (k, g) in globalAds.enumerated() {
            let pct = Int(((g.3 - 1) * 100).rounded())
            list.append(UpgradeDef(id: "all_\(k)", title: g.0, detail: "زباين أكتر: كل الأرباح +\(pct)%",
                                   icon: g.1, cost: g.2, section: nil, speed: 1, price: 1, customers: g.3))
        }
        return list.sorted { $0.cost < $1.cost }
    }()

    /// Upgrades grouped by section index for fast lookup in hot paths.
    static let upgradesBySection: [[UpgradeDef]] = businesses.map { b in upgrades.filter { $0.section == b.id } }
    static let globalUpgrades: [UpgradeDef] = upgrades.filter { $0.section == nil }

    /// "All sections" goals: every section reaching one of these doubles all profit.
    static func allSectionsLevel(minOwned: Int) -> Int {
        var level = 0
        if minOwned >= 25 { level += 1 }
        if minOwned >= 50 { level += 1 }
        level += minOwned / 100
        return level
    }

    static func nextAllSectionsGoal(minOwned: Int) -> Int {
        if minOwned < 25 { return 25 }
        if minOwned < 50 { return 50 }
        return (minOwned / 100 + 1) * 100
    }
}
