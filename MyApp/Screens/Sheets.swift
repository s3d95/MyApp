import SwiftUI

struct SheetLayer: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ZStack {
            if let sh = store.sheet, store.modals.isEmpty {
                content(sh)
                    .id(sh.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: store.sheet?.id)
    }

    @ViewBuilder
    private func content(_ sh: Sheet) -> some View {
        switch sh {
        case .upgrades: UpgradesSheet()
        case .goals: GoalsSheet()
        case .profile: ProfileSheet()
        case .settings: SettingsSheet()
        case .branch(let id): BranchSheet(cityId: id)
        case .teaser(let tab): TeaserSheet(tab: tab)
        case .twist: TwistSheet()
        }
    }
}

private func closeSheet(_ store: GameStore) {
    store.sheet = nil
    store.evaluateFtue()
}

// MARK: - Upgrades (S4)

struct UpgradesSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "الترقيات", onClose: { closeSheet(store) }) {
            Text("كل ترقية بتضرب الربح " + Num.mult(store.econ.upgradeMult))
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
            if store.nextUpgrades.isEmpty {
                Text("اشتريت كل الترقيات بهالمدينة!")
                    .font(.game(16, .bold))
                    .foregroundColor(Brand.goldLight)
                    .padding(.vertical, 20)
            }
            ForEach(Array(store.nextUpgrades.enumerated()), id: \.element.id) { k, u in
                UpgradeRow(upgrade: u, index: k)
            }
            if store.remainingUpgrades > 3 {
                Text("و" + Num.int(store.remainingUpgrades - 3) + " كمان")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.6))
            }
            Text("اشتريت " + Num.int(store.s.city.upgradesBought.count) + " ترقيات")
                .font(.body(11))
                .foregroundColor(Brand.cream.opacity(0.55))
        }
    }
}

struct UpgradeRow: View {
    @EnvironmentObject var store: GameStore
    let upgrade: UpgradeDef
    let index: Int

    var body: some View {
        let price = store.upgradePrice(upgrade)
        let ok = store.s.city.cash >= price
        HStack(spacing: 8) {
            ArtIcon(store.upgradeArt(upgrade), size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.t(upgrade.name))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(store.upgradeTargetName(upgrade) + " " + Num.mult(upgrade.mult))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.goldLight)
            }
            Spacer(minLength: 4)
            ChunkyButton(title: "اشتري", subtitle: Num.big(price), color: ok ? .green : .gray, sound: nil) {
                store.buyUpgrade(upgrade)
            }
            .frame(width: 100)
            .fxAnchor("upgrade.\(index).buy")
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
    }
}

// MARK: - Goals (S5)

struct GoalsSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "أهداف " + store.t(store.city.name), onClose: { closeSheet(store) }) {
            VStack(spacing: 4) {
                FancyBar(value: Double(store.s.city.stars) / Double(max(1, store.city.starsToGraduate)), tint: Brand.gold, height: 16,
                         label: "★ " + Num.int(store.s.city.stars) + " / " + Num.int(store.city.starsToGraduate) + " للفرع")
                if let n = store.nextCity {
                    Text(licenceText(n))
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.7))
                }
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(store.city.goals) { g in
                        GoalListRow(goal: g)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
}

extension GoalsSheet {
    func licenceText(_ n: CityDef) -> String {
        let name = store.t(n.name)
        if store.licenceLeft > 0 { return "رخصة \(name) بتطلع بعد \(Num.dur(store.licenceLeft))" }
        return "رخصة \(name) جاهزة"
    }
}

struct GoalListRow: View {
    @EnvironmentObject var store: GameStore
    let goal: GoalDef

    var body: some View {
        let supported = store.goalSupported(goal)
        let claimed = store.isClaimed(goal)
        let visible = store.visibleGoals.contains { $0.id == goal.id }
        HStack(spacing: 8) {
            ArtIcon(supported ? store.goalArt(goal) : "ui_locked", size: 28)
                .opacity(visible || claimed ? 1 : 0.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(visible || claimed ? store.goalText(goal) : (supported ? "؟ هدف جاي" : store.goalText(goal)))
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(visible || claimed ? 1 : 0.55))
                    .lineLimit(2)
                if visible && !claimed {
                    FancyBar(value: store.goalFraction(goal), tint: Brand.parsley, height: 9)
                }
                if !supported {
                    Tag(text: "قريباً بتحديث جاي", color: Brand.teal, textColor: .white)
                }
            }
            Spacer(minLength: 4)
            HStack(spacing: 1) {
                ForEach(0..<goal.stars, id: \.self) { _ in
                    ArtIcon("ui_star", size: 14, shadow: false)
                }
            }
            .opacity(claimed ? 1 : 0.45)
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Brand.parsley)
            } else if visible && store.goalDone(goal) {
                Button("خذ") { store.claimGoal(goal) }
                    .font(.game(13, .black))
                    .buttonStyle(ChunkyStyle(color: .gold, radius: 10, depth: 3))
                    .fixedSize()
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(claimed ? 0.15 : 0.3)))
    }
}

