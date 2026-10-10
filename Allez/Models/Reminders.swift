import Foundation
import UserNotifications

/// The daily "time to practise" notification. It's scheduled for the next 7 days and skips
/// today once you've done your 10 minutes.
enum Reminders {
    private static let ids = (0..<7).map { "daily-reminder-\($0)" }

    static func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    static func reschedule(for state: AppState) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        let settings = state.settings
        guard settings.remindersOn else { return }

        let streak = state.streak.count
        let doneToday = state.goalMet(on: .now)
        let today = Day.calendar.startOfDay(for: .now)
        for offset in 0..<7 {
            if offset == 0 && doneToday { continue }
            var parts = Day.calendar.dateComponents([.year, .month, .day], from: Day.adding(offset, to: today))
            parts.hour = settings.reminderHour
            parts.minute = settings.reminderMinute
            guard let fireDate = Day.calendar.date(from: parts), fireDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Time for French, \(settings.name)! 🇫🇷"
            content.body = streak > 0
                ? "Practise 10 minutes today to keep your \(streak)-day streak 🔥"
                : "Practise 10 minutes today to start a new streak 🔥"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: ids[offset], content: content, trigger: trigger))
        }
    }
}
