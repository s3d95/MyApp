import SwiftUI

/// The shop (GDD S17). Every price is in gold the player earned; nothing costs real money.
struct ShopScreen: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ShopSection(title: "الصناديق", art: "ui_gift") {
                    HStack(spacing: 8) {
                        ForEach(store.cat.chefs.chests) { def in
                            ShopChestCard(def: def)
                        }
                    }
                }
                ShopSection(title: "بسطة الطبّاخين", art: "ppl_cook") {
                    Text("عروض اليوم بتتغيّر كل يوم الساعة 4 الصبح")
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        ForEach(store.stallOffers) { o in
                            StallCard(offer: o)
                        }
                    }
                }
                ShopSection(title: "رزم وقت", art: "ui_hourglass") {
                    TimeWarpRow()
                }
                ShopSection(title: "ديكور البسطة", art: "ui_artist_palette") {
                    Text("مظلّات ويافطات وإضاءة للبسطة… جاي قريباً")
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

struct ShopSection<Content: View>: View {
    let title: String
    let art: String
    let content: Content

    init(title: String, art: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.art = art
        self.content = content()
    }

    var body: some View {
        WoodPanel(padding: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ArtIcon(art, size: 26)
                    Text(title)
                        .font(.game(17, .black))
                        .foregroundColor(Brand.goldLight)
                    Spacer()
                }
                content
            }
        }
    }
}

struct ShopChestCard: View {
    @EnvironmentObject var store: GameStore
    let def: ChestDef

    var body: some View {
        VStack(spacing: 6) {
            ChestArt(kind: def.id, size: 64)
            Text(store.t(def.name))
                .font(.game(13, .black))
                .foregroundColor(Brand.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(Num.int(def.cards) + " كرت")
                .font(.body(10, bold: true))
                .foregroundColor(Brand.cream.opacity(0.7))
            ChunkyButton(title: Num.int(def.price), icon: "ui_coin", color: store.s.wallet.gold >= def.price ? .gold : .gray,
                         sound: nil) {
                store.buyChest(def.id)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
    }
}

struct StallCard: View {
    @EnvironmentObject var store: GameStore
    let offer: StallOffer

    var body: some View {
        let c = store.cat.chef(offer.chefId)
        let bought = store.stallBought(offer.slot)
        VStack(spacing: 5) {
            RarityFrame(rarity: offer.rarity, art: c?.art ?? "ppl_cook", size: 58)
            Text(c.map { store.t($0.name) } ?? "")
                .font(.game(11, .black))
                .foregroundColor(Brand.cream)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .frame(height: 28)
            Text("×" + Num.int(offer.cards) + " كرت")
                .font(.game(12, .black))
                .foregroundColor(offer.rarity.color)
            if bought {
                Tag(text: "اشتريته", color: Brand.parsley, textColor: .white)
                    .padding(.vertical, 8)
            } else {
                ChunkyButton(title: Num.int(offer.price), icon: "ui_coin", color: store.s.wallet.gold >= offer.price ? .gold : .gray,
                             sound: nil) {
                    store.buyStall(offer)
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
        .fxAnchor("stall.\(offer.slot)")
    }
}

struct TimeWarpRow: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        if store.unlocked("timeWarpShop") {
            VStack(alignment: .leading, spacing: 6) {
                Text("دخل المعلّمين فوراً للمدينة الحالية · باقي " + Num.int(store.warpBuysLeft) + " اليوم")
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.75))
                HStack(spacing: 8) {
                    ChunkyButton(title: "ساعة", icon: "ui_coin", subtitle: "10", color: canBuy(10) ? .purple : .gray, sound: nil) {
                        store.buyTimeWarp(hours: 1, price: 10)
                    }
                    ChunkyButton(title: "4 ساعات", icon: "ui_coin", subtitle: "36", color: canBuy(36) ? .purple : .gray, sound: nil) {
                        store.buyTimeWarp(hours: 4, price: 36)
                    }
                }
            }
        } else {
            Text("بتفتح بمستوى " + Num.int(store.unlockLevel("timeWarpShop")))
                .font(.body(12, bold: true))
                .foregroundColor(Brand.cream.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func canBuy(_ price: Int) -> Bool { store.s.wallet.gold >= price && store.warpBuysLeft > 0 }
}

extension GameStore {
    var warpBuysLeft: Int {
        let used = s.wallet.warpDay == gameDay ? s.wallet.warpBuys : 0
        return max(0, 3 - used)
    }

    func buyTimeWarp(hours: Int, price: Int) {
        guard unlocked("timeWarpShop"), warpBuysLeft > 0, s.wallet.gold >= price else {
            Feedback.error()
            return
        }
        if s.wallet.warpDay != gameDay {
            s.wallet.warpDay = gameDay
            s.wallet.warpBuys = 0
        }
        s.wallet.warpBuys += 1
        s.wallet.gold -= price
        s.wallet.timeWarps.insert(hours * 60, at: 0)
        useTimeWarp(at: 0)
    }
}
