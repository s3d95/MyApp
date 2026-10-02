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
}

enum GameData {
    static let maxSellers = 50
    /// Reaching these seller counts speeds a section up by `milestoneSpeed` each.
    static let milestones = [10, 25, 50]
    static let milestoneSpeed = 1.25

    static let stageThresholds = [0, 10, 40, 100, 200]
    static let stageNames = ["بسطة", "كشك", "محل", "مطعم", "سلسلة مطاعم"]

    static let maxTapLevel = 20
    static let maxAutoLevel = 15
    static func tapCost(_ level: Int) -> Double { (40 * pow(1.5, Double(level))).rounded() }
    static func autoCost(_ level: Int) -> Double { (250 * pow(1.6, Double(level))).rounded() }

    static let maxOfflineSeconds: Double = 8 * 3600
    static let homeCity = "القدس"
    static let branchBonus = 0.10

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
    ]

    private static let branchData: [(String, Double)] = [
        ("رام الله", 50_000), ("بيت لحم", 150_000), ("نابلس", 400_000), ("الخليل", 1_000_000),
        ("جنين", 2_500_000), ("طولكرم", 5_000_000), ("أريحا", 9_000_000), ("غزة", 15_000_000),
        ("يافا", 25_000_000), ("حيفا", 40_000_000), ("عكا", 60_000_000), ("الناصرة", 90_000_000),
    ]
    static let branches: [BranchDef] = branchData.map { BranchDef(city: $0.0, cost: $0.1) }

    static let upgrades: [UpgradeDef] = {
        var list: [UpgradeDef] = []
        for b in businesses {
            list.append(UpgradeDef(id: "b\(b.id)_0", title: "معدات أسرع", detail: "سرعة \(b.name) +20%",
                                   icon: b.emoji, cost: b.sellerBase * 30, section: b.id,
                                   speed: 1.2, price: 1, customers: 1))
            list.append(UpgradeDef(id: "b\(b.id)_1", title: "جودة أعلى", detail: "سعر \(b.product) +20%",
                                   icon: b.emoji, cost: b.sellerBase * 120, section: b.id,
                                   speed: 1, price: 1.2, customers: 1))
            list.append(UpgradeDef(id: "b\(b.id)_2", title: "خط تحضير تاني", detail: "سرعة \(b.name) +30%",
                                   icon: b.emoji, cost: b.sellerBase * 400, section: b.id,
                                   speed: 1.3, price: 1, customers: 1))
        }

        let globals: [(String, String, Double, Double)] = [
            ("دعاية على فيسبوك", "📣", 3_000, 1.10),
            ("يافطة مضوّية", "💡", 20_000, 1.10),
            ("خدمة توصيل", "🛵", 150_000, 1.15),
            ("تطبيق طلبات", "📱", 1_000_000, 1.20),
            ("إعلان بالتلفزيون", "📺", 8_000_000, 1.25),
        ]
        for (k, g) in globals.enumerated() {
            let pct = Int(((g.3 - 1) * 100).rounded())
            list.append(UpgradeDef(id: "all_\(k)", title: g.0, detail: "زباين أكتر: كل الأرباح +\(pct)%",
                                   icon: g.1, cost: g.2, section: nil, speed: 1, price: 1, customers: g.3))
        }
        return list.sorted { $0.cost < $1.cost }
    }()
}
