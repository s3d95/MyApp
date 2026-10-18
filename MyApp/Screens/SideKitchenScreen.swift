import SwiftUI

/// Board of catering contracts (GDD S21).
struct ContractsSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "الطلبيات", onClose: { store.sheet = nil }) {
            Text("طلبيات أكل لمناسبات، بمطبخ لحاله وبوقت محدّد. كل هدف إله جايزة")
                .font(.body(12, bold: true))
                .foregroundColor(Brand.cream.opacity(0.8))
                .multilineTextAlignment(.center)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(store.s.contracts.active, id: \.defId) { k in
                        ActiveContractRow(kitchen: k)
                    }
                    if store.board.isEmpty {
                        Text("ما في طلبيات جديدة هسّا. بتنزل طلبيات الاتنين والأربعا والجمعة")
                            .font(.body(12, bold: true))
                            .foregroundColor(Brand.cream.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                    }
                    ForEach(store.board) { rel in
                        ReleaseCard(release: rel)
                    }
                }
            }
            .frame(maxHeight: 430)
            Text("خانات: " + Num.frac(store.s.contracts.active.count, store.contractSlots))
                .font(.body(11, bold: true))
                .foregroundColor(Brand.cream.opacity(0.6))
        }
    }
}

private struct ActiveContractRow: View {
    @EnvironmentObject var store: GameStore
    let kitchen: SideKitchenSave

    var body: some View {
        let def = store.cat.contract(kitchen.defId)
        HStack(spacing: 8) {
            ArtIcon(def?.art ?? "ui_clipboard", size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(def.map { store.t($0.title) } ?? "")
                    .font(.game(14, .black))
                    .foregroundColor(Brand.cream)
                Text("أهداف " + Num.frac(kitchen.reached, 3) + " · باقي " + Num.dur(kitchen.endAt - store.now()))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.goldLight)
            }
            Spacer(minLength: 4)
            ChunkyButton(title: "افتح", color: .green, sound: nil) { store.sheet = .side(.contract(kitchen.defId)) }
                .frame(width: 76)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Brand.teal.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.teal, lineWidth: 1.5))
    }
}

private struct ReleaseCard: View {
    @EnvironmentObject var store: GameStore
    let release: ReleaseInfo

    var body: some View {
        let def = store.cat.contract(release.contractId)
        let g = store.grade(for: store.level)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ArtIcon(def?.art ?? "ui_clipboard", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(def.map { store.t($0.title) } ?? "")
                            .font(.game(15, .black))
                            .foregroundColor(Brand.cream)
                        Tag(text: release.isNew ? "جديد" : "إعادة", color: release.isNew ? Brand.red : Brand.teal, textColor: .white)
                    }
                    Text((g.map { "صعوبة: " + store.t($0.name) } ?? "") + " · " + Num.dur((def?.durationHours ?? 48) * 3600))
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
            if let d = def {
                Text(store.t(d.desc))
                    .font(.body(11))
                    .foregroundColor(Brand.cream.opacity(0.8))
                    .lineLimit(2)
                HStack(spacing: -6) {
                    ForEach(d.stations.prefix(5)) { st in
                        ArtIcon(st.art, size: 28)
                    }
                    Spacer()
                    ChunkyButton(title: "ابدأ", color: store.s.contracts.active.count < store.contractSlots ? .gold : .gray, sound: nil) {
                        store.startContract(release)
                    }
                    .frame(width: 90)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.32)))
    }
}

/// A side kitchen (contract S22 or weekend venue S23): its own cash, stations, upgrades and goals.
struct SideKitchenSheet: View {
    @EnvironmentObject var store: GameStore
    let ref: SideRef
    @State private var page = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 8) {
                    header
                    if isEvent {
                        SegmentBar(titles: ["المطبخ", "الترتيب", "الدكانة"], selection: $page)
                    }
                    if page == 0 {
                        goalBar
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(0..<store.sideStations(ref).count, id: \.self) { i in
                                    SideStationCard(ref: ref, index: i)
                                }
                                upgradesRow
                            }
                        }
                    } else if page == 1 {
                        EventRanking()
                    } else {
                        EventShop()
                    }
                }
                .padding(12)
                .frame(maxWidth: 400)
                .background(RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Brand.gold, lineWidth: 2))
                .padding(.horizontal, 10)
                .padding(.top, geo.safeAreaInsets.top + 60)
                .padding(.bottom, geo.safeAreaInsets.bottom + 80)
            }
        }
    }

    private var isEvent: Bool {
        if case .event = ref { return true }
        return false
    }

    private var sky: [Color] {
        if case .event = ref, let th = store.cat.theme(store.s.event.themeId) {
            return th.palette.sky.map { $0.opacity(0.95) }
        }
        return [Color(hex: 0x24384A), Color(hex: 0x3A2D4A), Color(hex: 0x4A2718)]
    }

    private var header: some View {
        let k = store.side(ref)
        return HStack(spacing: 8) {
            ArtIcon(store.sideArt(ref), size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.sideTitle(ref))
                    .font(.game(17, .black))
                    .foregroundColor(Brand.goldLight)
                    .lineLimit(1)
                Text("باقي " + Num.dur((k?.endAt ?? 0) - store.now()))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.8))
            }
            Spacer(minLength: 4)
            CurrencyPill(icon: store.sideCashArt(ref), text: Num.big(k?.cash ?? 0))
            RoundIconButton(system: "xmark", size: 30) { store.sheet = nil }
        }
    }

    @ViewBuilder
    private var goalBar: some View {
        if let k = store.side(ref) {
            switch ref {
            case .contract:
                ContractGoals(kitchen: k)
            case .event:
                EventMilestones(kitchen: k)
            }
        }
    }

    private var upgradesRow: some View {
        let rules = store.sideRules(ref)
        return Group {
            if !rules.contains("noUpgrades"), let k = store.side(ref) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ترقيات المطبخ")
                        .font(.game(13, .black))
                        .foregroundColor(Brand.goldLight)
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { j in
                            upgradeButton(j, k)
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
            }
        }
    }

    private func upgradeButton(_ j: Int, _ k: SideKitchenSave) -> some View {
        let defs = store.sideStations(ref)
        let target = j == 2 ? "الكل" : (j < defs.count ? store.t(defs[j].name) : "")
        let bought = k.upgrades.contains(j)
        let price = store.sideUpgradePrice(j)
        return ChunkyButton(title: target + " ×3", subtitle: bought ? "✓" : Num.big(price),
                            color: bought ? .wood : (k.cash >= price ? .purple : .gray), sound: nil) {
            if !bought { store.sideBuyUpgrade(ref, j) }
        }
    }
}

