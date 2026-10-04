import SwiftUI

enum EmpirePage: Hashable, CaseIterable {
    case fame, branches, research, achievements, settings

    var title: String {
        switch self {
        case .fame: return "⭐ الشهرة"
        case .branches: return "🏙️ الفروع"
        case .research: return "📖 الوصفات"
        case .achievements: return "🏅 الإنجازات"
        case .settings: return "⚙️ الإعدادات"
        }
    }
}

struct EmpireView: View {
    @EnvironmentObject var game: Game
    @State private var page: EmpirePage = .fame

    var body: some View {
        VStack(spacing: 0) {
            SegmentChips(items: EmpirePage.allCases, selection: $page, title: { $0.title }, badge: { p in
                switch p {
                case .fame: return Badges.prestige(game.s)
                case .branches: return Badges.branches(game.s)
                case .research: return Badges.research(game.s)
                default: return false
                }
            })
            switch page {
            case .fame: PrestigeView()
            case .branches: BranchesView()
            case .research: ResearchView()
            case .achievements: AchievementsView()
            case .settings: MoreView()
            }
        }
    }
}

// MARK: - Prestige

struct PrestigeView: View {
    @EnvironmentObject var game: Game
    @State private var confirm = false

    var body: some View {
        let s = game.s
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "نجوم الشهرة ⭐",
                             subtitle: "بيع مشروعك وافتح من جديد بسمعة أكبر. كل نجمة بتزيد كل أرباحك \(Fmt.percent(s.starPower)) للأبد.")

