import SwiftUI

enum BuyMode: CaseIterable {
    case one, ten, max

    var label: String {
        switch self {
        case .one: return "×1"
        case .ten: return "×10"
        case .max: return "أقصى"
        }
    }
}

struct VIP: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let expires: Date
}

struct ToastMsg: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

/// Money made by the auto clicker, batched so the stall can show a floating label.
struct AutoBurst: Equatable {
    let id: Int
    let amount: Double
}

/// Cards that came out of a chest, shown in the reveal overlay.
struct ChestReveal: Identifiable {
    let id = UUID()
    let kind: ChestKind
    let cards: [Int]
    let newChefs: Set<Int>
}

struct RushReward {
    let cash: Double
    let liras: Int
    let record: Bool
}

final class Game: ObservableObject {
    @Published var s: GameState
    @Published var buyMode: BuyMode = .one
    @Published var vip: VIP?
    @Published var toast: ToastMsg?
    @Published var showOffline = false
    @Published var offlineGain: Double = 0
    @Published var offlineSeconds: Double = 0
    @Published var offlineDoubled = false
    @Published var autoBurst = AutoBurst(id: 0, amount: 0)
    @Published var showLogin = false
    @Published var showWhatsNew = false
    @Published var showWheel = false
    @Published var showRush = false
    @Published var chestReveal: ChestReveal?

    /// Bump to show the "what's new" screen once to returning players.
    static let whatsNewVersion = 2
    static let spinCost = 15
    static let ticketCost = 10
    static let doubleOfflineCost = 15
    static let megaBoostCost = 40
    static let megaBoostHours: Double = 4
    static let warpOffers: [(hours: Double, cost: Int)] = [(1, 20), (6, 100)]

    private var timer: Timer?
    private var lastTick = Date()
    private var lastSlowTick = Date.distantPast
    private var autoCarry = 0.0
    private var autoPending = 0.0
    private var lastBurstAt = Date()
    private var nextVIPAt = Date().addingTimeInterval(Double.random(in: 40...80))
    private var lastSaveAt = Date()
    private var toastQueue: [ToastMsg] = []
    private static let saveKey = "falafel.save.v2"

    var isRunning: Bool { timer != nil }
    var today: Int { DayClock.day(Date()) }

    init() {
        if let data = UserDefaults.standard.data(forKey: Game.saveKey),
           let loaded = try? JSONDecoder().decode(GameState.self, from: data) {
            s = loaded
        } else {
            s = GameState.fresh()
        }
        if !s.stallName.isEmpty && s.whatsNewSeen < Game.whatsNewVersion { showWhatsNew = true }
        resume()
    }

    // MARK: - Lifecycle

    func resume() {
        let now = Date()
        let away = Swift.max(0, now.timeIntervalSince(s.lastSaved))
        let cap = s.offlineHours * 3600

        // Managers keep selling while the game is closed, up to the offline limit.
        let cutoff = now.addingTimeInterval(-cap)
        for i in s.lines.indices where s.lines[i].hasManager {
            if let start = s.lines[i].cycleStart, start < cutoff { s.lines[i].cycleStart = cutoff }
        }

        // Offline income shouldn't finish today's "earn" mission on its own.
        // Roll the day first so yesterday's counter isn't carried into today.
        rollDay(now)
        let earnedToday = s.daily.earned
        let before = s.money
        lastTick = now
        tick()
        var gained = s.money - before
        if away > 60 && gained > 0 && s.offlineMultiplier > 1 {
            let extra = gained * (s.offlineMultiplier - 1)
            s.earn(extra)
            gained += extra
        }
        s.daily.earned = earnedToday
        if away > 60 && gained > 0 && !s.stallName.isEmpty {
            offlineGain = gained
            offlineSeconds = Swift.min(away, cap)
            offlineDoubled = false
            showOffline = true
        }
        s.lastSaved = now
        rollDay(now)
        s.refillTickets(now: now)
        if !s.stallName.isEmpty && s.loginPending(today: DayClock.day(now)) { showLogin = true }
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        save()
        Notifier.schedule(for: s, now: Date())
    }

    func save() {
        s.lastSaved = Date()
        lastSaveAt = Date()
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: Game.saveKey)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - Loop

