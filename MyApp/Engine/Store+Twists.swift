import Foundation

enum Weather: String {
    case sunny, hot, cold, rain

    var art: String {
        switch self {
        case .sunny: return "ui_sun_behind_cloud"
        case .hot: return "ui_sun"
        case .cold: return "ui_snowflake"
        case .rain: return "ui_cloud_with_rain"
        }
    }

    var name: String {
        switch self {
        case .sunny: return "مشمس"
        case .hot: return "شوب"
        case .cold: return "برد"
        case .rain: return "شتا"
        }
    }
}

struct PortStatus {
    var docked: Bool
    var dockId: Int
    var leavesIn: Double
    var nextIn: Double
}

/// The eight city twists (GDD 3.6). All are bonus-only: nothing here can lower income.
extension GameStore {
    func twists(_ type: TwistType) -> [TwistParams] {
        city.twists.filter { $0.type == type }.map { $0.params }
    }

    func twist(_ type: TwistType) -> TwistParams? { twists(type).first }

    var ovenParams: TwistParams? { twist(.ovenTiming) }

    func idx(_ key: String?) -> Int? {
        guard let k = key else { return nil }
        return city.stationIndex(key: k)
    }

    func listed(_ keys: [String], _ i: Int) -> Bool {
        keys.isEmpty || keys.contains(city.stations[i].key)
    }

    // MARK: Multipliers

    func twistProfit(_ i: Int, at t: Double) -> Double {
        var m = 1.0
        for (j, p) in twists(.productionChain).enumerated() where idx(p.outputStation) == i {
            let sigma = j < chainSigma.count ? chainSigma[j] : 0
            m *= 1 + (p.outputMult - 1) * sigma
        }
        if let p = ovenParams, idx(p.station) == i, effCycle(i) < p.minCycleSec {
            m *= 1.25
        }
        for p in twists(.nightMarket) where listed(p.stations, i) && isNight(p, at: t) {
            m *= p.nightMult
        }
        if let p = twist(.weatherSwing), weatherBoosts(p, i, at: t) {
            m *= p.mult
        }
        return m
    }

    func twistActive(_ i: Int) -> Double {
        guard let p = twist(.busWaves), s.city.twist.busWaveLeft > 0, listed(p.stations, i) else { return 1 }
        return p.waveMult
    }

    func twistMetricsOnCredit(_ i: Int, amount: Double, at t: Double) {
        let base = amount / scale
        if twists(.nightMarket).contains(where: { listed($0.stations, i) && isNight($0, at: t) }) {
            s.city.counters["nightEarnedBase", default: 0] += base
        }
        if let p = twist(.weatherSwing), weatherBoosts(p, i, at: t) {
            s.city.counters["weatherEarnedBase", default: 0] += base
        }
    }

    // MARK: Tick

    func tickTwists(dt: Double, at t: Double) {
        updateChains(dt: dt, at: t)
        if s.city.twist.busWaveLeft > 0 {
            s.city.twist.busWaveLeft = max(0, s.city.twist.busWaveLeft - dt)
        }
        tickPort(at: t)
        tickDelivery(dt: dt, at: t)
    }

    // MARK: 1. productionChain

    func isChainInput(_ i: Int) -> Bool {
        twists(.productionChain).contains { idx($0.inputStation) == i }
    }

    func chainOutputOf(_ i: Int) -> Int? {
        for p in twists(.productionChain) where idx(p.inputStation) == i { return idx(p.outputStation) }
        return nil
    }

    func chainPD(_ p: TwistParams, at t: Double) -> (P: Double, D: Double) {
        guard let a = idx(p.inputStation), let b = idx(p.outputStation) else { return (0, 0) }
        let sa = s.city.stations[a]
        let sb = s.city.stations[b]
        var P = 0.0
        var D = 0.0
        if sa.level > 0 && (sa.managed || sa.cooking) {
            P = Double(sa.level) * profitMult(a, at: t, active: false) * speedMult(a) / row(a).baseCycleSec
        }
        if sb.level > 0 && (sb.managed || sb.cooking) {
            D = Double(sb.level) * speedMult(b) / row(b).baseCycleSec * p.ratio
        }
        return (P, D)
    }