private struct ContractGoals: View {
    @EnvironmentObject var store: GameStore
    let kitchen: SideKitchenSave

    var body: some View {
        let delivered = store.delivered(kitchen)
        let g3 = store.contractTarget(kitchen, 2)
        let partners = store.partnerShare(kitchen, at: store.now()).reduce(0, +)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("تسليم: " + Num.big(delivered))
                    .font(.game(13, .black))
                    .foregroundColor(Brand.cream)
                Spacer()
                Text("الشركا: " + Num.big(partners))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.teal)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.4))
                    Capsule().fill(Brand.teal.opacity(0.8))
                        .frame(width: g.size.width * CGFloat(min(1, delivered / max(1, g3))))
                    Capsule().fill(Brand.titleFill)
                        .frame(width: g.size.width * CGFloat(min(1, kitchen.lifetime / max(1, g3))))
                    ForEach(0..<3, id: \.self) { i in
                        let x = min(1, store.contractTarget(kitchen, i) / max(1, g3))
                        Image(systemName: i < kitchen.reached ? "star.fill" : "star")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(i < kitchen.reached ? Brand.goldLight : Brand.cream)
                            .position(x: g.size.width * CGFloat(x) - 8, y: g.size.height / 2)
                    }
                }
            }
            .frame(height: 18)
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
    }
}

private struct EventMilestones: View {
    @EnvironmentObject var store: GameStore
    let kitchen: SideKitchenSave

    var body: some View {
        let count = store.cat.events.milestones.count
        let next = min(count - 1, kitchen.reached)
        let target = store.eventTarget(kitchen, next)
        let theme = store.cat.theme(store.s.event.themeId)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("مرحلة " + Num.frac(kitchen.reached, count))
                    .font(.game(13, .black))
                    .foregroundColor(Brand.cream)
                Spacer()
                ArtIcon(theme?.tokens.art ?? "ui_star", size: 20)
                Text(Num.int(store.s.event.tokens) + " " + (theme.map { store.t($0.tokens.name) } ?? ""))
                    .font(.game(12, .black))
                    .foregroundColor(Brand.goldLight)
            }
            HStack(spacing: 3) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule()
                        .fill(i < kitchen.reached ? AnyShapeStyle(Brand.titleFill) : AnyShapeStyle(Color.black.opacity(0.4)))
                        .frame(height: 8)
                }
            }
            if kitchen.reached < count {
                FancyBar(value: kitchen.lifetime / max(1, target), tint: Brand.teal, height: 11,
                         label: Num.fracBig(kitchen.lifetime, target))
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
    }
}

private struct SideStationCard: View {
    @EnvironmentObject var store: GameStore
    let ref: SideRef
    let index: Int

    var body: some View {
        let defs = store.sideStations(ref)
        if let k = store.side(ref), index < defs.count, index < k.stations.count {
            card(defs[index], k)
        }
    }

