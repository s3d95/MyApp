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
            Text("وإنت غايب، الموظفين ضلّوا شغّالين وربحولك:")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Text(Fmt.money(game.offlineGain))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(Theme.money)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Button {
                withAnimation { game.showOffline = false }
                if game.s.hapticsOn { Feedback.success() }
            } label: {
                BigButtonLabel(text: "استلم المصاري 💰")
            }
            .buttonStyle(PressableStyle())
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
            Text("بتبلّش ببسطة صغيرة بالقدس، وهدفك تصير أكبر سلسلة مطاعم بفلسطين. شو بدك تسمّي بسطتك؟")
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
