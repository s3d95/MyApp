import Foundation
import UserNotifications

/// Local notifications only, at most one per day, true and useful (GDD 6.15).
enum Notifier {
    static func request(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }

    static func clearDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static func schedule(store: GameStore) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard store.s.settings.notifications, store.s.notif.granted else { return }
        let now = Date().timeIntervalSince1970
        var items: [(id: String, at: Double, text: String)] = []
        if store.managersCount > 0 {
            let when = outOfQuietHours(now + max(store.vaultCapHours, 6) * 3600)
            items.append(("vaultFull", when,
                          store.mf("الخزنة تعبّت يا معلّم! تعال اجمعها", "الخزنة تعبّت يا معلّمة! تعالي اجمعيها")))
        }
        items.append(("winback3", at(days: 3, hour: 18, minute: 30, from: now), "ستّي بتسأل عنك… البسطة مشتاقتلك"))
        items.append(("winback7", at(days: 7, hour: 18, minute: 30, from: now), "زباينك ناطرينك، وفي إشي جديد بالسوق"))
        var usedDays = Set<Int>()
        for it in items.sorted(by: { $0.at < $1.at }) {
            let day = Clock.gameDay(it.at)
            if usedDays.contains(day) { continue }
            usedDays.insert(day)
            let content = UNMutableNotificationContent()
            content.title = "بسطة فلافل"
            content.body = it.text
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, it.at - now), repeats: false)
            center.add(UNNotificationRequest(identifier: it.id, content: content, trigger: trigger))
        }
    }

    /// Quiet hours 22:00–09:00 push a notification to 09:00.
    static func outOfQuietHours(_ t: Double) -> Double {
        let h = Clock.hourMinute(t).h
        let midnight = Clock.midnight(t)
        if h >= 22 { return midnight + 86400 + 9 * 3600 }
        if h < 9 { return midnight + 9 * 3600 }
        return t
    }

    static func at(days: Int, hour: Int, minute: Int, from t: Double) -> Double {
        Clock.midnight(t) + Double(days) * 86400 + Double(hour * 3600 + minute * 60)
    }
}
