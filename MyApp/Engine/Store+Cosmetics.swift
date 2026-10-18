import SwiftUI

// MARK: - Content (cosmetics.json)

struct CosmeticDef: Decodable, Identifiable {
    var id = ""
    var name = GText("")
    var slot = "awning"
    var art: String? = nil
    var pattern = "solid"
    var colors: [String] = []
    var price: Int? = nil
    var source = "level"

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        name = c.v("name", GText(id))
        slot = c.v("slot", slot)
        art = c.opt("art")
        pattern = c.v("pattern", pattern)
        colors = c.v("colors", [])
        price = c.intOpt("price")
        source = c.v("source", source)
    }

    var swatch: [Color] { colors.map { Color(hexString: $0) } }
}

struct CosmeticsFile: Decodable {
    var cosmetics: [CosmeticDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        cosmetics = c.v("cosmetics", [])
    }
}

// MARK: - Engine (GDD 6.20): visual only, applied to every kitchen's stall

extension GameStore {
    static let cosmeticSlots = ["awning", "sign", "lights", "prop", "frame"]

    func slotName(_ slot: String) -> String {
        switch slot {
        case "awning": return "المظلّة"
        case "sign": return "اليافطة"
        case "lights": return "الإضاءة"
        case "prop": return "الإكسسوار"
        default: return "الإطار"
        }
    }

    func cosmetic(_ id: String) -> CosmeticDef? { cat.cosmetics.cosmetics.first { $0.id == id } }

    func ownsCosmetic(_ c: CosmeticDef) -> Bool { c.source == "default" || s.cosmetics.owned.contains(c.id) }

    func equipped(_ slot: String) -> CosmeticDef? {
        if let id = s.cosmetics.equipped[slot], let c = cosmetic(id) { return c }
        return cat.cosmetics.cosmetics.first { $0.slot == slot && $0.source == "default" }
    }

    func grantCosmetic(_ id: String) {
        var real = id
        if id == "seasonCosmetic" || id == "themeDecoration" {
            let pool = cat.cosmetics.cosmetics.filter { ($0.source == "season" || $0.source == "event") && !s.cosmetics.owned.contains($0.id) }
            guard let pick = pool.first else { return }
            real = pick.id
        }
        guard cosmetic(real) != nil, !s.cosmetics.owned.contains(real) else { return }
        s.cosmetics.owned.append(real)
    }

    func buyCosmetic(_ c: CosmeticDef) {
        guard let price = c.price, !ownsCosmetic(c) else { return }
        guard s.wallet.gold >= price else {
            Feedback.error()
            showToast("الذهب مش كافي", art: "ui_coin")
            return
        }
        s.wallet.gold -= price
        s.cosmetics.owned.append(c.id)
        wear(c)
        Feedback.play(.t2)
        save()
    }

    func wear(_ c: CosmeticDef) {
        guard ownsCosmetic(c) else { return }
        s.cosmetics.equipped[c.slot] = c.id
        Feedback.play(.t1)
        save()
    }

    var awningColors: (Color, Color) {
        let sw = equipped("awning")?.swatch ?? []
        return (sw.first ?? Brand.awningOrange, sw.count > 1 ? sw[1] : Brand.awningCream)
    }

    var propArt: String? { equipped("prop")?.art }

    var lightsArt: String? {
        guard let c = equipped("lights"), c.source != "default" else { return nil }
        return c.art
    }

    var signColor: Color? {
        guard let c = equipped("sign"), c.source != "default" else { return nil }
        return c.swatch.first
    }
}
