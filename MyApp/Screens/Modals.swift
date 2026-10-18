import SwiftUI

struct ModalLayer: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ZStack {
            if let m = store.currentModal {
                modal(m)
                    .id(m.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: store.currentModal?.id)
    }

    @ViewBuilder
    private func modal(_ m: Modal) -> some View {
        switch m {
        case .newspaper(let info): NewspaperModal(info: info)
        case .levelUp(let info): LevelUpModal(info: info)
        case .unlock(let id): UnlockModal(id: id)
        case .story(let scene, let city): StoryModal(sceneId: scene, cityId: city)
        case .address: AddressModal()
        case .legacy: LegacyModal()
        case .graduateConfirm: GraduateConfirmModal()
        case .graduation(let from, let to): GraduationSequence(fromId: from, toId: to)
        case .chest(let r): ChestRevealModal(result: r)
        case .inspector(let score, let lines, let checks): InspectorModal(score: score, lines: lines, checks: checks)
        case .supply(let r): SupplyRevealModal(result: r)
        case .rewards(let title, let lines): RewardsModal(title: title, lines: lines)
        case .choice(let id): ChoiceModal(rowId: id)
        case .rush(let p): RushGameView(practice: p)
        }
    }
}

// MARK: - Newspaper + vault (S27)

struct NewspaperModal: View {
    @EnvironmentObject var store: GameStore
    let info: NewsInfo
    @State private var shown: Double = 0

    var body: some View {
        GameModal(title: "جريدة الحارة") {
            Text("غبت عنّا " + Num.dur(info.away))
                .font(.game(15, .bold))
                .foregroundColor(Brand.cream.opacity(0.85))
            VStack(spacing: 6) {
                ArtIcon("ui_money_bag", size: 64)
                Text("الخزنة جمّعت")
                    .font(.body(13, bold: true))
                    .foregroundColor(Brand.outline.opacity(0.8))
                Text(Num.big(shown))
                    .font(.game(28, .black).monospacedDigit())
                    .foregroundColor(Brand.outline)
                Text(info.currency + " · " + info.cityName)
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.outline.opacity(0.7))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Brand.cream))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.outline.opacity(0.4), lineWidth: 2))
            ForEach(info.lines, id: \.self) { l in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundColor(Brand.goldLight)
                    Text(l)
                        .font(.body(12, bold: true))
                        .foregroundColor(Brand.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: 8) {
                ChunkyButton(title: "اجمع", color: .green, sound: nil) {
                    store.collectVault(double: false)
                }
                .fxAnchor("vault.collect")
                if info.canDouble {
                    ChunkyButton(title: "اجمع ×2", icon: "ui_coin", subtitle: Num.int(info.doubleCost),
                                 color: store.s.wallet.gold >= info.doubleCost ? .gold : .gray, sound: nil) {
                        store.collectVault(double: true)
                    }
                }
            }
        }
        .onAppear {
            let steps = 20
            for k in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(k) * 0.04) {
                    shown = info.vault * Double(k) / Double(steps)
                }
            }
        }
    }
}

// MARK: - Level up (S31)

struct LevelUpModal: View {
    @EnvironmentObject var store: GameStore
    let info: LevelUpInfo

    var body: some View {
        RewardReveal(title: "مستوى " + Num.int(info.to) + "!", subtitle: subtitle, items: items, buttonTitle: "يلا") {
            store.closeModal()
        }
    }

    private var items: [RewardItem] {
        let list = info.rewards.prefix(6).map { RewardItem(art: $0.art, amount: $0.amount, caption: $0.caption) }
        return list.isEmpty ? [RewardItem(art: "ui_sparkles", amount: "", caption: "مستوى جديد")] : Array(list)
    }

    private var subtitle: String? {
        var parts: [String] = []
        if let t = info.title { parts.append("لقب جديد: " + t) }
        if !info.unlocks.isEmpty { parts.append("فتح: " + info.unlocks.joined(separator: "، ")) }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}

// MARK: - Twist introduction (system ceremony)

struct UnlockModal: View {
    @EnvironmentObject var store: GameStore
    let id: String

    var body: some View {
        let raw = id.hasPrefix("twist.") ? String(id.dropFirst(6)) : id
        let type = TwistType(rawValue: raw) ?? .unknown
        let def = store.city.twists.first { $0.typeRaw == raw }
        GameModal(title: store.twistName(type)) {
            ZStack {
                Rays().frame(width: 200, height: 200).opacity(0.7)
                ArtIcon(store.twistArt(type), size: 80)
            }
            .frame(height: 130)
            Text("سرّ " + store.t(store.city.name))
                .font(.game(16, .black))
                .foregroundColor(Brand.goldLight)
            if let d = def {
                Text(store.twistInfo(d))
                    .font(.body(14, bold: true))
                    .foregroundColor(Brand.cream)
                    .multilineTextAlignment(.center)
            }
            ChunkyButton(title: "فهمت!", color: .green, sound: nil) { store.closeModal() }
        }
    }
}

// MARK: - Story scene (S33)

struct StoryModal: View {
    @EnvironmentObject var store: GameStore
    let sceneId: String
    let cityId: String
    @State private var line = 0

