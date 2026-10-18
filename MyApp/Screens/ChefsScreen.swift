import SwiftUI

/// Chefs tab (GDD S9): equipped slots, the collection and the chest inventory.
struct ChefsScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var segment = 0
    @State private var cuisine = ""

    var body: some View {
        VStack(spacing: 8) {
            SlotsRow()
                .padding(.horizontal, 10)
            SegmentBar(titles: ["الطبّاخين", "الصناديق (" + Num.int(store.chestCount) + ")"], selection: $segment,
                       dots: [false, store.chestCount > 0])
                .padding(.horizontal, 10)
            if segment == 0 {
                CuisineChips(selection: $cuisine)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(chefs) { c in
                            ChefCell(chef: c)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    ChestsSection()
                        .padding(.horizontal, 10)
                        .padding(.bottom, 12)
                }
            }
        }
        .padding(.top, 4)
        .onAppear {
            if store.chestCount > 0 && !store.s.chefs.ftueChestOpened { segment = 1 }
        }
    }

    private var chefs: [ChefDef] {
        let all = store.collectionChefs
        return cuisine.isEmpty ? all : all.filter { $0.cuisine == cuisine }
    }
}

struct SegmentBar: View {
    let titles: [String]
    @Binding var selection: Int
    var dots: [Bool] = []

