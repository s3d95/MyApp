import SwiftUI

/// The city route (GDD S6): bottom = Jerusalem, three regions, branches with their safe on top.
struct MapScreen: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SafeCard()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    ForEach(Array(store.cat.cities.reversed())) { c in
                        if c.index == store.cat.cities.count || isRegionTop(c) {
                            RegionBanner(name: c.regionName)
                                .padding(.vertical, 8)
                        }
                        CityNode(city: c)
                            .id(c.id)
                    }
                    Color.clear.frame(height: 20)
                }
            }
            .onAppear {
                DispatchQueue.main.async { proxy.scrollTo(store.city.id, anchor: .center) }
                store.evaluateFtue()
            }
        }
    }

    private func isRegionTop(_ c: CityDef) -> Bool {
        guard let above = store.cat.city(index: c.index + 1) else { return true }
        return above.region != c.region
    }
}

struct RegionBanner: View {
    let name: String

    var body: some View {
        Ribbon(text: name, color: Brand.teal, size: 16)
    }
}

struct SafeCard: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        WoodPanel(padding: 10) {
            HStack(spacing: 10) {
                ArtIcon("bld_classical_building", size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("خزنة الفروع")
                        .font(.game(15, .black))
                        .foregroundColor(Brand.goldLight)
                    if store.s.branches.isEmpty {
                        Text(store.mf("افتح أوّل فرع عشان تجمع ذهب كل يوم", "افتحي أوّل فرع عشان تجمعي ذهب كل يوم"))
                            .font(.body(12))
                            .foregroundColor(Brand.cream.opacity(0.8))
                    } else {
                        FancyBar(value: store.safeFill, tint: Brand.gold, height: 13,
                                 label: Num.int(Int(store.s.branchSafe.stored)) + "/" + Num.int(Int(store.safeCap)))
                        Text(String(format: "%.1f", store.branchGoldPerDay) + " ذهب/يوم · " + Num.int(store.s.branches.count) + " فروع")
                            .font(.body(11, bold: true))
                            .foregroundColor(Brand.cream.opacity(0.75))
                    }
                }
                if !store.s.branches.isEmpty {
                    ChunkyButton(title: "اجمع", color: store.s.branchSafe.stored >= 1 ? .gold : .gray, sound: nil) {
                        store.collectSafe()
                    }
                    .frame(width: 80)
                    .fxAnchor("safe.collect")
                }
            }
        }
    }
}

struct CityNode: View {
    @EnvironmentObject var store: GameStore
    let city: CityDef

    private enum NodeState { case branch, current, next, locked }

    private var state: NodeState {
        if store.s.branches[city.id] != nil { return .branch }
        if city.id == store.city.id { return .current }
        if city.index == store.city.index + 1 { return .next }
        return .locked
    }

    var body: some View {
        let left = city.index % 2 == 0
        HStack {
            if left { Spacer() }
            node
                .frame(width: 210)
            if !left { Spacer() }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 6)
        .background(path, alignment: .center)
    }

    private var path: some View {
        Rectangle()
            .fill(Brand.goldLight.opacity(0.25))
            .frame(width: 4)
            .frame(maxHeight: .infinity)
    }

    private var node: some View {
        let st = state
        return Button {
            tap(st)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: city.palette.sky, startPoint: .top, endPoint: .bottom))
                        .frame(width: 76, height: 76)
                        .overlay(Circle().stroke(ring(st), lineWidth: st == .current ? 4 : 3))
                        .saturation(st == .locked ? 0.2 : 1)
                    if st == .locked {
                        Image(systemName: "questionmark")
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(Brand.cream.opacity(0.6))
                    } else {
                        ArtIcon(city.landmarkArt, size: 54)
                    }
                    if st == .next {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Brand.outline))
                            .offset(x: 26, y: 26)
                    }
                    if let b = store.s.branches[city.id] {
                        if b.crowned {
                            ArtIcon("ui_crown", size: 30).offset(y: -40)
                        }
                        Text(Num.int(b.level))
                            .font(.game(12, .black))
                            .foregroundColor(Brand.outline)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Brand.titleFill))
                            .overlay(Circle().stroke(Brand.outline, lineWidth: 1.5))
                            .offset(x: -28, y: 26)
                    }
                }
                .modifier(Pulse(active: st == .current, amount: 0.04))
                Text(st == .locked ? "؟" : store.t(city.name))
                    .font(.game(15, .black))
                    .foregroundColor(st == .locked ? Brand.cream.opacity(0.5) : Brand.cream)
                Text(subtitle(st))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.goldLight.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(PressScaleStyle())
        .modifier(NextAnchor(active: st == .next))
    }

    private func ring(_ st: NodeState) -> Color {
        switch st {
        case .branch: return Brand.gold
        case .current: return Brand.goldLight
        case .next: return Brand.cream.opacity(0.7)
        case .locked: return Color.black.opacity(0.4)
        }
    }

    private func subtitle(_ st: NodeState) -> String {
        switch st {
        case .branch:
            let b = store.s.branches[city.id] ?? BranchSave()
            let perDay = store.econ.branches.goldPerDayBase * (1 + store.econ.branches.goldPerLevel * Double(b.level))
            return "فرع · " + String(format: "%.1f", perDay) + " ذهب/يوم"
        case .current:
            return "★ " + Num.int(store.s.city.stars) + "/" + Num.int(store.starsNeeded)
        case .next:
            if store.licenceLeft > 0 { return "الرخصة بعد " + Num.dur(store.licenceLeft) }
            return "بدها " + Num.int(store.starsNeeded) + " نجمة"
        case .locked:
            return city.regionName
        }
    }

    private func tap(_ st: NodeState) {
        Feedback.play(.t0)
        switch st {
        case .branch: store.sheet = .branch(city.id)
        case .current: store.tab = .home
        case .next:
            if store.canGraduate {
                store.requestGraduation()
            } else {
                store.showToast(store.t(city.name) + " بتفتح لما تجمع " + Num.int(store.starsNeeded) + " نجمة وتطلع الرخصة",
                                art: city.landmarkArt)
            }
        case .locked:
            store.showToast("كمّل المدن اللي قبلها عشان توصل لهون", art: "ui_locked")
        }
    }
}

private struct NextAnchor: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.fxAnchor("map.next")
        } else {
            content
        }
    }
}