    func tick() {
        let now = Date()
        let dt = Swift.min(Swift.max(0, now.timeIntervalSince(lastTick)), 0.5)
        lastTick = now

        var st = s
        var earned = 0.0
        var sold = 0.0
        var changed = false

        for i in st.lines.indices where st.lines[i].owned > 0 {
            guard let start = st.lines[i].cycleStart else {
                if st.lines[i].hasManager {
                    st.lines[i].cycleStart = now
                    changed = true
                }
                continue
            }
            let t = st.cycleTime(i)
            let elapsed = now.timeIntervalSince(start)
            guard elapsed >= t else { continue }
            let rev = st.revenuePerCycle(i, now: now)
            let cycles: Double
            if st.lines[i].hasManager {
                cycles = floor(elapsed / t)
                st.lines[i].cycleStart = start.addingTimeInterval(cycles * t)
            } else {
                cycles = 1
                st.lines[i].cycleStart = nil
            }
            earned += rev * cycles
            sold += Double(st.lines[i].owned) * cycles
            changed = true
        }

        if st.autoLevel > 0 && dt > 0 {
            autoCarry += st.autoRate * dt
            let taps = floor(autoCarry)
            if taps > 0 {
                autoCarry -= taps
                let v = taps * st.tapValue(now: now)
                earned += v
                autoPending += v
                changed = true
            }
        }

        if earned > 0 { st.earn(earned) }
        if sold > 0 { st.totalSold += sold }
        if let u = st.boostUntil, now >= u {
            st.boostUntil = nil
            st.boostFactor = 1
            changed = true
        }
        if let u = st.megaBoostUntil, now >= u {
            st.megaBoostUntil = nil
            changed = true
        }
        if changed { s = st }

        if autoPending > 0 && now.timeIntervalSince(lastBurstAt) >= 0.45 {
            autoBurst = AutoBurst(id: autoBurst.id + 1, amount: autoPending)
            autoPending = 0
            lastBurstAt = now
        }

        if let v = vip, now >= v.expires {
            withAnimation { vip = nil }
        }
        if vip == nil, now >= nextVIPAt, st.totalSellers >= 5, !showOffline, !showLogin, !showRush, !showWhatsNew, !st.stallName.isEmpty {
            withAnimation(.spring()) {
                vip = VIP(x: CGFloat.random(in: 0.18...0.82),
                          y: CGFloat.random(in: 0.3...0.72),
                          expires: now.addingTimeInterval(12))
            }
            nextVIPAt = now.addingTimeInterval(Double.random(in: 70...160) * st.vipIntervalFactor)
        }

        if now.timeIntervalSince(lastSlowTick) >= 1 {
            lastSlowTick = now
            slowTick(now)
        }

        if now.timeIntervalSince(lastSaveAt) > 5 { save() }
    }

    /// Once-a-second housekeeping: new day, tickets, achievements.
    private func slowTick(_ now: Date) {
        rollDay(now)
        let tickets = s.tickets
        var st = s
        st.refillTickets(now: now)
        if st.tickets != tickets || st.ticketStamp != s.ticketStamp { s = st }
        checkAchievements()
    }

    private func rollDay(_ now: Date) {
        let day = DayClock.day(now)
        guard s.counterDay != day else { return }
        let firstEver = s.counterDay == 0
        s.counterDay = day
        s.daily = DailyCounters()
        s.missions = Catalog.makeMissions(income: s.incomePerSecond(now: now))
        s.missionBonusClaimed = false
        let open = s.lines.indices.filter { s.lines[$0].owned > 0 }
        s.dishIndex = open.randomElement() ?? 0
        if !firstEver && !s.stallName.isEmpty && s.loginPending(today: day) && !showLogin {
            showLogin = true
        }
    }

    private func checkAchievements() {
        var unlocked: [AchievementDef] = []
        for a in Catalog.achievements where !s.achievements.contains(a.id) && a.check(s) {
            unlocked.append(a)
        }
        guard !unlocked.isEmpty else { return }
        var st = s
        var total = 0
        for a in unlocked {
            st.achievements.insert(a.id)
            total += a.reward
        }
        st.addLiras(total)
        s = st
        if unlocked.count > 2 {
            showToast("🏅", "فتحت \(unlocked.count) إنجازات! +\(total) 🪙")
        } else {
            for a in unlocked { showToast("🏅", "إنجاز: \(a.title) · +\(a.reward) 🪙") }
        }
        if s.hapticsOn { Feedback.success() }
    }

