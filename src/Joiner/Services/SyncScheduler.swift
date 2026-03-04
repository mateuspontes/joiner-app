import Foundation
import Combine

@MainActor
@Observable
final class SyncScheduler {
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
        for event in events {
            NotificationService.shared.scheduleNotifications(for: event)
        }
    }
}
