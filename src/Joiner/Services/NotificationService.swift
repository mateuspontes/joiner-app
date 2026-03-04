import Foundation
import UserNotifications
import AppKit

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let joinActionId = Constants.joinActionIdentifier
    private let categoryId = Constants.meetingCategoryIdentifier

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }

        let joinAction = UNNotificationAction(
            identifier: joinActionId,
            title: "Join Now",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [joinAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([category])
    }

    func scheduleNotifications(for event: CalendarEvent) {
        guard event.meetingLink != nil else { return }
        guard !event.isAllDay else { return }
        
        // Use user preferences
        let prefs = UserDefaults.standard
        let enableSound = prefs.object(forKey: "enableSound") as? Bool ?? true
        let enableNotifications = prefs.object(forKey: "enablePreNotification") as? Bool ?? true // Rename for clarity if needed
        let preMinutes = prefs.object(forKey: "preNotificationMinutes") as? Int ?? 5

        guard enableNotifications else { return }

        let now = Date()
        
        // 5-minute pre-notification
        let preNotificationDate = event.startDate.addingTimeInterval(-TimeInterval(preMinutes * 60))
        if preNotificationDate > now {
            scheduleNotification(
                id: "\(event.id)-pre",
                title: "Meeting in \(preMinutes) minutes",
                body: event.title,
                meetingURL: event.meetingLink?.url.absoluteString,
                date: preNotificationDate,
                withSound: false // Spec: no sound for pre-notification
            )
        }

        // At-time notification
        // Schedule if in the future or within the last 5 seconds (to handle sync race conditions)
        if event.startDate > now.addingTimeInterval(-5) {
            scheduleNotification(
                id: "\(event.id)-start",
                title: "Meeting starting now",
                body: event.title,
                meetingURL: event.meetingLink?.url.absoluteString,
                date: event.startDate,
                withSound: enableSound
            )
        }
    }

    func removeAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        meetingURL: String?,
        date: Date,
        withSound: Bool
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = categoryId

        if withSound {
            content.sound = .default
        }

        if let url = meetingURL {
            content.userInfo = ["meetingURL": url]
        }

        let timeInterval = date.timeIntervalSinceNow
        
        // If it's slightly in the past (within 5s) but we're just scheduling it,
        // fire it almost immediately (e.g. 0.1s).
        let triggerInterval = max(0.1, timeInterval)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification \(id): \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == joinActionId || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let urlString = response.notification.request.content.userInfo["meetingURL"] as? String,
               let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // If notification content has sound, include it in presentation options
        if notification.request.content.sound != nil {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.banner])
        }
    }
}