    // MARK: - Stall actions

    @discardableResult
    func tapFalafel() -> Double {
        let v = s.tapValue(now: Date())
        s.earn(v)
        s.totalTaps += 1
        s.daily.taps += 1
        if s.hapticsOn { Feedback.light() }
        return v
    }

    func startLine(_ i: Int) {
        guard s.lines[i].owned > 0, !s.lines[i].hasManager, s.lines[i].cycleStart == nil else { return }
        s.lines[i].cycleStart = Date()
    }

    func buyCount(_ i: Int) -> Int {
        let remaining = s.remainingSellers(i)
        guard remaining > 0 else { return 0 }
        switch buyMode {
        case .one: return 1
        case .ten: return Swift.min(10, remaining)
        case .max: return Swift.max(1, s.maxAffordableSellers(i))
        }
    }

    /// What the main buy button of a section costs right now.
    func buyPrice(_ i: Int) -> Double {
        if s.lines[i].owned == 0 { return GameData.businesses[i].unlockCost }
        return s.sellerCost(i, count: buyCount(i))
    }

    func buy(_ i: Int) {
        let def = GameData.businesses[i]
        if s.lines[i].owned == 0 {
            guard s.money >= def.unlockCost else { return }
            s.money -= def.unlockCost
            s.lines[i].owned = 1
            showToast(def.emoji, "افتتحت قسم \(def.name)!")
            purchaseFeedback()
            return
        }

        let n = buyCount(i)
        guard n > 0 else { return }
        let c = s.sellerCost(i, count: n)
        guard c.isFinite, s.money >= c else { return }
        let speedBefore = s.milestoneCount(i)
        let profitBefore = s.profitMilestones(i)
        let allBefore = s.allSectionsLevel
        var st = s
        st.money = Swift.max(0, st.money - c)
        st.lines[i].owned += n
        st.sellersHired += n
        st.daily.sellers += Double(n)
        if st.lines[i].hasManager && st.lines[i].cycleStart == nil { st.lines[i].cycleStart = Date() }
        s = st

        if s.allSectionsLevel > allBefore {
            showToast("🏆", "كل الأقسام وصلت \(s.minOwned) بيّاع! كل الأرباح ×2")
            if s.hapticsOn { Feedback.success() }
        } else if s.profitMilestones(i) > profitBefore {
            showToast("💥", "قسم \(def.name) وصل \(s.profitMilestones(i) * GameData.profitStep) بيّاع: أرباحه ×2!")
        } else if s.milestoneCount(i) > speedBefore {
            showToast("⚡️", "قسم \(def.name) صار أسرع +25%!")
        }
        purchaseFeedback()
    }

    func hire(_ i: Int) {
        let def = GameData.businesses[i]
        guard !s.lines[i].hasManager, s.lines[i].owned > 0, s.money >= def.managerCost else { return }
        s.money -= def.managerCost
        s.lines[i].hasManager = true
        if s.lines[i].cycleStart == nil { s.lines[i].cycleStart = Date() }
        showToast(def.managerEmoji, "\(def.managerName) صار مدير قسم \(def.name)!")
        purchaseFeedback()
    }

    func buyUpgrade(_ u: UpgradeDef) {
        guard !s.purchased.contains(u.id), s.money >= u.cost else { return }
        s.money -= u.cost
        s.purchased.insert(u.id)
        showToast(u.icon, u.detail)
        purchaseFeedback()
    }

    func upgradeTap() {
        guard let c = s.nextTapCost, s.money >= c else { return }
        s.money -= c
        s.tapLevel += 1
        showToast("✋", "قوة الضغطة صارت مستوى \(s.tapLevel)")
        purchaseFeedback()
    }

    func upgradeAuto() {
        guard let c = s.nextAutoCost, s.money >= c else { return }
        s.money -= c
        s.autoLevel += 1
        showToast("🤖", "الأوتو كليكر صار \(s.autoLevel) ضغطة بالثانية")
        purchaseFeedback()
    }

