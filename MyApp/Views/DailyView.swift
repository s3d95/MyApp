import SwiftUI

struct DailyView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "اليومي",
                             subtitle: "ارجع كل يوم: مكافأة، مهام جديدة، لفّة ببلاش وطلبيات سريعة.")
                LoginCard()
                MissionsCard()
                WheelCard()
                RushCard()
                GoldShopCard()
            }
            .padding(16)
        }
    }
}

/// Live countdown text to a date.
struct Countdown: View {
    let to: Date
    var prefix: String = ""

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { ctx in
            Text(prefix + Fmt.duration(max(0, to.timeIntervalSince(ctx.date))))
                .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(Theme.muted)
        }
    }
}

// MARK: - Login streak

struct LoginCard: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        let today = game.today
        let pending = s.loginPending(today: today)
        let index = s.loginTrackIndex(today: today)
        let streak = s.loginDay >= today - 1 ? s.loginStreak : 0
        let nextIndex = pending ? index : (index + 1) % 7

        VStack(alignment: .leading, spacing: 10) {
            CardTitle(icon: "🔥", title: "سلسلة الأيام", trailing: "\(streak) يوم")
            LoginTrack(current: index, claimedThrough: pending ? index - 1 : index)
            if pending {
                ActionButton(title: "🎁 استلم مكافأة اليوم", tint: Color(hex: 0xEA580C)) {
                    game.claimLogin()
                }
            } else {
                HStack {
                    Text("بكرة: \(Catalog.loginTrack[nextIndex].text)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Countdown(to: DayClock.nextMidnight(after: Date()))
                }
            }
            Text("إذا غبت يوم، السلسلة بترجع من الأول.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted.opacity(0.8))
        }
        .card()
    }
}

// MARK: - Missions

struct MissionsCard: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CardTitle(icon: "📋", title: "مهام اليوم")
                Countdown(to: DayClock.nextMidnight(after: Date()), prefix: "جديدة بعد ")
            }
            ForEach(s.missions) { m in
                MissionRow(mission: m)
            }
            bonusRow(s)
        }
        .card()
    }

    private func bonusRow(_ s: GameState) -> some View {
        let claimed = s.missions.filter { $0.claimed }.count
        return HStack(spacing: 10) {
            ChestIcon(kind: .silver, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("خلّص الـ3 مهام")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text("الجائزة: صندوق فضة · \(claimed)/\(s.missions.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
            if s.missionBonusClaimed {
                Text("✅").font(.system(size: 20))
            } else {
                ActionButton(title: "استلم", tint: Color(hex: 0x7C3AED), enabled: s.missionBonusReady) {
                    game.claimMissionBonus()
                }
                .frame(width: 80)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.2)))
    }
}

struct MissionRow: View {
    @EnvironmentObject var game: Game
    let mission: Mission

    var body: some View {
        let value = game.s.daily.value(mission.kind)
        let done = value >= mission.target
        HStack(spacing: 10) {
            Text(mission.kind.icon)
                .font(.system(size: 22))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.07)))
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.text)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    ProgressBar(value: value / max(1, mission.target), tint: done ? Theme.money : Theme.gold, height: 6)
                    Text(progressText(value))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            if mission.claimed {
                Text("✅").font(.system(size: 20)).frame(width: 64)
            } else {
                Button { game.claimMission(mission.id) } label: {
                    Text("🪙 \(mission.reward)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(done ? Color(hex: 0x2A1608) : Theme.muted)
                        .frame(width: 64)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(done ? Theme.lira : Color.white.opacity(0.06)))
                }
                .buttonStyle(PressableStyle())
                .disabled(!done)
            }
        }
    }

    private func progressText(_ v: Double) -> String {
        let shown = min(v, mission.target)
        if mission.kind == .earn { return "\(Fmt.money(shown))/\(Fmt.money(mission.target))" }
        return "\(Int(shown))/\(Int(mission.target))"
    }
}

// MARK: - Wheel & rush entry cards

struct WheelCard: View {
    @EnvironmentObject var game: Game
    @State private var spin = false

    var body: some View {
        let free = game.freeSpinReady
        HStack(spacing: 12) {
            Text("🎡")
                .font(.system(size: 44))
                .rotationEffect(.degrees(spin ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spin = true }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text("دولاب الحظ")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text(free ? "عندك لفّة ببلاش اليوم!" : "اللفّة الجاية ببلاش بكرة، أو بـ \(Game.spinCost) 🪙")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(free ? Theme.money : Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            ActionButton(title: free ? "لفّ" : "افتح", tint: Color(hex: 0x7C3AED)) {
                withAnimation { game.showWheel = true }
            }
            .frame(width: 78)
        }
        .card()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(free ? Theme.gold.opacity(0.6) : Color.clear, lineWidth: 1.5))
    }
}

struct RushCard: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("🥙").font(.system(size: 44))
                VStack(alignment: .leading, spacing: 4) {
                    Text("طلبيات على السريع")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Text("جهّز السندويشات بالترتيب الصح قبل ما يخلص الوقت. كل طلبية = دقيقة من أرباحك!")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 8) {
                Chip(text: "🎟️ \(s.tickets)/\(s.maxTickets)")
                if s.bestRush > 0 { Chip(text: "🏆 أحسن نتيجة \(s.bestRush)") }
                Spacer()
                if let next = s.nextTicketAt {
                    Countdown(to: next, prefix: "🎟️ بعد ")
                }
            }
            HStack(spacing: 8) {
                ActionButton(title: s.tickets > 0 ? "▶️ العب" : "ما في تذاكر",
                             tint: Color(hex: 0xEA580C), enabled: s.tickets > 0) {
                    withAnimation(.spring()) { game.showRush = true }
                }
                GoldButton(title: "تذكرة زيادة", cost: Game.ticketCost, enabled: s.liras >= Game.ticketCost) {
                    game.buyTicket()
                }
                .frame(width: 110)
            }
        }
        .card()
    }
}

// MARK: - Gold shop

struct GoldShopCard: View {
    @EnvironmentObject var game: Game

    var body: some View {
        let s = game.s
        let income = s.incomePerSecond(now: Date())
        VStack(alignment: .leading, spacing: 10) {
            CardTitle(icon: "🪙", title: "دكّان الليرات", trailing: "عندك \(s.liras)")
            Text("الليرات الدهب بتجيك من المكافأة اليومية، المهام، الدولاب، الإنجازات وزباين VIP.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            shopRow(icon: "⚡", title: "كل الأرباح ×2", detail: "لمدة \(Int(Game.megaBoostHours)) ساعات (بتنجمع مع بعض)",
                    cost: Game.megaBoostCost) { game.buyMegaBoost() }
            ForEach(Game.warpOffers.indices, id: \.self) { k in
                let offer = Game.warpOffers[k]
                shopRow(icon: "⏩", title: "قفزة \(Int(offer.hours)) \(offer.hours == 1 ? "ساعة" : "ساعات")",
                        detail: "بتاخد هلّق \(Fmt.money(income * offer.hours * 3600))",
                        cost: offer.cost) { game.buyWarp(hours: offer.hours, cost: offer.cost) }
            }
        }
        .card()
    }

    private func shopRow(icon: String, title: String, detail: String, cost: Int, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.07)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.cream)
                Text(detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            GoldButton(title: "اشتري", cost: cost, enabled: game.s.liras >= cost, action: action)
                .frame(width: 84)
        }
    }
}
