import Foundation
import Combine

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
        // Initial sync
        Task { await performSync() }

        // Periodic sync
        timer = Timer.publish(every: Constants.syncIntervalSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.performSync() }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func syncNow() async {
        await performSync()
    }

    private func performSync() async {
        appState.isLoading = true

        let events = await syncService.syncAllAccounts()
        appState.todayEvents = events
        appState.lastSyncDate = Date()
        appState.isLoading = false

        // Reschedule notifications
        NotificationService.shared.removeAllScheduled()
        for event in events where event.startDate > Date() {
            NotificationService.shared.scheduleNotifications(for: event)
        }
    }
}
