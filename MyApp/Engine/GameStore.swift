import Foundation
import SwiftUI
import UIKit

enum GameTab: Int, CaseIterable {
    case map, tasks, home, chefs, shop

    var title: String {
        switch self {
        case .map: return "الخريطة"
        case .tasks: return "المهام"
        case .home: return "البسطة"
        case .chefs: return "الطبّاخين"
        case .shop: return "الدكان"
        }
    }

    var symbol: String {
        switch self {
        case .map: return "map.fill"
        case .tasks: return "checklist"
        case .home: return "flame.fill"
        case .chefs: return "person.3.fill"
        case .shop: return "bag.fill"
        }
    }

    /// The level system that opens this tab.
    var system: String {
        switch self {
        case .map: return "map"
        case .tasks: return "daily"
        case .home: return "kitchen"
        case .chefs: return "chefs"
        case .shop: return "shop"
        }
    }
}

enum BuyMode: Int {
    case x1, x10, next, max

    var label: String {
        switch self {
        case .x1: return "×1"
        case .x10: return "×10"
        case .next: return "التالي"
        case .max: return "أقصى"
        }
    }

    var following: BuyMode {
        switch self {
        case .x1: return .x10
        case .x10: return .next
        case .next: return .max
        case .max: return .x1
        }
    }
}

enum Sheet: Identifiable, Equatable {
    case upgrades, goals, profile, settings, branch(String), teaser(GameTab), twist, chef(String), chefPicker
    case research, supply, rushIntro, league, contracts
    case side(SideRef)

    var id: String {
        switch self {
        case .upgrades: return "upgrades"
        case .goals: return "goals"
        case .profile: return "profile"
        case .settings: return "settings"
        case .branch(let c): return "branch." + c
        case .teaser(let t): return "teaser.\(t.rawValue)"
        case .twist: return "twist"
        case .chef(let c): return "chef." + c
        case .chefPicker: return "chefPicker"
        case .research: return "research"
        case .supply: return "supply"
        case .rushIntro: return "rushIntro"
        case .league: return "league"
        case .contracts: return "contracts"
        case .side(let r):
            switch r {
            case .contract(let id): return "side.c." + id
            case .event: return "side.event"
            }
        }
    }
}

struct RewardLine: Identifiable {
    let id = UUID()
    let art: String
    let amount: String
    let caption: String
}

struct LevelUpInfo {
    var from: Int
    var to: Int
    var rewards: [RewardLine]
    var unlocks: [String]
    var title: String?
}

struct NewsInfo {
    var away: Double
    var vault: Double
    var cityName: String
    var currency: String
    var doubleCost: Int
    var canDouble: Bool
    var lines: [String]
    var freshDoughMin: Int
}

enum Modal: Identifiable {
    case newspaper(NewsInfo)
    case levelUp(LevelUpInfo)
    case unlock(String)
    case story(scene: String, city: String)
    case address
    case legacy
    case graduateConfirm
    case graduation(from: String, to: String)
    case chest(ChestResult)
    case inspector(score: Double, lines: [RewardLine], checks: [String])
    case supply(SupplyResult)
    case rewards(title: String, lines: [RewardLine])
    case choice(String)
    case rush(practice: Bool)

    var id: String {
        switch self {
        case .newspaper: return "news"
        case .levelUp(let i): return "level.\(i.to)"
        case .unlock(let s): return "unlock." + s
        case .story(let s, _): return "story." + s
        case .address: return "address"
        case .legacy: return "legacy"
        case .graduateConfirm: return "gradConfirm"
        case .graduation(let a, let b): return "grad." + a + b
        case .chest(let r): return "chest." + r.id.uuidString
        case .inspector: return "inspector"
        case .supply(let r): return "supply." + r.id.uuidString
        case .rewards(let title, _): return "rewards." + title
        case .choice(let id): return "choice." + id
        case .rush(let p): return p ? "rush.practice" : "rush"
        }
    }
}

enum SpecialOutcome: String {
    case tip, frenzy, critic, bus
}

struct SpecialVisit: Identifiable {
    let id = UUID()
    let art: String
    let outcome: SpecialOutcome
    let vipTier: Int
    let spawnedAt: Double
    var lifetime: Double = 15
}

struct OvenTray {
    var station: Int
    var payout: Double
    var deadline: Double
    var window: Double
}

struct Toast: Identifiable {
    let id = UUID()
    let text: String
    var art: String? = nil
}

/// Single source of truth for the v3 game. Rules live in the `Store+*.swift` extensions.
final class GameStore: ObservableObject {
    let cat: Catalog

