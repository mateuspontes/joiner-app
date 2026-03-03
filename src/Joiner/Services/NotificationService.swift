import Foundation
import UserNotifications
import AppKit

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let joinActionId = Constants.joinActionIdentifier
    private let categoryId = Constants.meetingCategoryIdentifier
    private var scheduledEventIds: Set<String> = []

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
        guard event.startDate > Date() else { return }
        guard !scheduledEventIds.contains(event.id) else { return }

        scheduledEventIds.insert(event.id)

        // 5-minute pre-notification (no sound)
        let preNotificationDate = event.startDate.addingTimeInterval(-5 * 60)
        if preNotificationDate > Date() {
            scheduleNotification(
                id: "\(event.id)-pre",
                title: "Meeting in 5 minutes",
                body: event.title,
                meetingURL: event.meetingLink?.url.absoluteString,
                date: preNotificationDate,
                withSound: false
            )
        }

        // At-time notification (with sound)
        scheduleNotification(
            id: "\(event.id)-start",
            title: "Meeting starting now",
            body: event.title,
            meetingURL: event.meetingLink?.url.absoluteString,
            date: event.startDate,
            withSound: true
        )
    }

    func removeAllScheduled() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduledEventIds.removeAll()
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

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
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
        completionHandler([.banner, .sound])
    }
}
