import Foundation

struct ChoiceOutcome {
    var text: String
    var lines: [RewardLine]
}

/// حكايات الحارة: choice events (GDD 6.12), and the rush minigame results (GDD 6.13).
extension GameStore {
    var hp: HappeningsFile { cat.happenings }

    func conditionMet(_ c: ConditionDef) -> Bool {
        if level < c.minLevel || level > c.maxLevel { return false }
        if !c.cityIds.isEmpty && !c.cityIds.contains(city.id) { return false }
        if !c.festivalIds.isEmpty { return false }
        if !c.weather.isEmpty {
            guard let w = cityWeather(day: gameDay), c.weather.contains(w.rawValue) else { return false }
        }
        if c.hours.count == 2 {
            let h = Clock.hourMinute(now()).h
            let a = c.hours[0]
            let b = c.hours[1]
            let inside = a <= b ? (h >= a && h < b) : (h >= a || h < b)
            if !inside { return false }
        }
        if !c.weekdays.isEmpty && !c.weekdays.contains(weekday) { return false }
        if let sys = c.requiresSystem, !(GameStore.builtSystems.contains(sys) && unlocked(sys)) { return false }
        if s.happenings.karma < c.minKarma { return false }
        if !c.flagsAll.allSatisfy({ s.happenings.flags.contains($0) }) { return false }
        if c.flagsNone.contains(where: { s.happenings.flags.contains($0) }) { return false }
        if s.happenings.playSeconds < c.minPlayMin * 60 { return false }
        return true
    }

    func tickChoices(dt: Double) {
        s.happenings.playSeconds += dt
        guard unlocked("choices"), kitchenVisible, special == nil,
              s.happenings.playSeconds >= hp.firstAfterPlayMin * 60 else { return }
        if s.happenings.choicesDay != dayNum {
            s.happenings.choicesDay = dayNum
            s.happenings.choicesToday = 0
        }
        guard s.happenings.choicesToday < hp.maxPerDay else { return }
        if s.happenings.choiceNext <= 0 {
            var r = Seed.rng("choiceGap", ["\(s.happenings.choiceCounter)"], player: s.meta.seed)
            s.happenings.choiceNext = hp.gapMinSec + r.unit() * (hp.gapMaxSec - hp.gapMinSec)
        }
        s.happenings.activeSinceChoice += dt
        guard s.happenings.activeSinceChoice >= s.happenings.choiceNext else { return }
        s.happenings.activeSinceChoice = 0
        s.happenings.choiceNext = 0
        s.happenings.choiceCounter += 1
        let pool = hp.choices.filter { row in
            let last = s.happenings.cooldowns[row.id] ?? -999
            return dayNum - last >= hp.cooldownDays && conditionMet(row.condition)
        }
        guard !pool.isEmpty else { return }
        var r = Seed.rng("choice", ["\(dayNum)", "\(s.happenings.choiceCounter)"], player: s.meta.seed)
        let row = pool[r.weighted(pool.map { $0.weight })]
        enqueue(.choice(row.id))
        SFX.pop.play()
    }

    func choiceBody(_ row: ChoiceRowDef) -> String {
        t(row.body)
            .replacingOccurrences(of: "{rival}", with: t(city.rival.name))
            .replacingOccurrences(of: "{city}", with: t(city.name))
    }

