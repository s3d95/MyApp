import SwiftUI

enum Tab: CaseIterable {
    case shop, managers, upgrades, branches, more

    var title: String {
        switch self {
        case .shop: return "البسطة"
        case .managers: return "الموظفين"
        case .upgrades: return "التطويرات"
        case .branches: return "الفروع"
        case .more: return "المزيد"
        }
    }

    var icon: String {
        switch self {
        case .shop: return "flame.fill"
        case .managers: return "person.3.fill"
        case .upgrades: return "arrow.up.circle.fill"
        case .branches: return "star.fill"
        case .more: return "chart.bar.fill"
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

            if let v = game.vip {
                VIPLayer(vip: v)
                    .id(v.id)
                    .transition(.scale.combined(with: .opacity))
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

            if game.showOffline {
                OfflineView().transition(.opacity)
            }
            if game.s.stallName.isEmpty {
                OnboardingView().transition(.opacity)
            }
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
        case .managers: ManagersView()
        case .upgrades: UpgradesView()
        case .branches: PrestigeView()
        case .more: MoreView()
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
                Chip(text: "📍 " + game.s.cityName)
                if game.s.claimedStars > 0 {
                    Chip(text: "⭐ \(Int(game.s.claimedStars)) · +\(Int(game.s.claimedStars * 2))%")
                }
                if let until = game.s.boostUntil, until > now {
                    TimelineView(.periodic(from: now, by: 1)) { ctx in
                        Chip(text: "🔥 ×\(Int(game.s.boostFactor)) · \(Fmt.duration(until.timeIntervalSince(ctx.date)))")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
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
        case .managers:
            return GameData.businesses.contains { d in
                s.lines[d.id].owned > 0 && !s.lines[d.id].hasManager && s.money >= d.managerCost
            }
        case .upgrades:
            return GameData.upgrades.contains { u in
                guard !s.purchased.contains(u.id), s.money >= u.cost else { return false }
                if case .business(let b) = u.target { return s.lines[b].owned > 0 }
                return true
            }
        case .branches:
            return s.starsToGain >= max(1, s.claimedStars)
        default:
            return false
        }
    }
}
