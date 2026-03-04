import Foundation
import Observation

@Observable
final class AppState {
    var todayEvents: [CalendarEvent] = []
    var isLoading = false
    var lastSyncDate: Date?

    var nextUpEvent: CalendarEvent? {
        let now = Date()
        let threshold = now.addingTimeInterval(15 * 60)
        return todayEvents.first { event in
            event.startDate > now && event.startDate <= threshold && event.meetingLink != nil
        }
    }

    var minutesUntilNext: Int? {
        guard let next = todayEvents.first(where: { $0.startDate > Date() }) else { return nil }
        let minutes = Int(next.startDate.timeIntervalSince(Date()) / 60)
        return minutes <= 30 ? minutes : nil
    }
}
