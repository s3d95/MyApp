import SwiftUI

/// One compact row per city twist with its live state and action (GDD 3.6 widgets).
struct TwistStrip: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(store.city.twists.enumerated()), id: \.offset) { k, d in
                TwistRow(def: d, chainIndex: chainIndex(k))
            }
        }
    }

    private func chainIndex(_ k: Int) -> Int {
        store.city.twists.prefix(k).filter { $0.type == .productionChain }.count
    }
}

struct TwistRow: View {
    @EnvironmentObject var store: GameStore
    let def: TwistDef
    let chainIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ArtIcon(store.twistArt(def.type), size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.twistName(def.type))
                    .font(.game(12, .black))
                    .foregroundColor(Brand.goldLight)
                Text(status)
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            action
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.38)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Brand.teal.opacity(0.6), lineWidth: 1))
        .onTapGesture {
            Feedback.play(.t0)
            store.sheet = .twist
        }
    }

    private var p: TwistParams { def.params }

    private var status: String {
        let t = store.now()
        switch def.type {
        case .productionChain:
            let sigma = chainIndex < store.chainSigma.count ? store.chainSigma[chainIndex] : 0
            let stock = chainIndex < store.s.city.twist.chainStock.count ? store.s.city.twist.chainStock[chainIndex] : 0
            if sigma >= 0.999 { return "المخزون " + Num.big(stock) + " · " + store.stationName(p.outputStation) + " " + Num.mult(p.outputMult) }
            if sigma <= 0 { return "شغّل " + store.stationName(p.inputStation) + " عشان يموّن " + store.stationName(p.outputStation) }
            return "ناقص " + Num.percent(1 - sigma) + " · كبّر " + store.stationName(p.inputStation)
        case .ovenTiming:
            return "دقّ عالصينيّة لما تلمع · مظبوطة: " + Num.big(store.s.city.counters["ovenPerfects"] ?? 0)
        case .busWaves:
            if store.busWaiting { return "الباص ناطر! باقي " + Num.dur(store.busSecondsLeft) }
            if store.s.city.twist.busWaveLeft > 0 { return "السيّاح عندك! " + Num.mult(p.waveMult) + " · " + Num.dur(store.s.city.twist.busWaveLeft) }
            return "الباص الجاي بعد " + Num.dur(store.nextBusIn())
        case .nightMarket:
            if store.isNight(p, at: t) { return "سوق الليل شغّال! " + Num.mult(p.nightMult) }
            return "بيفتح الساعة " + Num.int(p.startHour) + " لـ " + Num.int(p.endHour)
        case .portShipments:
            guard let st = store.portStatus(at: t) else { return "" }
            if st.docked && store.s.city.twist.portDockId == st.dockId {
                if store.s.city.twist.portLoaded { return "انشحنت! الباخرة بتروح بعد " + Num.dur(st.leavesIn) }
                let f = store.s.city.twist.portUnits / max(1, store.s.city.twist.portTarget)
                return "الشحنة " + Num.percent(min(1, f)) + " · بتروح بعد " + Num.dur(st.leavesIn)
            }
            return "الباخرة الجاية بعد " + Num.dur(st.nextIn)
        case .deliveryRuns:
            return "طلبات: " + Num.int(store.s.city.twist.deliveryQueue) + " · موتورات: "
                + Num.int(store.scootersFree) + "/" + Num.int(store.scootersTotal)
        case .weatherSwing:
            guard let w = store.cityWeather(day: Clock.gameDay(t)) else { return "" }
            let names = store.weatherStations(w).map { store.t(store.city.stations[$0].name) }
            if names.isEmpty { return "اليوم " + w.name + " · ما في عروض طقس" }
            return "اليوم " + w.name + ": " + names.joined(separator: "، ") + " " + Num.mult(p.mult)
        case .vipLounge:
            let lv = store.loungeIndex.map { store.s.city.stations[$0].level } ?? 0
            let tier = min(3, lv / max(1, p.levelPerTier))
            return store.stationName(p.loungeStation) + " بتخدم VIP درجة " + Num.int(tier) + " من 3"
        case .unknown:
            return ""
        }
    }

    @ViewBuilder
    private var action: some View {
        switch def.type {
        case .busWaves:
            if store.busWaiting {
                smallButton("استقبل", color: .green, anchor: "twist.bus") { store.welcomeBus() }
            }
        case .portShipments:
            if store.portReady {
                smallButton("حمّل الشحنة", color: .gold, anchor: "twist.port") { store.loadShipment() }
            } else {
                portBar
            }
        case .deliveryRuns:
            let ok = store.s.city.twist.deliveryQueue > 0 && store.scootersFree > 0
            smallButton("ابعت", color: ok ? .green : .gray, anchor: "twist.delivery") { store.sendDelivery() }
        case .weatherSwing:
            if let w = store.cityWeather(day: Clock.gameDay(store.now())) {
                ArtIcon(w.art, size: 30)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var portBar: some View {
        if let st = store.portStatus(at: store.now()), st.docked, store.s.city.twist.portDockId == st.dockId, !store.s.city.twist.portLoaded {
            FancyBar(value: store.s.city.twist.portUnits / max(1, store.s.city.twist.portTarget), tint: Brand.teal, height: 12)
                .frame(width: 70)
                .fxAnchor("twist.port")
        }
    }

    private func smallButton(_ title: String, color: ChunkyColor, anchor: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.game(13, .black))
                .lineLimit(1)
        }
        .buttonStyle(ChunkyStyle(color: color, radius: 12, depth: 3))
        .fixedSize()
        .fxAnchor(anchor)
    }
}
