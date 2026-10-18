import SwiftUI

/// Rects of `.fxAnchor` views, published for the tutorial spotlight.
final class AnchorBox: ObservableObject {
    @Published var rects: [String: CGRect] = [:]
}

struct RootView: View {
    @StateObject private var store = GameStore()
    @State private var loading = true
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

struct GameScreen: View {
    @EnvironmentObject var store: GameStore
    @StateObject private var box = AnchorBox()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CityBackdrop()
                VStack(spacing: 0) {
                    HUDBar()
                        .padding(.top, geo.safeAreaInsets.top + 4)
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    GameTabBar()
                        .padding(.bottom, max(6, geo.safeAreaInsets.bottom))
                }
                ToastLayer(top: geo.safeAreaInsets.top + 62)
                SheetLayer()
                ModalLayer()
                TutorialLayer(box: box, size: CGSize(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom))
                FXOverlay()
            }
            .ignoresSafeArea(.container, edges: .all)
            .coordinateSpace(name: gameSpace)
            .onPreferenceChange(FXAnchorKey.self) { value in
                FX.shared.anchors = value
                box.rects = value
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch store.tab {
        case .home: KitchenScreen()
        case .map: MapScreen()
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
