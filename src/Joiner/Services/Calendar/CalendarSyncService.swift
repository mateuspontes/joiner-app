import Foundation

@Observable
final class CalendarSyncService {
    private let eventKitService: EventKitService

    var isSyncing = false
    var lastError: String?

    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
    }

    @MainActor
    func syncEvents() -> [CalendarEvent] {
        isSyncing = true
        defer { isSyncing = false }
        lastError = nil

        guard eventKitService.hasAccess else {
            lastError = "No calendar access. Grant permission in System Settings."
            return []
        }

        let hiddenIds = PreferencesViewModel.hiddenCalendarIds()
        let allCalendars = eventKitService.fetchCalendars()
        let visibleIds = allCalendars
            .map(\.calendarIdentifier)
            .filter { !hiddenIds.contains($0) }

        let events = eventKitService.fetchTodayEvents(fromCalendarIds: visibleIds)
        return events.sorted { $0.startDate < $1.startDate }
    }
}
