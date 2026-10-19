import Foundation

/// City twists inside side kitchens (GDD 6.9 "any city twist may also be declared", 6.10 theme or season twist)
/// and the goldenHour rule. Same promise as the city: bonus-only, nothing here lowers income.
extension GameStore {
    static let sideTwistTypes: Set<TwistType> = [.productionChain, .ovenTiming, .busWaves, .nightMarket, .portShipments, .weatherSwing]

    func sideTwists(_ r: SideRef) -> [TwistDef] {
        var list: [TwistDef] = []
        switch r {
        case .contract(let id):
            list = cat.contract(id)?.twists ?? []
        case .event:
            list = cat.theme(s.event.themeId)?.twists ?? []
            if list.isEmpty, unlocked("season"), let tw = seasonTheme?.eventTwist { list = [tw] }
        }
        return list.filter { GameStore.sideTwistTypes.contains($0.type) }
    }

    func sideTwist(_ r: SideRef, _ type: TwistType) -> TwistParams? {
        sideTwists(r).first { $0.type == type }?.params
    }

    func sideIdx(_ r: SideRef, _ key: String?) -> Int? {
        guard let k = key else { return nil }
        return sideStations(r).firstIndex { $0.key == k }
    }

    func sideStationName(_ r: SideRef, _ key: String?) -> String {
        guard let i = sideIdx(r, key) else { return "" }
        return t(sideStations(r)[i].name)
    }

    private func sideListed(_ r: SideRef, _ keys: [String], _ i: Int) -> Bool {
        let defs = sideStations(r)
        return keys.isEmpty || (i < defs.count && keys.contains(defs[i].key))
    }

    /// Seed part that keeps each side kitchen's buses, ships and weather apart.
    private func sideSeedKey(_ r: SideRef) -> String {
        switch r {
        case .contract(let id): return "c." + id
        case .event: return "e." + s.event.themeId
        }
    }

    // MARK: Multipliers

    /// Passive twist multiplier for station i (counts offline too, like the city's).
    func sideTwistProfit(_ k: SideKitchenSave, _ r: SideRef, _ i: Int, at tNow: Double) -> Double {
        var m = 1.0
        for tw in sideTwists(r) {
            let p = tw.params
            switch tw.type {
            case .nightMarket:
                if sideListed(r, p.stations, i) && isNight(p, at: tNow) { m *= p.nightMult }
            case .weatherSwing:
                if sideWeatherBoosts(r, p, i, at: tNow) { m *= p.mult }
            case .productionChain:
                if sideIdx(r, p.outputStation) == i { m *= 1 + (p.outputMult - 1) * sideChainSupply(k, r, p) }
            case .ovenTiming:
                if sideIdx(r, p.station) == i && sideCycle(k, r, i) < p.minCycleSec { m *= 1.25 }
            default:
                break
            }
        }
        return m
    }

    /// Foreground-only twist multiplier: tourist bus wave and the goldenHour frenzy.
    func sideTwistActive(_ k: SideKitchenSave, _ r: SideRef, _ i: Int) -> Double {
        var m = 1.0
        if let p = sideTwist(r, .busWaves), k.twist.busWaveLeft > 0, sideListed(r, p.stations, i) { m *= p.waveMult }
        if sideFrenzyLeft(r, at: now()) > 0 { m *= econ.boosts.frenzyMult }
        return m
    }

    // MARK: Tick

    func tickSideTwists(_ k: inout SideKitchenSave, _ r: SideRef, dt: Double, at tNow: Double) {
        if k.twist.busWaveLeft > 0 { k.twist.busWaveLeft = max(0, k.twist.busWaveLeft - dt) }
        if k.twist.ovenStation >= 0 && tNow >= k.twist.ovenDeadline { collectSideOven(&k, r, perfect: false) }
        if let p = sideTwist(r, .portShipments), let st = sidePortStatus(r, p, at: tNow), st.docked, k.twist.portDockId != st.dockId {
            k.twist.portDockId = st.dockId
            k.twist.portUnits = 0
            k.twist.portLoaded = false
            var target = 1.0
            if let i = sideIdx(r, p.station), i < k.stations.count {
                let lv = Double(max(1, k.stations[i].level))
                target = max(1, p.targetMin * 60 / sideCycle(k, r, i) * lv)
            }
            k.twist.portTarget = target
            if sideOpen(r) { showToast("الباخرة وصلت! عبّي الشحنة", art: "veh_ship") }
        }
        if sideRules(r).contains("goldenHour") {
            let hour = Int(tNow / 3600)
            if sideFrenzyLeft(r, at: tNow) > 0 && k.twist.frenzyHour != hour {
                k.twist.frenzyHour = hour
                if sideOpen(r) {
                    showToast("عجقة زباين! الدخل " + Num.mult(econ.boosts.frenzyMult), art: "ui_fire")
                    Feedback.play(.t1)
                }
            }
        }
    }

