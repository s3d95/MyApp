import Foundation

struct BusinessDef: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let baseCost: Double
    let growth: Double
    let baseRevenue: Double
    let baseTime: Double
    let managerCost: Double
    let managerName: String
    let managerEmoji: String
    let tint: UInt32
}

enum UpgradeTarget: Equatable {
    case business(Int)
    case all
    case tap
}

struct UpgradeDef: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let cost: Double
    let target: UpgradeTarget
    let multiplier: Double
}

enum GameData {
    static let businesses: [BusinessDef] = [
        BusinessDef(id: 0, name: "فلافل", emoji: "🧆", baseCost: 4, growth: 1.07,
                    baseRevenue: 1, baseTime: 1, managerCost: 1_000,
                    managerName: "أبو العبد", managerEmoji: "👨‍🍳", tint: 0xD97706),
        BusinessDef(id: 1, name: "ليمون بالنعنع", emoji: "🍋", baseCost: 60, growth: 1.15,
                    baseRevenue: 60, baseTime: 3, managerCost: 15_000,
                    managerName: "أم سليم", managerEmoji: "👩‍🍳", tint: 0xCA8A04),
        BusinessDef(id: 2, name: "كعك بالسمسم", emoji: "🥯", baseCost: 720, growth: 1.14,
                    baseRevenue: 540, baseTime: 6, managerCost: 100_000,
                    managerName: "أبو صالح", managerEmoji: "🧔", tint: 0xB45309),
        BusinessDef(id: 3, name: "حمص وفول", emoji: "🥣", baseCost: 8_640, growth: 1.13,
                    baseRevenue: 4_320, baseTime: 12, managerCost: 500_000,
                    managerName: "الحجة فاطمة", managerEmoji: "🧕", tint: 0x65A30D),
        BusinessDef(id: 4, name: "شاورما", emoji: "🌯", baseCost: 103_680, growth: 1.12,
                    baseRevenue: 51_840, baseTime: 24, managerCost: 1_200_000,
                    managerName: "أبو خليل", managerEmoji: "👨‍🦱", tint: 0xEA580C),
        BusinessDef(id: 5, name: "كنافة نابلسية", emoji: "🍰", baseCost: 1_244_160, growth: 1.11,
                    baseRevenue: 622_080, baseTime: 48, managerCost: 10_000_000,
                    managerName: "أبو سمير", managerEmoji: "👴", tint: 0xDC2626),
        BusinessDef(id: 6, name: "مسخّن", emoji: "🍗", baseCost: 14_929_920, growth: 1.10,
                    baseRevenue: 7_464_960, baseTime: 96, managerCost: 111_000_000,
                    managerName: "أم يوسف", managerEmoji: "👵", tint: 0x16A34A),
        BusinessDef(id: 7, name: "قهوة عربية", emoji: "☕", baseCost: 179_159_040, growth: 1.09,
                    baseRevenue: 89_579_520, baseTime: 192, managerCost: 555_000_000,
                    managerName: "أبو ماهر", managerEmoji: "🧓", tint: 0x92400E),
    ]

    /// Owning this many units of a section doubles its speed each time.
    static let milestones = [25, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]

    static let stageThresholds = [0, 25, 100, 300, 800]
    static let stageNames = ["بسطة", "كشك", "محل", "مطعم", "سلسلة مطاعم"]

    static let cities = ["القدس", "رام الله", "نابلس", "الخليل", "بيت لحم", "جنين", "طولكرم",
                         "أريحا", "غزة", "يافا", "حيفا", "عكا", "الناصرة", "صفد"]

    static let upgrades: [UpgradeDef] = {
        var list: [UpgradeDef] = []

        let tiers: [(String, Double)] = [("مكونات أطيب", 2_500), ("وصفة الستّي", 2.5e6),
                                         ("معدات احترافية", 2.5e9), ("شهرة بكل البلد", 2.5e12),
                                         ("سرّ المهنة", 2.5e15)]
        for b in businesses {
            for (t, tier) in tiers.enumerated() {
                list.append(UpgradeDef(id: "b\(b.id)_\(t)", title: tier.0,
                                       detail: "أرباح \(b.name) ×3", icon: b.emoji,
                                       cost: b.baseCost * tier.1, target: .business(b.id), multiplier: 3))
            }
        }

        let globals: [(String, String, Double)] = [("دعاية على فيسبوك", "📣", 1e6), ("يافطة مضوّية", "💡", 1e9),
                                                   ("خدمة توصيل", "🛵", 1e12), ("تطبيق طلبات", "📱", 1e15),
                                                   ("برنامج تلفزيوني", "📺", 1e18), ("علامة تجارية عالمية", "🌍", 1e21)]
        for (k, g) in globals.enumerated() {
            list.append(UpgradeDef(id: "all_\(k)", title: g.0, detail: "أرباح كل الأقسام ×3",
                                   icon: g.1, cost: g.2, target: .all, multiplier: 3))
        }

        let taps: [(String, String, Double)] = [("إيد سريعة", "✋", 100), ("ملقط ذهبي", "🥢", 5_000),
                                                ("قلّاية مزدوجة", "🍳", 250_000), ("ماكينة فلافل", "⚙️", 2.5e7),
                                                ("روبوت طبّاخ", "🤖", 2.5e9)]
        for (k, t) in taps.enumerated() {
            list.append(UpgradeDef(id: "tap_\(k)", title: t.0, detail: "ربح الضغطة ×2",
                                   icon: t.1, cost: t.2, target: .tap, multiplier: 2))
        }

        return list.sorted { $0.cost < $1.cost }
    }()
}
