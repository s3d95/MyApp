import SwiftUI

/// رحلات التوريد (GDD S19) with the heritage box (S20) as its second page.
struct SupplySheet: View {
    @EnvironmentObject var store: GameStore
    @State private var page = 0
    @State private var picked: String? = nil

    var body: some View {
        GameModal(title: "رحلات التوريد", onClose: { store.sheet = nil }) {
            SegmentBar(titles: ["الكراج", "صندوق التراث"], selection: $page,
                       dots: [store.runsReady > 0, false])
                .fxAnchor("supply.segment.heritage")
            ScrollView(showsIndicators: false) {
                if page == 0 { garage } else { HeritageBox() }
            }
            .frame(maxHeight: 440)
        }
    }

    private var garage: some View {
        VStack(spacing: 8) {
            ForEach(store.s.supply.slots, id: \.runId) { sl in
                RunRow(slot: sl)
            }
            if store.freeSupplySlots > 0 {
                Text(store.mf("ابعت رحلة: اختار سيّارة", "ابعتي رحلة: اختاري سيّارة") + " (" + Num.int(store.freeSupplySlots) + " كراج فاضي)")
                    .font(.game(13, .black))
                    .foregroundColor(Brand.goldLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(store.vx.vehicles) { v in
                    VehicleRow(vehicle: v, picked: $picked)
                }
            } else {
                Text("كل الكراجات مشغولة. كراج جديد بمستوى " + Num.int(nextSlotLevel))
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.75))
            }
        }
    }

    private var nextSlotLevel: Int {
        store.vx.slotsByLevel.first { $0.level > store.level }?.level ?? 0
    }
}

private struct RunRow: View {
    @EnvironmentObject var store: GameStore
    let slot: SupplySlot

    var body: some View {
        let v = store.cat.vehicle(slot.vehicleId)
        let ready = store.now() >= slot.endAt
        HStack(spacing: 8) {
            ArtIcon(v?.art ?? "veh_truck", size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(v.map { store.t($0.name) } ?? "")
                    .font(.game(13, .black))
                    .foregroundColor(Brand.cream)
                if ready {
                    Text("رجعت ومعها إشي حلو!")
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.parsley)
                } else {
                    FancyBar(value: progress, tint: Brand.teal, height: 11, label: Num.dur(slot.endAt - store.now()))
                }
            }
            Spacer(minLength: 4)
            if ready {
                ChunkyButton(title: "افتح", color: .green, sound: nil) { store.claimRun(slot.runId) }
                    .frame(width: 76)
            } else {
                ChunkyButton(title: "رجّعها", icon: "ui_coin", subtitle: Num.int(store.rushRunCost(slot)),
                             color: store.s.wallet.gold >= store.rushRunCost(slot) ? .gold : .gray, sound: nil) {
                    store.rushRun(slot.runId)
                }
                .frame(width: 92)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Brand.cream.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.teal.opacity(0.7), lineWidth: 1.5))
    }

    private var progress: Double {
        let total = max(1, slot.endAt - slot.sentAt)
        return min(1, max(0, (store.now() - slot.sentAt) / total))
    }
}

private struct VehicleRow: View {
    @EnvironmentObject var store: GameStore
    let vehicle: VehicleDef
    @Binding var picked: String?

    var body: some View {
        let open = store.vehicleUnlocked(vehicle)
        let out = store.vehicleOut(vehicle.id)
        VStack(spacing: 6) {
            Button {
                Feedback.play(.t0)
                if open && !out {
                    picked = picked == vehicle.id ? nil : vehicle.id
                } else if !open {
                    store.showToast(lockText, art: "ui_locked")
                }
            } label: {
                HStack(spacing: 8) {
                    ArtIcon(vehicle.art, size: 42)
                        .saturation(open ? 1 : 0)
                        .opacity(open ? 1 : 0.4)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(store.t(vehicle.name))
                                .font(.game(14, .black))
                                .foregroundColor(Brand.cream)
                            ForEach(0..<store.vehicleStars(vehicle.id), id: \.self) { _ in
                                ArtIcon("ui_star", size: 12, shadow: false)
                            }
                        }
                        Text(open ? (out ? "بالطريق…" : "رحلات: " + Num.int(store.launches(vehicle.id))) : lockText)
                            .font(.body(11, bold: true))
                            .foregroundColor(open ? Brand.cream.opacity(0.7) : Brand.glow)
                    }
                    Spacer(minLength: 0)
                    if open && !out {
                        Image(systemName: picked == vehicle.id ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Brand.goldLight)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
            }
            .buttonStyle(PressScaleStyle())
            .fxAnchor("supply.vehicle." + vehicle.id)
            if picked == vehicle.id {
                HStack(spacing: 6) {
                    ForEach(0..<min(3, vehicle.durationsMin.count), id: \.self) { k in
                        durationCard(k)
                    }
                }
            }
        }
    }