    func upgradeShare() {
        guard let c = s.nextShareCost, s.money >= c else { return }
        s.money -= c
        s.shareLevel += 1
        showToast("✨", "كل ضغطة صارت تجيب \(Fmt.percent(s.shareRate)) من دخلك بالثانية")
        purchaseFeedback()
    }

    func buyBranch() {
        guard let b = s.nextBranch, s.money >= b.cost else { return }
        s.money -= b.cost
        s.branchesOwned += 1
        showToast("🏙️", "فتحت فرع في \(b.city)! كل الأرباح +\(Int((b.bonus * 100).rounded()))%")
        if s.hapticsOn { Feedback.success() }
        if s.soundOn { Feedback.click() }
    }

    func claimVIP() {
        guard vip != nil else { return }
        withAnimation { vip = nil }
        let now = Date()
        let income = s.incomePerSecond(now: now)
        s.vipsClaimed += 1
        s.daily.vips += 1
        let roll = Double.random(in: 0..<1)
        if roll < 0.33 && income > 0 {
            s.boostUntil = now.addingTimeInterval(30)
            s.boostFactor = 2
            showToast("🔥", "زحمة زباين! الأرباح ×2 لمدة 30 ثانية")
        } else if roll < 0.40 && income > 0 {
            s.boostUntil = now.addingTimeInterval(12)
            s.boostFactor = 7
            showToast("🤯", "جنون! الأرباح ×7 لمدة 12 ثانية — اضغط بسرعة!")
        } else if roll < 0.52 {
            let n = Int.random(in: 2...6)
            s.addLiras(n)
            showToast("🪙", "زبون VIP عطاك بقشيش \(n) ليرات دهب!")
        } else if roll < 0.56 {
            s.chests[ChestKind.wood.rawValue] += 1
            showToast("📦", "زبون VIP هداك صندوق خشب!")
        } else {
            let reward = Swift.max(50, income * 45 * s.vipRewardMultiplier).rounded()
            s.earn(reward)
            showToast("🤵", "زبون VIP طلب طلبية بـ \(Fmt.money(reward))!")
        }
        if s.hapticsOn { Feedback.success() }
    }

    // MARK: - Prestige

    func prestige() {
        let gain = s.pendingStars
        guard gain >= 1 else { return }
        s.prestige()
        vip = nil
        autoCarry = 0
        autoPending = 0
        showToast("⭐", "إعادة افتتاح! +\(Fmt.number(gain)) نجمة · أرباحك ×\(Fmt.multiplier(s.starMultiplier))")
        if s.hapticsOn { Feedback.success() }
        save()
    }

    // MARK: - Daily login

    func claimLogin() {
        let day = today
        guard s.loginPending(today: day) else {
            withAnimation { showLogin = false }
            return
        }
        s.loginStreak = s.loginDay == day - 1 ? s.loginStreak + 1 : 1
        s.loginDay = day
        s.bestStreak = Swift.max(s.bestStreak, s.loginStreak)
        let reward = Catalog.loginTrack[(s.loginStreak - 1) % 7]
        grant(liras: reward.liras, chest: reward.chest, boostMinutes: reward.boostMinutes)
        withAnimation { showLogin = false }
        showToast(reward.icon, "مكافأة اليوم \(s.loginStreak): \(reward.text)")
        if s.hapticsOn { Feedback.success() }
        askNotificationsOnce()
    }

    private func grant(liras: Int, chest: ChestKind?, boostMinutes: Int) {
        s.addLiras(liras)
        if let c = chest { s.chests[c.rawValue] += 1 }
        if boostMinutes > 0 { addMegaBoost(minutes: Double(boostMinutes)) }
    }

    private func addMegaBoost(minutes: Double) {
        let now = Date()
        var base = now
        if let u = s.megaBoostUntil, u > now { base = u }
        s.megaBoostUntil = base.addingTimeInterval(minutes * 60)
    }

    // MARK: - Missions

    func claimMission(_ id: Int) {
        guard let k = s.missions.firstIndex(where: { $0.id == id }) else { return }
        let m = s.missions[k]
        guard !m.claimed, s.missionDone(m) else { return }
        s.missions[k].claimed = true
        s.missionsDone += 1
        s.addLiras(m.reward)
        showToast("✅", "خلّصت المهمة! +\(m.reward) 🪙")
        purchaseFeedback()
    }