    @Published var s: GameSave
    @Published var tab: GameTab = .home
    @Published var sheet: Sheet? = nil
    @Published var modals: [Modal] = []
    @Published var special: SpecialVisit? = nil
    @Published var toast: Toast? = nil
    @Published var buyMode: BuyMode = .x1
    @Published var oven: OvenTray? = nil

    // Transient session state
    var cityCache: CityDef?
    var systemLevels: [String: Int] = [:]
    var anchorWall: Double = 0
    var anchorUptime: Double = 0
    var lastTickUptime: Double = 0
    var isForeground = true
    var saveClock: Double = 0
    var slowClock: Double = 0
    var awayGapThisLaunch: Double = 0
    var specialTappedFlag = false
    var vaultCollectedFlag = false
    var readyGoals: Set<String> = []
    var pendingLevelUp: LevelUpInfo? = nil
    var timer: Timer?
    var toastClock: Double = 0
    var lastCycleFeedback: [Int: Double] = [:]
    var newsAwayGap: Double = 0
    var chainSigma: [Double] = []
    var marketCacheDay = -1
    var marketCache: [MarketModDef] = []
    var festCacheDay = -1
    var festCache: [FestivalDef] = []
    var deliveryPaidFeedback: Double = 0

    init() {
        let catalog = Catalog.load()
        cat = catalog
        var save = GameStore.isDemo ? GameSave() : (GameSave.load() ?? GameSave())
        let fresh = save.meta.createdAt == 0
        if fresh {
            save.meta.playerSeed = String(UInt64.random(in: 1...UInt64.max))
            save.meta.createdAt = Date().timeIntervalSince1970
        }
        s = save
        for row in catalog.levels.levels {
            for u in row.unlocks where u.type == "system" {
                if let id = u.id, systemLevels[id] == nil { systemLevels[id] = row.level }
            }
        }
        if fresh || s.city.stations.isEmpty || cat.city(s.city.cityId) == nil {
            openCity(cat.cities.first?.id ?? "jerusalem", at: Date().timeIntervalSince1970, firstEver: fresh)
        }
        cityCache = cat.city(s.city.cityId)
        normalizeCity()
        applySettings()
        if !GameStore.isDemo { checkLegacy() }
        migratePendingRewards()
        resume(launch: true)
        start()
        if let d = GameStore.demoName { applyDemo(d) }
    }

    deinit { timer?.invalidate() }

    // MARK: - Basics

    var city: CityDef {
        if let c = cityCache, c.id == s.city.cityId { return c }
        let c = cat.city(s.city.cityId) ?? cat.cities[0]
        cityCache = c
        return c
    }

    var form: AddressForm { s.settings.address }

    func t(_ g: GText) -> String { g.s(form) }

    func mf(_ m: String, _ f: String) -> String { form == .f ? f : m }

    var level: Int { s.empire.level }

    func unlocked(_ system: String) -> Bool { level >= (systemLevels[system] ?? 1) }

    func unlockLevel(_ system: String) -> Int { systemLevels[system] ?? 1 }

    var currencyName: String { t(city.currency.name) }

    var currentModal: Modal? { modals.first }

    var kitchenVisible: Bool { tab == .home && sheet == nil && modals.isEmpty && isForeground }

    func now() -> Double {
        if anchorUptime == 0 { return Date().timeIntervalSince1970 }
        return anchorWall + (Clock.uptime() - anchorUptime)
    }

    var gameDay: Int { Clock.gameDay(now()) }

    func showToast(_ text: String, art: String? = nil) {
        toast = Toast(text: text, art: art)
        toastClock = 2.6
    }

    func enqueue(_ m: Modal) {
        if modals.contains(where: { $0.id == m.id }) { return }
        modals.append(m)
    }

    func closeModal() {
        if !modals.isEmpty { modals.removeFirst() }
        Feedback.play(.t0)
        flushLevelUp()
        save()
    }

    /// Makes sure the kitchen arrays match the city definition (content updates add stations safely).
    func normalizeCity() {
        let n = city.stations.count
        if s.city.stations.count < n {
            s.city.stations += Array(repeating: StationState(), count: n - s.city.stations.count)
        } else if s.city.stations.count > n {
            s.city.stations = Array(s.city.stations.prefix(n))
        }
        if n > 0 && s.city.stations[0].level == 0 { s.city.stations[0].level = 1 }
        let chains = city.twists.filter { $0.type == .productionChain }.count
        if s.city.twist.chainStock.count < chains {
            s.city.twist.chainStock += Array(repeating: 0, count: chains - s.city.twist.chainStock.count)
        }
    }

