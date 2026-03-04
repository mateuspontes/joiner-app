import Foundation
import ServiceManagement

/// A calendar entry with local visibility toggle.
struct CalendarInfo: Identifiable {
    let id: String          // EKCalendar.calendarIdentifier
    let summary: String
    let sourceName: String
    let backgroundColor: String?
    var isVisible: Bool
}

@MainActor
@Observable
final class PreferencesViewModel {
    var eventKitService: EventKitService
    var enableSound = true
    var enableCountdown = true
    var enablePreNotification = true
    var preNotificationMinutes = 5
    var enableOpenAtMeetingTime = true
    var launchAtLogin = false

    var calendars: [CalendarInfo] = []
    var onCalendarVisibilityChanged: (() -> Void)?
    var onNotificationPreferencesChanged: (() -> Void)?

    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
        loadPreferences()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Calendar Fetching

    func fetchCalendars() {
        guard eventKitService.hasAccess else {
            calendars = []
            return
        }

        let ekCalendars = eventKitService.fetchCalendars()
        let hidden = Self.hiddenCalendarIds()

        calendars = ekCalendars.map { cal in
            let colorHex: String
            if let cgColor = cal.cgColor {
                let comps = cgColor.components ?? [0.26, 0.52, 0.96]
                let r = Int((comps.count > 0 ? comps[0] : 0.26) * 255)
                let g = Int((comps.count > 1 ? comps[1] : 0.52) * 255)
                let b = Int((comps.count > 2 ? comps[2] : 0.96) * 255)
                colorHex = String(format: "#%02X%02X%02X", r, g, b)
            } else {
                colorHex = "#4285F4"
            }

            return CalendarInfo(
                id: cal.calendarIdentifier,
                summary: cal.title,
                sourceName: cal.source.title,
                backgroundColor: colorHex,
                isVisible: !hidden.contains(cal.calendarIdentifier)
            )
        }.sorted { a, b in
            if a.sourceName != b.sourceName {
                return a.sourceName.localizedCaseInsensitiveCompare(b.sourceName) == .orderedAscending
            }
            return a.summary.localizedCaseInsensitiveCompare(b.summary) == .orderedAscending
        }
    }

    func toggleCalendar(_ calendar: CalendarInfo) {
        guard let index = calendars.firstIndex(where: { $0.id == calendar.id }) else { return }

        calendars[index].isVisible.toggle()

        var hidden = Self.hiddenCalendarIds()
        if calendars[index].isVisible {
            hidden.remove(calendar.id)
        } else {
            hidden.insert(calendar.id)
        }
        Self.setHiddenCalendarIds(hidden)
        onCalendarVisibilityChanged?()
    }

    // MARK: - Hidden Calendar Persistence

    private static let hiddenCalendarsKey = "hiddenCalendars"

    static func hiddenCalendarIds() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: hiddenCalendarsKey) ?? []
        return Set(array)
    }

    private static func setHiddenCalendarIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: hiddenCalendarsKey)
    }

    // MARK: - General Preferences

    func loadPreferences() {
        enableSound = UserDefaults.standard.object(forKey: "enableSound") as? Bool ?? true
        enableCountdown = UserDefaults.standard.object(forKey: "enableCountdown") as? Bool ?? true
        enablePreNotification = UserDefaults.standard.object(forKey: "enablePreNotification") as? Bool ?? true
        preNotificationMinutes = UserDefaults.standard.object(forKey: "preNotificationMinutes") as? Int ?? 5
        enableOpenAtMeetingTime = UserDefaults.standard.object(forKey: "enableOpenAtMeetingTime") as? Bool ?? true
    }

    func savePreferences() {
        UserDefaults.standard.set(enableSound, forKey: "enableSound")
        UserDefaults.standard.set(enableCountdown, forKey: "enableCountdown")
        UserDefaults.standard.set(enablePreNotification, forKey: "enablePreNotification")
        UserDefaults.standard.set(preNotificationMinutes, forKey: "preNotificationMinutes")
        UserDefaults.standard.set(enableOpenAtMeetingTime, forKey: "enableOpenAtMeetingTime")
        onNotificationPreferencesChanged?()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            print("Launch at login failed: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
