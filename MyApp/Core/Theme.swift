import SwiftUI
import UIKit
import AudioToolbox

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    static let bgTop = Color(hex: 0x1A120D)
    static let bgBottom = Color(hex: 0x24170F)
    static let card = Color(hex: 0x2E2018)
    static let stroke = Color.white.opacity(0.08)
    static let gold = Color(hex: 0xFBBF24)
    static let money = Color(hex: 0x4ADE80)
    static let red = Color(hex: 0xEF4444)
    static let cream = Color(hex: 0xFFF7E6)
    static let muted = Color(hex: 0xC9B8A6)
    static let disabled = Color(hex: 0x4A3B30)
}

enum Feedback {
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)

    static func light() { lightGen.impactOccurred() }
    static func medium() { mediumGen.impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func click() { AudioServicesPlaySystemSound(1104) }
}

enum Fmt {
    private static let suffixes = ["ألف", "مليون", "مليار", "تريليون", "كوادريليون", "كوينتليون",
                                   "سكستليون", "سبتليون", "أوكتليون", "نونيليون", "ديسيليون"]

    private static let grouped: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    static func money(_ v: Double) -> String { "₪" + number(v) }

    static func number(_ v: Double) -> String {
        guard v.isFinite else { return "∞" }
        let a = abs(v)
        if a < 10 {
            let r = (v * 10).rounded(.down) / 10
            return r == r.rounded() ? String(format: "%.0f", r) : String(format: "%.1f", r)
        }
        if a < 1_000_000 {
            return grouped.string(from: NSNumber(value: v.rounded(.down))) ?? String(format: "%.0f", v)
        }
        var exp = Int(log10(a) / 3)
        var scaled = v / pow(1000, Double(exp))
        if abs(scaled) >= 1000 { exp += 1; scaled /= 1000 }
        let idx = exp - 1
        guard idx < suffixes.count else { return String(format: "%.2e", v) }
        return "\(short(scaled)) \(suffixes[idx])"
    }

    private static func short(_ x: Double) -> String {
        if x >= 100 { return String(format: "%.0f", x.rounded(.down)) }
        if x >= 10 { return String(format: "%.1f", (x * 10).rounded(.down) / 10) }
        return String(format: "%.2f", (x * 100).rounded(.down) / 100)
    }

    static func duration(_ s: Double) -> String {
        let t = max(0, Int(s.rounded(.up)))
        let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}