                starsCard(s)
                pendingCard(s)
                multipliersCard(s)
                rulesCard
            }
            .padding(16)
        }
        .alert("إعادة الافتتاح؟", isPresented: $confirm) {
            Button("افتح من جديد ⭐", role: .destructive) { game.prestige() }
            Button("لسا", role: .cancel) {}
        } message: {
            Text("رح تاخد \(Fmt.number(s.pendingStars)) نجمة، وبترجع تبلّش ببسطة صغيرة بس أرباحك ×\(Fmt.multiplier(s.prestigeGainRatio)) أكتر.")
        }
    }

    private func starsCard(_ s: GameState) -> some View {
        VStack(spacing: 6) {
            Text("⭐").font(.system(size: 44))
            Text(Fmt.number(s.stars))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(Theme.star)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("بونص النجوم: كل الأرباح +\(Fmt.number((s.starMultiplier - 1) * 100))%")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.money)
            if s.prestigeCount > 0 {
                Text("فتحت من جديد \(s.prestigeCount) مرات")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.star.opacity(0.4), lineWidth: 1))
    }

    private func pendingCard(_ s: GameState) -> some View {
        let prevAt = s.starsEarnable <= 0 ? 0 : pow(s.starsEarnable / s.starGainMultiplier, 2) * GameState.starDivisor
        let span = max(1, s.nextStarAt - prevAt)
        let progress = (s.allTimeEarnings - prevAt) / span
        let ready = s.pendingStars >= 1
        return VStack(alignment: .leading, spacing: 10) {
            CardTitle(icon: "🔄", title: "إعادة الافتتاح")
            HStack(alignment: .firstTextBaseline) {
                Text("+\(Fmt.number(s.pendingStars))")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(ready ? Theme.star : Theme.muted)
                Text("نجمة جاهزة")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.muted)
                Spacer()
                if ready {
                    Text("أرباحك ×\(Fmt.multiplier(s.prestigeGainRatio))")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(Theme.money)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                ProgressBar(value: progress, tint: Theme.star, height: 8)
                Text("النجمة الجاية لما توصل أرباحك بكل الأوقات \(Fmt.money(s.nextStarAt))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button { confirm = true } label: {
                BigButtonLabel(text: ready ? "إعادة الافتتاح ⭐" : "اربح أكتر عشان تاخد نجوم", enabled: ready)
            }
            .buttonStyle(PressableStyle())
            .disabled(!ready)
            Text("💡 أحسن وقت: لما الرقم الأخضر يصير ×2 أو أكتر.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.gold.opacity(0.9))
        }
        .card()
    }

    private func multipliersCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CardTitle(icon: "♾️", title: "بونصات دايمة", trailing: "×\(Fmt.multiplier(s.permanentMultiplier))")
            row("⭐", "نجوم الشهرة", s.starMultiplier)
            row("🏅", "الإنجازات (\(s.achievements.count))", s.achievementMultiplier)
            row("🧪", "خلطة سرّية", s.researchMultiplier)
            row("👵", "ستّي أم خليل", s.grandmaMultiplier)
        }
        .card()
    }

    private func row(_ icon: String, _ title: String, _ m: Double) -> some View {
        HStack {
            Text(icon)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
            Spacer()
            Text("×\(Fmt.multiplier(m))")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(m > 1 ? Theme.money : Theme.muted)
        }
    }

    private var rulesCard: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("🔄 بيرجع من الأول")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.red)
                ForEach(["المصاري", "البيّاعين والأقسام", "المدراء", "التطويرات", "الفروع"], id: \.self) { t in
                    Text("• " + t)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                Text("💎 بيضل معك")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.money)
                ForEach(["النجوم", "الليرات الدهب", "الطبّاخين والصناديق", "الوصفات", "الإنجازات"], id: \.self) { t in
                    Text("• " + t)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                             subtitle: "افتح فروع بفلسطين (+10%)، بعدين بالوطن العربي (+25%) وحول العالم (+50%).")

                HStack(spacing: 10) {
                    statBox("🏙️", "\(1 + s.branchesOwned)", "فروع")
                    statBox("📈", "+\(s.branchBonusPercent)%", "من الفروع")
                    statBox("📣", "+\(Fmt.number(Double(s.globalBonusPercent)))%", "بونص كلي")
                }

                if let next = s.nextBranch {
                    Button { game.buyBranch() } label: {
                        BigButtonLabel(text: "افتح فرع \(next.city) · \(Fmt.money(next.cost))",
                                       enabled: s.money >= next.cost)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(s.money < next.cost)
                } else {
                    Text("👑 فتحت فروع بكل العالم!")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.gold)
                }

                ForEach(0..<GameData.regionNames.count, id: \.self) { region in
                    regionSection(region, s)
                }
            }
            .padding(16)
        }
    }

    private func regionSection(_ region: Int, _ s: GameState) -> some View {
        let items = GameData.branches.enumerated().filter { $0.element.region == region }
        let pct = Int((GameData.regionBonus[region] * 100).rounded())
        return VStack(spacing: 8) {
            HStack {
                Text(GameData.regionNames[region])
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Spacer()
                Text("+\(pct)% لكل فرع")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.gold)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                if region == 0 {
                    cityTile(name: GameData.homeCity, sub: "🏠 الأصلي", owned: true, isNext: false)
                }
                ForEach(items, id: \.offset) { item in
                    let k = item.offset
                    cityTile(name: item.element.city,
                             sub: k < s.branchesOwned ? "✅ مفتوح" : Fmt.money(item.element.cost),
                             owned: k < s.branchesOwned,
                             isNext: k == s.branchesOwned)
                }
            }
        }
    }

    private func statBox(_ icon: String, _ value: String, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(icon).font(.system(size: 20))
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
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

// MARK: - Research

struct ResearchView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "دفتر وصفات ستّي",
                             subtitle: "تطويرات دايمة بالليرات الدهب. ما بتروح أبداً، حتى بعد إعادة الافتتاح.")
                HStack {
                    Spacer()
                    LiraChip(amount: game.s.liras)
                }
                ForEach(Catalog.research) { r in
                    ResearchRow(def: r)
                }
            }
            .padding(16)
        }
    }
}

struct ResearchRow: View {
    @EnvironmentObject var game: Game
    let def: ResearchDef

