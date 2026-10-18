import SwiftUI
import UIKit

enum Tier {
    case t0, t1, t2, t3
}

/// One feedback API for the whole game (GDD 1.8): T0 micro, T1 minor, T2 major, T3 epic.
/// Game code calls this instead of SFX, Haptic or FX directly.
enum Feedback {
    static var reduceMotion = false
    private static var lastT2: Double = -1000
    private static var lastT3: Double = -10000
    private static var t1Times: [Double] = []
    private static var lastT0: Double = 0

    private static var clock: Double { ProcessInfo.processInfo.systemUptime }

    static func play(_ tier: Tier, fromAnchor: String? = nil, at point: CGPoint? = nil, art: String? = nil,
                     to target: String? = nil, amount: Double = 1, label: String? = nil,
                     labelColor: Color = Brand.goldLight) {
        var tier = tier
        let now = clock
        if tier == .t3 {
            if now - lastT3 < 600 { tier = .t2 } else { lastT3 = now }
        }
        if tier == .t2 {
            if now - lastT2 < 60 { tier = .t1 } else { lastT2 = now }
        }
        let from = point ?? fromAnchor.flatMap { FX.shared.center($0) }
        switch tier {
        case .t0:
            guard now - lastT0 > 0.08 else { return }
            lastT0 = now
            SFX.tick.play(volume: 0.55)
            Haptic.tap()
        case .t1:
            t1Times = t1Times.filter { now - $0 < 1 }
            let allowFly = t1Times.count < 4
            t1Times.append(now)
            minor(from: from, art: art, target: target, amount: amount, label: label, color: labelColor, fly: allowFly)
            Haptic.press()
        case .t2:
            minor(from: from, art: art, target: target, amount: amount, label: label, color: labelColor, fly: true)
            SFX.levelup.play()
            Haptic.success()
            if !reduceMotion { FX.shared.confettiFromTop() }
        case .t3:
            minor(from: from, art: art, target: target, amount: amount, label: label, color: labelColor, fly: true)
            SFX.chest.play()
            Haptic.thud()
            Haptic.success()
            if !reduceMotion {
                FX.shared.confettiFromTop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { FX.shared.confettiFromTop() }
            }
        }
    }

    private static func minor(from: CGPoint?, art: String?, target: String?, amount: Double, label: String?,
                              color: Color, fly: Bool) {
        if let p = from, let a = art, let tg = target, fly, !reduceMotion {
            let n = Int(min(14, max(4, 4 + 2 * log10(max(1, amount)))))
            FX.shared.fly(a, from: p, to: tg, count: n, size: 28)
        } else if art != nil {
            SFX.coin.play(volume: 0.7)
        }
        if let l = label, let p = from {
            FX.shared.float(l, at: CGPoint(x: p.x, y: p.y - 18), color: color, size: 18)
        }
    }

    /// Can't afford / not allowed: error sound, no error haptic.
    static func error() {
        SFX.error.play(volume: 0.6)
    }
}
