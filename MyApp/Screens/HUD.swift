import SwiftUI

struct HUDBar: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        HStack(spacing: 6) {
            Button {
                Feedback.play(.t0)
                store.sheet = .profile
            } label: {
                LevelBadge(level: store.level, progress: store.xpProgress)
            }
            .buttonStyle(PressScaleStyle())
            .fxAnchor("hud.level")

            HStack(spacing: 4) {
                CurrencyPill(icon: store.city.currency.art, text: Num.big(store.s.city.cash), anchor: "pill.cash")
                    .layoutPriority(2)
                CurrencyPill(icon: "ui_coin", text: Num.int(store.s.wallet.gold), anchor: "pill.gold")
                CurrencyPill(icon: "ui_star", text: Num.int(store.s.city.stars) + "/" + Num.int(store.starsNeeded),
                             anchor: "pill.stars")
            }
            .frame(maxWidth: .infinity)

            RoundIconButton(system: "gearshape.fill", color: .wood, size: 34) {
                store.sheet = .settings
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }
}

struct GameTabBar: View {
    @EnvironmentObject var store: GameStore
    var bottomInset: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(GameTab.allCases, id: \.rawValue) { tab in
                TabButton(tab: tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, max(6, bottomInset))
        .background(
            LinearGradient(colors: [Brand.wood, Brand.woodDark], startPoint: .top, endPoint: .bottom)
                .overlay(Rectangle().fill(Brand.gold.opacity(0.5)).frame(height: 2), alignment: .top)
                .ignoresSafeArea()
        )
    }
}

struct TabButton: View {
    @EnvironmentObject var store: GameStore
    let tab: GameTab

    private var isOpen: Bool { store.unlocked(tab.system) }
    private var isBuilt: Bool { tab == .home || tab == .map }

    var body: some View {
        let selected = store.tab == tab
        let center = tab == .home
        Button {
            select()
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(selected ? AnyShapeStyle(Brand.titleFill) : AnyShapeStyle(Color.black.opacity(0.35)))
                        .frame(width: center ? 58 : 44, height: center ? 58 : 44)
                        .overlay(Circle().stroke(Brand.outline.opacity(0.7), lineWidth: 2))
                    Image(systemName: isOpen ? tab.symbol : "lock.fill")
                        .font(.system(size: center ? 26 : 19, weight: .heavy))
                        .foregroundColor(selected ? Brand.outline : (isOpen ? Brand.cream : Brand.cream.opacity(0.5)))
                }
                .overlay(redDot, alignment: .topTrailing)
                .offset(y: center ? -10 : 0)
                Text(label)
                    .font(.game(11, .bold))
                    .foregroundColor(selected ? Brand.goldLight : Brand.cream.opacity(isOpen ? 0.9 : 0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .offset(y: center ? -8 : 0)
            }
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("tab." + anchorName)
    }

    private var anchorName: String {
        switch tab {
        case .map: return "map"
        case .tasks: return "tasks"
        case .home: return "home"
        case .chefs: return "chefs"
        case .shop: return "shop"
        }
    }

    private var label: String {
        if !isOpen { return "مستوى " + Num.int(store.unlockLevel(tab.system)) }
        return tab.title
    }

    @ViewBuilder
    private var redDot: some View {
        if dot {
            RedDot().offset(x: 2, y: -2)
        }
    }

    private var dot: Bool {
        switch tab {
        case .home: return store.tab != .home && store.claimableGoals > 0
        case .map: return isOpen && (store.canGraduate || (!store.s.branches.isEmpty && store.safeFill >= 0.5))
        default: return false
        }
    }

    private func select() {
        Feedback.play(.t0)
        if !isOpen || !isBuilt {
            store.sheet = .teaser(tab)
            return
        }
        store.tab = tab
        store.evaluateFtue()
    }
}
