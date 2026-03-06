import Foundation
import Combine

@MainActor
final class SyncScheduler: ObservableObject {
    private var timer: AnyCancellable?
    private let syncService: CalendarSyncService
    private let appState: AppState

    init(syncService: CalendarSyncService, appState: AppState) {
        self.syncService = syncService
        self.appState = appState
    }

    func start() {
        performSync()

        // Periodic sync as fallback (EventKit change notifications are the primary trigger)
        timer = Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performSync()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func syncNow() {
        performSync()
    }

    private func performSync() {
        appState.isLoading = true

        let events = syncService.syncEvents()
        appState.todayEvents = events
        appState.lastSyncDate = Date()
        appState.isLoading = false

        // Reschedule notifications
        NotificationService.shared.removeAllScheduled()
        MeetingStartService.shared.removeAllScheduled()
        let dismissedIds = DismissedEventsStore.dismissedIds()
        for event in events where !dismissedIds.contains(event.id) {
            NotificationService.shared.scheduleNotifications(for: event)
            MeetingStartService.shared.scheduleOpen(for: event)
        }
    }
}
