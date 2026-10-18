import Foundation

/// Number and time formatting (GDD 0): Western digits by default, Arabic scale words,
/// every number wrapped in bidi isolates so it reads correctly inside RTL text.
enum Num {
    static var arabicDigits = false

    private static let scaleWords = ["مليون", "مليار", "تريليون", "كوادريليون", "كوينتليون",
                                     "سكستليون", "سبتليون", "أوكتليون", "نونليون", "ديسيليون"]

    private static let grouped: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        f.groupingSize = 3
        f.maximumFractionDigits = 0
        return f
    }()

    static func iso(_ s: String) -> String { "\u{2066}" + digits(s) + "\u{2069}" }

    private static func digits(_ s: String) -> String {
        guard arabicDigits else { return s }
        let map: [Character: Character] = ["0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
                                           "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩"]
        return String(s.map { map[$0] ?? $0 })
    }

    /// Big numbers: "12,450", "3.45 مليون", "1.23e34".
    static func big(_ v: Double) -> String {
        guard v.isFinite else { return iso("∞") }
        let a = abs(v)
        if a < 10 {
            let r = (v * 10).rounded(.down) / 10
            if r == r.rounded() { return iso(String(format: "%.0f", r)) }
            return iso(String(format: "%.1f", r))
        }
        if a < 1_000_000 {
            return iso(grouped.string(from: NSNumber(value: v.rounded(.down))) ?? String(format: "%.0f", v))
        }
        var exp3 = Int(floor(log10(a) / 3))
        var scaled = v / pow(10, Double(exp3 * 3))
        if abs(scaled) >= 1000 {
            exp3 += 1
            scaled /= 1000
        }
        let idx = exp3 - 2
        guard idx >= 0, idx < scaleWords.count else { return iso(String(format: "%.2e", v)) }
        return iso(sig3(scaled)) + " " + scaleWords[idx]
    }

    /// "12/40" kept together as one left-to-right unit inside Arabic text.
    static func frac(_ a: Int, _ b: Int) -> String {
        iso(plain(a) + "/" + plain(b))
    }

    private static func plain(_ v: Int) -> String { grouped.string(from: NSNumber(value: v)) ?? "\(v)" }

    /// Progress like "1,200/3,000" (one unit) or "1.2 مليون / 3 مليار" for big values.
    static func fracBig(_ a: Double, _ b: Double) -> String {
        if abs(a) < 1_000_000 && abs(b) < 1_000_000 {
            let pa = grouped.string(from: NSNumber(value: a.rounded(.down))) ?? "\(Int(a))"
            let pb = grouped.string(from: NSNumber(value: b.rounded(.down))) ?? "\(Int(b))"
            return iso(pa + "/" + pb)
        }
        return big(a) + " / " + big(b)
    }

    /// Puts a plus sign inside the number's isolate so it stays on the number's left in Arabic text.
    static func plus(_ s: String) -> String {
        if s.hasPrefix("\u{2066}") { return "\u{2066}+" + s.dropFirst() }
        return "+" + s
    }

    /// Integers (gold, stars, XP) with grouping.
    static func int(_ v: Int) -> String {
        iso(grouped.string(from: NSNumber(value: v)) ?? "\(v)")
    }

    private static func sig3(_ x: Double) -> String {
        if x >= 100 { return String(format: "%.0f", x.rounded(.down)) }
        if x >= 10 {
            let r = (x * 10).rounded(.down) / 10
            return r == r.rounded() ? String(format: "%.0f", r) : String(format: "%.1f", r)
        }
        let r = (x * 100).rounded(.down) / 100
        if r == r.rounded() { return String(format: "%.0f", r) }
        var s = String(format: "%.2f", r)
        while s.hasSuffix("0") { s.removeLast() }
        return s
    }

    /// "×3", "×1.25", "×2.4 مليون".
    static func mult(_ v: Double) -> String {
        if v < 1000 {
            let r = (v * 100).rounded() / 100
            let s: String
            if r == r.rounded() {
                s = String(format: "%.0f", r)
            } else if (r * 10).rounded() == r * 10 {
                s = String(format: "%.1f", r)
            } else {
                s = String(format: "%.2f", r)
            }
            return iso("×" + s)
        }
        return iso("×") + big(v)
    }

    /// "2س 14د", "45د", "30ث", "3 أيام". Never seconds above 10 minutes.
    static func dur(_ seconds: Double) -> String {
        let t = max(0, Int(seconds.rounded(.up)))
        let d = t / 86400
        let h = (t % 86400) / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if d >= 2 { return iso("\(d)") + " أيام" }
        if d == 1 { return h > 0 ? "يوم و" + iso("\(h)") + "س" : "يوم" }
        if h > 0 { return m > 0 ? iso("\(h)") + "س " + iso("\(m)") + "د" : iso("\(h)") + "س" }
        if t > 600 { return iso("\(m)") + "د" }
        if m > 0 { return s > 0 ? iso("\(m)") + "د " + iso("\(s)") + "ث" : iso("\(m)") + "د" }
        return iso("\(s)") + "ث"
    }

    /// Cycle time like "1.5ث".
    static func cycle(_ s: Double) -> String {
        if s < 10 { return iso(String(format: "%.1f", s)) + "ث" }
        return dur(s)
    }

    static func percent(_ f: Double) -> String {
        iso(String(format: "%.0f", (f * 100).rounded(.down)) + "%")
    }
}