    func claimMissionBonus() {
        guard s.missionBonusReady else { return }
        s.missionBonusClaimed = true
        s.chests[ChestKind.silver.rawValue] += 1
        showToast("🎁", "خلّصت كل مهام اليوم! ربحت صندوق فضة")
        if s.hapticsOn { Feedback.success() }
    }

    // MARK: - Lucky wheel

    var freeSpinReady: Bool { s.freeSpinReady(today: today) }

    /// Picks and grants a prize. Returns nil when there's no free spin and not enough liras.
    func spinWheel() -> (prize: WheelPrize, text: String)? {
        let day = today
        if s.freeSpinReady(today: day) {
            s.freeSpinDay = day
        } else {
            guard s.liras >= Game.spinCost else { return nil }
            s.liras -= Game.spinCost
        }
        s.daily.spins += 1
        let all = WheelPrize.allCases
        let prize = all[Pick.weighted(all.map { $0.weight })]
        let income = s.incomePerSecond(now: Date())
        let text: String
        switch prize {
        case .cashSmall:
            let v = Swift.max(200, income * 600).rounded()
            s.earn(v)
            text = "ربحت \(Fmt.money(v))"
        case .cashBig:
            let v = Swift.max(1_000, income * 3_600).rounded()
            s.earn(v)
            text = "ربحت \(Fmt.money(v))"
        case .liraSmall:
            s.addLiras(5)
            text = "ربحت 5 ليرات دهب"
        case .liraMid:
            s.addLiras(15)
            text = "ربحت 15 ليرة دهب"
        case .jackpot:
            s.addLiras(50)
            text = "الجائزة الكبرى! 50 ليرة دهب"
        case .woodChest:
            s.chests[ChestKind.wood.rawValue] += 1
            text = "ربحت صندوق خشب"
        case .silverChest:
            s.chests[ChestKind.silver.rawValue] += 1
            text = "ربحت صندوق فضة"
        case .boost:
            addMegaBoost(minutes: 30)
            text = "الأرباح ×2 لمدة نص ساعة"
        }
        save()
        return (prize, text)
    }

    // MARK: - Chests & chefs

    func buyChest(_ kind: ChestKind) {
        guard s.liras >= kind.price else { return }
        s.liras -= kind.price
        s.chests[kind.rawValue] += 1
        purchaseFeedback()
    }

    func openChest(_ kind: ChestKind) {
        guard s.chests[kind.rawValue] > 0 else { return }
        var st = s
        st.chests[kind.rawValue] -= 1
        st.chestsOpened += 1
        var cards: [Int] = []
        let special = Int.random(in: 0..<kind.cards)
        for slot in 0..<kind.cards {
            var r = Rarity(rawValue: Pick.weighted(kind.weights)) ?? .common
            if slot == special && r.rawValue < kind.guaranteed.rawValue { r = kind.guaranteed }
            if let chef = Catalog.chefs(of: r).randomElement() { cards.append(chef.id) }
        }
        var fresh = Set<Int>()
        for c in cards {
            if st.chefLevel[c] == 0 {
                st.chefLevel[c] = 1
                fresh.insert(c)
            } else {
                st.chefCards[c] += 1
            }
        }
        s = st
        save()
        withAnimation(.spring()) { chestReveal = ChestReveal(kind: kind, cards: cards, newChefs: fresh) }
        if s.hapticsOn { Feedback.success() }
    }

    func upgradeChef(_ id: Int) {
        guard let need = s.chefCardsNeeded(id), s.chefCards[id] >= need else { return }
        s.chefCards[id] -= need
        s.chefLevel[id] += 1
        let c = Catalog.chefs[id]
        showToast(c.emoji, "\(c.name) صار مستوى \(s.chefLevel[id]): \(Catalog.perkText(c, level: s.chefLevel[id]))")
        if s.hapticsOn { Feedback.success() }
    }

    // MARK: - Research & gold shop

    func buyResearch(_ id: Int) {
        guard let c = s.researchCost(id), s.liras >= c else { return }
        s.liras -= c
        s.research[id] += 1
        if id == Catalog.rTickets { s.tickets += 1 }
        let r = Catalog.research[id]
        showToast(r.icon, Catalog.researchText(id, level: s.research[id]))
        purchaseFeedback()
    }

