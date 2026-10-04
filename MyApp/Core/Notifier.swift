import Foundation
import UserNotifications

/// Local reminders that bring the player back: full offline earnings, the daily reward, full tickets.
enum Notifier {
    static func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(for s: GameState, now: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard s.notificationsOn, !s.stallName.isEmpty else { return }

        if s.lines.contains(where: { $0.hasManager }) {
            add(center, id: "offline",
                title: "الخزنة امتلت 💰",
                body: "المدراء بـ\(s.displayName) جمعولك أقصى أرباح. تعال استلمهم وكبّر الشغل!",
                after: s.offlineHours * 3600)
        }

        if let next = s.nextTicketAt, s.tickets < s.maxTickets {
            let full = next.addingTimeInterval(Double(s.maxTickets - s.tickets - 1) * Catalog.ticketHours * 3600)
            add(center, id: "tickets",
                title: "🎟️ التذاكر امتلت",
                body: "الزباين واقفين طابور! العب الطلبيات السريعة واربح مصاري وليرات دهب.",
                after: full.timeIntervalSince(now))
        }

        let midnight = DayClock.nextMidnight(after: now)
        if let morning = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: midnight) {
            let streak = s.loginDay == DayClock.day(now) ? s.loginStreak : 0
            let body = streak > 1
                ? "سلسلتك \(streak) يوم ورا بعض — لا تخلّيها تنقطع! مكافأتك ودولاب الحظ بيستنوك."
                : "مكافأتك اليومية ودولاب الحظ ومهام جديدة بيستنوك."
            add(center, id: "daily", title: "🎁 مكافأة اليوم جاهزة", body: body,
                after: morning.timeIntervalSince(now))
        }
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, title: String, body: String, after seconds: TimeInterval) {
        guard seconds > 60 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
