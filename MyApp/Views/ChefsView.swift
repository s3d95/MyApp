import SwiftUI

struct ChefsView: View {
    @EnvironmentObject var game: Game
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        let s = game.s
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                SectionTitle(title: "الطبّاخين",
                             subtitle: "افتح صناديق وجمّع طبّاخين. النسخ المكررة بترقّيهم، وبيضلّوا معك للأبد حتى بعد إعادة الافتتاح.")

                HStack(spacing: 8) {
                    ForEach(ChestKind.allCases) { kind in
                        ChestSlot(kind: kind)
                    }
                }

                HStack {
                    Text("المجموعة")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Spacer()
                    Text("\(s.chefsOwned)/\(Catalog.chefs.count) · مجموع المستويات \(s.chefLevelsTotal)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
                .padding(.top, 4)

                ForEach(Array(Rarity.allCases.reversed()), id: \.rawValue) { r in
                    rarityHeader(r)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Catalog.chefs(of: r)) { c in
                            ChefCardView(chef: c)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func rarityHeader(_ r: Rarity) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: r.tint)).frame(width: 8, height: 8)
            Text(r.name)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: r.tint))
            Rectangle().fill(Color(hex: r.tint).opacity(0.25)).frame(height: 1)
        }
        .padding(.top, 4)
    }
}

struct ChestSlot: View {
    @EnvironmentObject var game: Game
    let kind: ChestKind
    @State private var wiggle = false

    var body: some View {
        let count = game.s.chests[kind.rawValue]
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ChestIcon(kind: kind, size: 46)
                    .rotationEffect(.degrees(count > 0 && wiggle ? 6 : (count > 0 ? -6 : 0)))
                    .padding(.top, 6)
                if count > 0 {
                    Text("×\(count)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.red))
                        .offset(x: 6, y: -2)
                }
            }
            Text(kind.name)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
            Text("\(kind.cards) كروت")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted)
            if count > 0 {
                ActionButton(title: "افتح", tint: Color(hex: 0xEA580C)) { game.openChest(kind) }
            } else {
                GoldButton(title: "اشتري", cost: kind.price, enabled: game.s.liras >= kind.price) {
                    game.buyChest(kind)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .card()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) { wiggle = true }
        }
    }
}

struct ChefCardView: View {
    @EnvironmentObject var game: Game
    let chef: ChefDef

    var body: some View {
        let level = game.s.chefLevel[chef.id]
        let tint = Color(hex: chef.rarity.tint)
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Text(level > 0 ? chef.emoji : "❔")
                    .font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(LinearGradient(colors: [tint.opacity(0.6), tint.opacity(0.15)],
                                                             startPoint: .top, endPoint: .bottom)))
                    .saturation(level > 0 ? 1 : 0)
                if let i = chef.sectionIndex {
                    Text(GameData.businesses[i].emoji)
                        .font(.system(size: 15))
                        .offset(x: 4, y: 2)
                }
            }
            Text(level > 0 ? chef.name : "؟؟؟")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if level > 0 {
                owned(level, tint: tint)
            } else {
                Text("لسا ما لقيته")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .frame(height: 24)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(level > 0 ? tint.opacity(0.8) : Theme.stroke, lineWidth: level > 0 ? 1.5 : 1))
        .opacity(level > 0 ? 1 : 0.6)
    }

    @ViewBuilder
    private func owned(_ level: Int, tint: Color) -> some View {
        Text("مستوى \(level)")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundColor(Color(hex: 0x2A1608))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Capsule().fill(tint))
        Text(Catalog.perkText(chef, level: level))
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(Theme.gold)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(height: 24)
        if let need = game.s.chefCardsNeeded(chef.id) {
            let have = game.s.chefCards[chef.id]
            if have >= need {
                Button { game.upgradeChef(chef.id) } label: {
                    Text("⬆️ رقّي")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x16A34A)))
                }
                .buttonStyle(PressableStyle())
            } else {
                VStack(spacing: 2) {
                    ProgressBar(value: Double(have) / Double(need), tint: tint, height: 5)
                    Text("\(have)/\(need)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
            }
        } else {
            Text("🏆 ماكس")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(Theme.gold)
        }
    }
}

// MARK: - Chest opening

struct ChestRevealView: View {
    @EnvironmentObject var game: Game
    let reveal: ChestReveal
    @State private var opened = false
    @State private var shake = false
    @State private var shown = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var groups: [(id: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for c in reveal.cards { counts[c, default: 0] += 1 }
        return counts.map { (id: $0.key, count: $0.value) }.sorted { a, b in
            let ra = Catalog.chefs[a.id].rarity.rawValue
            let rb = Catalog.chefs[b.id].rarity.rawValue
            return ra != rb ? ra > rb : a.id < b.id
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(reveal.kind.name)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Theme.cream)
                ChestIcon(kind: reveal.kind, size: opened ? 70 : 110, open: opened)
                    .rotationEffect(.degrees(opened ? 0 : (shake ? 8 : -8)))
                    .animation(opened ? .default : .easeInOut(duration: 0.08).repeatCount(8, autoreverses: true), value: shake)
                if opened {
                    let list = groups
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(list.enumerated()), id: \.offset) { k, g in
                                RevealCard(chef: Catalog.chefs[g.id], count: g.count,
                                           isNew: reveal.newChefs.contains(g.id))
                                    .opacity(k < shown ? 1 : 0)
                                    .scaleEffect(k < shown ? 1 : 0.3)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 380)
                    Button {
                        withAnimation { game.chestReveal = nil }
                    } label: {
                        BigButtonLabel(text: "تمام 👌")
                    }
                    .buttonStyle(PressableStyle())
                    .frame(maxWidth: 320)
                } else {
                    Text("اضغط عالصندوق!")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
            }
            .padding(20)
        }
        .contentShape(Rectangle())
        .onTapGesture { openNow() }
        .onAppear {
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { openNow() }
        }
    }

    private func openNow() {
        guard !opened else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { opened = true }
        if game.s.hapticsOn { Feedback.medium() }
        let total = groups.count
        for k in 0..<total {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(k) * 0.12) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { shown = k + 1 }
                if game.s.hapticsOn { Feedback.light() }
            }
        }
    }
}

struct RevealCard: View {
    let chef: ChefDef
    let count: Int
    let isNew: Bool

    var body: some View {
        let tint = Color(hex: chef.rarity.tint)
        VStack(spacing: 3) {
            Text(chef.emoji).font(.system(size: 32))
            Text(chef.name)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(chef.rarity.name)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(tint)
            Text("×\(count)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(Theme.lira)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [tint.opacity(0.35), Theme.card], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint, lineWidth: 1.5))
        .overlay(Group {
            if isNew {
                Text("جديد!")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.red))
                    .offset(x: 4, y: -6)
            }
        }, alignment: .topTrailing)
        .shadow(color: chef.rarity == .legendary ? tint.opacity(0.8) : .clear, radius: 8)
    }
}
