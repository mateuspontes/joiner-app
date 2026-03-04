import Foundation

enum DismissedEventsStore {
    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "dismissedEvents_\(formatter.string(from: Date()))"
    }

    static func dismissedIds() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: todayKey) ?? []
        return Set(array)
    }

    static func dismiss(_ eventId: String) {
        var ids = dismissedIds()
        ids.insert(eventId)
        UserDefaults.standard.set(Array(ids), forKey: todayKey)
        NotificationCenter.default.post(name: .dismissedEventsChanged, object: nil)
    }

    static func restoreAll() {
        UserDefaults.standard.removeObject(forKey: todayKey)
        NotificationCenter.default.post(name: .dismissedEventsChanged, object: nil)
    }

    static var hasDismissed: Bool {
        !dismissedIds().isEmpty
    }

    static var dismissedCount: Int {
        dismissedIds().count
    }

    /// Remove keys older than yesterday to prevent UserDefaults bloat.
    static func cleanupOldKeys() {
        let prefix = "dismissedEvents_"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = todayKey
        let yesterday = "dismissedEvents_\(formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))"

        for key in UserDefaults.standard.dictionaryRepresentation().keys
            where key.hasPrefix(prefix) && key != today && key != yesterday {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

extension Notification.Name {
    static let dismissedEventsChanged = Notification.Name("DismissedEventsChanged")
}
