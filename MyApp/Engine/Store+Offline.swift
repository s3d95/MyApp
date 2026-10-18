import Foundation

/// Resume, clock guard, offline vault and newspaper (GDD 2.10, 7.3).
extension GameStore {
    var vaultCapHours: Double {
        min(econ.offline.maxCapHours, econ.offline.baseCapHours + researchValue("vaultCapHours") + heritageBonus("vaultCapHours"))
    }

    var vaultEff: Double { min(1, econ.offline.baseEff + researchValue("vaultEffPct") + marketVaultAdd) }

    /// Called at launch and on every return to the foreground.
    func resume(launch: Bool) {
        let wall = Date().timeIntervalSince1970
        let up = Clock.uptime()
        let boot = Clock.bootTime()
        let m = s.meta
        var trusted = wall
        var frozen = false
        if m.lastTrustedWall > 0 {
            if up >= m.lastUptime && m.lastUptime > 0 && abs(boot - m.bootTime) < 5 {
                // Same boot: the monotonic clock is the truth, whatever the wall clock says.
                trusted = m.lastTrustedWall + (up - m.lastUptime)
            } else if wall < m.lastTrustedWall - 300 {
                frozen = true
                trusted = m.lastTrustedWall
            } else {
                trusted = max(wall, m.lastTrustedWall)
            }
        }
        anchorWall = trusted
        anchorUptime = up
        lastTickUptime = up
        s.meta.clockFrozen = frozen
        let gap = (m.lastActiveTick > 0 && !frozen) ? max(0, trusted - m.lastActiveTick) : 0
        awayGapThisLaunch = gap
        if gap > 0 { applyAway(gap: gap, from: m.lastActiveTick) }
        rollover(trusted)
        stampClock()
        Notifier.clearDelivered()
        save()
    }

    func checkClockFrozen(wall: Double) {
        guard s.meta.clockFrozen else { return }
        if wall >= s.meta.lastTrustedWall {
            s.meta.clockFrozen = false
            anchorWall = wall
            anchorUptime = Clock.uptime()
        }
    }

    func applyAway(gap: Double, from start: Double) {
        let tNow = now()
        if gap < econ.offline.minGapSec {
            updateChains(dt: gap, at: tNow)
            advanceKitchen(dt: gap, at: tNow, foreground: false)
            return
        }
        // Unmanaged stations that were cooking finish their one cycle.
        for i in s.city.stations.indices where s.city.stations[i].cooking && !s.city.stations[i].managed {
            s.city.stations[i].cooking = false
            s.city.stations[i].progress = 0
            completeCycles(i, count: 1, at: tNow, foreground: false)
        }
        if let o = oven { credit(o.payout, station: o.station, at: tNow) }
        oven = nil
        special = nil
        let window = min(gap, vaultCapHours * 3600)
        let vault = offlineIntegrate(start: start, window: window)
        let sideLines = sideOffline(window: window)
        if let p = twist(.deliveryRuns) {
            s.city.twist.deliveryQueue = max(s.city.twist.deliveryQueue, min(3, p.queueMax))
        }
        var doughMin = 0
        if gap >= econ.freshDough.minGapHours * 3600 {
            let days = min(econ.freshDough.maxDays, floor(gap / 86400))
            doughMin = Int(econ.freshDough.minutesPerDay * days)
            addBoost("dough", mult: econ.freshDough.mult, seconds: Double(doughMin) * 60)
        }
        let o = econ.offline
        let cost = Int(min(o.doubleMax, max(o.doubleMin, (o.doubleGoldPerHour * window / 3600 * vaultEff).rounded(.up))))
        var lines: [String] = []
        if managersCount == 0 { lines.append("ما في معلّمين بيشتغلوا وإنت برّا. وظّف معلّم عشان الخزنة تتعبّى!") }
        if gap > window { lines.append("الخزنة بتوسع " + Num.dur(vaultCapHours * 3600) + " بس") }
        if canGraduate { lines.append("الرخصة جاهزة! فيك تفتح فرع وتنقل على " + t(nextCity?.name ?? GText(""))) }
        if !s.branches.isEmpty && safeFill >= 0.5 { lines.append("خزنة الفروع فيها " + Num.int(Int(s.branchSafe.stored)) + " ذهب") }
        lines += sideLines
        let info = NewsInfo(away: gap, vault: vault, cityName: t(city.name), currency: currencyName,
                            doubleCost: cost, canDouble: vault > 0 && s.wallet.vaultDoubleDay != gameDay,
                            lines: lines, freshDoughMin: doughMin)
        newsAwayGap = gap
        modals.removeAll { $0.id == "news" }
        modals.insert(.newspaper(info), at: 0)
    }