    func updateChains(dt: Double, at t: Double) {
        let chains = twists(.productionChain)
        guard !chains.isEmpty else {
            if !chainSigma.isEmpty { chainSigma = [] }
            return
        }
        if chainSigma.count != chains.count { chainSigma = Array(repeating: 0, count: chains.count) }
        if s.city.twist.chainStock.count < chains.count {
            s.city.twist.chainStock += Array(repeating: 0, count: chains.count - s.city.twist.chainStock.count)
        }
        for (j, p) in chains.enumerated() {
            let pd = chainPD(p, at: t)
            var stock = s.city.twist.chainStock[j]
            var sigma = 0.0
            if pd.D <= 0 {
                sigma = pd.P > 0 ? 1 : 0
            } else if stock > 0 || pd.P >= pd.D {
                sigma = 1
            } else {
                sigma = pd.P / pd.D
            }
            let capStock = pd.D * 60 * p.stockCapMin
            stock = min(capStock, max(0, stock + (pd.P - sigma * pd.D) * dt))
            s.city.twist.chainStock[j] = stock
            chainSigma[j] = sigma
            let used = sigma * pd.D * dt
            if used > 0 { s.city.counters["chainUnits", default: 0] += used }
        }
    }

    // MARK: 2. ovenTiming

    func collectOven(perfect: Bool) {
        guard let o = oven else { return }
        oven = nil
        let t = now()
        let hit = perfect && t <= o.deadline
        let mult = hit ? (ovenParams?.perfectMult ?? 3) : 1
        credit(o.payout * mult, station: o.station, at: t)
        if hit {
            s.city.counters["ovenPerfects", default: 0] += 1
            Feedback.play(.t1, fromAnchor: "station.\(o.station).cook", art: city.currency.art, to: "pill.cash",
                          amount: o.payout * mult, label: "مظبوطة! " + Num.mult(mult))
        }
    }

    // MARK: 3. busWaves

    func busOffset(_ p: TwistParams, day: Int) -> Int {
        let iv = max(1, Int(p.intervalMin))
        var r = Seed.rng("busOffset", [city.id, "\(day)"], player: s.meta.seed)
        return Int(r.next() % UInt64(iv))
    }

    /// Id of the bus at the stop right now, if any.
    func currentBus(at t: Double) -> Int? {
        guard let p = twist(.busWaves) else { return nil }
        let iv = max(1, Int(p.intervalMin))
        let hm = Clock.hourMinute(t)
        let day = Clock.gameDay(t)
        let mod = hm.h * 60 + hm.m
        let off = busOffset(p, day: day)
        guard ((mod - off) % iv + iv) % iv == 0, Double(hm.s) < p.windowSec else { return nil }
        return day * 10000 + mod
    }

    var busWaiting: Bool {
        guard let id = currentBus(at: now()) else { return false }
        return id != s.city.twist.busHandledId
    }

    var busSecondsLeft: Double {
        guard let p = twist(.busWaves) else { return 0 }
        let hm = Clock.hourMinute(now())
        return max(0, p.windowSec - Double(hm.s))
    }

    func nextBusIn() -> Double {
        guard let p = twist(.busWaves) else { return 0 }
        let t = now()
        let iv = max(1, Int(p.intervalMin))
        let hm = Clock.hourMinute(t)
        let off = busOffset(p, day: Clock.gameDay(t))
        let mod = hm.h * 60 + hm.m
        var k = ((off - mod) % iv + iv) % iv
        if k == 0 { k = iv }
        return Double(k * 60 - hm.s)
    }

    func welcomeBus() {
        guard let p = twist(.busWaves), let id = currentBus(at: now()), id != s.city.twist.busHandledId else { return }
        s.city.twist.busHandledId = id
        s.city.twist.busWaveLeft = p.waveSec
        s.city.counters["busesWelcomed", default: 0] += 1
        Feedback.play(.t1, fromAnchor: "twist.bus", art: "veh_bus", to: "pill.cash", amount: 10,
                      label: "باص سيّاح! " + Num.mult(p.waveMult))
        save()
    }

    // MARK: 4. nightMarket

    func isNight(_ p: TwistParams, at t: Double) -> Bool {
        let h = Clock.hourMinute(t).h
        if p.startHour > p.endHour { return h >= p.startHour || h < p.endHour }
        return h >= p.startHour && h < p.endHour
    }

    var nightActive: Bool { twists(.nightMarket).contains { isNight($0, at: now()) } }

    // MARK: 5. portShipments

    func portStatus(at t: Double) -> PortStatus? {
        guard let p = twist(.portShipments) else { return nil }
        let iv = max(1, p.intervalHours)
        let day = Clock.gameDay(t)
        var r = Seed.rng("portOffset", [city.id, "\(day)"], player: s.meta.seed)
        let off = Int(r.next() % UInt64(iv))
        let sod = Clock.secondsOfDay(t)
        let h = Int(sod / 3600)
        let k = ((h - off) % iv + iv) % iv
        let startHour = h - k
        let docked = k < p.dockHours
        let leaves = Double((startHour + p.dockHours) * 3600) - sod
        let next = Double((startHour + iv) * 3600) - sod
        return PortStatus(docked: docked, dockId: day * 100 + (startHour + 24) % 24, leavesIn: leaves, nextIn: next)
    }

