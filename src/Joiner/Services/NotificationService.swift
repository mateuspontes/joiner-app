import Foundation
import UserNotifications
import AppKit

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let joinActionId = Constants.joinActionIdentifier
    private let categoryId = Constants.meetingCategoryIdentifier
    private var didPromptForSettings = false

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
            if !granted {
                self.promptForNotificationSettingsIfNeeded()
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

        promptForNotificationSettingsIfNeeded()
        
        // Use user preferences
        let prefs = UserDefaults.standard
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
    }

    func removeAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func removeScheduled(for eventId: String) {
        let ids = ["\(eventId)-pre"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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

    private func promptForNotificationSettingsIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .denied else { return }
            DispatchQueue.main.async {
                guard !self.didPromptForSettings else { return }
                self.didPromptForSettings = true

                let alert = NSAlert()
                alert.messageText = "Notifications are disabled"
                alert.informativeText = "Enable Joiner notifications in System Settings to receive meeting reminders."
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Not now")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn,
                   let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