    /// Called for every finished cycle of station i. Returns false when the oven keeps the payout on a tray.
    func sideCycleDone(_ k: inout SideKitchenSave, _ r: SideRef, _ i: Int, count: Int, pay: Double, foreground: Bool) -> Bool {
        if let p = sideTwist(r, .portShipments), sideIdx(r, p.station) == i, !k.twist.portLoaded,
           let st = sidePortStatus(r, p, at: now()), st.docked, st.dockId == k.twist.portDockId {
            k.twist.portUnits += Double(k.stations[i].level * count)
        }
        guard foreground, k.twist.ovenStation < 0, let p = sideTwist(r, .ovenTiming), sideIdx(r, p.station) == i,
              sideCycle(k, r, i) >= p.minCycleSec else { return false }
        let one = pay / Double(max(1, count))
        k.cash += one * Double(count - 1)
        k.lifetime += one * Double(count - 1)
        k.twist.ovenStation = i
        k.twist.ovenPayout = one
        k.twist.ovenDeadline = now() + p.windowSec
        Feedback.play(.t0)
        return true
    }

    func sideOpen(_ r: SideRef) -> Bool {
        if case .side(let x)? = sheet, x == r { return isForeground }
        return false
    }

    // MARK: goldenHour

    var frenzyWindow: Double { econ.boosts.frenzySec + researchValue("frenzySec") }

    /// Seconds of frenzy left right now (0 outside the window at the top of each hour).
    func sideFrenzyLeft(_ r: SideRef, at tNow: Double) -> Double {
        guard sideRules(r).contains("goldenHour") else { return 0 }
        let into = Clock.secondsOfDay(tNow).truncatingRemainder(dividingBy: 3600)
        return max(0, frenzyWindow - into)
    }

    func sideNextFrenzyIn(at tNow: Double) -> Double {
        3600 - Clock.secondsOfDay(tNow).truncatingRemainder(dividingBy: 3600)
    }

    // MARK: ovenTiming

    func sideOvenReady(_ k: SideKitchenSave, _ i: Int) -> Bool { k.twist.ovenStation == i }

    func collectSideOven(_ k: inout SideKitchenSave, _ r: SideRef, perfect: Bool) {
        guard k.twist.ovenStation >= 0 else { return }
        let i = k.twist.ovenStation
        let hit = perfect && now() <= k.twist.ovenDeadline
        let mult = hit ? (sideTwist(r, .ovenTiming)?.perfectMult ?? 3) : 1
        let pay = k.twist.ovenPayout * mult
        k.cash += pay
        k.lifetime += pay
        k.twist.ovenStation = -1
        k.twist.ovenPayout = 0
        if hit {
            bump("ovenPerfects")
            Feedback.play(.t1, fromAnchor: "side.\(i).cook", art: sideCashArt(r), to: "side.cash", amount: pay,
                          label: "مظبوطة! " + Num.mult(mult))
        }
    }

    // MARK: busWaves

    func sideBus(_ r: SideRef, at tNow: Double) -> Int? {
        guard let p = sideTwist(r, .busWaves) else { return nil }
        let iv = max(1, Int(p.intervalMin))
        let hm = Clock.hourMinute(tNow)
        let day = Clock.gameDay(tNow)
        let mod = hm.h * 60 + hm.m
        var rng = Seed.rng("sideBus", [sideSeedKey(r), "\(day)"], player: s.meta.seed)
        let off = Int(rng.next() % UInt64(iv))
        guard ((mod - off) % iv + iv) % iv == 0, Double(hm.s) < p.windowSec else { return nil }
        return day * 10000 + mod
    }

    func sideBusWaiting(_ r: SideRef) -> Bool {
        guard let k = side(r), let id = sideBus(r, at: now()) else { return false }
        return id != k.twist.busHandledId
    }

    func sideNextBusIn(_ r: SideRef) -> Double {
        guard let p = sideTwist(r, .busWaves) else { return 0 }
        let tNow = now()
        let iv = max(1, Int(p.intervalMin))
        let hm = Clock.hourMinute(tNow)
        var rng = Seed.rng("sideBus", [sideSeedKey(r), "\(Clock.gameDay(tNow))"], player: s.meta.seed)
        let off = Int(rng.next() % UInt64(iv))
        let mod = hm.h * 60 + hm.m
        var n = ((off - mod) % iv + iv) % iv
        if n == 0 { n = iv }
        return Double(n * 60 - hm.s)
    }

    func welcomeSideBus(_ r: SideRef) {
        guard let p = sideTwist(r, .busWaves), var k = side(r), let id = sideBus(r, at: now()), id != k.twist.busHandledId else { return }
        k.twist.busHandledId = id
        k.twist.busWaveLeft = p.waveSec
        setSide(r, k)
        bump("busesWelcomed")
        Feedback.play(.t1, fromAnchor: "side.twist.bus", art: "veh_bus", to: "side.cash", amount: 10,
                      label: "باص سيّاح! " + Num.mult(p.waveMult))
        save()
    }