// MARK: - Profile (S25)

struct ProfileSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: store.s.settings.stallName, onClose: { closeSheet(store) }) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        LevelBadge(level: store.level, progress: store.xpProgress)
                            .scaleEffect(1.3)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.currentTitle)
                                .font(.game(18, .black))
                                .foregroundColor(Brand.goldLight)
                            FancyBar(value: store.xpProgress, tint: Brand.teal, height: 14,
                                     label: Num.int(store.s.empire.xp) + "/" + Num.int(store.xpNeed(store.level)) + " خبرة")
                        }
                    }
                    statsGrid
                    multipliers
                    inventory
                }
            }
            .frame(maxHeight: 460)
        }
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 6) {
            stat("ui_star", Num.int(store.s.stats.starsTotal), "نجوم")
            stat("bld_classical_building", Num.int(store.s.branches.count), "فروع")
            stat("ppl_person", Num.big(store.s.stats.customers), "زباين")
            stat("ui_glowing_star", Num.int(store.s.stats.specials), "زباين مميّزين")
        }
    }

    private func stat(_ art: String, _ value: String, _ caption: String) -> some View {
        HStack(spacing: 6) {
            ArtIcon(art, size: 26)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.game(15, .black).monospacedDigit()).foregroundColor(Brand.cream)
                Text(caption).font(.body(10)).foregroundColor(Brand.cream.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var multipliers: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ليش دخلي هيك؟")
                .font(.game(14, .black))
                .foregroundColor(Brand.goldLight)
            line("الفروع", Num.mult(store.branchMult))
            line("زعتر ذهبي (" + Num.int(store.s.wallet.zaatar) + ")", Num.mult(store.zaatarMult))
            line("كل المحطّات", Num.mult(pow(store.econ.milestoneMult, Double(store.allMilestones))))
            line("قوّة الإمبراطورية", Num.mult(store.permMult))
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private func line(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(.body(12, bold: true)).foregroundColor(Brand.cream.opacity(0.85))
            Spacer()
            Text(b).font(.game(13, .black)).foregroundColor(Brand.goldLight)
        }
    }

    private var inventory: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("أغراضك")
                .font(.game(14, .black))
                .foregroundColor(Brand.goldLight)
            if store.s.wallet.timeWarps.isEmpty && store.pendingChestCount == 0 && store.s.wallet.pendingChefCards == 0
                && store.s.wallet.pendingHeritage == 0 {
                Text("لسّا ما في أغراض")
                    .font(.body(12))
                    .foregroundColor(Brand.cream.opacity(0.6))
            }
            ForEach(Array(store.s.wallet.timeWarps.enumerated()), id: \.offset) { k, m in
                HStack {
                    ArtIcon("ui_hourglass", size: 26)
                    Text("رزمة وقت " + Num.dur(Double(m) * 60))
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream)
                    Spacer()
                    Button("استعمل") { store.useTimeWarp(at: k) }
                        .font(.game(12, .black))
                        .buttonStyle(ChunkyStyle(color: .purple, radius: 10, depth: 3))
                        .fixedSize()
                }
            }
            ForEach(["wood", "silver", "gold"], id: \.self) { kind in
                if let n = store.s.wallet.pendingChests[kind], n > 0 {
                    HStack {
                        ArtIcon(store.chestArt(kind), size: 26)
                        Text(store.chestName(kind) + " ×" + Num.int(n))
                            .font(.body(12, bold: true))
                            .foregroundColor(Brand.cream)
                        Spacer()
                        Tag(text: "بينفتح مع الطبّاخين", color: Brand.teal, textColor: .white)
                    }
                }
            }
            if store.s.wallet.pendingChefCards > 0 {
                pendingRow("ppl_cook", "كروت طبّاخين ×" + Num.int(store.s.wallet.pendingChefCards))
            }
            if store.s.wallet.pendingHeritage > 0 {
                pendingRow("ui_old_key", "قطع تراث ×" + Num.int(store.s.wallet.pendingHeritage))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private func pendingRow(_ art: String, _ text: String) -> some View {
        HStack {
            ArtIcon(art, size: 26)
            Text(text).font(.body(12, bold: true)).foregroundColor(Brand.cream)
            Spacer()
            Tag(text: "محفوظة لإلك", color: Brand.teal, textColor: .white)
        }
    }
}

// MARK: - Settings (S26)

struct SettingsSheet: View {
    @EnvironmentObject var store: GameStore
    @State private var resetText = ""
    @State private var confirmReset = false