    func buyMegaBoost() {
        guard s.liras >= Game.megaBoostCost else { return }
        s.liras -= Game.megaBoostCost
        addMegaBoost(minutes: Game.megaBoostHours * 60)
        showToast("⚡", "كل الأرباح ×2 لمدة \(Int(Game.megaBoostHours)) ساعات!")
        purchaseFeedback()
    }

    func buyWarp(hours: Double, cost: Int) {
        guard s.liras >= cost else { return }
        let v = (s.incomePerSecond(now: Date()) * hours * 3600).rounded()
        guard v > 0 else {
            showToast("🤔", "وظّف مدير أول عشان يكون في دخل")
            return
        }
        s.liras -= cost
        s.earn(v)
        showToast("⏩", "قفزت \(Int(hours)) ساعة لقدّام: +\(Fmt.money(v))")
        purchaseFeedback()
    }

    func buyTicket() {
        guard s.liras >= Game.ticketCost else { return }
        s.liras -= Game.ticketCost
        s.tickets += 1
        purchaseFeedback()
    }

    func doubleOffline() {
        guard !offlineDoubled, s.liras >= Game.doubleOfflineCost else { return }
        s.liras -= Game.doubleOfflineCost
        s.earn(offlineGain)
        offlineGain *= 2
        offlineDoubled = true
        if s.hapticsOn { Feedback.success() }
    }

    // MARK: - Rush mini-game

    func useTicket() -> Bool {
        s.refillTickets(now: Date())
        guard s.tickets > 0 else { return false }
        s.tickets -= 1
        if s.tickets == s.maxTickets - 1 { s.ticketStamp = Date() }
        return true
    }

    func finishRush(orders: Int, perfect: Bool) -> RushReward {
        let income = s.incomePerSecond(now: Date())
        let perOrder = Swift.max(100, income * 60)
        let cash = (perOrder * Double(orders) * (perfect && orders > 0 ? 1.5 : 1)).rounded()
        var liras = orders / 3
        let record = orders > s.bestRush && orders > 0
        if record && s.bestRush > 0 { liras += 5 }
        s.bestRush = Swift.max(s.bestRush, orders)
        s.rushPlays += 1
        s.daily.rushPlays += 1
        s.daily.rushBest = Swift.max(s.daily.rushBest, Double(orders))
        s.earn(cash)
        s.addLiras(liras)
        save()
        return RushReward(cash: cash, liras: liras, record: record)
    }

    // MARK: - Misc

    func resetAll() {
        s = GameState.fresh()
        vip = nil
        autoCarry = 0
        autoPending = 0
        save()
    }

    func rename(_ name: String) {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let first = s.stallName.isEmpty
        s.stallName = String(t.prefix(24))
        if first { s.whatsNewSeen = Game.whatsNewVersion }
        save()
        if first && s.loginPending(today: today) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                withAnimation { self?.showLogin = true }
            }
        }
    }

    func closeWhatsNew() {
        s.whatsNewSeen = Game.whatsNewVersion
        withAnimation { showWhatsNew = false }
        save()
    }

    func setNotifications(_ on: Bool) {
        s.notificationsOn = on
        if on { Notifier.request() }
    }

    private func askNotificationsOnce() {
        guard !s.notificationsAsked else { return }
        s.notificationsAsked = true
        Notifier.request()
    }

    func showToast(_ icon: String, _ text: String) {
        toastQueue.append(ToastMsg(icon: icon, text: text))
        if toastQueue.count > 3 { toastQueue.removeFirst(toastQueue.count - 3) }
        if toast == nil { showNextToast() }
    }

    private func showNextToast() {
        guard !toastQueue.isEmpty else { return }
        let t = toastQueue.removeFirst()
        withAnimation(.spring()) { toast = t }
        let hold = toastQueue.isEmpty ? 2.4 : 1.6
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [weak self] in
            guard let self = self, self.toast?.id == t.id else { return }
            withAnimation(.easeOut) { self.toast = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.showNextToast() }
        }
    }

    private func purchaseFeedback() {
        if s.hapticsOn { Feedback.medium() }
        if s.soundOn { Feedback.click() }
    }
}
