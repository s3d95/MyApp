import SwiftUI

private let twoColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

// MARK: - Managers

struct ManagersView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "المدراء",
                             subtitle: "المدير بيشغّل القسم عنك بدون ما تضغط، وبيضل يبيع حتى وإنت مسكّر اللعبة (لحد ٨ ساعات).")
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
                             subtitle: "اشتريت \(s.purchased.count) من \(GameData.upgrades.count) تطوير.")

                LazyVGrid(columns: twoColumns, spacing: 10) {
                    LevelCard(icon: "🤖", title: "الأوتو كليكر",
                              value: s.autoLevel == 0 ? "مش مفعّل" : "\(s.autoLevel) ضغطة بالثانية",
                              level: s.autoLevel, maxLevel: GameData.maxAutoLevel,
                              cost: s.nextAutoCost, buttonTitle: s.autoLevel == 0 ? "شغّله" : "+1 ضغطة/ث") {
                        game.upgradeAuto()
                    }
                    LevelCard(icon: "✋", title: "قوة الضغطة",
                              value: "\(Fmt.money(Double(1 + s.tapLevel))) بالضغطة",
                              level: s.tapLevel, maxLevel: GameData.maxTapLevel,
                              cost: s.nextTapCost, buttonTitle: "+₪1 بالضغطة") {
                        game.upgradeTap()
                    }
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

// MARK: - Branches

struct BranchesView: View {
    @EnvironmentObject var game: Game
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        let s = game.s

        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "الفروع",
                             subtitle: "كل فرع جديد بمدينة تانية بيزيد كل أرباحك 10%.")

                HStack(spacing: 10) {
                    statBox("🏙️", "\(1 + s.branchesOwned)", "فروع")
                    statBox("📈", "+\(s.branchesOwned * 10)%", "من الفروع")
                    statBox("📣", "+\(s.globalBonusPercent)%", "بونص كلي")
                }

                if let next = s.nextBranch {
                    Button { game.buyBranch() } label: {
                        BigButtonLabel(text: "افتح فرع \(next.city) · \(Fmt.money(next.cost))",
                                       enabled: s.money >= next.cost)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(s.money < next.cost)
                } else {
                    Text("👑 فتحت فروع بكل المدن!")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.gold)
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    cityTile(name: GameData.homeCity, sub: "🏠 الأصلي", owned: true, isNext: false)
                    ForEach(Array(GameData.branches.enumerated()), id: \.offset) { k, b in
                        cityTile(name: b.city,
                                 sub: k < s.branchesOwned ? "✅ مفتوح" : Fmt.money(b.cost),
                                 owned: k < s.branchesOwned,
                                 isNext: k == s.branchesOwned)
                    }
                }
            }
            .padding(16)
        }
    }

    private func statBox(_ icon: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(icon).font(.system(size: 20))
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func cityTile(name: String, sub: String, owned: Bool, isNext: Bool) -> some View {
        VStack(spacing: 4) {
            Text(owned ? "🏪" : (isNext ? "📍" : "🔒")).font(.system(size: 24))
            Text(name)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(owned ? Theme.money : Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(owned ? Theme.cardHi : Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isNext ? Theme.gold : Theme.stroke, lineWidth: isNext ? 2 : 1))
        .opacity(owned || isNext ? 1 : 0.6)
    }
}

// MARK: - Stats & settings

struct MoreView: View {
    @EnvironmentObject var game: Game
    @State private var confirmReset = false
    @State private var nameDraft = ""

    var body: some View {
        let s = game.s
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "إحصائيات", subtitle: "كل شي عن مشروعك.")

                VStack(spacing: 12) {
                    statRow("💰", "أرباحك بكل الأوقات", Fmt.money(s.lifetimeEarnings))
                    statRow("🧆", "قطع مبيوعة", Fmt.number(s.totalSold))
                    statRow("👨‍🍳", "عدد البياعين", "\(s.totalSellers)")
                    statRow("👆", "عدد الضغطات", "\(s.totalTaps)")
                    statRow("⬆️", "التطويرات", "\(s.purchased.count)")
                    statRow("🏙️", "الفروع", "\(1 + s.branchesOwned)")
                }
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Text("الإعدادات")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                    HStack(spacing: 8) {
                        TextField("اسم البسطة", text: $nameDraft)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
                            .foregroundColor(Theme.cream)
                        Button("حفظ") { game.rename(nameDraft) }
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.gold)
                    }
                    Toggle("الاهتزاز", isOn: $game.s.hapticsOn)
                    Toggle("الأصوات", isOn: $game.s.soundOn)
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.cream)
                .tint(Theme.gold)
                .card()

                Button { confirmReset = true } label: {
                    Text("مسح اللعبة والبدء من جديد")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.5), lineWidth: 1))
                }

                VStack(spacing: 4) {
                    Text("Developer: Saad")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.gold)
                        .environment(\.layoutDirection, .leftToRight)
                    Text("صُنعت بحب ❤️ في فلسطين · نسخة 1.1")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.muted.opacity(0.7))
                }
                .padding(.top, 6)
            }
            .padding(16)
        }
        .onAppear { nameDraft = game.s.stallName }
        .alert("مسح كل شي؟", isPresented: $confirmReset) {
            Button("امسح", role: .destructive) { game.resetAll() }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("رح تخسر كل التقدم والفروع. ما في رجعة.")
        }
    }

    private func statRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(icon).font(.system(size: 18))
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