    var body: some View {
        GameModal(title: "الإعدادات", onClose: { closeSheet(store) }) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    toggle("الأصوات", \.sfx)
                    toggle("الاهتزاز", \.haptics)
                    notificationsToggle
                    toggle("تقليل الحركة", \.reduceMotion)
                    toggle("أرقام عربية (١٢٣)", \.arabicDigits)
                    addressPicker
                    credits
                    resetBox
                }
            }
            .frame(maxHeight: 460)
        }
    }

    private func toggle(_ title: String, _ key: WritableKeyPath<SettingsSave, Bool>) -> some View {
        Toggle(isOn: Binding(get: { store.s.settings[keyPath: key] }, set: { v in
            store.s.settings[keyPath: key] = v
            store.applySettings()
            Feedback.play(.t0)
            store.save()
        })) {
            Text(title).font(.game(15, .bold)).foregroundColor(Brand.cream)
        }
        .toggleStyle(SwitchToggleStyle(tint: Brand.gold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var notificationsToggle: some View {
        Toggle(isOn: Binding(get: { store.s.settings.notifications && store.s.notif.granted }, set: { v in
            store.s.settings.notifications = v
            if v && !store.s.notif.granted {
                Notifier.request { ok in
                    store.s.notif.granted = ok
                    store.save()
                }
            }
            store.save()
        })) {
            Text("الإشعارات").font(.game(15, .bold)).foregroundColor(Brand.cream)
        }
        .toggleStyle(SwitchToggleStyle(tint: Brand.gold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var addressPicker: some View {
        HStack(spacing: 8) {
            Text("طريقة المناداة").font(.game(15, .bold)).foregroundColor(Brand.cream)
            Spacer()
            ForEach([AddressForm.m, AddressForm.f], id: \.rawValue) { f in
                Button(f == .m ? "يا شب" : "يا صبية") {
                    store.s.settings.address = f
                    store.s.settings.addressAsked = true
                    Feedback.play(.t0)
                    store.save()
                }
                .font(.game(13, .black))
                .buttonStyle(ChunkyStyle(color: store.form == f ? .gold : .wood, radius: 10, depth: 3))
                .fixedSize()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var credits: some View {
        VStack(spacing: 4) {
            Text("عن اللعبة").font(.game(15, .black)).foregroundColor(Brand.goldLight)
            Text("المطوّر: سعد").font(.body(13, bold: true)).foregroundColor(Brand.cream)
            Text("Developer: Saad")
                .font(.body(12, bold: true))
                .foregroundColor(Brand.cream.opacity(0.8))
                .environment(\.layoutDirection, .leftToRight)
            Text("Fluent Emoji 3D — MIT License, Microsoft\nBaloo Bhaijaan 2 · Cairo — SIL Open Font License 1.1")
                .font(.body(10))
                .foregroundColor(Brand.cream.opacity(0.6))
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .leftToRight)
            Text("نسخة " + appVersion).font(.body(10)).foregroundColor(Brand.cream.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "3"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return v + " (" + b + ")"
    }

    private var resetBox: some View {
        VStack(spacing: 6) {
            Text("ابدأ من جديد").font(.game(14, .black)).foregroundColor(Brand.red)
            Text("اكتب \"امسح\" عشان تمسح التقدّم كلّه").font(.body(11)).foregroundColor(Brand.cream.opacity(0.7))
            TextField("امسح", text: $resetText)
                .font(.body(14, bold: true))
                .multilineTextAlignment(.center)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Brand.cream))
                .foregroundColor(Brand.outline)
            if resetText.trimmingCharacters(in: .whitespaces) == "امسح" {
                ChunkyButton(title: confirmReset ? "أكيد؟ دقّ كمان مرّة" : "امسح كل إشي", color: .red, sound: nil) {
                    if confirmReset {
                        store.resetGame()
                        resetText = ""
                        confirmReset = false
                    } else {
                        confirmReset = true
                    }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }
}

// MARK: - Branch (S7)

struct BranchSheet: View {
    @EnvironmentObject var store: GameStore
    let cityId: String

    var body: some View {
        let c = store.cat.city(cityId)
        let b = store.s.branches[cityId] ?? BranchSave()
        GameModal(title: "فرع " + (c.map { store.t($0.name) } ?? ""), onClose: { closeSheet(store) }) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: c?.palette.sky ?? [Brand.duskTop, Brand.sunset], startPoint: .top, endPoint: .bottom))
                    .frame(width: 110, height: 110)
                ArtIcon(c?.landmarkArt ?? "bld_mosque", size: 76)
                if b.crowned { ArtIcon("ui_crown", size: 36).offset(y: -58) }
            }
            Text("مستوى الفرع " + Num.int(b.level) + "/" + Num.int(store.econ.branches.maxLevel))
                .font(.game(18, .black))
                .foregroundColor(Brand.goldLight)
            VStack(spacing: 3) {
                Text("ذهب كل يوم: " + String(format: "%.1f", store.econ.branches.goldPerDayBase * (1 + store.econ.branches.goldPerLevel * Double(b.level))))
                Text("+" + Num.percent(store.econ.branches.incomePerBranch + store.econ.branches.incomePerLevel * Double(b.level)) + " دخل لكل المدن")
                Text("★ " + Num.int(b.stars) + " · دخل آخر يوم " + Num.big(b.finalIncome) + "/ث")
            }
            .font(.body(12, bold: true))
            .foregroundColor(Brand.cream.opacity(0.85))
            if let cost = store.branchUpgradeCost(b.level) {
                if store.unlocked("branchUpgrades") {
                    ChunkyButton(title: "كبّر الفرع", icon: "ui_coin", subtitle: Num.int(cost) + " ذهب",
                                 color: store.s.wallet.gold >= cost ? .gold : .gray, sound: nil) {
                        store.upgradeBranch(cityId)
                    }
                    .fxAnchor("branch.upgrade")
                } else {
                    Tag(text: "تكبير الفروع بيفتح بمستوى " + Num.int(store.unlockLevel("branchUpgrades")), color: Brand.teal, textColor: .white)
                }
            } else {
                Tag(text: "الفرع بأعلى مستوى", color: Brand.gold)
            }
        }
    }
}

// MARK: - Teasers for systems that are not open yet

struct TeaserSheet: View {
    @EnvironmentObject var store: GameStore
    let tab: GameTab

    var body: some View {
        GameModal(title: tab.title, onClose: { closeSheet(store) }) {
            TeaserScreen(tab: tab)
        }
    }
}

struct TeaserScreen: View {
    @EnvironmentObject var store: GameStore
    let tab: GameTab

    var body: some View {
        VStack(spacing: 10) {
            ArtIcon(art, size: 80)
            Text(headline)
                .font(.game(18, .black))
                .foregroundColor(Brand.goldLight)
                .multilineTextAlignment(.center)
            Text(blurb)
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
                .multilineTextAlignment(.center)
            if tab == .chefs && store.pendingChestCount > 0 {
                Tag(text: "عندك " + Num.int(store.pendingChestCount) + " صناديق محفوظة", color: Brand.gold)
            }
        }
        .padding(.vertical, 8)
    }

    private var art: String {
        switch tab {
        case .map: return "bld_world_map"
        case .tasks: return "ui_clipboard"
        case .home: return "food_falafel"
        case .chefs: return "ppl_cook"
        case .shop: return "bld_convenience_store"
        }
    }

    private var headline: String {
        let lv = store.unlockLevel(tab.system)
        if store.level < lv { return "بتفتح بمستوى " + Num.int(lv) }
        return "جاي بالتحديث الجاي!"
    }

    private var blurb: String {
        switch tab {
        case .map: return "الخريطة ومدن جديدة، وفروع بتجيب ذهب كل يوم"
        case .tasks: return "طلبات اليوم والأسبوع، الروزنامة، الموسم والإنجازات"
        case .home: return ""
        case .chefs: return "طبّاخين بمهارات بيقوّوا محطّاتك، وصناديق بمفاجآت"
        case .shop: return "صناديق، رزم وقت، تذاكر وديكور للبسطة، كلّه بالذهب اللي بتجمعه"
        }
    }
}

// MARK: - Twist info

struct TwistSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "سرّ " + store.t(store.city.name), onClose: { closeSheet(store) }) {
            ForEach(Array(store.city.twists.enumerated()), id: \.offset) { _, d in
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ArtIcon(store.twistArt(d.type), size: 44)
                        Text(store.twistName(d.type))
                            .font(.game(17, .black))
                            .foregroundColor(Brand.goldLight)
                        Spacer()
                    }
                    Text(store.twistInfo(d))
                        .font(.body(13, bold: true))
                        .foregroundColor(Brand.cream)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if d.type == .deliveryRuns { deliveryShop }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
            }
        }
    }

    @ViewBuilder
    private var deliveryShop: some View {
        if let c = store.nextScooterCost {
            ChunkyButton(title: "موتور زيادة", icon: "veh_scooter", subtitle: Num.big(c),
                         color: store.s.city.cash >= c ? .green : .gray, sound: nil) { store.buyScooter() }
        }
        if let c = store.dispatcherCost {
            ChunkyButton(title: "موظّف دليفري (بيشتغل وإنت برّا)", icon: "ppl_man_office", subtitle: Num.big(c),
                         color: store.s.city.cash >= c ? .green : .gray, sound: nil) { store.buyDispatcher() }
        } else if store.s.city.twist.dispatcher {
            Tag(text: "موظّف الدليفري شغّال", color: Brand.parsley, textColor: .white)
        }
    }
}