    private func card(_ d: SideStationDef, _ k: SideKitchenSave) -> some View {
        let st = k.stations[index]
        let locked = store.sideStationLocked(ref, index)
        let plan = store.sideBuyPlan(ref, index)
        return HStack(spacing: 10) {
            Button {
                store.sideTap(ref, index)
            } label: {
                ZStack {
                    Circle()
                        .fill(st.level > 0 ? Brand.cream : Color.black.opacity(0.35))
                        .frame(width: 54, height: 54)
                    if st.managed || st.cooking {
                        Circle()
                            .trim(from: 0, to: store.sideCycle(k, ref, index) < 0.6 ? 1 : CGFloat(st.progress))
                            .stroke(Brand.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 60, height: 60)
                    }
                    ArtIcon(d.art, size: 40)
                        .saturation(st.level > 0 ? 1 : 0)
                        .opacity(st.level > 0 ? 1 : 0.5)
                }
                .frame(width: 62, height: 62)
            }
            .buttonStyle(PressScaleStyle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.t(d.name))
                    .font(.game(15, .black))
                    .foregroundColor(Brand.cream)
                if locked {
                    Text("بتفتح بالمرحلة 3")
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.glow)
                } else if st.level > 0 {
                    Text("مستوى " + Num.frac(st.level, store.sideEcon.cap))
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.75))
                    Text(Num.big(store.sideIncome(k, ref, index, active: true)) + "/ث")
                        .font(.game(12, .black))
                        .foregroundColor(Theme.money)
                }
            }
            Spacer(minLength: 4)
            VStack(spacing: 4) {
                if !locked {
                    ChunkyButton(title: st.level == 0 ? "افتح" : "اشتري", subtitle: Num.big(plan.cost),
                                 color: plan.affordable ? .green : .gray, sound: nil) {
                        store.sideBuy(ref, index)
                    }
                }
                if st.level > 0 && !st.managed && !store.sideRules(ref).contains("noManagers") {
                    let c = store.sideManagerCost(ref, index)
                    Button {
                        store.sideHire(ref, index)
                    } label: {
                        Text("وظّف " + Num.big(c))
                            .font(.game(10, .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 9).fill(k.cash >= c ? Brand.teal : Color(hex: 0x5E5048)))
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
            .frame(width: 100)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.35)))
    }
}

private struct EventRanking: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 3) {
                ForEach(Array(store.eventRows.enumerated()), id: \.element.id) { k, row in
                    HStack(spacing: 8) {
                        Text(Num.int(k + 1))
                            .font(.game(13, .black))
                            .foregroundColor(Brand.cream)
                            .frame(width: 26)
                        ArtIcon(row.art, size: 24)
                        Text(row.name)
                            .font(.game(13, row.isPlayer ? .black : .bold))
                            .foregroundColor(row.isPlayer ? Brand.outline : Brand.cream)
                            .lineLimit(1)
                        Spacer()
                        Text(Num.big(Double(row.score)))
                            .font(.game(12, .black))
                            .foregroundColor(row.isPlayer ? Brand.outline : Brand.goldLight)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(row.isPlayer ? Brand.goldLight : Color.black.opacity(0.3)))
                }
            }
        }
    }
}

private struct EventShop: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let theme = store.cat.theme(store.s.event.themeId)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 6) {
                HStack {
                    ArtIcon(theme?.tokens.art ?? "ui_star", size: 26)
                    Text(Num.int(store.s.event.tokens) + " " + (theme.map { store.t($0.tokens.name) } ?? ""))
                        .font(.game(15, .black))
                        .foregroundColor(Brand.goldLight)
                    Spacer()
                }
                ForEach(store.cat.events.shop) { item in
                    shopRow(item, theme)
                }
                Text("اللي بيضل من التوكنز بيتحوّل ذهب بآخر المهرجان")
                    .font(.body(10))
                    .foregroundColor(Brand.cream.opacity(0.6))
            }
        }
    }

    private func shopRow(_ item: EventShopItemDef, _ theme: EventThemeDef?) -> some View {
        let bought = store.s.event.shop[item.id] ?? 0
        let left = item.max - bought
        return HStack(spacing: 8) {
            ArtIcon(SeasonTierRowArt.art(item.reward), size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(itemName(item))
                    .font(.game(13, .black))
                    .foregroundColor(Brand.cream)
                Text("باقي " + Num.int(left))
                    .font(.body(10))
                    .foregroundColor(Brand.cream.opacity(0.6))
            }
            Spacer()
            ChunkyButton(title: Num.int(item.price), icon: theme?.tokens.art, color: left > 0 && store.s.event.tokens >= item.price ? .gold : .gray,
                         sound: nil) {
                store.buyEventItem(item)
            }
            .frame(width: 90)
            .fxAnchor("eventShop." + item.id)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private func itemName(_ item: EventShopItemDef) -> String {
        let r = item.reward
        switch r.type {
        case "chefCards": return "كروت طبّاخ ×" + Num.int(Int(r.amount))
        case "timeWarpMin": return "رزمة وقت " + Num.dur(r.amount * 60)
        case "chest": return store.chestName(r.id ?? "wood")
        case "heritageCase": return "صندوق تراث"
        case "tickets": return "تذكرة"
        case "cosmetic": return "زينة المهرجان"
        default: return r.type
        }
    }
}

enum SeasonTierRowArt {
    static func art(_ r: Reward) -> String {
        switch r.type {
        case "gold": return "ui_coin"
        case "chest": return "ui_gift"
        case "tickets": return "ui_admission_tickets"
        case "timeWarpMin": return "ui_hourglass"
        case "chefCards": return "ppl_cook"
        case "heritageItem", "heritageCase": return "ui_old_key"
        case "freezes": return "ui_snowflake"
        case "cosmetic": return "ui_artist_palette"
        default: return "ui_gift"
        }
    }
}
