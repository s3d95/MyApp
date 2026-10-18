import SwiftUI

/// الدوري (GDD S24): 30 rows, green promotion zone, red demotion zone. The other chains are fictional.
struct LeagueSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let rows = store.leagueRows
        let tier = store.leagueTier
        let promote = store.s.league.trial ? 15 : (tier?.promote ?? 0)
        let demote = store.s.league.tier > 1 ? (tier?.demote ?? 0) : 0
        GameModal(title: "الدوري", onClose: { store.sheet = nil }) {
            HStack(spacing: 10) {
                ArtIcon(tier?.art ?? "bld_tent", size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text("درجة " + Num.int(store.s.league.tier) + ": " + store.tierName(store.s.league.tier))
                        .font(.game(17, .black))
                        .foregroundColor(Brand.goldLight)
                    Text("بيخلص بعد " + Num.dur(store.leagueTimeLeft) + (store.s.league.trial ? " · أسبوع تجريبي" : ""))
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.75))
                    Text("سمعتك: " + Num.int(store.leagueScore) + " · المركز " + Num.int(store.leagueRank))
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream)
                }
                Spacer(minLength: 0)
            }
            Text("السمعة بتيجي من الطلبات والأهداف والزباين والرحلات. المطاعم التانية وهمية للعب")
                .font(.body(10))
                .foregroundColor(Brand.cream.opacity(0.6))
                .multilineTextAlignment(.center)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { k, row in
                        LeagueRowView(rank: k + 1, row: row, zone: zone(k + 1, promote: promote, demote: demote, count: rows.count))
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    private func zone(_ rank: Int, promote: Int, demote: Int, count: Int) -> Int {
        if rank <= promote { return 1 }
        if demote > 0 && rank > count - demote { return -1 }
        return 0
    }
}

private struct LeagueRowView: View {
    let rank: Int
    let row: LeagueRow
    let zone: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(Num.int(rank))
                .font(.game(13, .black))
                .foregroundColor(Brand.cream)
                .frame(width: 26)
            ArtIcon(row.art, size: 26)
            Text(row.name)
                .font(.game(13, row.isPlayer ? .black : .bold))
                .foregroundColor(row.isPlayer ? Brand.outline : Brand.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(Num.int(row.score))
                .font(.game(13, .black).monospacedDigit())
                .foregroundColor(row.isPlayer ? Brand.outline : Brand.goldLight)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 8).fill(background))
    }

    private var background: Color {
        if row.isPlayer { return Brand.goldLight }
        switch zone {
        case 1: return Brand.parsley.opacity(0.25)
        case -1: return Brand.red.opacity(0.25)
        default: return Color.black.opacity(0.25)
        }
    }
}

/// Live-ops rail on the leading side of the stage (league, and later contracts, venue, season).
struct RightRail: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 4) {
            if store.unlocked("league") {
                RailButton(icon: store.leagueTier?.art ?? "ui_trophy", label: "#" + Num.int(store.leagueRank), dot: false) {
                    store.sheet = .league
                }
                .fxAnchor("rail.league")
            }
            if store.unlocked("contracts") {
                RailButton(icon: "ui_clipboard", label: contractsLabel, dot: store.contractsDot) {
                    store.sheet = .contracts
                }
                .fxAnchor("rail.contracts")
            }
            if store.unlocked("events") {
                RailButton(icon: eventArt, label: Num.dur(store.eventCountdown), dot: store.s.event.kitchen != nil) {
                    if store.s.event.kitchen != nil {
                        store.sheet = .side(.event)
                    } else {
                        store.showToast("مهرجان الويكند بيبلّش الخميس", art: "ui_party_popper")
                    }
                }
                .fxAnchor("rail.event")
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 34)
    }

    private var contractsLabel: String {
        if let k = store.s.contracts.active.first { return Num.frac(k.reached, 3) }
        return "طلبيات"
    }

    private var eventArt: String {
        if let th = store.cat.theme(store.s.event.themeId), store.s.event.kitchen != nil { return th.art }
        return store.themeFor(week: store.weekNum)?.art ?? "ui_party_popper"
    }
}
