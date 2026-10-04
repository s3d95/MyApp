import SwiftUI

enum Tab: CaseIterable {
    case shop, upgrades, daily, chefs, empire

    var title: String {
        switch self {
        case .shop: return "البسطة"
        case .upgrades: return "التطويرات"
        case .daily: return "اليومي"
        case .chefs: return "الطبّاخين"
        case .empire: return "الإمبراطورية"
        }
    }

    var icon: String {
        switch self {
        case .shop: return "flame.fill"
        case .upgrades: return "arrow.up.circle.fill"
        case .daily: return "gift.fill"
        case .chefs: return "person.2.fill"
        case .empire: return "crown.fill"
        }
    }
}

struct RootView: View {
    @StateObject private var game = Game()
    @State private var tab: Tab = .shop
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bgTop, Theme.bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                TabBar(tab: $tab)
            }

            if let v = game.vip, !game.showRush {
                VIPLayer(vip: v)
                    .id(v.id)
                    .transition(.scale.combined(with: .opacity))
            }

            if let r = game.chestReveal {
                ChestRevealView(reveal: r)
                    .id(r.id)
                    .transition(.opacity)
            }

            if game.showWheel {
                WheelView().transition(.opacity)
            }

            if game.showRush {
                RushView().transition(.move(edge: .bottom))
            }

            if game.showOffline {
                OfflineView().transition(.opacity)
            } else if game.showWhatsNew && !game.s.stallName.isEmpty {
                WhatsNewView().transition(.opacity)
            } else if game.showLogin && !game.s.stallName.isEmpty {
                LoginView().transition(.opacity)
            }
            if game.s.stallName.isEmpty {
                OnboardingView().transition(.opacity)
            }

            VStack {
                if let t = game.toast {
                    ToastView(toast: t)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 70)
            .allowsHitTesting(false)
        }
        .environmentObject(game)
        .onChange(of: phase) { p in
            if p == .active {
                if !game.isRunning { game.resume() }
            } else if p == .background {
                game.pause()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .shop: ShopView()
        case .upgrades: UpgradesTab()
        case .daily: DailyView()
        case .chefs: ChefsView()
        case .empire: EmpireView()
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let now = Date()
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.money(game.s.money))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(Theme.money)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("+\(Fmt.money(game.s.incomePerSecond(now: now))) بالثانية")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 5) {
                    if game.s.stars > 0 {
                        Chip(text: "⭐ \(Fmt.number(game.s.stars))")
                    }
                    LiraChip(amount: game.s.liras)
                }
                BoostChips(now: now)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}

/// Live countdowns for temporary profit boosts.
struct BoostChips: View {
    @EnvironmentObject var game: Game
    let now: Date

    var body: some View {
        let event = game.s.boostUntil.flatMap { $0 > now ? $0 : nil }
        let mega = game.s.megaBoostUntil.flatMap { $0 > now ? $0 : nil }
        if event != nil || mega != nil {
            TimelineView(.periodic(from: now, by: 1)) { ctx in
                HStack(spacing: 5) {
                    if let u = event {
                        Chip(text: "🔥 ×\(Int(game.s.boostFactor)) · \(Fmt.duration(u.timeIntervalSince(ctx.date)))")
                    }
                    if let u = mega {
                        Chip(text: "⚡ ×2 · \(Fmt.duration(u.timeIntervalSince(ctx.date)))")
                    }
                }
            }
        }
    }
}

struct TabBar: View {
    @Binding var tab: Tab
    @EnvironmentObject var game: Game

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    tab = t
                    if game.s.hapticsOn { Feedback.light() }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: t.icon)
                                .font(.system(size: 20, weight: .semibold))
                            if hasBadge(t) {
                                Circle()
                                    .fill(Theme.red)
                                    .frame(width: 9, height: 9)
                                    .offset(x: 6, y: -3)
                            }
                        }
                        Text(t.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(tab == t ? Theme.gold : Theme.muted.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                }
            }
        }
        .background(Theme.bgBottom.ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .top)
    }

    private func hasBadge(_ t: Tab) -> Bool {
        let s = game.s
        switch t {
        case .shop:
            return false
        case .upgrades:
            return Badges.managers(s) || Badges.upgrades(s)
        case .daily:
            return Badges.daily(s, today: game.today)
        case .chefs:
            return Badges.chefs(s)
        case .empire:
            return Badges.branches(s) || Badges.research(s) || Badges.prestige(s)
        }
    }
}

/// Red-dot rules shared by the tab bar and the sub-tab chips.
enum Badges {
    static func managers(_ s: GameState) -> Bool {
        GameData.businesses.contains { d in
            s.lines[d.id].owned > 0 && !s.lines[d.id].hasManager && s.money >= d.managerCost
        }
    }

    static func upgrades(_ s: GameState) -> Bool {
        if let c = s.nextAutoCost, s.money >= c { return true }
        if let c = s.nextTapCost, s.money >= c { return true }
        if let c = s.nextShareCost, s.money >= c { return true }
        return GameData.upgrades.contains { u in
            guard !s.purchased.contains(u.id), s.money >= u.cost else { return false }
            if let sec = u.section { return s.lines[sec].owned > 0 }
            return true
        }
    }

    static func daily(_ s: GameState, today: Int) -> Bool {
        s.loginPending(today: today) || s.freeSpinReady(today: today) || s.missionClaimable
            || s.missionBonusReady || s.tickets >= s.maxTickets
    }

    static func chefs(_ s: GameState) -> Bool {
        s.chests.contains { $0 > 0 } || s.anyChefUpgradable
    }

    static func branches(_ s: GameState) -> Bool {
        if let b = s.nextBranch { return s.money >= b.cost }
        return false
    }

    static func research(_ s: GameState) -> Bool { s.anyResearchAffordable }

    /// Worth prestiging once it would at least double the star bonus.
    static func prestige(_ s: GameState) -> Bool { s.pendingStars >= 1 && s.prestigeGainRatio >= 2 }
}