    /// Resolves a choice. Never net-negative: a stake is always followed by a larger reward.
    func resolveChoice(_ rowId: String, option: Int) -> ChoiceOutcome {
        guard let row = hp.choices.first(where: { $0.id == rowId }), option < row.choices.count else {
            return ChoiceOutcome(text: "", lines: [])
        }
        let opt = row.choices[option]
        var r = Seed.rng("choiceRoll", [rowId, "\(dayNum)", "\(s.happenings.choiceCounter)"], player: s.meta.seed)
        let idx = r.weighted(opt.outcomes.map { $0.p })
        guard idx < opt.outcomes.count else { return ChoiceOutcome(text: "", lines: []) }
        let outcome = opt.outcomes[idx]
        s.happenings.cooldowns[rowId] = dayNum
        s.happenings.choicesToday += 1
        bump("choices")
        rep("choice")
        addXP(5)
        var lines: [RewardLine] = []
        let inc = totalIncome(active: false) * (1 + researchValue("happeningRewardPct"))
        for e in outcome.effects {
            switch e.type {
            case "stake":
                let amount = min(s.city.cash, e.minutes * 60 * totalIncome(active: false))
                s.city.cash -= amount
            case "reward":
                guard let rw = e.reward else { continue }
                if rw.type == "incomeMin" {
                    let amount = rw.amount * 60 * inc
                    credit(amount, station: nil, at: now())
                    lines.append(RewardLine(art: city.currency.art, amount: "+" + Num.big(amount), caption: currencyName))
                } else if rw.type == "xp" {
                    addXP(Int(rw.amount))
                    lines.append(RewardLine(art: "ui_sparkles", amount: "+" + Num.int(Int(rw.amount)), caption: "خبرة"))
                } else if let l = applyReward(rw) {
                    lines.append(l)
                }
            case "incomeMult":
                let scope: String
                switch e.scopeKind {
                case "category": scope = "cat:" + (e.scopeValue ?? "")
                case "cuisine": scope = "cui:" + (e.scopeValue ?? "")
                default: scope = ""
                }
                let secs = e.durationSec ?? 1800
                addBoost("choice." + rowId, mult: e.mult, seconds: secs, scope: scope)
                lines.append(RewardLine(art: "ui_fire", amount: Num.mult(e.mult), caption: Num.dur(secs)))
            case "frenzy":
                addBoost("frenzy", mult: e.mult > 1 ? e.mult : econ.boosts.frenzyMult, seconds: e.durationSec ?? econ.boosts.frenzySec)
                lines.append(RewardLine(art: "ui_fire", amount: Num.mult(econ.boosts.frenzyMult), caption: "عجقة زباين"))
            case "spawnSpecial":
                if special == nil { spawnSpecial(forced: nil) }
            case "karma":
                s.happenings.karma += e.delta
            case "setFlag":
                if let f = e.flag, !s.happenings.flags.contains(f) { s.happenings.flags.append(f) }
            case "storyScene":
                if let id = e.sceneId { playScene(id) }
            case "freeRushRound":
                s.wallet.tickets = min(9, s.wallet.tickets + 1)
                lines.append(RewardLine(art: "ui_admission_tickets", amount: "+1", caption: "تذكرة"))
            default:
                break
            }
        }
        for k in hp.karmaRewards where s.happenings.karma >= k.karma && !s.happenings.karmaClaimed.contains(k.karma) {
            s.happenings.karmaClaimed.append(k.karma)
            for rw in k.rewards { if let l = applyReward(rw) { lines.append(l) } }
        }
        Feedback.play(.t1)
        save()
        return ChoiceOutcome(text: t(outcome.text), lines: lines)
    }

    // MARK: Rush minigame results (GDD 6.13)

    var rushBest: Int { s.rush.best[city.id] ?? 0 }

    func startRush(practice: Bool) {
        if !practice {
            guard s.wallet.tickets > 0 else {
                showToast("ما معك تذاكر. بتجيك وحدة كل 3 ساعات", art: "ui_admission_tickets")
                Feedback.error()
                return
            }
            s.wallet.tickets -= 1
            if s.wallet.tickets < ticketCap && s.wallet.ticketAt <= 0 { s.wallet.ticketAt = now() }
        }
        enqueue(.rush(practice: practice))
        save()
    }

    func finishRush(score: Int, practice: Bool) -> [RewardLine] {
        guard !practice else { return [] }
        var lines: [RewardLine] = []
        let minutes = min(30, max(5, 5 + Double(score) / 400))
        let existing = s.boosts.first { $0.kind == "walla" }?.left ?? 0
        addBoost("walla", mult: 2, seconds: min(3600, existing + minutes * 60))
        lines.append(RewardLine(art: "ui_fire", amount: "×2", caption: "ولعة " + Num.dur(minutes * 60)))
        let cash = Double(score) / 1000 * 3 * 60 * totalIncome(active: false)
        if cash > 0 {
            credit(cash, station: nil, at: now())
            lines.append(RewardLine(art: city.currency.art, amount: "+" + Num.big(cash), caption: currencyName))
        }
        addXP(10)
        lines.append(RewardLine(art: "ui_sparkles", amount: "+10", caption: "خبرة"))
        bump("rushRounds")
        seasonPoint("rushRound")
        bump("rep", Double(10 + score / 500))
        if score > rushBest {
            s.rush.best[city.id] = score
            Feedback.play(.t2)
        } else {
            Feedback.play(.t1)
        }
        s.rush.rounds += 1
        save()
        return lines
    }
}
