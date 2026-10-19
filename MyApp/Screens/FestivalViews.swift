import SwiftUI

/// Active real-calendar festival card in Tasks → اليوم (GDD 6.11).
struct FestivalCard: View {
    @EnvironmentObject var store: GameStore
    let festival: FestivalDef

    var body: some View {
        HStack(spacing: 10) {
            ArtIcon(festival.art, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.t(festival.name))
                    .font(.game(16, .black))
                    .foregroundColor(Brand.goldLight)
                Text(effectText)
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            if store.festivalClaimReady(festival) {
                ChunkyButton(title: festival.collectible != nil ? "خذ" : "عيديّة", color: .gold, sound: nil) {
                    store.claimFestival(festival)
                }
                .frame(width: 80)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Brand.red.opacity(0.35), Brand.gold.opacity(0.2)],
                                                                           startPoint: .leading, endPoint: .trailing)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.gold, lineWidth: 1.5))
    }

    private var effectText: String {
        var parts: [String] = []
        for e in festival.effects where e.type == "incomeMult" {
            switch e.scopeKind {
            case "cuisine": parts.append(GameStore.cuisineName(e.scopeValue ?? "") + " " + Num.mult(e.mult))
            case "weatherTag": parts.append((e.scopeValue == "cold" ? "البارد" : "السخن") + " " + Num.mult(e.mult))
            case "category": parts.append(GameStore.categoryName(e.scopeValue ?? "") + " " + Num.mult(e.mult))
            default: parts.append("كل الدخل " + Num.mult(e.mult))
            }
        }
        for w in festival.windows {
            parts.append((w.kind == "iftar" ? "ساعة الإفطار " : "السحور ") + Num.mult(w.mult))
        }
        if !festival.dailyClaim.isEmpty { parts.append("هديّة كل يوم") }
        return parts.isEmpty ? "أيام حلوة بالحارة" : parts.joined(separator: " · ")
    }
}

/// مفتّش البلدية (GDD S35): six checks and the score. Never a penalty.
struct InspectorModal: View {
    @EnvironmentObject var store: GameStore
    let score: Double
    let lines: [RewardLine]
    let checks: [String]

    private func points(_ c: String) -> Double {
        Double(c.split(separator: " ").last.map(String.init) ?? "0") ?? 0
    }

    private func icon(_ c: String) -> String {
        let p = points(c)
        if p >= 2.5 { return "checkmark.seal.fill" }
        return p > 0 ? "checkmark.circle" : "xmark.circle"
    }

    private func color(_ c: String) -> Color {
        let p = points(c)
        if p >= 2.5 { return Brand.parsley }
        return p > 0 ? Brand.gold : Brand.cream.opacity(0.4)
    }

    var body: some View {
        GameModal(title: "مفتّش البلدية") {
            ArtIcon("ui_clipboard", size: 64)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(checks, id: \.self) { c in
                    HStack {
                        Image(systemName: icon(c))
                            .foregroundColor(color(c))
                        Text(c)
                            .font(.body(13, bold: true))
                            .foregroundColor(Brand.cream)
                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Brand.cream.opacity(0.12)))
            OutlinedText(text: "العلامة: " + String(format: "%.1f", score) + " من 15", size: 20, color: Brand.goldLight)
            Text(score >= 12 ? "شهادة نظافة! البسطة بتلمع" : (score >= 8 ? "منيح كتير، كمّل هيك" : "نصيحة: وظّف معلّمين وحطّ طبّاخين واجمع الخزنة"))
                .font(.body(12, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                ForEach(lines) { l in
                    VStack(spacing: 2) {
                        ArtIcon(l.art, size: 30)
                        Text(l.amount).font(.game(12, .black)).foregroundColor(Brand.goldLight)
                    }
                }
            }
            ChunkyButton(title: "تمام", color: .green, sound: nil) { store.closeModal() }
        }
    }
}

/// Activate button for an equipped epic or legendary chef's skill (from L22).
struct SkillButton: View {
    @EnvironmentObject var store: GameStore
    let chef: ChefDef

    var body: some View {
        let ready = store.skillReadyIn(chef.id)
        let open = store.unlocked("chefSkills") && store.isEquipped(chef.id)
        ChunkyButton(title: ready > 0 ? "جاهزة بعد " + Num.dur(ready) : "فعّل المهارة", icon: "ui_high_voltage",
                     color: open && ready <= 0 ? .purple : .gray, sound: nil) {
            store.activateSkill(chef.id)
        }
    }
}