    func tickPort(at t: Double) {
        guard let p = twist(.portShipments), let st = portStatus(at: t), st.docked else { return }
        if s.city.twist.portDockId != st.dockId {
            s.city.twist.portDockId = st.dockId
            s.city.twist.portUnits = 0
            s.city.twist.portLoaded = false
            var target = 1.0
            if let i = idx(p.station) {
                let lv = Double(max(1, s.city.stations[i].level))
                target = max(1, p.targetMin * 60 / effCycle(i) * lv)
            }
            s.city.twist.portTarget = target
            if isForeground { showToast("الباخرة وصلت الميناء! عبّي الشحنة", art: "veh_ship") }
        }
    }

    func portCycles(_ i: Int, count: Int) {
        guard let p = twist(.portShipments), idx(p.station) == i, !s.city.twist.portLoaded,
              let st = portStatus(at: now()), st.docked, st.dockId == s.city.twist.portDockId else { return }
        s.city.twist.portUnits += Double(s.city.stations[i].level * count)
    }

    var portReady: Bool {
        guard let st = portStatus(at: now()), st.docked, st.dockId == s.city.twist.portDockId else { return false }
        return !s.city.twist.portLoaded && s.city.twist.portUnits >= s.city.twist.portTarget
    }

    func loadShipment() {
        guard let p = twist(.portShipments), portReady else { return }
        let reward = p.rewardMin * 60 * totalIncome(active: false)
        s.city.twist.portLoaded = true
        s.city.counters["shipmentsDelivered", default: 0] += 1
        credit(reward, station: nil, at: now())
        Feedback.play(.t1, fromAnchor: "twist.port", art: city.currency.art, to: "pill.cash", amount: reward,
                      label: "+" + Num.big(reward))
        save()
    }

    // MARK: 6. deliveryRuns

    var scootersTotal: Int { (twist(.deliveryRuns)?.scooters ?? 0) + s.city.twist.extraScooters }

    var scootersFree: Int { max(0, scootersTotal - s.city.twist.deliveryOut.count) }

    func tickDelivery(dt: Double, at t: Double) {
        guard let p = twist(.deliveryRuns) else { return }
        s.city.twist.deliveryClock += dt
        let iv = max(30, p.intervalMin * 60)
        if s.city.twist.deliveryClock >= iv {
            s.city.twist.deliveryClock -= iv
            s.city.twist.deliveryQueue = min(p.queueMax, s.city.twist.deliveryQueue + 1)
        }
        if s.city.twist.deliveryOut.contains(where: { $0 <= t }) {
            let back = s.city.twist.deliveryOut.filter { $0 <= t }.count
            s.city.twist.deliveryOut.removeAll { $0 <= t }
            let reward = Double(back) * p.rewardMin * 60 * totalIncome(active: false)
            s.city.counters["deliveriesDone", default: 0] += Double(back)
            credit(reward, station: nil, at: t)
            Feedback.play(.t1, fromAnchor: "twist.delivery", art: city.currency.art, to: "pill.cash", amount: reward,
                          label: "+" + Num.big(reward))
        }
    }

    func sendDelivery() {
        guard let p = twist(.deliveryRuns), s.city.twist.deliveryQueue > 0, scootersFree > 0 else {
            Feedback.error()
            return
        }
        s.city.twist.deliveryQueue -= 1
        s.city.twist.deliveryOut.append(now() + p.tripMin * 60)
        Feedback.play(.t0)
        SFX.whoosh.play()
    }

    var nextScooterCost: Double? {
        guard let p = twist(.deliveryRuns), s.city.twist.extraScooters < p.extraScooterCostsBase.count else { return nil }
        return p.extraScooterCostsBase[s.city.twist.extraScooters] * scale
    }

    var dispatcherCost: Double? {
        guard let p = twist(.deliveryRuns), !s.city.twist.dispatcher, p.dispatcherCostBase > 0 else { return nil }
        return p.dispatcherCostBase * scale
    }

    func buyScooter() {
        guard let c = nextScooterCost, s.city.cash >= c else {
            Feedback.error()
            return
        }
        s.city.cash -= c
        s.city.twist.extraScooters += 1
        Feedback.play(.t1, fromAnchor: "twist.delivery", art: "veh_scooter", to: "twist.delivery", amount: 1, label: "موتور جديد!")
        save()
    }

    func buyDispatcher() {
        guard let c = dispatcherCost, s.city.cash >= c else {
            Feedback.error()
            return
        }
        s.city.cash -= c
        s.city.twist.dispatcher = true
        Feedback.play(.t1, fromAnchor: "twist.delivery", art: "ppl_man_office", to: "twist.delivery", amount: 1, label: "موظّف دليفري!")
        save()
    }

