import SwiftUI

struct KitchenScreen: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 8) {
            StageView()
                .frame(height: 214)
                .padding(.horizontal, 10)
            if store.goalStripVisible {
                GoalStrip()
                    .padding(.horizontal, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if !store.city.twists.isEmpty {
                TwistStrip()
                    .padding(.horizontal, 10)
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(0..<store.city.stations.count, id: \.self) { i in
                        StationCard(i: i)
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 10)
                .padding(.top, 2)
            }
            ActionBar()
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
        .padding(.top, 2)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.goalStripVisible)
    }
}

// MARK: - Stage

struct StageView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let c = store.city
        let night = store.nightActive
        let sky = night ? [Color(hex: 0x0B1030), Color(hex: 0x1B2350), Color(hex: 0x3A2D63), Color(hex: 0x6E4A7A)] : c.palette.sky
        let style = SceneStyle(sky: sky, ground: Color(hex: 0x6B4A33), landmark: c.landmarkArt)
        ZStack {
            StreetScene(style: style, title: store.s.settings.stallName,
                        dishes: unlockedDishes, customers: c.customerArts + StreetScene.defaultCustomers,
                        rate: crowdRate, lights: store.stallTier >= 2 || night, tier: store.stallTier)
            VStack(spacing: 4) {
                BannerLine()
                BoostChips()
                Spacer()
            }
            .padding(8)
            HStack {
                Spacer()
                LeftRail()
            }
            .padding(.horizontal, 6)
            if let sp = store.special {
                SpecialCustomerView(visit: sp)
                    .environment(\.layoutDirection, .leftToRight)
                    .id(sp.id)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var unlockedDishes: [String] {
        let list = store.city.stations.enumerated().filter { store.s.city.stations[$0.offset].level > 0 }.map { $0.element.art }
        return list.isEmpty ? ["food_falafel"] : list
    }

    private var crowdRate: Double {
        let inc = store.totalIncome(active: true)
        return min(40, max(6, 6 + 4 * log10(inc + 1)))
    }
}

struct BannerLine: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        Group {
            if store.s.meta.clockFrozen {
                banner("ساعة الجهاز رجعت لورا، الوقت موقّف لحد ما ترجع", color: Brand.red, art: "ui_alarm_clock")
            } else if store.busWaiting {
                banner("باص سيّاح وصل! استقبله من تحت", color: Brand.teal, art: "veh_bus")
            } else if store.isRushHour {
                banner("ساعة الذروة! الدخل دبل", color: Brand.goldDeep, art: "ui_fire")
            }
        }
    }

    private func banner(_ text: String, color: Color, art: String) -> some View {
        HStack(spacing: 6) {
            ArtIcon(art, size: 22, shadow: false)
            Text(text)
                .font(.game(13, .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.92)))
        .overlay(Capsule().stroke(Brand.outline.opacity(0.6), lineWidth: 1.5))
        .fxAnchor("banner.rushHour")
    }
}

struct BoostChips: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        HStack(spacing: 4) {
            ForEach(store.s.boosts) { b in
                chip(art: store.boostArt(b.kind), text: Num.mult(b.mult) + " " + Num.dur(b.left))
            }
            if store.s.city.twist.busWaveLeft > 0, let p = store.twist(.busWaves) {
                chip(art: "veh_bus", text: Num.mult(p.waveMult) + " " + Num.dur(store.s.city.twist.busWaveLeft))
            }
            Spacer(minLength: 0)
        }
    }

    private func chip(art: String, text: String) -> some View {
        HStack(spacing: 3) {
            ArtIcon(art, size: 18, shadow: false)
            Text(text)
                .font(.game(11, .black).monospacedDigit())
                .foregroundColor(Brand.goldLight)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.black.opacity(0.6)))
    }
}