    /// Integrates managed income over the away window in steps, so night hours, chains, ships and
    /// day changes are all accounted for. Returns the vault amount (already × efficiency).
    func offlineIntegrate(start: Double, window: Double) -> Double {
        guard window > 0 else { return 0 }
        let steps = max(1, min(240, Int(window / 120)))
        let dt = window / Double(steps)
        let eff = vaultEff
        var total = 0.0
        var extra = 0.0
        let port = twist(.portShipments)
        let portIdx = idx(port?.station)
        for k in 0..<steps {
            let t = start + (Double(k) + 0.5) * dt
            updateChains(dt: dt, at: t)
            if port != nil { tickPort(at: t) }
            for i in s.city.stations.indices where s.city.stations[i].managed && s.city.stations[i].level > 0 {
                let earned = income(i, at: t, active: false) * dt
                total += earned
                twistMetricsOnCredit(i, amount: earned * eff, at: t)
                let cycles = dt / effCycle(i)
                s.city.counters["customers", default: 0] += cycles
                s.stats.customers += cycles
                if let p = port, portIdx == i, !s.city.twist.portLoaded,
                   let st = portStatus(at: t), st.docked, st.dockId == s.city.twist.portDockId {
                    s.city.twist.portUnits += cycles * Double(s.city.stations[i].level)
                    if s.city.twist.portUnits >= s.city.twist.portTarget {
                        s.city.twist.portLoaded = true
                        s.city.counters["shipmentsDelivered", default: 0] += 1
                        extra += p.rewardMin * 60 * totalIncome(active: false) * p.offlineRewardFrac
                    }
                }
            }
        }
        if let p = twist(.deliveryRuns), s.city.twist.dispatcher {
            let orders = floor(window / max(60, p.intervalMin * 60))
            if orders > 0 {
                s.city.counters["deliveriesDone", default: 0] += orders
                extra += orders * p.rewardMin * 60 * totalIncome(active: false) * p.offlineRewardFrac
            }
        }
        return total * eff + extra
    }

    var newsInfo: NewsInfo? {
        if case .newspaper(let info)? = modals.first { return info }
        return nil
    }

    func collectVault(double: Bool) {
        guard let info = newsInfo else { return }
        var amount = info.vault
        if double {
            guard info.canDouble, s.wallet.gold >= info.doubleCost else {
                Feedback.error()
                return
            }
            s.wallet.gold -= info.doubleCost
            s.wallet.vaultDoubleDay = gameDay
            amount *= 2
        }
        credit(amount, station: nil, at: now())
        s.happenings.lastVaultCollect = now()
        if info.away >= 1800 {
            s.stats.vaultCollects += 1
            bump("vaultCollects")
        }
        vaultCollectedFlag = true
        modals.removeFirst()
        if amount > 0 {
            Feedback.play(.t1, fromAnchor: "vault.collect", art: city.currency.art, to: "pill.cash", amount: amount,
                          label: "+" + Num.big(amount))
        } else {
            Feedback.play(.t0)
        }
        if info.freshDoughMin > 0 {
            showToast("عجينة طازة! دبل لمدّة " + Num.int(info.freshDoughMin) + " دقيقة", art: "food_bread")
        }
        evaluateFtue()
        flushLevelUp()
        save()
    }
}
