import Foundation

struct ConflictGroup: Identifiable {
    let id = UUID()
    let events: [CalendarEvent]

    var timeRange: String {
        guard let first = events.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let latestEnd = events.map(\.endDate).max() ?? first.endDate
        return "\(formatter.string(from: first.startDate)) - \(formatter.string(from: latestEnd))"
    }
}

enum EventSection: Identifiable {
    case single(CalendarEvent)
    case conflict(ConflictGroup)

    var id: String {
        switch self {
        case .single(let event): return event.id
        case .conflict(let group): return group.id.uuidString
        }
    }
}