/// Appointment rail (GDD 1.6): research, supply runs, vault and branch safe; the next locked item shows as "?".
struct LeftRail: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 4) {
            if store.unlocked("research") {
                RailButton(icon: "ui_notebook", label: researchLabel, dot: researchDot) {
                    store.sheet = .research
                }
                .fxAnchor("rail.research")
            }
            if store.unlocked("supply") {
                RailButton(icon: "veh_tractor", label: supplyLabel, dot: supplyDot) {
                    store.sheet = .supply
                }
                .fxAnchor("rail.supply")
            }
            RailButton(icon: "ui_money_bag", label: Num.dur(store.vaultCapHours * 3600), dot: false) {
                store.showToast("الخزنة بتجمع دخل المعلّمين لحد " + Num.dur(store.vaultCapHours * 3600) + " وإنت برّا", art: "ui_money_bag")
            }
            .fxAnchor("rail.vault")
            if !store.s.branches.isEmpty {
                RailButton(icon: "bld_classical_building", label: Num.percent(store.safeFill), dot: store.safeFill >= 0.5) {
                    store.collectSafe()
                }
                .fxAnchor("safe.collect")
            } else if let next = nextLocked {
                RailButton(icon: nil, label: "مستوى " + Num.int(next.1), dot: false) {
                    store.showToast(next.0 + " بتفتح بمستوى " + Num.int(next.1), art: "ui_locked")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private var nextLocked: (String, Int)? {
        if !store.unlocked("research") { return ("دفتر ستّي", store.unlockLevel("research")) }
        if !store.unlocked("supply") { return ("رحلات التوريد", store.unlockLevel("supply")) }
        return nil
    }

    private var researchLabel: String {
        if store.researchReady { return "خلص!" }
        if let e = store.nextResearchEnd { return Num.dur(max(0, e - store.now())) }
        return "فاضي"
    }

    private var researchDot: Bool {
        store.researchReady || store.freeResearchSlots > 0
    }

    private var supplyLabel: String {
        if store.runsReady > 0 { return "رجعت!" }
        if let e = store.nextRunEnd { return Num.dur(max(0, e - store.now())) }
        return "فاضي"
    }

    private var supplyDot: Bool { store.runsReady > 0 || store.freeSupplySlots > 0 }
}

/// Compact round rail button with a label chip and a red dot.
struct RailButton: View {
    let icon: String?
    let label: String
    var dot = false
    let action: () -> Void

    var body: some View {
        Button {
            Feedback.play(.t0)
            action()
        } label: {
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Brand.gold.opacity(0.6), lineWidth: 1.5))
                Group {
                    if let i = icon {
                        ArtIcon(i, size: 28)
                    } else {
                        Image(systemName: "questionmark")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(Brand.cream.opacity(0.6))
                    }
                }
                .frame(width: 42, height: 42)
                Text(label)
                    .font(.game(9, .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 34, maxWidth: 52)
                    .background(Capsule().fill(Brand.outline.opacity(0.92)))
                    .offset(y: 7)
            }
            .frame(width: 52, height: 50)
            .overlay(Group { if dot { RedDot().offset(x: -2, y: 0) } }, alignment: .topTrailing)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct SpecialCustomerView: View {
    @EnvironmentObject var store: GameStore
    let visit: SpecialVisit
    @State private var appear = false

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.1)) { _ in
                let age = store.now() - visit.spawnedAt
                let left = max(0, 1 - age / visit.lifetime)
                Button {
                    store.tapSpecial()
                } label: {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Brand.goldLight.opacity(0.85), Brand.gold.opacity(0)],
                                                 center: .center, startRadius: 4, endRadius: 46))
                            .frame(width: 92, height: 92)
                        Circle()
                            .trim(from: 0, to: CGFloat(left))
                            .stroke(Brand.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 68, height: 68)
                        ArtIcon(visit.art, size: 56)
                        ArtIcon(store.specialIcon(visit), size: 26)
                            .offset(y: -40)
                    }
                }
                .buttonStyle(PressScaleStyle())
                .fxAnchor("special")
                .scaleEffect(appear ? 1 : 0.3)
                .position(x: geo.size.width * 0.32, y: geo.size.height * 0.58)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { appear = true }
        }
    }
}

// MARK: - Action bar

struct ActionBar: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Feedback.play(.t0)
                store.buyMode = store.buyMode.following
                store.evaluateFtue()
            } label: {
                VStack(spacing: 0) {
                    Text("اشتري")
                        .font(.game(10, .bold))
                    Text(store.buyMode.label)
                        .font(.game(17, .black))
                }
                .frame(width: 70)
            }
            .buttonStyle(ChunkyStyle(color: .blue))
            .fxAnchor("buyMode")

            upgradesButton

            Button {
                Feedback.play(.t0)
                store.sheet = .goals
            } label: {
                HStack(spacing: 4) {
                    ArtIcon("ui_star", size: 22, shadow: false)
                    Text(Num.frac(store.s.city.stars, store.supportedStars))
                        .font(.game(14, .black).monospacedDigit())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyStyle(color: .wood))
        }
        .frame(height: 52)
    }

    private var upgradesButton: some View {
        let open = store.unlocked("upgrades")
        let affordable = store.nextUpgrades.first.map { store.s.city.cash >= store.upgradePrice($0) } ?? false
        return Button {
            Feedback.play(.t0)
            if open {
                store.sheet = .upgrades
            } else {
                store.showToast("الترقيات بتفتح بمستوى " + Num.int(store.unlockLevel("upgrades")), art: "ui_locked")
            }
        } label: {
            HStack(spacing: 4) {
                if open {
                    ArtIcon("ui_sparkles", size: 22, shadow: false)
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 14, weight: .heavy))
                }
                Text(open ? "ترقيات" : "مستوى " + Num.int(store.unlockLevel("upgrades")))
                    .font(.game(15, .black))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyStyle(color: open ? .purple : .gray))
        .overlay(Group { if open && affordable { RedDot().offset(x: 4, y: -4) } }, alignment: .topTrailing)
        .fxAnchor("upgrades")
    }
}
