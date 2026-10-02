import SwiftUI

enum BuyMode: CaseIterable {
    case one, ten, hundred, max

    var label: String {
        switch self {
        case .one: return "×1"
        case .ten: return "×10"
        case .hundred: return "×100"
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

final class Game: ObservableObject {
    @Published var s: GameState
    @Published var buyMode: BuyMode = .one
    @Published var vip: VIP?
    @Published var toast: ToastMsg?
    @Published var showOffline = false
    @Published var offlineGain: Double = 0

    private var timer: Timer?
    private var nextVIPAt = Date().addingTimeInterval(Double.random(in: 40...80))
    private var lastSaveAt = Date()
    private static let saveKey = "falafel.save.v1"

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
        let away = now.timeIntervalSince(s.lastSaved)
        let before = s.money
        tick()
        let gained = s.money - before
        if away > 60 && gained > 0 && !s.stallName.isEmpty {
            offlineGain = gained
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
        var st = s
        var earned = 0.0
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
            if st.lines[i].hasManager {
                let n = floor(elapsed / t)
                earned += rev * n
                st.lines[i].cycleStart = start.addingTimeInterval(n * t)
            } else {
                earned += rev
                st.lines[i].cycleStart = nil
            }
            changed = true
        }

        if earned > 0 { st.earn(earned) }
        if let u = st.boostUntil, now >= u {
            st.boostUntil = nil
            st.boostFactor = 1
            changed = true
        }
        if changed { s = st }

        if let v = vip, now >= v.expires {
            withAnimation { vip = nil }
        }
        if vip == nil, now >= nextVIPAt, st.totalOwned >= 5, !showOffline, !st.stallName.isEmpty {
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
        if s.hapticsOn { Feedback.light() }
    }

    func buyCount(_ i: Int) -> Int {
        if s.lines[i].owned == 0 { return 1 }
        switch buyMode {
        case .one: return 1
        case .ten: return 10
        case .hundred: return 100
        case .max: return Swift.max(1, s.maxAffordable(i))
        }
    }

    func buy(_ i: Int) {
        let n = buyCount(i)
        let c = s.cost(i, count: n)
        guard c.isFinite, s.money >= c else { return }
        let wasLocked = s.lines[i].owned == 0
        let before = s.milestoneCount(i)
        s.money = Swift.max(0, s.money - c)
        s.lines[i].owned += n
        if s.lines[i].hasManager && s.lines[i].cycleStart == nil { s.lines[i].cycleStart = Date() }

        let def = GameData.businesses[i]
        if wasLocked {
            showToast(def.emoji, "افتتحت قسم \(def.name)!")
        } else if s.milestoneCount(i) > before {
            showToast("⚡️", "\(def.name) صار أسرع ×2!")
        }
        purchaseFeedback()
    }

    func hire(_ i: Int) {
        let def = GameData.businesses[i]
        guard !s.lines[i].hasManager, s.lines[i].owned > 0, s.money >= def.managerCost else { return }
        s.money -= def.managerCost
        s.lines[i].hasManager = true
        if s.lines[i].cycleStart == nil { s.lines[i].cycleStart = Date() }
        showToast(def.managerEmoji, "\(def.managerName) صار يشتغل عندك!")
        purchaseFeedback()
    }

    func buyUpgrade(_ u: UpgradeDef) {
        guard !s.purchased.contains(u.id), s.money >= u.cost else { return }
        s.money -= u.cost
        s.purchased.insert(u.id)
        showToast(u.icon, u.detail)
        purchaseFeedback()
    }

    func claimVIP() {
        guard vip != nil else { return }
        withAnimation { vip = nil }
        let now = Date()
        let income = s.incomePerSecond(now: now)
        if Bool.random() && income > 0 {
            s.boostUntil = now.addingTimeInterval(30)
            s.boostFactor = 3
            showToast("🔥", "زحمة زباين! الأرباح ×3 لمدة 30 ثانية")
        } else {
            let reward = Swift.max(50, income * 120, s.tapValue(now: now) * 40)
            s.earn(reward)
            showToast("🤵", "زبون VIP دفعلك \(Fmt.money(reward))!")
        }
        if s.hapticsOn { Feedback.success() }
    }

    func prestige() {
        let gain = s.starsToGain
        guard gain >= 1 else { return }
        var n = GameState.fresh()
        n.claimedStars = s.claimedStars + gain
        n.lifetimeEarnings = s.lifetimeEarnings
        n.cityIndex = s.cityIndex + 1
        n.prestigeCount = s.prestigeCount + 1
        n.stallName = s.stallName
        n.totalTaps = s.totalTaps
        n.createdAt = s.createdAt
        n.soundOn = s.soundOn
        n.hapticsOn = s.hapticsOn
        s = n
        vip = nil
        save()
        showToast("🚀", "فتحت فرع جديد في \(s.cityName)!")
        if s.hapticsOn { Feedback.success() }
    }

    func resetAll() {
        s = GameState.fresh()
        vip = nil
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