    private func durationCard(_ k: Int) -> some View {
        Button {
            store.sendRun(vehicle.id, durationIdx: k)
            picked = nil
        } label: {
            VStack(spacing: 3) {
                Text(["قصيرة", "متوسّطة", "طويلة"][k])
                    .font(.game(12, .black))
                    .foregroundColor(Brand.outline)
                Text(Num.dur(store.runDuration(vehicle, k)))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.outline)
                Text(Num.int(store.runRolls(vehicle, k)) + " غنائم")
                    .font(.body(10, bold: true))
                    .foregroundColor(Brand.outline.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Brand.titleFill))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.outline, lineWidth: 1.5))
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("supply.duration.\(k)")
    }

    private var lockText: String {
        if store.level < vehicle.unlockLevel { return "بتفتح بمستوى " + Num.int(vehicle.unlockLevel) }
        if let a = vehicle.afterVehicle, let av = store.cat.vehicle(a) {
            return "ابعت " + store.t(av.name) + " " + Num.int(vehicle.afterLaunches) + " مرّات"
        }
        return ""
    }
}

/// صندوق التراث: 8 shelves of 4 items with levels and set bonuses.
struct HeritageBox: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("قطع: " + Num.frac(store.uniqueItems, store.hx.items.count))
                    .font(.game(13, .black))
                    .foregroundColor(Brand.goldLight)
                Spacer()
                if store.level >= store.hx.craftUnlockLevel {
                    HStack(spacing: 3) {
                        ArtIcon("ui_hammer_and_wrench", size: 18, shadow: false)
                        Text(Num.int(store.s.supply.craftPoints))
                            .font(.game(13, .black))
                            .foregroundColor(Brand.cream)
                    }
                }
            }
            ForEach(store.hx.sets) { set in
                SetShelf(set: set)
            }
        }
    }
}

private struct SetShelf: View {
    @EnvironmentObject var store: GameStore
    let set: HeritageSetDef

    var body: some View {
        let done = store.setComplete(set)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ArtIcon(set.art, size: 24)
                Text(store.t(set.name))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.cream)
                Spacer()
                Text(store.bonusText(set.bonusType, done ? store.setStrength(set) : set.bonusBase))
                    .font(.body(10, bold: true))
                    .foregroundColor(done ? Brand.parsley : Brand.cream.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 6) {
                ForEach(set.itemIds, id: \.self) { id in
                    ItemTile(itemId: id)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(done ? Brand.gold : Color.clear, lineWidth: 1.5))
    }
}

private struct ItemTile: View {
    @EnvironmentObject var store: GameStore
    let itemId: String

    var body: some View {
        let item = store.cat.item(itemId)
        let lv = store.itemLevel(itemId)
        Button {
            guard let it = item else { return }
            if store.level >= store.hx.craftUnlockLevel && store.s.supply.craftPoints >= store.craftCost(it) {
                store.craft(itemId)
            } else {
                store.showToast(store.t(it.name) + ": " + store.t(it.desc), art: it.art)
            }
        } label: {
            VStack(spacing: 2) {
                RarityFrame(rarity: item?.rarity ?? .common, art: item?.art ?? "ui_old_key", size: 50, dimmed: lv == 0)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { k in
                        Circle()
                            .fill(k < lv ? Brand.goldLight : Color.black.opacity(0.4))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressScaleStyle())
        .fxAnchor("heritage." + itemId)
    }
}

/// Reveal for a returned supply run (T1, T2 for epic or better).
struct SupplyRevealModal: View {
    @EnvironmentObject var store: GameStore
    let result: SupplyResult

    var body: some View {
        RewardReveal(title: "رجعت الرحلة!", subtitle: store.cat.vehicle(result.vehicleId).map { store.t($0.name) },
                     items: items, buttonTitle: "خذ") {
            store.closeModal()
        }
    }

    private var items: [RewardItem] {
        var list = result.loot.prefix(5).map {
            RewardItem(art: $0.art, amount: $0.amount > 1 ? "×" + Num.int($0.amount) : ($0.isNew ? "جديد!" : "+1"),
                       caption: $0.title, glow: $0.rarity.color)
        }
        list.append(RewardItem(art: "ui_sparkles", amount: "+" + Num.int(result.xp), caption: "خبرة"))
        return Array(list)
    }
}