    // MARK: portShipments

    func sidePortStatus(_ r: SideRef, _ p: TwistParams, at tNow: Double) -> PortStatus? {
        let iv = max(1, p.intervalHours)
        let day = Clock.gameDay(tNow)
        var rng = Seed.rng("sidePort", [sideSeedKey(r), "\(day)"], player: s.meta.seed)
        let off = Int(rng.next() % UInt64(iv))
        let sod = Clock.secondsOfDay(tNow)
        let h = Int(sod / 3600)
        let n = ((h - off) % iv + iv) % iv
        let startHour = h - n
        let docked = n < p.dockHours
        let leaves = Double((startHour + p.dockHours) * 3600) - sod
        let next = Double((startHour + iv) * 3600) - sod
        return PortStatus(docked: docked, dockId: day * 100 + (startHour + 24) % 24, leavesIn: leaves, nextIn: next)
    }

    func sidePortReady(_ r: SideRef) -> Bool {
        guard let p = sideTwist(r, .portShipments), let k = side(r), let st = sidePortStatus(r, p, at: now()),
              st.docked, st.dockId == k.twist.portDockId else { return false }
        return !k.twist.portLoaded && k.twist.portUnits >= k.twist.portTarget
    }

    func loadSideShipment(_ r: SideRef) {
        guard let p = sideTwist(r, .portShipments), sidePortReady(r), var k = side(r) else { return }
        let reward = p.rewardMin * 60 * sideTotalIncome(r) * (1 + researchValue("happeningRewardPct"))
        k.twist.portLoaded = true
        k.cash += reward
        k.lifetime += reward
        setSide(r, k)
        bump("shipmentsDelivered")
        Feedback.play(.t1, fromAnchor: "side.twist.port", art: sideCashArt(r), to: "side.cash", amount: reward,
                      label: Num.plus(Num.big(reward)))
        save()
    }

    // MARK: weatherSwing

    func sideWeather(_ r: SideRef, day: Int) -> Weather? {
        guard let p = sideTwist(r, .weatherSwing) else { return nil }
        var rng = Seed.rng("sideWeather", [sideSeedKey(r), "\(day)"], player: s.meta.seed)
        let u = rng.unit()
        if u < p.hotProb { return .hot }
        if u < p.hotProb + p.coldProb { return .cold }
        if u < p.hotProb + p.coldProb + p.rainProb { return .rain }
        return .sunny
    }

    func sideWeatherKeys(_ p: TwistParams, _ w: Weather) -> [String] {
        switch w {
        case .hot: return p.hotDayStations
        case .cold: return p.coldDayStations
        case .rain: return p.rainDayStations
        case .sunny: return []
        }
    }

    private func sideWeatherBoosts(_ r: SideRef, _ p: TwistParams, _ i: Int, at tNow: Double) -> Bool {
        guard let w = sideWeather(r, day: Clock.gameDay(tNow)) else { return false }
        let defs = sideStations(r)
        return i < defs.count && sideWeatherKeys(p, w).contains(defs[i].key)
    }

    // MARK: productionChain

    /// Share of the output station's demand the input station covers (0…1). No stock in side kitchens.
    func sideChainSupply(_ k: SideKitchenSave, _ r: SideRef, _ p: TwistParams) -> Double {
        guard let a = sideIdx(r, p.inputStation), let b = sideIdx(r, p.outputStation),
              a < k.stations.count, b < k.stations.count else { return 0 }
        let sa = k.stations[a]
        let sb = k.stations[b]
        guard sa.level > 0, sa.managed || sa.cooking else { return 0 }
        let supply = Double(sa.level) * sideSpeed(k, r, a) / sideRow(r, a).baseCycleSec
        let demand = Double(sb.level) * sideSpeed(k, r, b) / sideRow(r, b).baseCycleSec * p.ratio
        guard demand > 0 else { return 1 }
        return min(1, supply / demand)
    }

    // MARK: Text

    func ruleName(_ rule: String) -> String {
        switch rule {
        case "noManagers": return "بدون معلّمين: كل الطبخ بإيدك"
        case "noUpgrades": return "بدون ترقيات"
        case "chefsOff": return "الطبّاخين بإجازة"
        case "fastCheap": return "سريع ورخيص: الطبخ والأسعار بالنص"
        case "goldenHour": return "عجقة زباين أول كل ساعة"
        case "oneStation": return "محطّة وحدة بس"
        default: return rule
        }
    }

    func ruleArt(_ rule: String) -> String {
        switch rule {
        case "noManagers": return "ppl_cook"
        case "noUpgrades": return "ui_locked"
        case "chefsOff": return "face_sleeping_face"
        case "fastCheap": return "ui_high_voltage"
        case "goldenHour": return "ui_fire"
        default: return "ui_clipboard"
        }
    }
}
