import SwiftUI

struct GoalStrip: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 6) {
            if store.starsEnough && store.nextCity != nil {
                GraduateCard()
            }
            HStack(spacing: 6) {
                ForEach(Array(store.visibleGoals.enumerated()), id: \.element.id) { k, g in
                    GoalChip(goal: g, index: k)
                }
                if store.visibleGoals.isEmpty {
                    Text(store.crownEarned ? "خلّصت كل أهداف " + store.t(store.city.name) + "!" : "")
                        .font(.game(14, .bold))
                        .foregroundColor(Brand.goldLight)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
    }
}

struct GoalChip: View {
    @EnvironmentObject var store: GameStore
    let goal: GoalDef
    let index: Int

    var body: some View {
        let done = store.goalDone(goal)
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                ArtIcon(store.goalArt(goal), size: 26)
                Text(store.goalText(goal))
                    .font(.body(10, bold: true))
                    .foregroundColor(Brand.cream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            if done {
                Button {
                    store.claimGoal(goal)
                } label: {
                    HStack(spacing: 2) {
                        Text("خذ")
                            .font(.game(13, .black))
                        ForEach(0..<goal.stars, id: \.self) { _ in
                            ArtIcon("ui_star", size: 13, shadow: false)
                        }
                    }
                    .foregroundColor(Brand.outline)
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .background(Capsule().fill(Brand.titleFill))
                    .overlay(Capsule().stroke(Brand.outline.opacity(0.6), lineWidth: 1.5))
                }
                .buttonStyle(PressScaleStyle())
                .modifier(Pulse(active: true, amount: 0.05))
                .fxAnchor("goal.\(index).claim")
            } else {
                FancyBar(value: store.goalFraction(goal), tint: Brand.parsley, height: 11)
                    .padding(.vertical, 5)
                    .fxAnchor("goal.\(index).claim")
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(done ? Brand.gold : Brand.gold.opacity(0.2), lineWidth: done ? 2 : 1))
        .onTapGesture {
            Feedback.play(.t0)
            store.sheet = .goals
        }
    }
}

/// Pulsing gold card shown when the city can graduate (or is waiting for its licence).
struct GraduateCard: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let next = store.nextCity
        let ready = store.canGraduate
        Button {
            if ready {
                store.requestGraduation()
            } else if !store.unlocked("map") {
                store.showToast("الفروع بتفتح بمستوى " + Num.int(store.unlockLevel("map")), art: "ui_locked")
            } else {
                store.showToast("الرخصة بتطلع بعد " + Num.dur(store.licenceLeft), art: "ui_scroll")
            }
        } label: {
            HStack(spacing: 8) {
                ArtIcon(next?.landmarkArt ?? "bld_mosque", size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title(next))
                        .font(.game(15, .black))
                        .foregroundColor(Brand.outline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(subtitle)
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.outline.opacity(0.8))
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: ready ? "arrow.left.circle.fill" : "hourglass")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Brand.outline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.titleFill))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Brand.outline, lineWidth: 2))
            .shine(ready)
        }
        .buttonStyle(PressScaleStyle())
        .modifier(Pulse(active: ready, amount: 0.03))
        .fxAnchor("goalStrip.graduate")
    }

    private func title(_ next: CityDef?) -> String {
        guard let n = next else { return "" }
        return store.mf("افتح فرع وانقل على ", "افتحي فرع وانقلي على ") + store.t(n.name)
    }

    private var subtitle: String {
        if !store.unlocked("map") { return "بتفتح بمستوى " + Num.int(store.unlockLevel("map")) }
        if store.licenceLeft > 0 { return "الرخصة بتطلع بعد " + Num.dur(store.licenceLeft) }
        return "الفرع بعطيك ذهب كل يوم و+10% دخل"
    }
}