    var body: some View {
        let scene = store.cat.scene(sceneId)
        let lines = scene?.lines ?? []
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { next(lines.count) }
            if line < lines.count {
                let who = store.speaker(lines[line], cityId: cityId)
                VStack(spacing: 8) {
                    StoryBubble(character: who.art, name: who.name, text: store.t(lines[line].text)) {
                        next(lines.count)
                    }
                    .id(line)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    Text(Num.frac(line + 1, lines.count))
                        .font(.body(11, bold: true))
                        .foregroundColor(Brand.cream.opacity(0.6))
                }
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            if lines.isEmpty { store.closeModal() }
        }
    }

    private func next(_ count: Int) {
        Feedback.play(.t0)
        if line + 1 < count {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { line += 1 }
        } else {
            store.closeModal()
        }
    }
}

// MARK: - Address form (asked once)

struct AddressModal: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "كيف بدّك ستّي تناديك؟") {
            ArtIcon("ppl_old_woman", size: 70)
            Text("عشان تحكيلك صح")
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
            HStack(spacing: 10) {
                ChunkyButton(title: "يا شب", icon: "ppl_boy", color: .blue, sound: nil) { pick(.m) }
                ChunkyButton(title: "يا صبية", icon: "ppl_girl", color: .purple, sound: nil) { pick(.f) }
            }
        }
    }

    private func pick(_ f: AddressForm) {
        store.s.settings.address = f
        store.s.settings.addressAsked = true
        store.closeModal()
    }
}

// MARK: - Legacy gift (S34)

struct LegacyModal: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        RewardReveal(title: "هديّة من ستّي",
                     subtitle: "شكراً إنّك معنا من الأوّل! ستّي خبّتلك هديّة",
                     items: [RewardItem(art: "ui_coin", amount: "300", caption: "ذهب"),
                             RewardItem(art: "ui_crown", amount: "×1", caption: "صندوق ذهب"),
                             RewardItem(art: "ppl_old_man", amount: "", caption: "أبو صبحي (قريباً)")],
                     buttonTitle: "استلم") {
            store.claimLegacy()
            store.closeModal()
        }
    }
}

// MARK: - Graduation (S8)

struct GraduateConfirmModal: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let next = store.nextCity
        GameModal(title: "افتح فرع؟", onClose: { store.closeModal() }) {
            HStack(spacing: 14) {
                ArtIcon(store.city.landmarkArt, size: 56)
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(Brand.goldLight)
                ArtIcon(next?.landmarkArt ?? "bld_mosque", size: 56)
            }
            Text("رح تسكّر " + store.t(store.city.name) + " وتصير فرع. الفرع بعطيك ذهب كل يوم و+10% دخل لكل المدن الجاية.")
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream)
                .multilineTextAlignment(.center)
            if !store.crownEarned {
                Text("الأهداف اللي ما خلّصتها رح تروح (والتاج كمان).")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.glow)
                    .multilineTextAlignment(.center)
            } else {
                Tag(text: "معك التاج! الفرع بيبلّش مستوى 1 + زعتر ذهبي", color: Brand.gold)
            }
            HStack(spacing: 10) {
                ChunkyButton(title: "مش هسّا", color: .wood, sound: nil) { store.closeModal() }
                ChunkyButton(title: "يلا عـ" + store.t(next?.name ?? GText("")), color: .green, sound: nil) { store.graduate() }
            }
        }
    }
}

struct GraduationSequence: View {
    @EnvironmentObject var store: GameStore
    let fromId: String
    let toId: String
    @State private var phase = 0
    @State private var travel: CGFloat = 0

    var body: some View {
        let from = store.cat.city(fromId)
        let to = store.cat.city(toId)
        ZStack {
            LinearGradient(colors: (phase >= 2 ? to?.palette.sky : from?.palette.sky) ?? [Brand.duskTop, Brand.sunset],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: phase)
            Rays(color: Brand.goldLight).opacity(phase >= 2 ? 0.8 : 0.3).ignoresSafeArea()
            VStack(spacing: 18) {
                if phase < 2 {
                    Ribbon(text: "فرع " + (from.map { store.t($0.name) } ?? ""), color: Brand.red, size: 22)
                    ArtIcon(from?.landmarkArt ?? "bld_mosque", size: 85)
                } else {
                    Ribbon(text: "أهلا بـ" + (to.map { store.t($0.name) } ?? "") + "!", color: Brand.teal, size: 24)
                    ArtIcon(to?.landmarkArt ?? "bld_mosque", size: 85)
                    Text(to?.regionName ?? "")
                        .font(.game(16, .bold))
                        .foregroundColor(Brand.cream)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.35)).frame(height: 8)
                        Capsule().fill(Brand.titleFill).frame(width: g.size.width * travel, height: 8)
                        ArtIcon("veh_taxi", size: 44)
                            .offset(x: g.size.width * travel - 22, y: -20)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                }
                .frame(height: 50)
                .padding(.horizontal, 40)
                if phase >= 2 {
                    ChunkyButton(title: "يلا نبلّش!", color: .gold, sound: nil) { store.closeModal() }
                        .frame(width: 220)
                        .transition(.scale)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6)) { travel = 1 }
            SFX.whoosh.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { phase = 2 }
                Feedback.play(.t2)
            }
        }
    }
}
