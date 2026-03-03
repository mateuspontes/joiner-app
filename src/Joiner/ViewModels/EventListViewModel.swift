import Foundation

@Observable
final class EventListViewModel {
    var sections: [EventSection] = []

    func update(with events: [CalendarEvent]) {
        let filtered = events
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        sections = groupIntoSections(filtered)
    }

    private func groupIntoSections(_ events: [CalendarEvent]) -> [EventSection] {
        var result: [EventSection] = []
        var i = 0

        while i < events.count {
            let current = events[i]
            var conflicting = [current]
            var maxEnd = current.endDate
            var j = i + 1

            while j < events.count && events[j].startDate < maxEnd {
                conflicting.append(events[j])
                maxEnd = max(maxEnd, events[j].endDate)
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
