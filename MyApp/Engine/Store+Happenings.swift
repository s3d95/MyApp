import Foundation

/// Special customers and active boosts (GDD 2.11, 6.12).
extension GameStore {
    // MARK: Boosts

    func tickBoosts(dt: Double) {
        guard !s.boosts.isEmpty else { return }
        for i in s.boosts.indices { s.boosts[i].left -= dt }
        if s.boosts.contains(where: { $0.left <= 0 }) { s.boosts.removeAll { $0.left <= 0 } }
    }

    func addBoost(_ kind: String, mult: Double, seconds: Double) {
        if let i = s.boosts.firstIndex(where: { $0.kind == kind }) {
            s.boosts[i].left = max(s.boosts[i].left, seconds)
            s.boosts[i].mult = mult
        } else {
            s.boosts.append(BoostSave(kind: kind, mult: mult, left: seconds))
        }
    }

    func boostName(_ kind: String) -> String {
        switch kind {
        case "frenzy": return "عجقة زباين"
        case "critic": return "ناقد طعام"
        case "dough": return "عجينة طازة"
        default: return kind
        }
    }

    func boostArt(_ kind: String) -> String {
        switch kind {
        case "frenzy": return "ui_fire"
        case "critic": return "ui_memo"
        case "dough": return "food_bread"
        default: return "ui_sparkles"
        }
    }

    // MARK: Special customers

    var specialAllowed: Bool {
        unlocked("specials") && (s.ftue.done || s.ftue.step > 10)
    }

    func rollNextSpecial() {
        var r = Seed.rng("special", ["\(s.happenings.specialCounter)", "gap"], player: s.meta.seed)
        var t = 300.0
        while t < 900 {
            let p = pow((t - 300) / 600, 5)
            if r.unit() < p { break }
            t += 1
        }
        let m = twist(.vipLounge)?.specialIntervalMult ?? 1
        s.happenings.nextSpecialAt = t * m
        s.happenings.activeSinceSpecial = 0
    }

    func tickSpecials(dt: Double, at t: Double) {
        if let sp = special {
            if t - sp.spawnedAt > sp.lifetime {
                special = nil
                rollNextSpecial()
            }
            return
        }
        guard specialAllowed, kitchenVisible else { return }
        if s.happenings.nextSpecialAt <= 0 { rollNextSpecial() }
        s.happenings.activeSinceSpecial += dt
        if s.happenings.activeSinceSpecial >= s.happenings.nextSpecialAt { spawnSpecial(forced: nil) }
    }

    func spawnSpecial(forced: SpecialOutcome?) {
        var r = Seed.rng("special", ["\(s.happenings.specialCounter)", "spawn"], player: s.meta.seed)
        s.happenings.specialCounter += 1
        let outcomes: [SpecialOutcome] = [.tip, .frenzy, .critic, .bus]
        let pick = outcomes[r.weighted([60, 25, 8, 7])]
        var vip = 0
        if forced == nil, let p = twist(.vipLounge), r.unit() < p.vipShare {
            vip = 1 + r.weighted(p.vipTierWeights)
        }
        let pool = city.customerArts + StreetScene.defaultCustomers
        let art = vip > 0 ? "ppl_prince" : pool[r.int(pool.count)]
        let life: Double = forced != nil ? 600 : 15
        special = SpecialVisit(art: art, outcome: forced ?? pick, vipTier: vip, spawnedAt: now(), lifetime: life)
        s.happenings.activeSinceSpecial = 0
        SFX.pop.play()
        Haptic.tap()
    }

    func tapSpecial() {
        guard let sp = special else { return }
        special = nil
        rollNextSpecial()
        s.city.counters["specials", default: 0] += 1
        s.stats.specials += 1
        specialTappedFlag = true
        addXP(econ.xp.special)
        let inc = totalIncome(active: false)
        if sp.vipTier > 0, let p = twist(.vipLounge) {
            let lv = loungeIndex.map { s.city.stations[$0].level } ?? 0
            if lv >= sp.vipTier * p.levelPerTier {
                let amount = p.vipTipMin * Double(sp.vipTier) * 60 * inc
                credit(amount, station: nil, at: now())
                s.city.counters["vipServed", default: 0] += 1
                Feedback.play(.t1, fromAnchor: "special", art: city.currency.art, to: "pill.cash", amount: amount,
                              label: "ضيف VIP! +" + Num.big(amount))
            } else {
                showToast("صالة كبار الزوار بدها تكبر (مستوى " + Num.int(sp.vipTier * p.levelPerTier) + ")", art: "ppl_prince")
            }
            evaluateFtue()
            return
        }
        switch sp.outcome {
        case .tip:
            let amount = max(2 * 60 * inc, min(0.15 * s.city.cash, 15 * 60 * inc))
            credit(amount, station: nil, at: now())
            Feedback.play(.t1, fromAnchor: "special", art: city.currency.art, to: "pill.cash", amount: amount,
                          label: "زبون كريم! +" + Num.big(amount))
        case .frenzy:
            addBoost("frenzy", mult: econ.boosts.frenzyMult, seconds: econ.boosts.frenzySec)
            Feedback.play(.t2)
            showToast("عجقة زباين! الدخل " + Num.mult(econ.boosts.frenzyMult), art: "ui_fire")
        case .critic:
            addBoost("critic", mult: 2, seconds: 300)
            Feedback.play(.t1, fromAnchor: "special", art: "ui_memo", to: "pill.cash", amount: 1, label: "ناقد طعام! ×2")
            showToast("ناقد طعام مدح البسطة! ×2 لـ 5د", art: "ui_memo")
        case .bus:
            let amount = 10 * 60 * inc
            credit(amount, station: nil, at: now())
            Feedback.play(.t1, fromAnchor: "special", art: city.currency.art, to: "pill.cash", amount: amount,
                          label: "باص رحلة! +" + Num.big(amount))
        }
        evaluateFtue()
    }

    func specialIcon(_ sp: SpecialVisit) -> String {
        if sp.vipTier > 0 { return "ui_crown" }
        switch sp.outcome {
        case .tip: return "ui_money_bag"
        case .frenzy: return "ui_fire"
        case .critic: return "ui_memo"
        case .bus: return "veh_bus"
        }
    }
}
