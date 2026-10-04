import SwiftUI

/// "طلبيات على السريع": tap the ingredients of each sandwich in order before time runs out.
final class RushEngine: ObservableObject {
    enum Phase { case ready, countdown, playing, over }

    @Published var phase: Phase = .ready
    @Published var count = 3
    @Published var timeLeft: Double = Catalog.rushSeconds
    @Published var orders = 0
    @Published var combo = 0
    @Published var bestCombo = 0
    @Published var mistakes = 0
    @Published var order: [Int] = []
    @Published var step = 0
    @Published var layout: [Int] = Array(0..<Catalog.rushIngredients.count)
    @Published var customer = "👨"
    @Published var shake: CGFloat = 0
    @Published var served = 0
    @Published var reward: RushReward?
    @Published var timeBonus: Double = 0

    private var timer: Timer?
    private var last = Date()

    var totalTime: Double { Catalog.rushSeconds }

    func start() {
        orders = 0
        combo = 0
        bestCombo = 0
        mistakes = 0
        timeLeft = totalTime
        reward = nil
        layout = Array(0..<Catalog.rushIngredients.count)
        newOrder()
        count = 3
        phase = .countdown
        timer?.invalidate()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        last = Date()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private var countAcc = 0.0

    private func tick() {
        let now = Date()
        let dt = min(0.2, now.timeIntervalSince(last))
        last = now
        switch phase {
        case .countdown:
            countAcc += dt
            if countAcc >= 0.8 {
                countAcc = 0
                if count > 1 {
                    count -= 1
                } else {
                    phase = .playing
                }
            }
        case .playing:
            timeLeft -= dt
            if timeLeft <= 0 {
                timeLeft = 0
                phase = .over
                stop()
            }
        default:
            break
        }
    }

    /// Returns true when the tap was the right ingredient.
    @discardableResult
    func tap(_ ingredient: Int) -> Bool {
        guard phase == .playing, step < order.count else { return false }
        if order[step] == ingredient {
            step += 1
            if step == order.count {
                orders += 1
                combo += 1
                bestCombo = max(bestCombo, combo)
                served += 1
                timeBonus = combo >= 3 ? 1.5 : 1
                timeLeft = min(totalTime, timeLeft + timeBonus)
                newOrder()
            }
            return true
        }
        mistakes += 1
        combo = 0
        step = 0
        timeLeft = max(0, timeLeft - 2)
        withAnimation(.default) { shake += 1 }
        return false
    }

    private func newOrder() {
        let len = min(6, 3 + orders / 3)
        var list = [0]
        while list.count < len {
            let next = Int.random(in: 1..<Catalog.rushIngredients.count)
            if next != list.last { list.append(next) }
        }
        order = list
        step = 0
        customer = Catalog.rushCustomers.randomElement() ?? "👨"
        if orders >= 2 { layout.shuffle() }
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}

struct RushView: View {
    @EnvironmentObject var game: Game
    @StateObject private var engine = RushEngine()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x3B1E0E), Color(hex: 0x1A120D)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                topBar
                switch engine.phase {
                case .ready: readyView
                case .countdown: countdownView
                case .playing: playView
                case .over: overView
                }
            }
            .padding(16)
        }
        .onDisappear { engine.stop() }
        .onChange(of: engine.phase) { p in
            if p == .over {
                let r = game.finishRush(orders: engine.orders, perfect: engine.mistakes == 0)
                withAnimation(.spring()) { engine.reward = r }
                if game.s.hapticsOn { Feedback.success() }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("🥙 طلبيات على السريع")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Spacer()
            Chip(text: "🎟️ \(game.s.tickets)")
            if engine.phase != .playing && engine.phase != .countdown {
                Button {
                    engine.stop()
                    withAnimation(.spring()) { game.showRush = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Theme.muted)
                }
            }
        }
    }

    // MARK: Ready

    private var readyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧆🫓🍅").font(.system(size: 54))
            Text("الزباين واقفين طابور!")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            VStack(alignment: .leading, spacing: 8) {
                rule("1️⃣", "كل زبون بيطلب سندويشة: اضغط المكونات بنفس الترتيب.")
                rule("⏱️", "عندك \(Int(Catalog.rushSeconds)) ثانية. كل طلبية صح بتزيدك وقت.")
                rule("❌", "الغلط بياكل ثانيتين وبيرجّع السندويشة من الأول.")
                rule("💰", "كل طلبية = دقيقة من أرباحك، وبدون ولا غلطة ×1.5!")
            }
            .card()
            if game.s.bestRush > 0 {
                Text("🏆 أحسن نتيجة: \(game.s.bestRush) طلبيات")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.gold)
            }
            Spacer()
            startButton
        }
    }

    private func rule(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon).font(.system(size: 16))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.cream)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var startButton: some View {
        let has = game.s.tickets > 0
        return VStack(spacing: 8) {
            Button {
                if game.useTicket() {
                    engine.start()
                    if game.s.hapticsOn { Feedback.medium() }
                }
            } label: {
                BigButtonLabel(text: has ? "ابدأ (🎟️ تذكرة وحدة)" : "خلصت التذاكر", enabled: has)
            }
            .buttonStyle(PressableStyle())
            .disabled(!has)
            if !has {
                GoldButton(title: "اشتري تذكرة", cost: Game.ticketCost, enabled: game.s.liras >= Game.ticketCost) {
                    game.buyTicket()
                }
            }
        }
    }

    // MARK: Countdown

    private var countdownView: some View {
        VStack {
            Spacer()
            Text("\(engine.count)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundColor(Theme.gold)
                .id(engine.count)
                .transition(.scale.combined(with: .opacity))
            Text("جهّز حالك!")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
            Spacer()
        }
        .animation(.spring(), value: engine.count)
    }

    // MARK: Playing

    private var playView: some View {
        VStack(spacing: 14) {
            hud
            orderCard
                .modifier(ShakeEffect(animatableData: engine.shake))
            Spacer(minLength: 0)
            ingredientGrid
        }
    }

    private var hud: some View {
        VStack(spacing: 8) {
            HStack {
                Text("✅ \(engine.orders)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Theme.money)
                Spacer()
                if engine.combo >= 2 {
                    Text("🔥 كومبو ×\(engine.combo)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Theme.gold)
                }
                Spacer()
                Text(String(format: "%.1f", engine.timeLeft))
                    .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor(engine.timeLeft < 6 ? Theme.red : Theme.cream)
            }
            ProgressBar(value: engine.timeLeft / engine.totalTime,
                        tint: engine.timeLeft < 6 ? Theme.red : Theme.money, height: 10)
        }
    }

    private var orderCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text(engine.customer).font(.system(size: 44))
                VStack(alignment: .leading, spacing: 2) {
                    Text("بدّي سندويشة فيها:")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.cream)
                    Text("الطلبية رقم \(engine.orders + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
                Spacer()
            }
            HStack(spacing: 6) {
                ForEach(Array(engine.order.enumerated()), id: \.offset) { k, ing in
                    let done = k < engine.step
                    let current = k == engine.step
                    Text(Catalog.rushIngredients[ing].0)
                        .font(.system(size: 28))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(done ? Theme.money.opacity(0.3) : Color.white.opacity(current ? 0.14 : 0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(current ? Theme.gold : Color.clear, lineWidth: 2))
                        .overlay(Group {
                            if done { Text("✓").font(.system(size: 13, weight: .black)).foregroundColor(Theme.money).padding(3) }
                        }, alignment: .topTrailing)
                        .opacity(done ? 0.7 : 1)
                }
            }
        }
        .card()
        .id(engine.served)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private var ingredientGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(engine.layout, id: \.self) { ing in
                Button {
                    let ok = withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { engine.tap(ing) }
                    if game.s.hapticsOn {
                        if ok { Feedback.light() } else { Feedback.error() }
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(Catalog.rushIngredients[ing].0).font(.system(size: 34))
                        Text(Catalog.rushIngredients[ing].1)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.cream)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.cardHi))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .animation(.easeInOut(duration: 0.25), value: engine.layout)
        .padding(.bottom, 8)
    }

    // MARK: Results

    private var overView: some View {
        VStack(spacing: 14) {
            Spacer()
            Text(engine.orders >= 10 ? "🏆" : (engine.orders >= 5 ? "🎉" : "👏"))
                .font(.system(size: 64))
            Text("خلص الوقت!")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Text("جهّزت \(engine.orders) طلبيات")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.gold)
            if let r = engine.reward {
                VStack(spacing: 8) {
                    if r.record {
                        Text("🥇 رقم قياسي جديد!")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(Theme.lira)
                    }
                    if engine.mistakes == 0 && engine.orders > 0 {
                        Text("✨ ولا غلطة! المكافأة ×1.5")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.money)
                    }
                    Text("+\(Fmt.money(r.cash))")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(Theme.money)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if r.liras > 0 {
                        Text("+\(r.liras) 🪙")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Theme.lira)
                    }
                    Text("أحسن كومبو: \(engine.bestCombo) · أغلاط: \(engine.mistakes)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .card()
                .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            startButton
            Button {
                withAnimation(.spring()) { game.showRush = false }
            } label: {
                Text("رجوع للبسطة")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .padding(.vertical, 6)
            }
        }
    }
}