    var body: some View {
        let level = game.s.research[def.id]
        let cost = game.s.researchCost(def.id)
        HStack(spacing: 12) {
            Text(def.icon)
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Circle().fill(Theme.lira.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(def.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Text("\(level)/\(def.maxLevel)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.gold.opacity(0.15)))
                }
                Text(level > 0 ? Catalog.researchText(def.id, level: level) : "لسا ما اشتريته")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(level > 0 ? Theme.money : Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if cost != nil {
                    Text("الجاي: " + Catalog.researchText(def.id, level: level + 1))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            if let c = cost {
                GoldButton(title: "طوّر", cost: c, enabled: game.s.liras >= c) { game.buyResearch(def.id) }
                    .frame(width: 80)
            } else {
                Text("🏆")
                    .font(.system(size: 24))
                    .frame(width: 80)
            }
        }
        .card()
    }
}

// MARK: - Achievements

struct AchievementsView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        let all = Catalog.achievements
        let locked = all.filter { !s.achievements.contains($0.id) }
        let done = all.filter { s.achievements.contains($0.id) }
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "الإنجازات",
                             subtitle: "كل إنجاز بيعطيك ليرات دهب وبيزيد كل أرباحك 2% للأبد.")
                VStack(spacing: 8) {
                    HStack {
                        Text("🏅 \(done.count)/\(all.count)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Theme.cream)
                        Spacer()
                        Text("كل الأرباح +\(Int(((s.achievementMultiplier - 1) * 100).rounded()))%")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.money)
                    }
                    ProgressBar(value: Double(done.count) / Double(max(1, all.count)), tint: Theme.gold, height: 8)
                }
                .card()

                LazyVGrid(columns: twoColumns, spacing: 10) {
                    ForEach(locked) { a in AchievementTile(a: a, done: false) }
                    ForEach(done) { a in AchievementTile(a: a, done: true) }
                }
            }
            .padding(16)
        }
    }
}

struct AchievementTile: View {
    let a: AchievementDef
    let done: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(a.icon).font(.system(size: 24))
                Spacer()
                Text(done ? "✅" : "🪙 \(a.reward)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.lira)
            }
            Text(a.title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(a.detail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .card()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(done ? Theme.gold.opacity(0.6) : Color.clear, lineWidth: 1))
        .opacity(done ? 0.75 : 1)
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
                    statRow("💰", "أرباحك بكل الأوقات", Fmt.money(s.allTimeEarnings))
                    statRow("📈", "أرباح الافتتاح الحالي", Fmt.money(s.lifetimeEarnings))
                    statRow("🧆", "قطع مبيوعة", Fmt.number(s.totalSold))
                    statRow("👨‍🍳", "عدد البياعين", "\(s.totalSellers)")
                    statRow("👆", "عدد الضغطات", Fmt.number(Double(s.totalTaps)))
                    statRow("⬆️", "التطويرات", "\(s.purchased.count)")
                    statRow("🏙️", "الفروع", "\(1 + s.branchesOwned)")
                    statRow("⭐", "نجوم الشهرة", Fmt.number(s.stars))
                    statRow("🔄", "مرات إعادة الافتتاح", "\(s.prestigeCount)")
                    statRow("🪙", "ليرات ربحتها", Fmt.number(Double(s.lirasEarned)))
                    statRow("🔥", "أطول سلسلة أيام", "\(s.bestStreak)")
                    statRow("📋", "مهام خلّصتها", "\(s.missionsDone)")
                    statRow("🤵", "زباين VIP", "\(s.vipsClaimed)")
                    statRow("📦", "صناديق فتحتها", "\(s.chestsOpened)")
                    statRow("⏱️", "أحسن طلبيات سريعة", "\(s.bestRush)")
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
                    Toggle("التذكيرات", isOn: Binding(get: { game.s.notificationsOn },
                                                     set: { game.setNotifications($0) }))
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
                    Text("صُنعت بحب ❤️ في فلسطين · نسخة 2.0")
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
            Text("رح تخسر كل التقدم: النجوم والطبّاخين والليرات والفروع. ما في رجعة.")
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
