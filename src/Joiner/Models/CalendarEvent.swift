import Foundation

struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let description: String?
    let calendarId: String
    let calendarTitle: String
    let calendarColor: String
    var meetingLink: MeetingLink?
    let isAllDay: Bool

    var isOngoing: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }

    var hasStarted: Bool {
        startDate <= Date()
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
