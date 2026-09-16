import Foundation
import UserNotifications

enum NotificationService {
    static let rescanIdentifier = "com.zzoutuo.JawScore.weeklyRescan"

    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleWeeklyRescan() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [rescanIdentifier])
        let content = UNMutableNotificationContent()
        content.title = "Time for your weekly rescan"
        content.body = "See how your scores moved this week."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7 * 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: rescanIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
