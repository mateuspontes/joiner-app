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
        let deduped = deduplicate(events)
        return deduped.sorted { $0.startDate < $1.startDate }
    }

    private func deduplicate(_ events: [CalendarEvent]) -> [CalendarEvent] {
        var byKey: [String: CalendarEvent] = [:]
        byKey.reserveCapacity(events.count)

        for event in events {
            let key = dedupKey(for: event)
            if let existing = byKey[key] {
                if shouldReplace(existing: existing, with: event) {
                    byKey[key] = event
                }
            } else {
                byKey[key] = event
            }
        }

        return Array(byKey.values)
    }

    private func dedupKey(for event: CalendarEvent) -> String {
        let title = normalizedText(event.title)
        let start = Int(event.startDate.timeIntervalSince1970)
        let end = Int(event.endDate.timeIntervalSince1970)

        if let link = event.meetingLink?.url {
            let normalizedLink = normalizedMeetingLink(link)
            return "link|\(normalizedLink)|\(start)|\(end)|\(title)"
        }

        let location = normalizedText(event.location ?? "")
        return "basic|\(title)|\(start)|\(end)|\(location)"
    }

    private func normalizedText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedMeetingLink(_ url: URL) -> String {
        var value = url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix("https://") {
            value.removeFirst("https://".count)
        } else if value.hasPrefix("http://") {
            value.removeFirst("http://".count)
        }
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }

    private func shouldReplace(existing: CalendarEvent, with candidate: CalendarEvent) -> Bool {
        let existingScore = eventQualityScore(existing)
        let candidateScore = eventQualityScore(candidate)
        if candidateScore != existingScore {
            return candidateScore > existingScore
        }
        if candidate.calendarTitle != existing.calendarTitle {
            return candidate.calendarTitle < existing.calendarTitle
        }
        return candidate.id < existing.id
    }

    private func eventQualityScore(_ event: CalendarEvent) -> Int {
        var score = 0
        if event.meetingLink != nil { score += 2 }
        if let location = event.location, !location.isEmpty { score += 1 }
        if let description = event.description, !description.isEmpty { score += 1 }
        return score
    }
}
