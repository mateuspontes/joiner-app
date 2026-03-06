import EventKit
import Foundation
import Combine

@MainActor
final class EventKitService: ObservableObject {
    private let eventStore = EKEventStore()
    private var changeObserver: NSObjectProtocol?

    @Published var hasAccess = false
    var onCalendarChanged: (() -> Void)?

    // MARK: - Access

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            hasAccess = granted
            if granted { startMonitoring() }
            return granted
        } catch {
            print("EventKit access error: \(error)")
            hasAccess = false
            return false
        }
    }

    // MARK: - Calendars

    func fetchCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event)
    }

    // MARK: - Events

    func fetchTodayEvents(fromCalendarIds calendarIds: [String]) -> [CalendarEvent] {
        let allCalendars = eventStore.calendars(for: .event)
        let selectedCalendars = allCalendars.filter { calendarIds.contains($0.calendarIdentifier) }
        guard !selectedCalendars.isEmpty else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: selectedCalendars
        )

        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.compactMap { ekEvent in
            EventParser.parse(ekEvent)
        }
    }

    // MARK: - Change Monitoring

    func startMonitoring() {
        stopMonitoring()
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.onCalendarChanged?()
        }
    }

    func stopMonitoring() {
        if let observer = changeObserver {
            NotificationCenter.default.removeObserver(observer)
            changeObserver = nil
        }
    }
}
