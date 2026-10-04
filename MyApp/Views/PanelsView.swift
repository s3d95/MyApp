import SwiftUI

let twoColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

// MARK: - Upgrades tab (upgrades + managers)

enum UpgradesPage: Hashable, CaseIterable {
    case upgrades, managers

    var title: String {
        switch self {
        case .upgrades: return "⬆️ التطويرات"
        case .managers: return "👔 المدراء"
        }
    }
}

struct UpgradesTab: View {
    @EnvironmentObject var game: Game
    @State private var page: UpgradesPage = .upgrades

    var body: some View {
        VStack(spacing: 0) {
            SegmentChips(items: UpgradesPage.allCases, selection: $page, title: { $0.title }, badge: { p in
                p == .managers ? Badges.managers(game.s) : Badges.upgrades(game.s)
            })
            switch page {
            case .upgrades: UpgradesView()
            case .managers: ManagersView()
            }
        }
    }
}

// MARK: - Managers

struct ManagersView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "المدراء",
                             subtitle: "المدير بيشغّل القسم عنك بدون ما تضغط، وبيضل يبيع حتى وإنت مسكّر اللعبة.")
                LazyVGrid(columns: twoColumns, spacing: 10) {
                    ForEach(GameData.businesses) { def in
                        ManagerTile(def: def)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct ManagerTile: View {
    @EnvironmentObject var game: Game
    let def: BusinessDef

    var body: some View {
        let line = game.s.lines[def.id]
        VStack(spacing: 6) {
            EmojiBubble(emoji: def.managerEmoji, tint: Color(hex: def.tint), size: 50)
            Text(def.managerName)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
            Text("قسم \(def.name) \(def.emoji)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
            Spacer(minLength: 0)
            if line.hasManager {
                Text("✅ شغّال")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.money)
                    .padding(.vertical, 9)
            } else if line.owned == 0 {
                Text("🔒 افتح القسم أول")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .padding(.vertical, 9)
            } else {
                PriceButton(title: "وظّف", price: Fmt.money(def.managerCost),
                            enabled: game.s.money >= def.managerCost) {
                    game.hire(def.id)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .card()
        .opacity(line.owned == 0 ? 0.55 : 1)
    }
}

// MARK: - Upgrades

struct UpgradesView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        let available = GameData.upgrades.filter { u in
            guard !s.purchased.contains(u.id) else { return false }
            if let sec = u.section { return s.lines[sec].owned > 0 }
            return true
        }

        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "التطويرات",
                             subtitle: "اشتريت \(s.purchased.count) من \(GameData.upgrades.count) تطوير. بترجع تنفتح بعد إعادة الافتتاح.")

                AllSectionsCard()

                LazyVGrid(columns: twoColumns, spacing: 10) {
                    LevelCard(icon: "🤖", title: "الأوتو كليكر",
                              value: s.autoLevel == 0 ? "مش مفعّل" : "\(s.autoLevel) ضغطة بالثانية",
                              level: s.autoLevel, maxLevel: GameData.maxAutoLevel,
                              cost: s.nextAutoCost, buttonTitle: s.autoLevel == 0 ? "شغّله" : "+1 ضغطة/ث") {
                        game.upgradeAuto()
                    }
                    LevelCard(icon: "✋", title: "قوة الضغطة",
                              value: "\(Fmt.money(Double(1 + s.tapLevel) * s.tapMultiplier)) بالضغطة",
                              level: s.tapLevel, maxLevel: GameData.maxTapLevel,
                              cost: s.nextTapCost, buttonTitle: "قوّي الضغطة") {
                        game.upgradeTap()
                    }
                }

                LevelCard(icon: "✨", title: "ضغطة البركة",
                          value: s.shareLevel == 0
                              ? "كل ضغطة بتجيب جزء من دخلك بالثانية"
                              : "كل ضغطة = \(Fmt.percent(s.shareRate)) من دخلك بالثانية",
                          level: s.shareLevel, maxLevel: GameData.maxShareLevel,
                          cost: s.nextShareCost,
                          buttonTitle: "+\(Fmt.percent(GameData.sharePerLevel)) من الدخل") {
                    game.upgradeShare()
                }

                if !available.isEmpty {
                    Text("تطويرات الأقسام والدعاية")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                LazyVGrid(columns: twoColumns, spacing: 10) {
                    ForEach(available) { u in
                        UpgradeTile(u: u)
                    }
                }

                if available.isEmpty {
                    Text("ما في تطويرات متاحة هلء. افتح أقسام جديدة! 🏆")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .padding(.top, 20)
                }
            }
            .padding(16)
        }
    }
}

/// The "all sections" goal: every section reaching the next count doubles all profit.
struct AllSectionsCard: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        let goal = GameData.nextAllSectionsGoal(minOwned: s.minOwned)
        let done = s.lines.filter { $0.owned >= goal }.count
        let total = s.lines.count
        VStack(alignment: .leading, spacing: 8) {
            CardTitle(icon: "🏆", title: "هدف كل الأقسام",
                      trailing: s.allSectionsLevel > 0 ? "الحالي ×\(Fmt.number(s.allSectionsMultiplier))" : nil)
            Text("خلّي كل الأقسام الـ\(total) يوصلوا \(goal) بيّاع، وكل الأرباح بتصير ×2")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ProgressBar(value: Double(done) / Double(total), tint: Theme.gold, height: 8)
                Text("\(done)/\(total)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
            }
            HStack(spacing: 4) {
                ForEach(GameData.businesses) { b in
                    Text(b.emoji)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .opacity(s.lines[b.id].owned >= goal ? 1 : 0.3)
                }
            }
        }
        .card()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
    }
}

struct LevelCard: View {
    @EnvironmentObject var game: Game
    let icon: String
    let title: String
    let value: String
    let level: Int
    let maxLevel: Int
    let cost: Double?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(icon).font(.system(size: 28))
                Spacer()
                Text("مستوى \(level)/\(maxLevel)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.gold.opacity(0.15)))
            }
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.money)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let cost = cost {
                PriceButton(title: buttonTitle, price: Fmt.money(cost), enabled: game.s.money >= cost, action: action)
            } else {
                Text("🏆 الحد الأقصى")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .card()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.gold.opacity(0.35), lineWidth: 1))
    }
}

struct UpgradeTile: View {
    @EnvironmentObject var game: Game
    let u: UpgradeDef

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(u.icon).font(.system(size: 26))
            Text(u.title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(u.detail)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.gold)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            PriceButton(title: "اشتري", price: Fmt.money(u.cost), enabled: game.s.money >= u.cost) {
                game.buyUpgrade(u)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .card()
    }
}
