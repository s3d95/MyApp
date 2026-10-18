import SwiftUI

/// حكاية من الحارة (GDD S28): a small story with 2–3 choices; the outcome is always positive.
struct ChoiceModal: View {
    @EnvironmentObject var store: GameStore
    let rowId: String
    @State private var result: ChoiceOutcome? = nil

    var body: some View {
        if let row = store.hp.choices.first(where: { $0.id == rowId }) {
            GameModal(title: store.t(row.title), onClose: closeAction) {
                ArtIcon(row.art, size: 70)
                if let r = result {
                    Text(r.text)
                        .font(.game(16, .bold))
                        .foregroundColor(Brand.cream)
                        .multilineTextAlignment(.center)
                    if !r.lines.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(r.lines.prefix(4)) { l in
                                VStack(spacing: 2) {
                                    ArtIcon(l.art, size: 34)
                                    Text(l.amount)
                                        .font(.game(12, .black))
                                        .foregroundColor(Brand.goldLight)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    ChunkyButton(title: "تمام", color: .green, sound: nil) { store.closeModal() }
                } else {
                    Text(store.choiceBody(row))
                        .font(.body(15, bold: true))
                        .foregroundColor(Brand.cream)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        ForEach(Array(row.choices.enumerated()), id: \.offset) { k, opt in
                            optionButton(k, opt)
                        }
                    }
                }
            }
        }
    }

    private var closeAction: (() -> Void)? {
        guard result == nil else { return nil }
        let store = self.store
        return { store.closeModal() }
    }

    private func optionButton(_ k: Int, _ opt: ChoiceOptDef) -> some View {
        let luck = opt.hint == "luck"
        return Button {
            Feedback.play(.t0)
            let r = store.resolveChoice(rowId, option: k)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { result = r }
        } label: {
            HStack(spacing: 8) {
                Text(store.t(opt.label))
                    .font(.game(15, .black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Tag(text: luck ? "حظّ" : "أكيد", color: luck ? Brand.glow : Brand.parsley, textColor: luck ? Brand.outline : .white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyStyle(color: k == 0 ? .gold : (k == 1 ? .blue : .purple)))
    }
}
