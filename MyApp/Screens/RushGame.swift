import SwiftUI
import Combine

/// "طلبيات على السريع" (GDD 6.13): build the sandwich, base first, then the fillings, then wrap.
struct RushGameView: View {
    @EnvironmentObject var store: GameStore
    let practice: Bool

    @State private var phase = 0
    @State private var countdown = 3
    @State private var timeLeft: Double = 60
    @State private var score = 0
    @State private var streak = 0
    @State private var orderNo = 0
    @State private var base = ""
    @State private var fillings: [String] = []
    @State private var picked: [String] = []
    @State private var customer = "ppl_man"
    @State private var orderStart: Double = 0
    @State private var urgentLeft: Double = 0
    @State private var shakeKey = ""
    @State private var shake: CGFloat = 0
    @State private var results: [RewardLine] = []
    @State private var seedBase = 0
    @State private var lastPoints = 0

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var bases: [IngredientDef] { store.city.rushBases }
    private var fills: [IngredientDef] { store.city.rushFillings }
    private var combo: Double { min(2.0, 1 + 0.1 * Double(streak)) }
    private var urgent: Bool { orderNo > 0 && orderNo % 5 == 0 }

    var body: some View {
        ZStack {
            LinearGradient(colors: store.city.palette.sky, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                header
                Spacer(minLength: 4)
                switch phase {
                case 0: countdownView
                case 1: playView
                default: resultsView
                }
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 50)
        }
        .onAppear(perform: start)
        .onReceive(timer) { _ in step() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text(practice ? "تدريب" : "طلبيات على السريع")
                    .font(.game(20, .black))
                    .foregroundColor(Brand.goldLight)
                Spacer()
                if phase != 1 {
                    RoundIconButton(system: "xmark", action: { store.closeModal() })
                }
            }
            HStack(spacing: 10) {
                FancyBar(value: timeLeft / 60, tint: timeLeft < 10 ? Brand.red : Brand.parsley, height: 16,
                         label: Num.int(Int(timeLeft.rounded(.up))) + "ث")
                OutlinedText(text: Num.int(score), size: 20, color: .white)
                Text(Num.mult(combo))
                    .font(.game(14, .black))
                    .foregroundColor(Brand.outline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Brand.goldLight))
            }
        }
    }

    private var countdownView: some View {
        VStack(spacing: 10) {
            OutlinedText(text: countdown > 0 ? Num.int(countdown) : "يلا!", size: 64, color: Brand.goldLight)
            Text("دقّ الخبز أوّل، بعدين الحشوة، وبعدين لفّ")
                .font(.game(15, .bold))
                .foregroundColor(Brand.cream)
                .multilineTextAlignment(.center)
        }
    }

    private var playView: some View {
        VStack(spacing: 16) {
            orderCard
            grid
        }
    }

    private var orderCard: some View {
        HStack(spacing: 10) {
            ArtIcon(customer, size: 60)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ingredientIcon(base, done: picked.contains(base))
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Brand.outline.opacity(0.6))
                    ForEach(fillings, id: \.self) { f in
                        ingredientIcon(f, done: picked.contains(f))
                    }
                }
                if urgent {
                    HStack(spacing: 4) {
                        Tag(text: "مستعجل ×1.5", color: Brand.red, textColor: .white)
                        FancyBar(value: urgentLeft / 6, tint: Brand.red, height: 8)
                            .frame(width: 70)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Brand.cream))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.outline, lineWidth: 2))
    }

    private func ingredientIcon(_ key: String, done: Bool) -> some View {
        ZStack {
            ArtIcon(art(key), size: 34)
                .opacity(done ? 0.35 : 1)
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Brand.parsley)
            }
        }
    }

    private var grid: some View {
        let items = gridItems
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(84), spacing: 12), count: 3), spacing: 12) {
            ForEach(0..<9, id: \.self) { k in
                if k == 4 {
                    Button {
                        wrap()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.uturn.down.circle.fill")
                                .font(.system(size: 28, weight: .heavy))
                            Text("لفّ").font(.game(16, .black))
                        }
                        .foregroundColor(Brand.outline)
                        .frame(width: 84, height: 84)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Brand.titleFill))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Brand.outline, lineWidth: 2))
                    }
                    .buttonStyle(PressScaleStyle())
                    .modifier(Shake(trigger: shakeKey == "wrap" ? shake : 0))
                } else {
                    let key = items[k < 4 ? k : k - 1]
                    Button {
                        tap(key)
                    } label: {
                        VStack(spacing: 0) {
                            ArtIcon(art(key), size: 46)
                            Text(name(key))
                                .font(.game(11, .black))
                                .foregroundColor(Brand.cream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(width: 84, height: 84)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.45)))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(bases.contains { $0.key == key } ? Brand.goldLight : Brand.gold.opacity(0.3), lineWidth: 2))
                    }
                    .buttonStyle(PressScaleStyle())
                    .modifier(Shake(trigger: shakeKey == key ? shake : 0))
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var resultsView: some View {
        VStack(spacing: 14) {
            Ribbon(text: score > store.rushBest || practice ? "يا سلام!" : "خلص الوقت!", color: Brand.red, size: 22)
            OutlinedText(text: Num.int(score) + " نقطة", size: 30, color: Brand.goldLight)
            Text("أحسن نتيجة ب" + store.t(store.city.name) + ": " + Num.int(max(score, store.rushBest)))
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream.opacity(0.85))
            if practice {
                Text("التدريب ما بيعطي جوايز، بس بيخلّيك أسرع")
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.75))
            } else {
                HStack(spacing: 10) {
                    ForEach(results) { l in
                        VStack(spacing: 2) {
                            ArtIcon(l.art, size: 36)
                            Text(l.amount)
                                .font(.game(13, .black))
                                .foregroundColor(Brand.goldLight)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text(l.caption)
                                .font(.body(10))
                                .foregroundColor(Brand.cream.opacity(0.75))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            ChunkyButton(title: "خذ", color: .green, sound: .cash) { store.closeModal() }
                .frame(width: 200)
        }
    }

    // MARK: Rules

    private var gridItems: [String] {
        let keys = (bases.map { $0.key } + fills.map { $0.key })
        var r = Seed.rng("rushGrid", [store.city.id], player: store.s.meta.seed)
        var list = keys
        for i in stride(from: list.count - 1, to: 0, by: -1) {
            let j = r.int(i + 1)
            list.swapAt(i, j)
        }
        while list.count < 8 { list.append(keys.first ?? "") }
        return Array(list.prefix(8))
    }

    private func art(_ key: String) -> String {
        (bases + fills).first { $0.key == key }?.art ?? "food_bread"
    }

    private func name(_ key: String) -> String {
        (bases + fills).first { $0.key == key }.map { store.t($0.name) } ?? ""
    }

    private func start() {
        seedBase = store.s.rush.counter
        store.s.rush.counter += 1
        for k in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.7) {
                countdown = 3 - k
                SFX.tick.play()
                if k == 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        phase = 1
                        nextOrder()
                    }
                }
            }
        }
    }

    private func nextOrder() {
        orderNo += 1
        var r = Seed.rng("rushOrders", [store.city.id, "\(seedBase)", "\(orderNo)"], player: store.s.meta.seed)
        let n = orderNo <= 3 ? 2 : (orderNo <= 7 ? 3 : (orderNo <= 12 ? 4 : 5))
        base = bases.isEmpty ? "" : bases[r.int(bases.count)].key
        var pool = fills.map { $0.key }
        var chosen: [String] = []
        for _ in 0..<min(n, pool.count) {
            chosen.append(pool.remove(at: r.int(pool.count)))
        }
        fillings = chosen
        picked = []
        let people = store.city.customerArts + StreetScene.defaultCustomers
        customer = people[r.int(people.count)]
        orderStart = store.now()
        urgentLeft = 6
    }

    private func step() {
        guard phase == 1 else { return }
        timeLeft = max(0, timeLeft - 0.1)
        if urgent {
            urgentLeft -= 0.1
            if urgentLeft <= 0 {
                streak = 0
                SFX.wrong.play(volume: 0.6)
                nextOrder()
            }
        }
        if timeLeft <= 0 { finish() }
    }

    private func tap(_ key: String) {
        guard phase == 1 else { return }
        if picked.isEmpty {
            if key == base {
                picked.append(key)
                Feedback.play(.t0)
            } else {
                wrong(key)
            }
            return
        }
        if fillings.contains(key) && !picked.contains(key) {
            picked.append(key)
            Feedback.play(.t0)
        } else {
            wrong(key)
        }
    }

    private func wrap() {
        guard phase == 1 else { return }
        guard picked.contains(base) && fillings.allSatisfy({ picked.contains($0) }) else {
            wrong("wrap")
            return
        }
        let fast = store.now() - orderStart <= 3
        var points = Double(100 + 25 * fillings.count) * combo + (fast ? 50 : 0)
        if urgent { points *= 1.5 }
        lastPoints = Int(points.rounded())
        score += lastPoints
        streak += 1
        SFX.correct.play()
        Haptic.tap()
        nextOrder()
    }

    private func wrong(_ key: String) {
        streak = 0
        shakeKey = key
        SFX.wrong.play(volume: 0.7)
        withAnimation(.linear(duration: 0.3)) { shake += 1 }
    }

    private func finish() {
        phase = 2
        results = store.finishRush(score: score, practice: practice)
    }
}