    func applySettings() {
        AudioEngine.shared.enabled = s.settings.sfx
        Haptic.enabled = s.settings.haptics
        Num.arabicDigits = s.settings.arabicDigits
        Feedback.reduceMotion = s.settings.reduceMotion || UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Lifecycle

    func start() {
        lastTickUptime = Clock.uptime()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func didEnterBackground() {
        isForeground = false
        stampClock()
        save()
        if !GameStore.isDemo { Notifier.schedule(store: self) }
    }

    func didBecomeActive() {
        guard !isForeground else { return }
        isForeground = true
        resume(launch: false)
    }

    func stampClock() {
        let t = now()
        s.meta.lastTrustedWall = t
        s.meta.lastActiveTick = t
        s.meta.lastUptime = Clock.uptime()
        s.meta.bootTime = Clock.bootTime()
    }

    func save(backup: Bool = false) {
        stampClock()
        saveClock = 0
        guard !GameStore.isDemo else { return }
        s.write(backup: backup)
    }

    // MARK: - Tick (10 Hz, GDD 2.12)

    func tick() {
        let up = Clock.uptime()
        var dt = up - lastTickUptime
        lastTickUptime = up
        if dt <= 0 { return }
        dt = min(dt, 1.0)
        guard isForeground else { return }

        let t = now()
        checkClockFrozen(wall: Date().timeIntervalSince1970)
        rollover(t)

        advanceKitchen(dt: dt, at: t, foreground: true)
        tickTwists(dt: dt, at: t)
        tickBoosts(dt: dt)
        tickSpecials(dt: dt, at: t)
        tickChoices(dt: dt)
        if !s.meta.clockFrozen { accrueBranchSafe(until: t) }
        tickResearch(at: t)
        advanceSides(dt: dt, foreground: true)
        tickTickets(at: t)

        if let o = oven, t >= o.deadline { collectOven(perfect: false) }
        if toastClock > 0 {
            toastClock -= dt
            if toastClock <= 0 { toast = nil }
        }

        slowClock += dt
        if slowClock >= 0.5 {
            slowClock = 0
            refreshGoalSlots()
            checkGoalChimes()
            checkStoryTriggers()
            dailyRollover()
            leagueRollover()
            seasonRollover()
            checkContracts()
            eventTick()
            checkEvent()
            tickInspector()
            evaluateFtue()
            flushLevelUp()
        }
        saveClock += dt
        if saveClock >= 10 { save() }
    }

    func rollover(_ t: Double) {
        guard !s.meta.clockFrozen else { return }
        let day = Clock.gameDay(t)
        if day > s.meta.lastProcessedDay {
            let first = s.meta.lastProcessedDay == 0
            s.meta.lastProcessedDay = day
            if !first { save(backup: true) }
        }
    }

    // MARK: - Legacy gift (GDD 6.16)

    func checkLegacy() {
        guard !s.legacy.checked else { return }
        s.legacy.checked = true
        guard let data = UserDefaults.standard.data(forKey: GameSave.v2Key) else { return }
        s.legacy.eligible = true
        if let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            if let name = obj["stallName"] as? String, !name.isEmpty { s.legacy.v2StallName = name }
            if let p = obj["prestigeCount"] as? Int { s.legacy.prestigeCount = p }
        }
    }

    func claimLegacy() {
        guard s.legacy.eligible, !s.legacy.claimed else { return }
        s.legacy.claimed = true
        s.wallet.gold += 300
        s.wallet.pendingChests["gold", default: 0] += 1
        if !s.legacy.v2StallName.isEmpty { s.settings.stallName = s.legacy.v2StallName }
        Feedback.play(.t2)
        save()
    }
}

extension GameStore {
    /// "ابدأ من جديد": wipes progress, keeps settings and the legacy flag (GDD 6.17).
    func resetGame() {
        var fresh = GameSave()
        fresh.settings = s.settings
        fresh.legacy = s.legacy
        fresh.notif = s.notif
        fresh.meta.playerSeed = String(UInt64.random(in: 1...UInt64.max))
        fresh.meta.createdAt = Date().timeIntervalSince1970
        s = fresh
        modals = []
        sheet = nil
        special = nil
        oven = nil
        tab = .home
        buyMode = .x1
        readyGoals = []
        pendingLevelUp = nil
        chainSigma = []
        openCity(cat.cities.first?.id ?? "jerusalem", at: now(), firstEver: true)
        save()
    }
}
