import SwiftUI

struct VIPLayer: View {
    @EnvironmentObject var game: Game
    let vip: VIP
    @State private var bob = false

    var body: some View {
        GeometryReader { geo in
            Button { game.claimVIP() } label: {
                VStack(spacing: 3) {
                    Text("🤵")
                        .font(.system(size: 42))
                        .padding(10)
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().stroke(Theme.gold, lineWidth: 3))
                        .shadow(color: Theme.gold.opacity(0.9), radius: bob ? 18 : 6)
                    Text("زبون VIP!")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: 0x2A1608))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.gold))
                }
            }
            .buttonStyle(PressableStyle())
            .offset(y: bob ? -8 : 8)
            .position(x: geo.size.width * vip.x, y: geo.size.height * vip.y)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { bob = true }
            }
        }
    }
}

struct ToastView: View {
    let toast: ToastMsg

    var body: some View {
        HStack(spacing: 8) {
            Text(toast.icon).font(.system(size: 20))
            Text(toast.text)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.cream)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color(hex: 0x3A2A1F)))
        .overlay(Capsule().stroke(Theme.gold.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}

struct OfflineView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        ModalCard {
            Text("🌙").font(.system(size: 56))
            Text("أهلاً فيك رجعت!")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Text("غبت \(Fmt.longDuration(game.offlineSeconds))، والمدراء ضلّوا يبيعوا وربحولك:")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Text(Fmt.money(game.offlineGain))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(Theme.money)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if !game.offlineDoubled {
                GoldButton(title: "ضاعفهم ×2", cost: Game.doubleOfflineCost,
                           enabled: game.s.liras >= Game.doubleOfflineCost) {
                    withAnimation(.spring()) { game.doubleOffline() }
                }
            } else {
                Text("✨ تضاعفوا!")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.lira)
            }
            Button {
                withAnimation { game.showOffline = false }
                if game.s.hapticsOn { Feedback.success() }
            } label: {
                BigButtonLabel(text: "استلم المصاري 💰")
            }
            .buttonStyle(PressableStyle())
            Text("المدراء بيشتغلوا لحد \(Int(game.s.offlineHours)) ساعة وإنت برّا")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.muted.opacity(0.8))
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var game: Game
    @State private var name = ""

    var body: some View {
        ModalCard {
            Text("🧆").font(.system(size: 64))
            Text("أهلاً فيك بإمبراطورية الفلافل!")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
                .multilineTextAlignment(.center)
            Text("بتبلّش ببسطة صغيرة بالقدس، وهدفك تصير أكبر سلسلة مطاعم بفلسطين والعالم. شو بدك تسمّي بسطتك؟")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            TextField("مثلاً: فلافل الأصالة", text: $name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.cream)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
            Button {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                withAnimation { game.rename(trimmed.isEmpty ? "فلافل الأصالة" : trimmed) }
                if game.s.hapticsOn { Feedback.success() }
            } label: {
                BigButtonLabel(text: "افتح البسطة 🚀")
            }
            .buttonStyle(PressableStyle())
        }
    }
}

/// Daily login reward with the 7-day streak track.
struct LoginView: View {
    @EnvironmentObject var game: Game
    @State private var pop = false

    var body: some View {
        let today = game.today
        let index = game.s.loginTrackIndex(today: today)
        let streak = game.s.loginDay == today - 1 ? game.s.loginStreak + 1 : 1
        let reward = Catalog.loginTrack[index]

        ModalCard {
            Text("🎁")
                .font(.system(size: 60))
                .scaleEffect(pop ? 1.08 : 0.92)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pop = true }
                }
            Text("مكافأة اليوم \(streak)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Theme.cream)
            Text(streak > 1 ? "🔥 \(streak) يوم ورا بعض! ارجع بكرة عشان تكمّل السلسلة." : "افتح اللعبة كل يوم والمكافآت بتكبر، واليوم السابع فيه صندوق دهب!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            LoginTrack(current: index, claimedThrough: index - 1)
            Text(reward.text)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.lira)
                .multilineTextAlignment(.center)
            Button {
                game.claimLogin()
            } label: {
                BigButtonLabel(text: "استلم المكافأة")
            }
            .buttonStyle(PressableStyle())
        }
    }
}

/// Row of the 7 daily rewards; `current` is highlighted.
struct LoginTrack: View {
    let current: Int
    let claimedThrough: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { k in
                let r = Catalog.loginTrack[k]
                VStack(spacing: 2) {
                    Text(k <= claimedThrough ? "✅" : r.icon).font(.system(size: 17))
                    Text("\(k + 1)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(k == current ? Color(hex: 0x2A1608) : Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(k == current ? Theme.gold : Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(k == 6 ? Theme.lira.opacity(0.6) : Color.clear, lineWidth: 1))
            }
        }
    }
}