    // MARK: 7. weatherSwing

    func cityWeather(day: Int) -> Weather? {
        guard let p = twist(.weatherSwing) else { return nil }
        var r = Seed.rng("weather", [city.id, "\(day)"], player: s.meta.seed)
        let u = r.unit()
        if u < p.hotProb { return .hot }
        if u < p.hotProb + p.coldProb { return .cold }
        if u < p.hotProb + p.coldProb + p.rainProb { return .rain }
        return .sunny
    }

    func weatherBoosts(_ p: TwistParams, _ i: Int, at t: Double) -> Bool {
        guard let w = cityWeather(day: Clock.gameDay(t)) else { return false }
        let key = city.stations[i].key
        switch w {
        case .hot: return p.hotDayStations.contains(key)
        case .cold: return p.coldDayStations.contains(key)
        case .rain: return p.rainDayStations.contains(key)
        case .sunny: return false
        }
    }

    func weatherStations(_ w: Weather) -> [Int] {
        guard let p = twist(.weatherSwing) else { return [] }
        let keys: [String]
        switch w {
        case .hot: keys = p.hotDayStations
        case .cold: keys = p.coldDayStations
        case .rain: keys = p.rainDayStations
        case .sunny: keys = []
        }
        return keys.compactMap { idx($0) }
    }

    // MARK: 8. vipLounge

    var loungeIndex: Int? { idx(twist(.vipLounge)?.loungeStation) }

    // MARK: Info

    func twistName(_ type: TwistType) -> String {
        switch type {
        case .productionChain: return "سلسلة إنتاج"
        case .ovenTiming: return "توقيت الفرن"
        case .busWaves: return "باصات السيّاح"
        case .nightMarket: return "سوق الليل"
        case .portShipments: return "شحنات الميناء"
        case .deliveryRuns: return "طلبات دليفري"
        case .weatherSwing: return "طقس متقلّب"
        case .vipLounge: return "صالة كبار الزوار"
        case .unknown: return ""
        }
    }

    func twistArt(_ type: TwistType) -> String {
        switch type {
        case .productionChain: return "bld_factory"
        case .ovenTiming: return "ui_fire"
        case .busWaves: return "veh_bus"
        case .nightMarket: return "bld_night_with_stars"
        case .portShipments: return "veh_ship"
        case .deliveryRuns: return "veh_scooter"
        case .weatherSwing: return "ui_sun_behind_cloud"
        case .vipLounge: return "ppl_prince"
        case .unknown: return "ui_sparkles"
        }
    }

    func stationName(_ key: String?) -> String {
        guard let i = idx(key) else { return "" }
        return t(city.stations[i].name)
    }

    func twistInfo(_ d: TwistDef) -> String {
        let p = d.params
        switch d.type {
        case .productionChain:
            let a = stationName(p.inputStation)
            let b = stationName(p.outputStation)
            return "\(a) بيموّن \(b). ما دام في مخزون، \(b) بيربح \(Num.mult(p.outputMult))."
        case .ovenTiming:
            let tap = mf("دقّ عليها بسرعة وبتربح", "دقّي عليها بسرعة وبتربحي")
            return "لما تطلع صينيّة \(stationName(p.station))، \(tap) \(Num.mult(p.perfectMult))!"
        case .busWaves:
            let welcome = mf("استقبله", "استقبليه")
            return "كل \(Num.int(Int(p.intervalMin))) دقيقة بيوصل باص سيّاح. \(welcome) وبتصير المحطّات \(Num.mult(p.waveMult)) لمدّة \(Num.dur(p.waveSec))."
        case .nightMarket:
            return "من الساعة \(Num.int(p.startHour)) لـ \(Num.int(p.endHour)) بالليل، محطّات السوق \(Num.mult(p.nightMult))، حتى والبسطة مسكّرة."
        case .portShipments:
            return "لما ترسى الباخرة، عبّي الشحنة من \(stationName(p.station)) وحمّلها: بتاخد دخل \(Num.dur(p.rewardMin * 60))."
        case .deliveryRuns:
            let send = mf("ابعت", "ابعتي")
            return "بتوصل طلبات دليفري. \(send) الموتور وبيرجع بدخل \(Num.dur(p.rewardMin * 60))."
        case .weatherSwing:
            return "كل يوم طقس جديد: بالشوب البارد بيبيع \(Num.mult(p.mult))، وبالبرد السخن \(Num.mult(p.mult))."
        case .vipLounge:
            let grow = mf("كبّر", "كبّري")
            return "كبار الزوار بيجوا كتير. \(grow) \(stationName(p.loungeStation)) عشان تخدمهم وتاخد بقشيش كبير."
        case .unknown:
            return ""
        }
    }
}
