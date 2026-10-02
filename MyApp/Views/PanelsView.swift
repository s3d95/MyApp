import SwiftUI

// MARK: - Managers

struct ManagersView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                SectionTitle(title: "الموظفين",
                             subtitle: "وظّف حدا يشغّل القسم عنك، وبيضل يربحلك حتى وإنت مسكّر اللعبة.")
                ForEach(GameData.businesses) { def in
                    ManagerCard(def: def)
                }
            }
            .padding(16)
        }
    }
}

struct ManagerCard: View {
    @EnvironmentObject var game: Game
    let def: BusinessDef

    var body: some View {
        let line = game.s.lines[def.id]
        HStack(spacing: 12) {
            EmojiBubble(emoji: def.managerEmoji, tint: Color(hex: def.tint), size: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(def.managerName)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text("مسؤول قسم \(def.name) \(def.emoji)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
            }
            Spacer(minLength: 6)
            if line.hasManager {
                Label("شغّال", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.money)
            } else if line.owned == 0 {
                Text("افتح القسم أول")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.muted)
            } else {
                PriceButton(title: "وظّف", price: Fmt.money(def.managerCost),
                            enabled: game.s.money >= def.managerCost) {
                    game.hire(def.id)
                }
                .frame(width: 118)
            }
        }
        .card()
        .opacity(line.owned == 0 ? 0.55 : 1)
    }
}

// MARK: - Upgrades

struct UpgradesView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let lines = game.s.lines
        let available = GameData.upgrades.filter { u in
            guard !game.s.purchased.contains(u.id) else { return false }
            if case .business(let b) = u.target { return lines[b].owned > 0 }
            return true
        }
        let bought = game.s.purchased.count

        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                SectionTitle(title: "التطويرات",
                             subtitle: "اشتريت \(bought) من \(GameData.upgrades.count). كل تطوير بيضاعف أرباحك.")
                ForEach(Array(available.prefix(30))) { u in
                    UpgradeCard(u: u)
                }
                if available.isEmpty {
                    Text("ما في تطويرات متاحة هلء. افتح أقسام جديدة! 🏆")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .padding(.top, 30)
                }
            }
            .padding(16)
        }
    }
}

struct UpgradeCard: View {
    @EnvironmentObject var game: Game
    let u: UpgradeDef

    var body: some View {
        HStack(spacing: 12) {
            EmojiBubble(emoji: u.icon, tint: Theme.gold.opacity(0.7), size: 50)
            VStack(alignment: .leading, spacing: 3) {
                Text(u.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text(u.detail)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.gold)
            }
            Spacer(minLength: 6)
            PriceButton(title: "اشتري", price: Fmt.money(u.cost), enabled: game.s.money >= u.cost) {
                game.buyUpgrade(u)
            }
            .frame(width: 118)
        }
        .card()
    }
}

// MARK: - Branches (prestige)

struct PrestigeView: View {
    @EnvironmentObject var game: Game
    @State private var confirm = false

    var body: some View {
        let s = game.s
        let gain = s.starsToGain
        let canOpen = gain >= 1

        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "الفروع",
                             subtitle: "افتح فرع بمدينة جديدة: بتبلّش من الأول، بس بتاخد معك نجوم السمعة ⭐ وكل نجمة بتزيد أرباحك 2% للأبد.")

                VStack(spacing: 6) {
                    Text("⭐").font(.system(size: 50))
                    Text("\(Int(s.claimedStars)) نجمة سمعة")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Text("أرباحك زايدة +\(Int(s.claimedStars * 2))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gold)
                }
                .frame(maxWidth: .infinity)
                .card()

                VStack(alignment: .leading, spacing: 10) {
                    Text("إذا فتحت فرع جديد هلء:")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                    infoRow("نجوم جديدة", "+\(Int(gain)) ⭐")
                    infoRow("المدينة الجاية", "📍 \(s.nextCityName)")
                    infoRow("أرباحك بتصير", "+\(Int((s.claimedStars + gain) * 2))%")
                    if !canOpen {
                        let p = min(1, s.lifetimeEarnings / s.lifetimeForNextStar)
                        Text("لازم توصل أرباحك الكلية لـ \(Fmt.money(s.lifetimeForNextStar)) لتاخد أول نجمة.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.35))
                                Capsule().fill(Theme.gold).frame(width: geo.size.width * CGFloat(p))
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .card()

                Button { confirm = true } label: {
                    BigButtonLabel(text: "افتح فرع في \(s.nextCityName) 🚀", enabled: canOpen)
                }
                .buttonStyle(PressableStyle())
                .disabled(!canOpen)

                CitiesStrip(current: s.cityIndex)
            }
            .padding(16)
        }
        .alert("متأكد؟", isPresented: $confirm) {
            Button("افتح الفرع", role: .destructive) { game.prestige() }
            Button("لا، بعدين", role: .cancel) {}
        } message: {
            Text("رح تبلّش من الأول في \(s.nextCityName): المصاري والأقسام والموظفين والتطويرات بيرجعوا لصفر، بس بتاخد معك \(Int(gain)) نجمة ⭐ بتزيد أرباحك للأبد.")
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
        }
    }
}

struct CitiesStrip: View {
    let current: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameData.cities.indices, id: \.self) { k in
                    let visited = k < current
                    let here = k == current % GameData.cities.count && current < GameData.cities.count
                    Text((visited ? "✓ " : "") + GameData.cities[k])
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(here ? Color(hex: 0x2A1608) : (visited ? Theme.money : Theme.muted))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(here ? Theme.gold : Color.white.opacity(0.06)))
                }
            }
            .padding(.vertical, 4)
        }
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
                SectionTitle(title: "إحصائيات", subtitle: "كل شي عن إمبراطوريتك.")

                VStack(spacing: 12) {
                    statRow("💰", "أرباحك بكل الأوقات", Fmt.money(s.lifetimeEarnings))
                    statRow("🏪", "أرباح هالفرع", Fmt.money(s.runEarnings))
                    statRow("👆", "عدد الضغطات", "\(s.totalTaps)")
                    statRow("📦", "الوحدات اللي بتملكها", "\(s.totalOwned)")
                    statRow("⬆️", "التطويرات", "\(s.purchased.count)")
                    statRow("🌍", "الفروع اللي فتحتها", "\(s.prestigeCount)")
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

                Text("صُنعت بحب ❤️ في فلسطين · نسخة 1.0")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted.opacity(0.7))
                    .padding(.top, 6)
            }
            .padding(16)
        }
        .onAppear { nameDraft = game.s.stallName }
        .alert("مسح كل شي؟", isPresented: $confirmReset) {
            Button("امسح", role: .destructive) { game.resetAll() }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("رح تخسر كل التقدم والنجوم والفروع. ما في رجعة.")
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
