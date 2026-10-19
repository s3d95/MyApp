import SwiftUI

/// Rules and twists of a side kitchen, one compact row each, with live state and actions.
struct SideTwistStrip: View {
    @EnvironmentObject var store: GameStore
    let ref: SideRef

    var body: some View {
        let rules = store.sideRules(ref)
        let twists = store.sideTwists(ref)
        if !rules.isEmpty || !twists.isEmpty {
            VStack(spacing: 4) {
                ForEach(rules, id: \.self) { rule in
                    if rule == "goldenHour" {
                        GoldenHourRow(ref: ref)
                    } else {
                        SideInfoRow(art: store.ruleArt(rule), title: "شرط الطلبية", status: store.ruleName(rule))
                    }
                }
                ForEach(Array(twists.enumerated()), id: \.offset) { _, d in
                    SideTwistRow(ref: ref, def: d)
                }
            }
        }
    }
}

private struct SideInfoRow<Action: View>: View {
    let art: String
    let title: String
    let status: String
    var highlight = false
    let action: Action

    init(art: String, title: String, status: String, highlight: Bool = false, @ViewBuilder action: () -> Action) {
        self.art = art
        self.title = title
        self.status = status
        self.highlight = highlight
        self.action = action()
    }

    var body: some View {
        HStack(spacing: 8) {
            ArtIcon(art, size: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
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
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(highlight ? Brand.red.opacity(0.45) : Color.black.opacity(0.38)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(highlight ? Brand.gold : Brand.teal.opacity(0.6), lineWidth: 1))
    }
}

extension SideInfoRow where Action == EmptyView {
    init(art: String, title: String, status: String, highlight: Bool = false) {
        self.init(art: art, title: title, status: status, highlight: highlight) { EmptyView() }
    }
}

private struct GoldenHourRow: View {
    @EnvironmentObject var store: GameStore
    let ref: SideRef

    var body: some View {
        let left = store.sideFrenzyLeft(ref, at: store.now())
        SideInfoRow(art: "ui_fire", title: "عجقة كل ساعة", status: status(left), highlight: left > 0)
            .pulse(left > 0, amount: 0.03)
    }

    private func status(_ left: Double) -> String {
        if left > 0 {
            let mult = Num.mult(store.econ.boosts.frenzyMult)
            return "العجقة شغّالة! الدخل " + mult + " · باقي " + Num.dur(left)
        }
        let next = Num.dur(store.sideNextFrenzyIn(at: store.now()))
        return "العجقة الجاية بعد " + next + " · خلّي المطبخ مفتوح"
    }
}

private struct SideTwistRow: View {
    @EnvironmentObject var store: GameStore
    let ref: SideRef
    let def: TwistDef

    var body: some View {
        SideInfoRow(art: store.twistArt(def.type), title: store.twistName(def.type), status: status) {
            action
        }
    }

    private var p: TwistParams { def.params }

    private var status: String {
        let tNow = store.now()
        let k = store.side(ref)
        switch def.type {
        case .productionChain:
            let a = store.sideStationName(ref, p.inputStation)
            let b = store.sideStationName(ref, p.outputStation)
            let sup = k.map { store.sideChainSupply($0, ref, p) } ?? 0
            if sup >= 0.999 { return a + " بيموّن " + b + ": " + Num.mult(p.outputMult) }
            if sup <= 0 { return "شغّل " + a + " عشان يموّن " + b }
            return "التموين " + Num.percent(sup) + " · كبّر " + a
        case .ovenTiming:
            return "لما تطلع صينيّة " + store.sideStationName(ref, p.station) + " دقّ عليها: " + Num.mult(p.perfectMult)
        case .busWaves:
            if store.sideBusWaiting(ref) { return "الباص ناطر! استقبله" }
            if let left = k?.twist.busWaveLeft, left > 0 { return "السيّاح عندك! " + Num.mult(p.waveMult) + " · " + Num.dur(left) }
            return "الباص الجاي بعد " + Num.dur(store.sideNextBusIn(ref))
        case .nightMarket:
            if store.isNight(p, at: tNow) { return "سوق الليل شغّال! " + Num.mult(p.nightMult) }
            return "من الساعة " + Num.int(p.startHour) + " لـ " + Num.int(p.endHour) + ": " + Num.mult(p.nightMult)
        case .portShipments:
            guard let st = store.sidePortStatus(ref, p, at: tNow), let kk = k else { return "" }
            if st.docked && kk.twist.portDockId == st.dockId {
                if kk.twist.portLoaded { return "انشحنت! الباخرة بتروح بعد " + Num.dur(st.leavesIn) }
                let f = kk.twist.portUnits / max(1, kk.twist.portTarget)
                return "عبّي من " + store.sideStationName(ref, p.station) + ": " + Num.percent(min(1, f)) + " · بتروح بعد " + Num.dur(st.leavesIn)
            }
            return "الباخرة الجاية بعد " + Num.dur(st.nextIn)
        case .weatherSwing:
            guard let w = store.sideWeather(ref, day: Clock.gameDay(tNow)) else { return "" }
            let names = store.sideWeatherKeys(p, w).compactMap { key -> String? in
                let n = store.sideStationName(ref, key)
                return n.isEmpty ? nil : n
            }
            if names.isEmpty { return "اليوم " + w.name + " · ما في عروض طقس" }
            return "اليوم " + w.name + ": " + names.joined(separator: "، ") + " " + Num.mult(p.mult)
        default:
            return ""
        }
    }

    @ViewBuilder
    private var action: some View {
        switch def.type {
        case .busWaves:
            if store.sideBusWaiting(ref) {
                smallButton("استقبل", color: .green, anchor: "side.twist.bus") { store.welcomeSideBus(ref) }
            }
        case .portShipments:
            if store.sidePortReady(ref) {
                smallButton("حمّل الشحنة", color: .gold, anchor: "side.twist.port") { store.loadSideShipment(ref) }
            } else {
                portBar
            }
        case .weatherSwing:
            if let w = store.sideWeather(ref, day: Clock.gameDay(store.now())) {
                ArtIcon(w.art, size: 28)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var portBar: some View {
        if let k = store.side(ref), let st = store.sidePortStatus(ref, p, at: store.now()), st.docked,
           k.twist.portDockId == st.dockId, !k.twist.portLoaded {
            FancyBar(value: k.twist.portUnits / max(1, k.twist.portTarget), tint: Brand.teal, height: 12)
                .frame(width: 64)
                .fxAnchor("side.twist.port")
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

/// Small icons on a contract card: its twists and rules, so the player knows before starting.
struct SideFeatureTags: View {
    @EnvironmentObject var store: GameStore
    let def: ContractDef

    var body: some View {
        let twists = def.twists.filter { GameStore.sideTwistTypes.contains($0.type) }
        if !twists.isEmpty || !def.rules.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(twists.enumerated()), id: \.offset) { _, d in
                    tag(art: store.twistArt(d.type), text: store.twistName(d.type), color: Brand.teal)
                }
                ForEach(def.rules, id: \.self) { rule in
                    tag(art: store.ruleArt(rule), text: shortRule(rule), color: Brand.red)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func shortRule(_ rule: String) -> String {
        switch rule {
        case "noManagers": return "بدون معلّمين"
        case "noUpgrades": return "بدون ترقيات"
        case "chefsOff": return "بدون طبّاخين"
        case "fastCheap": return "سريع ورخيص"
        case "goldenHour": return "عجقة كل ساعة"
        case "oneStation": return "محطّة وحدة"
        default: return rule
        }
    }

    private func tag(art: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            ArtIcon(art, size: 16, shadow: false)
            Text(text)
                .font(.body(10, bold: true))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(color.opacity(0.55)))
        .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}
