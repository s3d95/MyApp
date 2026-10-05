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
    // Palette from the "بسطة فلافل" logo: dusk sky, stall wood, golden title.
    static let bgTop = Color(hex: 0x2B1422)
    static let bgBottom = Color(hex: 0x3A1D12)
    static let card = Color(hex: 0x4A2718)
    static let cardHi = Color(hex: 0x5E331C)
    static let stroke = Color(hex: 0xF9B233).opacity(0.16)
    static let gold = Color(hex: 0xF9B233)
    static let money = Color(hex: 0x6EDB72)
    static let red = Color(hex: 0xE5533A)
    static let cream = Color(hex: 0xFFF4DE)
    static let muted = Color(hex: 0xDDBE9C)
    static let disabled = Color(hex: 0x5A3B2A)
    static let lira = Color(hex: 0xFACC15)
    static let star = Color(hex: 0xFDE68A)
    static let purple = Color(hex: 0xA855F7)
    static let blue = Color(hex: 0x3B82F6)
}

enum Feedback {
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)

    static func light() { lightGen.impactOccurred() }
    static func medium() { mediumGen.impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func click() { AudioServicesPlaySystemSound(1104) }
}

enum Fmt {
    private static let suffixes = ["ألف", "مليون", "مليار", "تريليون", "كوادريليون", "كوينتليون",
                                   "سكستليون", "سبتليون", "أوكتليون", "نونيليون", "ديسيليون",
                                   "أنديسيليون", "دوديسيليون", "تريديسيليون", "كواتوردسيليون"]

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

    /// A share like 0.025 as "2.5%".
    static func percent(_ v: Double) -> String {
        let p = v * 100
        return (p == p.rounded() ? String(format: "%.0f", p) : String(format: "%.1f", p)) + "%"
    }

    /// Multipliers like "×1.5" or "×2.3 مليون".
    static func multiplier(_ v: Double) -> String {
        if v < 10 { return String(format: "%.2f", (v * 100).rounded(.down) / 100) }
        return number(v)
    }

    /// Short cycle times like "4.0ث".
    static func seconds(_ s: Double) -> String {
        if s < 60 { return String(format: "%.1fث", max(0, s)) }
        return duration(s)
    }

    /// Human time away, like "2 ساعة و15 دقيقة".
    static func longDuration(_ s: Double) -> String {
        let t = max(0, Int(s))
        let h = t / 3600, m = (t % 3600) / 60
        if h > 0 { return m > 0 ? "\(h) ساعة و\(m) دقيقة" : "\(h) ساعة" }
        return "\(max(1, m)) دقيقة"
    }

    static func duration(_ s: Double) -> String {
        let t = max(0, Int(s.rounded(.up)))
        let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}
