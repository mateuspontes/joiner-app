import Foundation
import Combine
import AppKit

@Observable
final class StatusItemViewModel {
    var countdownText: String?
    var isOverdue = false
    var isBlinking = false
    var showIcon = true

    private var updateTimer: AnyCancellable?
    private var blinkTimer: AnyCancellable?
    private var joinedMeetingIds: Set<String> = []
    private weak var appState: AppState?

    func bind(to appState: AppState) {
        self.appState = appState
        startMonitoring()
    }

    func markJoined(_ eventId: String) {
        joinedMeetingIds.insert(eventId)
        update()
    }

    func startMonitoring() {
        update()
        updateTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.update()
            }
    }

    func stopMonitoring() {
        updateTimer?.cancel()
        blinkTimer?.cancel()
    }

    private func update() {
        guard let appState else { return }

        let now = Date()
        let events = appState.todayEvents.filter { !$0.isAllDay }

        // Find next upcoming event
        let nextEvent = events.first { $0.startDate > now }

        if let next = nextEvent {
            let minutes = Int(next.startDate.timeIntervalSince(now) / 60)
            if minutes <= Constants.countdownThresholdMinutes {
                countdownText = DateFormatters.shortCountdown(minutes: max(1, minutes))
            } else {
                countdownText = nil
            }
        } else {
            countdownText = nil
        }

        // Check for overdue meetings (started but not joined)
        let overdueEvent = events.first { event in
            event.isOngoing
                && event.meetingLink != nil
                && !joinedMeetingIds.contains(event.id)
        }

        let wasOverdue = isOverdue
        isOverdue = overdueEvent != nil

        if isOverdue && !wasOverdue {
            startBlinking()
        } else if !isOverdue && wasOverdue {
            stopBlinking()
        }
    }

    private func startBlinking() {
        isBlinking = true
        blinkTimer = Timer.publish(every: 0.7, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.showIcon.toggle()
            }
    }

    private func stopBlinking() {
        isBlinking = false
        blinkTimer?.cancel()
        blinkTimer = nil
        showIcon = true
    }
}
