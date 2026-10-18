import SwiftUI

/// Rects of `.fxAnchor` views, published for the tutorial spotlight.
final class AnchorBox: ObservableObject {
    @Published var rects: [String: CGRect] = [:]
}

struct RootView: View {
    @StateObject private var store = GameStore()
    @State private var loading = !GameStore.isDemo
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            GameScreen()
                .environmentObject(store)
            if loading {
                LoadingView { loading = false }
                    .transition(.opacity)
            }
        }
        .onChange(of: phase) { p in
            switch p {
            case .active: store.didBecomeActive()
            case .background: store.didEnterBackground()
            default: break
            }
        }
    }
}

/// The root of the game. The root itself is left-to-right so that measured anchor frames, the tutorial
/// spotlight and flying effects all share one physical coordinate space; every screen inside is
/// laid out right-to-left for Arabic.
struct GameScreen: View {
    @EnvironmentObject var store: GameStore
    @StateObject private var box = AnchorBox()

    var body: some View {
        // The outer reader respects the safe area (for the insets); the inner one fills the screen,
        // so the game's coordinate space starts at the top-left corner of the display.
        GeometryReader { outer in
            let insets = outer.safeAreaInsets
            GeometryReader { geo in
                let full = geo.size
                ZStack {
                    CityBackdrop()
                    VStack(spacing: 0) {
                        HUDBar()
                            .padding(.top, insets.top + 4)
                        tabContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        GameTabBar(bottomInset: insets.bottom)
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                    ToastLayer(top: insets.top + 62)
                        .environment(\.layoutDirection, .rightToLeft)
                    SheetLayer()
                        .environment(\.layoutDirection, .rightToLeft)
                    ModalLayer()
                        .environment(\.layoutDirection, .rightToLeft)
                    TutorialLayer(box: box, size: full)
                    FXOverlay()
                    if GameStore.demoName == "anchors" {
                        DebugAnchorsView(box: box)
                    }
                }
                .frame(width: full.width, height: full.height)
                .coordinateSpace(name: gameSpace)
                .environment(\.layoutDirection, .leftToRight)
                .onPreferenceChange(FXAnchorKey.self) { value in
                    FX.shared.anchors = value
                    box.rects = value
                }
            }
            .ignoresSafeArea(.container, edges: .all)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch store.tab {
        case .home: KitchenScreen()
        case .map: MapScreen()
        case .chefs: ChefsScreen()
        case .shop: ShopScreen()
        default: TeaserScreen(tab: store.tab)
        }
    }
}

/// Dusk sky in the current city's palette behind every screen.
struct CityBackdrop: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        let sky = store.city.palette.sky
        ZStack {
            LinearGradient(colors: [Theme.bgTop, Theme.bgBottom], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [sky[0].opacity(0.9), sky[1].opacity(0.55), Theme.bgBottom.opacity(0.0)],
                           startPoint: .top, endPoint: .center)
            RadialGradient(colors: [store.city.palette.accentColor.opacity(0.18), Color.clear], center: .top,
                           startRadius: 10, endRadius: 420)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ToastLayer: View {
    @EnvironmentObject var store: GameStore
    let top: CGFloat

    var body: some View {
        VStack {
            if let t = store.toast {
                HStack(spacing: 8) {
                    if let a = t.art { ArtIcon(a, size: 28) }
                    Text(t.text)
                        .font(.game(15, .bold))
                        .foregroundColor(Brand.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.78)))
                .overlay(Capsule().stroke(Brand.gold.opacity(0.6), lineWidth: 1.5))
                .padding(.horizontal, 20)
                .id(t.id)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { store.toast = nil }
            }
            Spacer()
        }
        .padding(.top, top)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: store.toast?.id)
    }
}
