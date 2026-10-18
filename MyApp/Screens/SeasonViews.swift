import SwiftUI

/// الموسم (GDD S15): 50 free tiers over 42 days.
struct SeasonView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        if store.unlocked("season") {
            content
        } else {
            TeaserLine(text: "الموسم بيفتح بمستوى " + Num.int(store.unlockLevel("season")) + ": 50 درجة جوايز ببلاش كل 6 أسابيع",
                       art: "ui_ticket")
        }
    }

    private var content: some View {
        let per = Double(max(1, store.sx.pointsPerTier))
        let tier = store.seasonTier
        let into = store.s.season.points - Double(tier) * per
        let done = tier >= store.sx.tiers.count
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                ArtIcon(store.seasonTheme?.art ?? "ui_calendar", size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.seasonTheme.map { store.t($0.name) } ?? "الموسم")
                        .font(.game(17, .black))
                        .foregroundColor(Brand.goldLight)
                    Text("درجة " + Num.frac(tier, store.sx.tiers.count) + " · باقي " + Num.int(store.seasonDaysLeft) + " يوم")
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.8))
                    FancyBar(value: done ? 1 : into / per, tint: Brand.teal, height: 12, label: Num.frac(Int(into), Int(per)))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.32)))
            ForEach(store.sx.tiers, id: \.tier) { t in
                SeasonTierRow(tier: t.tier)
            }
        }
    }
}

private struct SeasonTierRow: View {
    @EnvironmentObject var store: GameStore
    let tier: Int

    var body: some View {
        let reached = tier <= store.seasonTier
        let claimed = store.s.season.claimed.contains(tier)
        let rewards = store.seasonRewards(tier)
        let big = tier % 25 == 0
        HStack(spacing: 8) {
            Text(Num.int(tier))
                .font(.game(15, .black))
                .foregroundColor(reached ? Brand.outline : Brand.cream.opacity(0.6))
                .frame(width: 34, height: 34)
                .background(Circle().fill(reached ? AnyShapeStyle(Brand.titleFill) : AnyShapeStyle(Color.black.opacity(0.35))))
            ForEach(Array(rewards.enumerated()), id: \.offset) { _, r in
                HStack(spacing: 2) {
                    ArtIcon(SeasonTierRow.art(r), size: 26)
                    Text(SeasonTierRow.amount(r))
                        .font(.game(11, .black))
                        .foregroundColor(Brand.goldLight)
                }
            }
            Spacer(minLength: 4)
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Brand.parsley)
            } else if reached {
                ChunkyButton(title: "خذ", color: .green, sound: nil) { store.claimSeason(tier) }
                    .frame(width: 64)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(Brand.cream.opacity(0.4))
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(big ? 0.45 : 0.28)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(big ? Brand.gold : Color.clear, lineWidth: 1.5))
        .fxAnchor("season.tier.\(tier)")
    }

    static func art(_ r: Reward) -> String {
        switch r.type {
        case "gold": return "ui_coin"
        case "chest": return "ui_gift"
        case "tickets": return "ui_admission_tickets"
        case "timeWarpMin": return "ui_hourglass"
        case "chefCards": return "ppl_cook"
        case "heritageItem", "heritageCase": return "ui_old_key"
        case "freezes": return "ui_snowflake"
        case "cosmetic": return "ui_artist_palette"
        default: return "ui_gift"
        }
    }

    static func amount(_ r: Reward) -> String {
        if r.type == "timeWarpMin" { return Num.dur(r.amount * 60) }
        if r.type == "cosmetic" { return "" }
        return "×" + Num.int(Int(r.amount))
    }
}

/// الإنجازات (GDD S16): families with five tiers each, counted retroactively.
struct AchievementsView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 6) {
            ForEach(store.ax.families) { f in
                AchRow(family: f)
            }
        }
    }
}

private struct AchRow: View {
    @EnvironmentObject var store: GameStore
    let family: AchFamilyDef

    var body: some View {
        let t = store.achTier(family)
        let ready = store.achReady(family)
        let target = t < family.tiers.count ? family.tiers[t] : (family.tiers.last ?? 1)
        let value = store.statValue(family.metric)
        HStack(spacing: 8) {
            ArtIcon(family.art, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(store.t(family.name))
                        .font(.game(13, .black))
                        .foregroundColor(Brand.cream)
                    stars(t)
                }
                Text(store.t(family.desc).replacingOccurrences(of: "{n}", with: Num.big(target)))
                    .font(.body(10, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if t < family.tiers.count {
                    FancyBar(value: min(1, value / max(1, target)), tint: ready ? Brand.parsley : Brand.gold, height: 9)
                }
            }
            Spacer(minLength: 4)
            if ready {
                ChunkyButton(title: "خذ", color: .green, sound: nil) { store.claimAch(family) }
                    .frame(width: 60)
            } else if t >= family.tiers.count {
                ArtIcon("ui_trophy", size: 26)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
        .fxAnchor("ach." + family.id)
    }

    private func stars(_ t: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { k in
                Image(systemName: "star.fill")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(k < t ? Brand.gold : Color.black.opacity(0.4))
            }
        }
    }
}

struct TeaserLine: View {
    let text: String
    let art: String

    var body: some View {
        HStack(spacing: 10) {
            ArtIcon(art, size: 40)
            Text(text)
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.3)))
    }
}
