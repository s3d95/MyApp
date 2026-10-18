import Foundation
import SwiftUI

/// Screenshot states for CI (`-demo <name>` launch argument, see .github/workflows/check.yml).
/// Demo runs never read or write the player's save.
extension GameStore {
    static let demoName: String? = {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-demo"), i + 1 < a.count else { return nil }
        return a[i + 1]
    }()

    static var isDemo: Bool { demoName != nil }

    /// Puts a city in a mid-game state.
    func demoCity(_ index: Int, levels: [Int], managed: Int, claimed: Int, cash: Double, level: Int) {
        s.ftue.seenTwists = ["productionChain", "ovenTiming", "busWaves", "nightMarket", "portShipments",
                             "deliveryRuns", "weatherSwing", "vipLounge"]
        if let c = cat.city(index: index) { openCity(c.id, at: now(), firstEver: true) }
        modals = []
        for (i, lv) in levels.enumerated() where i < s.city.stations.count {
            s.city.stations[i].level = lv
            s.city.stations[i].managed = i < managed && lv > 0
            s.city.stations[i].cooking = i < managed && lv > 0
            s.city.stations[i].progress = Double(i % 3) * 0.3
            s.city.stations[i].milestonesSeen = stationMilestones(i)
        }
        let goals = Array(supportedGoals.prefix(claimed))
        s.city.goalsClaimed = goals.map { $0.id }
        s.city.stars = goals.reduce(0) { $0 + $1.stars }
        s.city.cash = cash
        s.city.lifetimeEarned = cash * 3
        if let u = city.upgrades.first, cash > 1e6 { s.city.upgradesBought = [u.id] }
        s.empire.level = level
        s.empire.xp = xpNeed(level) / 3
        s.wallet.gold = 140
        s.ftue.done = true
        s.settings.addressAsked = true
        s.happenings.nextSpecialAt = 99999
        s.city.scenesSeen = cat.chapter(cityId: city.id)?.scenes.map { $0.id } ?? []
    }

    func demoChefs() {
        for (id, lv, cards) in [("samiFryer", 3, 9), ("ummMohammad", 2, 3), ("hajjaUmmSubhi", 2, 1), ("chefRami", 3, 2),
                                ("chefMaher", 1, 0), ("muratGrill", 1, 1)] {
            var o = ChefOwn()
            o.level = lv
            o.cards = cards
            s.chefs.owned[id] = o
        }
        s.chefs.equipped = ["samiFryer", "chefRami"]
        s.chefs.chests = ["wood": 2, "silver": 1]
        s.chefs.ftueChestGiven = true
        s.chefs.ftueChestOpened = true
    }

