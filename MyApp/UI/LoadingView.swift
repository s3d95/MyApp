import SwiftUI

/// Animated loading screen that continues the static launch screen: the logo stays exactly
/// where iOS drew it, then the sunset, lights, bunting and a wooden progress bar fade in.
struct LoadingView: View {
    let onFinish: () -> Void

    @State private var shown = false
    @State private var progress: CGFloat = 0
    @State private var step = 0
    @State private var bob = false
    @State private var leaving = false

    private let steps = [
        "عم نسخّن الزيت…",
        "عم نقلي الفلافل…",
        "عم نخبز الخبز…",
        "عم نحضّر الطحينة…",
        "عم نضوّي البسطة…",
    ]

    var body: some View {
        ZStack {
            Brand.duskTop.ignoresSafeArea()

            SunsetBackdrop()
                .opacity(shown ? 1 : 0)

            VStack(spacing: 0) {
                TwinkleLights()
                    .frame(height: 30)
                Bunting()
                    .frame(height: 42)
                Spacer()
            }
            .padding(.top, 4)
            .opacity(shown ? 1 : 0)

            // Centered on the whole screen, like the launch screen image.
            Color.clear
                .overlay(
                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .shadow(color: .black.opacity(shown ? 0.45 : 0), radius: 18, y: 10)
                        .scaleEffect(leaving ? 1.08 : 1)
                        .offset(y: bob ? -5 : 0)
                )
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()
                WoodLoadingBar(progress: progress)
                    .frame(width: 260, height: 24)
                Text(steps[step])
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Brand.cream)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                    .id(step)
                    .transition(.opacity)
                Text("Developer: Saad")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.cream.opacity(0.65))
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.top, 18)
            }
            .padding(.bottom, 28)
            .opacity(shown ? 1 : 0)
        }
        .opacity(leaving ? 0 : 1)
        .onAppear(perform: start)
    }

    private func start() {
        withAnimation(.easeOut(duration: 0.45)) { shown = true }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true }
        let total = 2.4
        let n = steps.count
        for k in 0..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + total * Double(k) / Double(n)) {
                withAnimation(.easeInOut(duration: total / Double(n))) {
                    progress = CGFloat(k + 1) / CGFloat(n)
                }
                withAnimation(.easeInOut(duration: 0.25)) { step = k }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + total) {
            withAnimation(.easeIn(duration: 0.35)) { leaving = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { onFinish() }
        }
    }
}
