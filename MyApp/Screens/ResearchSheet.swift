import SwiftUI

/// دفتر ستّي (GDD S18): slot strip on top, four notebook pages of nodes.
struct ResearchSheet: View {
    @EnvironmentObject var store: GameStore
    @State private var page = "kitchen"

    private let pages = ["kitchen", "customers", "vault", "empire"]

    var body: some View {
        GameModal(title: "دفتر ستّي", onClose: { store.sheet = nil }) {
            slotStrip
            SegmentBar(titles: pages.map { GameStore.branchName($0) }, selection: Binding(
                get: { pages.firstIndex(of: page) ?? 0 },
                set: { page = pages[$0] }))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(store.cat.research.nodes.filter { $0.branch == page }) { n in
                        NodeRow(node: n)
                    }
                }
            }
            .frame(maxHeight: 360)
        }
    }

    private var slotStrip: some View {
        VStack(spacing: 6) {
            ForEach(store.s.research.slots, id: \.nodeId) { sl in
                SlotStrip(slot: sl)
            }
            if store.freeResearchSlots > 0 {
                Text(store.mf("الدفتر فاضي، اختار بحث من تحت", "الدفتر فاضي، اختاري بحث من تحت"))
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.goldLight)
            }
        }
    }
}

private struct SlotStrip: View {
    @EnvironmentObject var store: GameStore
    let slot: ResearchSlot

    var body: some View {
        let n = store.cat.node(slot.nodeId)
        HStack(spacing: 8) {
            ArtIcon(n?.art ?? "ui_notebook", size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text((n.map { store.t($0.name) } ?? "") + " · مستوى " + Num.int(slot.level))
                    .font(.game(13, .black))
                    .foregroundColor(Brand.cream)
                    .lineLimit(1)
                if slot.applied {
                    Text("خلص البحث!")
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.parsley)
                } else {
                    FancyBar(value: progress, tint: Brand.teal, height: 11, label: Num.dur(slot.endAt - store.now()))
                }
            }
            Spacer(minLength: 4)
            if slot.applied {
                ChunkyButton(title: "خذ", color: .green, sound: nil) { store.claimResearch(slot.nodeId) }
                    .frame(width: 70)
                    .fxAnchor("research.slot." + slot.nodeId)
            } else {
                ChunkyButton(title: "خلّصها", icon: "ui_coin", subtitle: Num.int(store.researchRushCost(slot)),
                             color: store.s.wallet.gold >= store.researchRushCost(slot) ? .gold : .gray, sound: nil) {
                    store.rushResearch(slot.nodeId)
                }
                .frame(width: 92)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Brand.cream.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.teal.opacity(0.7), lineWidth: 1.5))
    }

    private var progress: Double {
        let total = max(1, slot.endAt - slot.startAt)
        return min(1, max(0, (store.now() - slot.startAt) / total))
    }
}

private struct NodeRow: View {
    @EnvironmentObject var store: GameStore
    let node: ResearchNodeDef

    var body: some View {
        let lv = store.researchLevel(node.id)
        let open = store.nodeOpen(node)
        let maxed = lv >= node.maxLevel
        let busy = store.nodeBusy(node.id)
        let next = store.nextResearchLevel(node)
        HStack(spacing: 8) {
            ArtIcon(node.art, size: 36)
                .saturation(open ? 1 : 0)
                .opacity(open ? 1 : 0.5)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(store.t(node.name))
                        .font(.game(14, .black))
                        .foregroundColor(Brand.cream)
                    Text(Num.frac(lv, node.maxLevel))
                        .font(.game(11, .black))
                        .foregroundColor(Brand.goldLight)
                }
                Text(store.researchDesc(node))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if !open {
                    Text(lockText)
                        .font(.body(10, bold: true))
                        .foregroundColor(Brand.glow)
                } else if !maxed && !busy {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .heavy))
                        Text(Num.dur(store.researchDuration(node, level: next)))
                            .font(.body(10, bold: true))
                    }
                    .foregroundColor(Brand.cream.opacity(0.65))
                }
            }
            Spacer(minLength: 4)
            action(open: open, maxed: maxed, busy: busy, next: next)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
        .fxAnchor("research.node." + node.id)
    }

    @ViewBuilder
    private func action(open: Bool, maxed: Bool, busy: Bool, next: Int) -> some View {
        if maxed {
            Tag(text: "مكتمل", color: Brand.gold)
        } else if busy {
            Tag(text: "شغّال", color: Brand.teal, textColor: .white)
        } else if open {
            let cost = store.researchCost(node, level: next)
            ChunkyButton(title: "ابدأ", subtitle: Num.big(cost),
                         color: store.s.city.cash >= cost && store.freeResearchSlots > 0 ? .green : .gray, sound: nil) {
                store.startResearch(node.id)
            }
            .frame(width: 96)
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Brand.cream.opacity(0.5))
                .frame(width: 40)
        }
    }

    private var lockText: String {
        if store.level < node.unlockLevel { return "بتفتح بمستوى " + Num.int(node.unlockLevel) }
        let parts = node.requires.compactMap { r -> String? in
            guard let n = store.cat.node(r.nodeId), store.researchLevel(r.nodeId) < r.level else { return nil }
            return store.t(n.name) + " " + Num.int(r.level)
        }
        return "بدها: " + parts.joined(separator: "، ")
    }
}
