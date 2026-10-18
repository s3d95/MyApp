import SwiftUI

/// Full-screen dim with a rounded hole; only the hole lets taps through (even-odd hit testing).
struct SpotlightShape: Shape {
    var hole: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        p.addRoundedRect(in: hole, cornerSize: CGSize(width: 14, height: 14))
        return p
    }
}

/// FTUE overlay (GDD 6.18): spotlight, hand pointer and Sitti's bubble.
struct TutorialLayer: View {
    @EnvironmentObject var store: GameStore
    @ObservedObject var box: AnchorBox
    let size: CGSize
    @State private var stepShownAt = Date()
    @State private var lastStepId = -1

    var body: some View {
        ZStack {
            if let step = store.ftueActive, allowed(step) {
                content(step)
            }
        }
        .onChange(of: store.ftueActive?.id ?? -1) { id in
            if id != lastStepId {
                lastStepId = id
                stepShownAt = Date()
            }
        }
    }

    /// The overlay waits while a modal is up, except for the vault step inside the newspaper.
    private func allowed(_ step: FtueStepDef) -> Bool {
        if store.modals.isEmpty { return store.sheet == nil || anchorRect(step) != nil }
        return step.anchors.contains("vault.collect") && store.newsInfo != nil
    }

    private func anchorRect(_ step: FtueStepDef) -> CGRect? {
        for a in step.anchors.reversed() {
            if let r = box.rects[a], r.width > 1, r.height > 1, r.maxY > 0, r.minY < size.height { return r }
        }
        return nil
    }

    @ViewBuilder
    private func content(_ step: FtueStepDef) -> some View {
        let rect = anchorRect(step)
        let soft = store.ftueIsSoft(step) || rect == nil
        ZStack {
            if !soft, let r = rect {
                let hole = r.insetBy(dx: -8, dy: -8)
                SpotlightShape(hole: hole)
                    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                    .contentShape(SpotlightShape(hole: hole), eoFill: true)
                    .frame(width: size.width, height: size.height)
                    .onTapGesture { Feedback.play(.t0) }
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Brand.goldLight, lineWidth: 3)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .allowsHitTesting(false)
            }
            if let r = rect {
                TutorialHand()
                    .position(x: min(size.width - 30, r.midX + 18), y: min(size.height - 30, r.maxY + 16))
                    .allowsHitTesting(false)
            }
            bubble(step, rect: rect, soft: soft)
        }
        .frame(width: size.width, height: size.height)
    }

    private func bubble(_ step: FtueStepDef, rect: CGRect?, soft: Bool) -> some View {
        let y = bubbleY(rect)
        let store = self.store
        var next: (() -> Void)? = nil
        if closable(step) { next = { store.closeFtueBubble() } }
        return VStack(spacing: 6) {
            StoryBubble(character: "ppl_old_woman", name: "ستّي", text: store.ftueText(step), onNext: next)
            if step.id == 14 && !store.s.ftue.bubbleClosed {
                notificationButtons
            }
            if !soft && Date().timeIntervalSince(stepShownAt) > 20 {
                Button("تخطّي الشرح") { store.skipFtueStep() }
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.8))
            }
        }
        .frame(width: min(size.width - 24, 380))
        .position(x: size.width / 2, y: y)
        .transition(.opacity)
    }

    private func closable(_ step: FtueStepDef) -> Bool {
        switch step.complete.type {
        case "bubbleClosed": return step.id != 14
        case "screenViewed": return store.tab == .map
        default: return false
        }
    }

    private var notificationButtons: some View {
        HStack(spacing: 10) {
            ChunkyButton(title: "أكيد، خبّرني", color: .green, sound: nil) {
                store.s.notif.asked += 1
                Notifier.request { ok in
                    store.s.notif.granted = ok
                    store.save()
                }
                store.closeFtueBubble()
            }
            ChunkyButton(title: "مش هسّا", color: .wood, sound: nil) {
                store.s.notif.asked += 1
                store.closeFtueBubble()
            }
        }
        .frame(width: 300)
    }

    private func bubbleY(_ rect: CGRect?) -> CGFloat {
        guard let r = rect else { return size.height * 0.62 }
        let h: CGFloat = 130
        if r.midY > size.height / 2 {
            return max(h / 2 + 40, r.minY - 28 - h / 2)
        }
        return min(size.height - h / 2 - 30, r.maxY + 56 + h / 2)
    }
}