struct RushIntroSheet: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GameModal(title: "طلبيات على السريع", onClose: { store.sheet = nil }) {
            HStack(spacing: -8) {
                ForEach(store.city.rushFillings.prefix(4)) { f in
                    ArtIcon(f.art, size: 44)
                }
            }
            Text("60 ثانية: حضّر السندويشات بسرعة. كل ما تسرع بتولّع البسطة ×2!")
                .font(.body(13, bold: true))
                .foregroundColor(Brand.cream)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ArtIcon("ui_admission_tickets", size: 26)
                Text("تذاكر: " + Num.frac(store.s.wallet.tickets, store.ticketCap))
                    .font(.game(15, .black))
                    .foregroundColor(Brand.goldLight)
                Spacer()
                Text("أحسن نتيجة: " + Num.int(store.rushBest))
                    .font(.body(12, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.8))
            }
            ChunkyButton(title: "العب (تذكرة)", icon: "ui_admission_tickets", color: store.s.wallet.tickets > 0 ? .green : .gray, sound: nil) {
                store.sheet = nil
                store.startRush(practice: false)
            }
            ChunkyButton(title: "تدريب ببلاش", color: .wood, sound: nil) {
                store.sheet = nil
                store.startRush(practice: true)
            }
            if store.s.wallet.tickets < store.ticketCap {
                Text("التذكرة الجاية بعد " + Num.dur(max(0, store.s.wallet.ticketAt + 3 * 3600 - store.now())))
                    .font(.body(11, bold: true))
                    .foregroundColor(Brand.cream.opacity(0.7))
            }
        }
    }
}