    var body: some View {
        HStack(spacing: 4) {
            ForEach(titles.indices, id: \.self) { k in
                Button {
                    Feedback.play(.t0)
                    selection = k
                } label: {
                    Text(titles[k])
                        .font(.game(14, .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundColor(selection == k ? Brand.outline : Brand.cream.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(Capsule().fill(selection == k ? AnyShapeStyle(Brand.titleFill) : AnyShapeStyle(Color.clear)))
                        .overlay(Group { if k < dots.count && dots[k] { RedDot().offset(x: -4, y: -2) } }, alignment: .topTrailing)
                }
                .buttonStyle(PressScaleStyle())
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.4)))
        .overlay(Capsule().stroke(Brand.gold.opacity(0.3), lineWidth: 1))
    }
}

struct CuisineChips: View {
    @Binding var selection: String
    private let all = ["", "palestinian", "levantine", "egyptian", "gulf", "iraqi", "maghrebi", "turkish", "world"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(all, id: \.self) { c in
                    Button {
                        Feedback.play(.t0)
                        selection = c
                    } label: {
                        Text(c.isEmpty ? "الكل" : GameStore.cuisineName(c).replacingOccurrences(of: "مطبخ ", with: ""))
                            .font(.game(12, .bold))
                            .foregroundColor(selection == c ? Brand.outline : Brand.cream)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(selection == c ? Brand.goldLight : Color.black.opacity(0.35)))
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
            .padding(.horizontal, 10)
        }
    }
}

/// The equipped slots row ("بالمطبخ").
struct SlotsRow: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let slots = store.chefSlots
        let shown = min(6, slots + (store.nextChefSlotLevel == nil ? 0 : 1))
        WoodPanel(padding: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("بالمطبخ")
                        .font(.game(15, .black))
                        .foregroundColor(Brand.goldLight)
                    Spacer()
                    Text("الطبّاخ بيقوّي المحطّات من مطبخه أو من صنفه")
                        .font(.body(10))
                        .foregroundColor(Brand.cream.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                HStack(spacing: 8) {
                    ForEach(0..<max(1, shown), id: \.self) { k in
                        SlotView(index: k, open: k < slots)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct SlotView: View {
    @EnvironmentObject var store: GameStore
    let index: Int
    let open: Bool

    var body: some View {
        let id = index < store.s.chefs.equipped.count ? store.s.chefs.equipped[index] : nil
        Button {
            Feedback.play(.t0)
            if let id = id {
                store.sheet = .chef(id)
            } else if open {
                store.sheet = .chefPicker
            } else {
                store.showToast("خانة جديدة بمستوى " + Num.int(store.nextChefSlotLevel ?? 0), art: "ui_locked")
            }
        } label: {
            ZStack {
                if let id = id, let c = store.cat.chef(id) {
                    RarityFrame(rarity: c.rarity, art: c.art, size: 52)
                } else if open {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.goldLight.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .frame(width: 52, height: 52)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Brand.goldLight)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 52, height: 52)
                    VStack(spacing: 0) {
                        Image(systemName: "lock.fill").font(.system(size: 14, weight: .heavy))
                        Text(Num.int(store.nextChefSlotLevel ?? 0)).font(.game(11, .black))
                    }
                    .foregroundColor(Brand.cream.opacity(0.6))
                }
            }
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("chef.slot.\(index)")
    }
}

struct ChefCell: View {
    @EnvironmentObject var store: GameStore
    let chef: ChefDef

    var body: some View {
        let own = store.s.chefs.owned[chef.id]
        Button {
            Feedback.play(.t0)
            store.sheet = .chef(chef.id)
        } label: {
            VStack(spacing: 4) {
                RarityFrame(rarity: chef.rarity, art: chef.art, size: 62, dimmed: own == nil)
                    .overlay(Group {
                        if store.isEquipped(chef.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(Brand.parsley)
                                .background(Circle().fill(Color.white).padding(2))
                        }
                    }, alignment: .bottomLeading)
                    .overlay(Group { if store.canLevelUp(chef.id) { RedDot() } }, alignment: .topTrailing)
                Text(own == nil ? "؟" : store.t(chef.name))
                    .font(.game(11, .bold))
                    .foregroundColor(Brand.cream)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .frame(height: 28)
                if let o = own {
                    cardBar(own: o)
                } else {
                    Text(chef.rarity.name)
                        .font(.body(10, bold: true))
                        .foregroundColor(chef.rarity.color)
                        .frame(height: 12)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(chef.rarity.color.opacity(own == nil ? 0.2 : 0.6), lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("chef.card." + chef.id)
    }

    private func cardBar(own: ChefOwn) -> some View {
        let need = store.cardsNeeded(chef, level: own.level)
        let label = need.map { Num.frac(own.cards, $0) } ?? "مكتمل"
        return VStack(spacing: 1) {
            Text("مستوى " + Num.int(own.level))
                .font(.body(9, bold: true))
                .foregroundColor(Brand.goldLight)
            FancyBar(value: need.map { Double(own.cards) / Double(max(1, $0)) } ?? 1,
                     tint: (need.map { own.cards >= $0 } ?? true) ? Brand.parsley : chef.rarity.color, height: 10, label: label)
        }
    }
}

struct ChestsSection: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 8) {
            if store.chestCount == 0 {
                Text("ما في صناديق هسّا. بتجيك صناديق من المستويات والأهداف والدكان")
                    .font(.body(13, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
            }
            ForEach(store.cat.chefs.chests) { def in
                ChestRow(def: def, isFirst: firstAvailable == def.id)
            }
        }
    }

    private var firstAvailable: String? {
        store.cat.chefs.chests.first { (store.s.chefs.chests[$0.id] ?? 0) > 0 }?.id
    }
}

struct ChestRow: View {
    @EnvironmentObject var store: GameStore
    let def: ChestDef
    let isFirst: Bool

    var body: some View {
        let count = store.s.chefs.chests[def.id] ?? 0
        HStack(spacing: 10) {
            ChestArt(kind: def.id, size: 58)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.t(def.name))
                    .font(.game(16, .black))
                    .foregroundColor(Brand.cream)
                Text(contents)
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.7))
                Text("عندك " + Num.int(count))
                    .font(.body(11, bold: true))
                    .foregroundColor(count > 0 ? Brand.goldLight : Brand.cream.opacity(0.5))
            }
            Spacer(minLength: 4)
            if count > 0 {
                ChunkyButton(title: "افتح", color: .green, sound: nil) { store.openChest(def.id) }
                    .frame(width: 90)
                    .fxAnchor(isFirst ? "chest.free" : "chest." + def.id)
            } else {
                buyButton
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.32)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(chestTint.opacity(0.7), lineWidth: 1.5))
    }

    private var chestTint: Color { ChestArt.tint(def.id) }

    private var buyButton: some View {
        let ok = store.s.wallet.gold >= def.price
        return ChunkyButton(title: "اشتري", icon: "ui_coin", subtitle: Num.int(def.price), color: ok ? .gold : .gray, sound: nil) {
            store.buyChest(def.id)
        }
        .frame(width: 90)
    }

    private var contents: String {
        let cards: String = Num.int(def.cards)
        let gold: String = Num.frac(def.goldMin, def.goldMax).replacingOccurrences(of: "/", with: "–")
        return "\(cards) كرت · \(gold) ذهب"
    }
}

/// The gift art inside a coloured ring that tells wood, silver and gold apart.
struct ChestArt: View {
    let kind: String
    var size: CGFloat = 58

    static func tint(_ kind: String) -> Color {
        switch kind {
        case "gold": return Brand.gold
        case "silver": return Color(hex: 0xC9D3DD)
        default: return Brand.woodLight
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [ChestArt.tint(kind).opacity(0.9), ChestArt.tint(kind).opacity(0.15)],
                                     center: .center, startRadius: 2, endRadius: size * 0.6))
            Circle().stroke(Brand.outline.opacity(0.7), lineWidth: 2)
            ArtIcon("ui_gift", size: size * 0.72)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chef detail (S10)

struct ChefDetailSheet: View {
    @EnvironmentObject var store: GameStore
    let chefId: String

    var body: some View {
        if let c = store.cat.chef(chefId) {
            content(c)
        }
    }

    private func content(_ c: ChefDef) -> some View {
        let own = store.s.chefs.owned[c.id]
        return GameModal(title: own == nil ? "طبّاخ ما عندك" : store.t(c.name), onClose: { store.sheet = nil }) {
            HStack(spacing: 12) {
                RarityFrame(rarity: c.rarity, art: c.art, size: 86, dimmed: own == nil)
                VStack(alignment: .leading, spacing: 4) {
                    Tag(text: c.rarity.name, color: c.rarity.color, textColor: .white)
                    Text(GameStore.cuisineName(c.cuisine) + " · " + GameStore.categoryName(c.category))
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.85))
                    if let o = own {
                        Text("مستوى " + Num.int(o.level) + " · +" + Num.percent(store.chefBonus(c.id)))
                            .font(.game(15, .black))
                            .foregroundColor(Brand.goldLight)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(store.t(c.bio))
                .font(.body(12))
                .foregroundColor(Brand.cream.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let o = own {
                levelBox(c, own: o)
                equipButton(c)
            } else {
                Text("بيطلع من الصناديق ومن بسطة الطبّاخين بالدكان")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.glow)
            }
            if let sk = c.skill { skillBox(c, sk) }
            stationsBox(c)
        }
    }

    private func levelBox(_ c: ChefDef, own: ChefOwn) -> some View {
        let cards = store.cardsNeeded(c, level: own.level)
        let gold = store.goldNeeded(level: own.level)
        return VStack(spacing: 6) {
            FancyBar(value: cards.map { Double(own.cards) / Double(max(1, $0)) } ?? 1, tint: c.rarity.color, height: 15,
                     label: cards.map { "كروت " + Num.frac(own.cards, $0) } ?? "أعلى مستوى")
            if let cg = gold, cards != nil {
                ChunkyButton(title: "كبّر الطبّاخ", icon: "ui_coin", subtitle: Num.int(cg),
                             color: store.canLevelUp(c.id) ? .gold : .gray, sound: nil) {
                    store.levelUpChef(c.id)
                }
                .fxAnchor("chef.levelup")
            }
        }
    }

    private func equipButton(_ c: ChefDef) -> some View {
        Group {
            if store.isEquipped(c.id) {
                ChunkyButton(title: "شيله من المطبخ", color: .wood, sound: nil) { store.unequip(c.id) }
            } else if store.chefSlots > 0 {
                ChunkyButton(title: "حطّه بالمطبخ", color: .green, sound: nil) {
                    store.equip(c.id)
                    if store.isEquipped(c.id) { store.sheet = nil }
                }
            } else {
                Tag(text: "الطبّاخين بيشتغلوا من مستوى " + Num.int(store.unlockLevel("chefs")), color: Brand.teal, textColor: .white)
            }
        }
    }

    private func skillBox(_ c: ChefDef, _ sk: SkillDef) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                ArtIcon("ui_high_voltage", size: 22)
                Text("مهارة: " + store.t(sk.name))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.goldLight)
                Spacer()
            }
            Text(GameStore.skillText(sk))
                .font(.body(11, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
            if !store.unlocked("chefSkills") {
                Text("المهارات بتفتح بمستوى " + Num.int(store.unlockLevel("chefSkills")))
                    .font(.body(10, bold: true))
                    .foregroundColor(Brand.glow)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private func stationsBox(_ c: ChefDef) -> some View {
        let list = store.chefStations(c.id)
        return VStack(alignment: .leading, spacing: 4) {
            Text("وين بيقوّي ب" + store.t(store.city.name) + "؟")
                .font(.game(13, .black))
                .foregroundColor(Brand.goldLight)
            if list.isEmpty {
                Text("ولا محطّة هون، بس ممكن يقوّي بمدن تانية")
                    .font(.body(11))
                    .foregroundColor(Brand.cream.opacity(0.7))
            } else {
                HStack(spacing: 6) {
                    ForEach(list, id: \.self) { i in
                        VStack(spacing: 1) {
                            ArtIcon(store.city.stations[i].art, size: 30)
                            Text("×" + String(format: "%.1f", store.matchFactor(c, store.city.stations[i])))
                                .font(.game(10, .black))
                                .foregroundColor(Brand.cream)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }
}

struct ChefPickerSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "اختار طبّاخ", onClose: { store.sheet = nil }) {
            if candidates.isEmpty {
                Text("ما عندك طبّاخين فاضيين. افتح صندوق!")
                    .font(.body(13, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.8))
                    .padding(.vertical, 16)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(candidates) { c in
                        row(c)
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    private var candidates: [ChefDef] {
        store.cat.chefs.chefs.filter { store.s.chefs.owned[$0.id] != nil && !store.isEquipped($0.id) }
            .sorted { cityGain($0) > cityGain($1) }
    }

    private func cityGain(_ c: ChefDef) -> Double {
        store.chefStations(c.id).reduce(0.0) { $0 + store.chefBonus(c.id) * store.matchFactor(c, store.city.stations[$1]) }
    }

    private func row(_ c: ChefDef) -> some View {
        HStack(spacing: 8) {
            RarityFrame(rarity: c.rarity, art: c.art, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.t(c.name)).font(.game(13, .black)).foregroundColor(Brand.cream).lineLimit(1)
                Text("+" + Num.percent(store.chefBonus(c.id)) + " · " + Num.int(store.chefStations(c.id).count) + " محطّات هون")
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.goldLight)
            }
            Spacer(minLength: 4)
            ChunkyButton(title: "حطّ", color: .green, sound: nil) {
                store.equip(c.id)
                store.sheet = nil
            }
            .frame(width: 70)
            .fxAnchor("chef.pick." + c.id)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }
}

extension GameStore {
    static func categoryName(_ c: String) -> String {
        switch c {
        case "fried": return "مقالي"
        case "grill": return "مشاوي"
        case "bakery": return "مخبوزات"
        case "sweets": return "حلويات"
        case "drinks": return "مشروبات"
        case "dishes": return "طبخات"
        case "seafood": return "بحري"
        case "street": return "أكل شارع"
        case "any": return "كل الأصناف"
        default: return ""
        }
    }

    static func skillText(_ sk: SkillDef) -> String {
        let mult = Num.mult(sk.magnitude)
        let dur = Num.dur(sk.durationSec)
        let cd = Num.dur(sk.cooldownMin * 60)
        switch sk.type {
        case "categoryBoost": return "\(categoryName(sk.value ?? "")) \(mult) لمدّة \(dur)، كل \(cd)"
        case "cuisineBoost": return "\(cuisineName(sk.value ?? "")) \(mult) لمدّة \(dur)، كل \(cd)"
        case "allBoost": return "كل المحطّات \(mult) لمدّة \(dur)، كل \(cd)"
        case "instantIncome": return "دخل \(Num.dur(sk.magnitude * 60)) فوراً، كل \(cd)"
        case "spawnSpecial": return "بيجيب زبون مميّز هسّا، كل \(cd)"
        case "frenzy": return "عجقة زباين فوراً، كل \(cd)"
        default: return ""
        }
    }
}
