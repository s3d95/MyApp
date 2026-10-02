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

final class Game: ObservableObject {
    @Published var s: GameState
    @Published var buyMode: BuyMode = .one
    @Published var vip: VIP?
    @Published var toast: ToastMsg?
    @Published var showOffline = false
    @Published var offlineGain: Double = 0
    @Published var offlineSeconds: Double = 0
    @Published var autoBurst = AutoBurst(id: 0, amount: 0)

    private var timer: Timer?
    private var lastTick = Date()
    private var autoCarry = 0.0
    private var autoPending = 0.0
    private var lastBurstAt = Date()
    private var nextVIPAt = Date().addingTimeInterval(Double.random(in: 40...80))
    private var lastSaveAt = Date()
    private static let saveKey = "falafel.save.v2"

    var isRunning: Bool { timer != nil }

    init() {
        if let data = UserDefaults.standard.data(forKey: Game.saveKey),
           let loaded = try? JSONDecoder().decode(GameState.self, from: data) {
            s = loaded
        } else {
            s = GameState.fresh()
        }
        resume()
    }

    // MARK: - Lifecycle

    func resume() {
        let now = Date()
        let away = Swift.max(0, now.timeIntervalSince(s.lastSaved))

        // Managers keep selling while the game is closed, up to the offline limit.
        let cutoff = now.addingTimeInterval(-GameData.maxOfflineSeconds)
        for i in s.lines.indices where s.lines[i].hasManager {
            if let start = s.lines[i].cycleStart, start < cutoff { s.lines[i].cycleStart = cutoff }
        }

        let before = s.money
        lastTick = now
        tick()
        let gained = s.money - before
        if away > 60 && gained > 0 && !s.stallName.isEmpty {
            offlineGain = gained
            offlineSeconds = Swift.min(away, GameData.maxOfflineSeconds)
            showOffline = true
        }
        s.lastSaved = now
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        save()
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
        if changed { s = st }

        if autoPending > 0 && now.timeIntervalSince(lastBurstAt) >= 0.45 {
            autoBurst = AutoBurst(id: autoBurst.id + 1, amount: autoPending)
            autoPending = 0
            lastBurstAt = now
        }

        if let v = vip, now >= v.expires {
            withAnimation { vip = nil }
        }
        if vip == nil, now >= nextVIPAt, st.totalSellers >= 5, !showOffline, !st.stallName.isEmpty {
            withAnimation(.spring()) {
                vip = VIP(x: CGFloat.random(in: 0.18...0.82),
                          y: CGFloat.random(in: 0.3...0.72),
                          expires: now.addingTimeInterval(12))
            }
            nextVIPAt = now.addingTimeInterval(Double.random(in: 70...160))
        }

        if now.timeIntervalSince(lastSaveAt) > 5 { save() }
    }

    // MARK: - Actions

    @discardableResult
    func tapFalafel() -> Double {
        let v = s.tapValue(now: Date())
        s.earn(v)
        s.totalTaps += 1
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
        let before = s.milestoneCount(i)
        s.money = Swift.max(0, s.money - c)
        s.lines[i].owned += n
        if s.lines[i].hasManager && s.lines[i].cycleStart == nil { s.lines[i].cycleStart = Date() }

        if s.lines[i].owned >= GameData.maxSellers {
            showToast("🏆", "قسم \(def.name) وصل الحد الأقصى!")
        } else if s.milestoneCount(i) > before {
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
        showToast("✋", "كل ضغطة صارت بـ \(Fmt.money(Double(1 + s.tapLevel)))")
        purchaseFeedback()
    }

    func upgradeAuto() {
        guard let c = s.nextAutoCost, s.money >= c else { return }
        s.money -= c
        s.autoLevel += 1
        showToast("🤖", "الأوتو كليكر صار \(s.autoLevel) ضغطة بالثانية")
        purchaseFeedback()
    }

    func buyBranch() {
        guard let b = s.nextBranch, s.money >= b.cost else { return }
        s.money -= b.cost
        s.branchesOwned += 1
        showToast("🏙️", "فتحت فرع في \(b.city)! كل الأرباح +10%")
        if s.hapticsOn { Feedback.success() }
        if s.soundOn { Feedback.click() }
    }

    func claimVIP() {
        guard vip != nil else { return }
        withAnimation { vip = nil }
        let now = Date()
        let income = s.incomePerSecond(now: now)
        if Bool.random() && income > 0 {
            s.boostUntil = now.addingTimeInterval(30)
            s.boostFactor = 2
            showToast("🔥", "زحمة زباين! الأرباح ×2 لمدة 30 ثانية")
        } else {
            let reward = Swift.max(50, income * 45).rounded()
            s.earn(reward)
            showToast("🤵", "زبون VIP طلب طلبية بـ \(Fmt.money(reward))!")
        }
        if s.hapticsOn { Feedback.success() }
    }

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
        s.stallName = String(t.prefix(24))
        save()
    }

    func showToast(_ icon: String, _ text: String) {
        let t = ToastMsg(icon: icon, text: text)
        withAnimation(.spring()) { toast = t }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self = self, self.toast?.id == t.id else { return }
            withAnimation(.easeOut) { self.toast = nil }
        }
    }

    private func purchaseFeedback() {
        if s.hapticsOn { Feedback.medium() }
        if s.soundOn { Feedback.click() }
    }
}
