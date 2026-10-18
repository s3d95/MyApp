import SwiftUI
import UIKit

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
