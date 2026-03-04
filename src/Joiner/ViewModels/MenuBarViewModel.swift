import Foundation
import Combine
import AppKit

@Observable
final class MenuBarViewModel {
    var appState: AppState
    var sections: [EventSection] = []
    var nextUpEvent: CalendarEvent?
    var hasDismissedEvents = false
    var dismissedCount = 0

    private var refreshTimer: AnyCancellable?

    init(appState: AppState) {
        self.appState = appState
    }

    func startRefreshing() {
        refresh()
        refreshTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func stopRefreshing() {
        refreshTimer?.cancel()
    }

    func refresh() {
        let now = Date()
        let dismissedIds = DismissedEventsStore.dismissedIds()
        hasDismissedEvents = !dismissedIds.isEmpty
        dismissedCount = dismissedIds.count

        let events = appState.todayEvents
            .filter { !$0.isAllDay && !dismissedIds.contains($0.id) }

        // Update next up
        let threshold = now.addingTimeInterval(Double(Constants.nextUpThresholdMinutes) * 60)
        nextUpEvent = events.first { event in
            event.startDate > now && event.startDate <= threshold && event.meetingLink != nil
        }

        // Also include ongoing event with meeting link if no upcoming
        if nextUpEvent == nil {
            nextUpEvent = events.first { event in
                event.isOngoing && event.meetingLink != nil
            }
        }

        // Build sections from remaining events (only those with meeting links)
        let remainingEvents = events.filter { $0.id != nextUpEvent?.id && $0.meetingLink != nil }
        sections = buildSections(from: remainingEvents)
    }

    func joinMeeting(_ event: CalendarEvent) {
        guard let link = event.meetingLink else { return }
        NSWorkspace.shared.open(link.url)
    }

    func copyLink(_ event: CalendarEvent) {
        guard let link = event.meetingLink else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
    }

    func dismissEvent(_ event: CalendarEvent) {
        DismissedEventsStore.dismiss(event.id)
        refresh()
    }

    func restoreAllDismissed() {
        DismissedEventsStore.restoreAll()
        refresh()
    }

    // MARK: - Conflict Grouping

    private func buildSections(from events: [CalendarEvent]) -> [EventSection] {
        let sorted = events.sorted { $0.startDate < $1.startDate }
        var result: [EventSection] = []
        var i = 0

        while i < sorted.count {
            let current = sorted[i]
            var conflicting = [current]
            var maxEnd = current.endDate
            var j = i + 1

            while j < sorted.count && sorted[j].startDate < maxEnd {
                conflicting.append(sorted[j])
                maxEnd = max(maxEnd, sorted[j].endDate)
                j += 1
            }

            if conflicting.count > 1 {
                result.append(.conflict(ConflictGroup(events: conflicting)))
            } else {
                result.append(.single(current))
            }

            i = j
        }

        return result
    }
}