    func demoKitchen() {
        demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e6, level: 5)
    }

    func applyDemo(_ name: String) {
        s.happenings.nextSpecialAt = 99999
        switch name {
        case "tut1":
            break
        case "tut3":
            s.ftue.step = 3
            s.ftue.tapCooks["jerusalem.falafel"] = 1
        case "tut5":
            s.city.stations[0].level = 10
            s.city.stations[0].milestonesSeen = 1
            s.city.cash = 70
            s.ftue.step = 5
        case "tut7":
            s.city.stations[0].level = 10
            s.city.stations[1].level = 1
            s.ftue.tapCooks["jerusalem.hummus"] = 1
            s.ftue.step = 7
        case "tut8":
            s.empire.level = 2
            s.city.stations[0].level = 12
            s.city.stations[1].level = 3
            s.city.goalsClaimed = ["jerusalem.g01"]
            s.city.stars = 1
            s.city.cash = 1200
            s.ftue.step = 8
            s.settings.addressAsked = true
        case "tut11":
            demoCity(1, levels: [30, 20, 10, 0, 0, 0], managed: 2, claimed: 4, cash: 300_000, level: 3)
            s.city.upgradesBought = []
            s.ftue.done = false
            s.ftue.step = 11
        case "tut11b":
            demoCity(1, levels: [30, 20, 10, 0, 0, 0], managed: 2, claimed: 4, cash: 300_000, level: 3)
            s.city.upgradesBought = []
            s.ftue.done = false
            s.ftue.step = 11
            sheet = .upgrades
        case "tut14":
            demoKitchen()
            s.ftue.done = false
            s.ftue.step = 14
        case "kitchen":
            demoKitchen()
        case "scroll":
            demoCity(1, levels: [100, 80, 60, 50, 40, 25], managed: 6, claimed: 15, cash: 4.2e9, level: 8)
        case "special":
            demoKitchen()
            spawnSpecial(forced: .tip)
            addBoost("frenzy", mult: 5, seconds: 48)
        case "upgrades":
            demoKitchen()
            sheet = .upgrades
        case "goals":
            demoKitchen()
            sheet = .goals
        case "profile":
            demoKitchen()
            s.wallet.timeWarps = [60]
            s.wallet.pendingChests = ["wood": 2, "silver": 1]
            sheet = .profile
        case "settings":
            demoKitchen()
            sheet = .settings
        case "teaser":
            demoKitchen()
            sheet = .teaser(.chefs)
        case "levelup":
            demoKitchen()
            let lines = [RewardLine(art: "ui_coin", amount: "+10", caption: "ذهب"),
                         RewardLine(art: "veh_package", amount: "×1", caption: "صندوق خشب")]
            modals = [.levelUp(LevelUpInfo(from: 5, to: 6, rewards: lines, unlocks: ["الخريطة والفروع"], title: nil))]
        case "news":
            demoKitchen()
            let info = NewsInfo(away: 7400, vault: 1_234_000, cityName: t(city.name), currency: currencyName,
                                doubleCost: 15, canDouble: true, lines: ["خزنة الفروع فيها 4 ذهب"], freshDoughMin: 0)
            modals = [.newspaper(info)]
        case "story":
            demoKitchen()
            modals = [.story(scene: "ch01_rival", city: "jerusalem")]
        case "address":
            demoKitchen()
            modals = [.address]
        case "legacy":
            demoKitchen()
            modals = [.legacy]
        case "confirm":
            demoCity(1, levels: [100, 60, 50, 50, 50, 50], managed: 6, claimed: 19, cash: 8e9, level: 7)
            modals = [.graduateConfirm]
        case "graduation":
            demoKitchen()
            modals = [.graduation(from: "jerusalem", to: "bethlehem")]
        case "unlock":
            demoCity(2, levels: [10, 1, 0, 0, 0, 0], managed: 1, claimed: 1, cash: 900, level: 6)
            modals = [.unlock("twist.busWaves")]
        case "map":
            demoCity(4, levels: [80, 60, 40, 30, 20, 0, 0], managed: 5, claimed: 8, cash: 9e8, level: 14)
            var b1 = BranchSave()
            b1.level = 1
            b1.crowned = true
            b1.stars = 27
            var b2 = BranchSave()
            b2.stars = 34
            var b3 = BranchSave()
            b3.level = 2
            b3.stars = 35
            s.branches = ["jerusalem": b1, "bethlehem": b2, "nablus": b3]
            s.branchSafe.stored = 3.4
            s.branchSafe.lastAccrual = now()
            tab = .map
        case "bethlehem":
            demoCity(2, levels: [50, 40, 30, 20, 10, 5], managed: 6, claimed: 10, cash: 5e7, level: 7)
            s.city.twist.busWaveLeft = 40
        case "nablus":
            demoCity(3, levels: [60, 50, 40, 30, 25, 10, 5], managed: 6, claimed: 8, cash: 8e7, level: 9)
            if let i = idx(ovenParams?.station) {
                s.city.stations[i].level = 25
                oven = OvenTray(station: i, payout: 12_000, deadline: now() + 600, window: 1.6)
            }
        case "hebron":
            demoCity(4, levels: [60, 50, 40, 30, 25, 10, 5], managed: 7, claimed: 8, cash: 8e8, level: 11)
        case "jaffa":
            demoCity(5, levels: [60, 50, 40, 30, 25, 10, 0], managed: 6, claimed: 8, cash: 2e9, level: 12)
        case "haifa":
            demoCity(6, levels: [60, 50, 40, 30, 25, 10, 0], managed: 6, claimed: 8, cash: 3e9, level: 13)
            s.city.twist.deliveryQueue = 3
        case "gaza":
            demoCity(7, levels: [60, 50, 40, 30, 25, 10, 0], managed: 6, claimed: 8, cash: 4e9, level: 14)
        case "ramallah":
            demoCity(8, levels: [60, 50, 40, 30, 25, 10, 0], managed: 6, claimed: 8, cash: 5e9, level: 15)
        case "dubai":
            demoCity(15, levels: [90, 70, 60, 50, 40, 30, 20, 0], managed: 7, claimed: 8, cash: 5e14, level: 30)
        case "chefs":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e6, level: 9)
            demoChefs()
            tab = .chefs
        case "chests":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e6, level: 9)
            demoChefs()
            tab = .chefs
        case "chestopen":
            demoKitchen()
            addChest("silver")
            openChest("silver")
        case "chefdetail":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e6, level: 9)
            demoChefs()
            tab = .chefs
            sheet = .chef("chefRami")
        case "shop":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e6, level: 9)
            s.wallet.gold = 320
            tab = .shop
        case "tut12":
            demoCity(1, levels: [30, 20, 10, 0, 0, 0], managed: 2, claimed: 5, cash: 300_000, level: 4)
            s.ftue.done = false
            s.ftue.step = 12
        case "research":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e8, level: 12)
            s.research.levels = ["secretBlend": 3, "biggerVault": 2, "happyCustomer": 1]
            var sl = ResearchSlot()
            sl.nodeId = "loyalManagers"
            sl.level = 1
            sl.startAt = now() - 120
            sl.endAt = now() + 480
            s.research.slots = [sl]
            sheet = .research
        case "supply":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e8, level: 12)
            s.supply.launches = ["tractor": 5, "pickup": 1]
            var run = SupplySlot()
            run.runId = "demo"
            run.vehicleId = "tractor"
            run.sentAt = now() - 300
            run.endAt = now() + 900
            s.supply.slots = [run]
            sheet = .supply
        case "heritage":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e8, level: 20)
            for (k, item) in cat.heritage.items.enumerated() where k % 3 != 2 { s.supply.heritage[item.id] = 1 + k % 6 }
            sheet = .supply
        case "supplyreveal":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e8, level: 12)
            var run = SupplySlot()
            run.runId = "demo"
            run.vehicleId = "pickup"
            run.durationIdx = 1
            run.sentAt = now() - 3000
            run.endAt = now() - 1
            s.supply.slots = [run]
            claimRun("demo")
        case "tut17":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e7, level: 7)
            s.ftue.done = false
            s.ftue.step = 17
        case "tut18":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e7, level: 8)
            s.ftue.done = false
            s.ftue.step = 18
            sheet = .supply
        case "tasks", "weekly", "calendar":
            demoCity(1, levels: [60, 45, 30, 25, 10, 0], managed: 4, claimed: 9, cash: 2.5e8, level: 12)
            s.daily.lastRolledDay = dayNum
            dailyRollover()
            for k in s.daily.orders.indices where k < 2 {
                if let q = template(s.daily.orders[k].templateId) { bump(q.metric, s.daily.orders[k].target * (k == 0 ? 1 : 0.4)) }
            }
            if !s.daily.orders.isEmpty { s.daily.orders[0].claimed = true }
            s.daily.streak = 5
            s.daily.streakBest = 9
            s.daily.streakLastDay = dayNum
            s.wallet.freezes = 1
            s.daily.calIndex = 6
            tab = .tasks
        case "anchors", "fx":
            demoKitchen()
            spawnSpecial(forced: .tip)
        default:
            break
        }
        normalizeCity()
        if name == "fx" {
            let t = Timer(timeInterval: 0.6, repeats: true) { _ in
                Feedback.play(.t1, fromAnchor: "station.0.cook", art: "ui_dollar", to: "pill.cash", amount: 1000,
                              label: "+1,000")
                Feedback.play(.t1, fromAnchor: "goal.1.claim", art: "ui_star", to: "pill.stars", amount: 10)
            }
            RunLoop.main.add(t, forMode: .common)
        }
    }
}

/// Outlines every effect anchor (demo "anchors") to check that measured rects match the views.
struct DebugAnchorsView: View {
    @ObservedObject var box: AnchorBox

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(box.rects.keys.sorted()), id: \.self) { k in
                if let r = box.rects[k] {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                    Text(k)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.green)
                        .position(x: r.midX, y: r.minY + 5)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
