import Foundation
import AppKit

@MainActor
final class MeetingStartService {
    static let shared = MeetingStartService()

    var onMeetingStart: ((CalendarEvent) -> Void)?

    private var timers: [String: Timer] = [:]

    func scheduleOpen(for event: CalendarEvent) {
        guard event.meetingLink != nil else { return }
        guard !event.isAllDay else { return }

        let prefs = UserDefaults.standard
        let enableOpenAtMeetingTime = prefs.object(forKey: "enableOpenAtMeetingTime") as? Bool ?? true
        guard enableOpenAtMeetingTime else { return }

        let now = Date()
        guard event.startDate > now.addingTimeInterval(-5) else { return }

        let interval = max(0.1, event.startDate.timeIntervalSinceNow)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleMeetingStart(event)
        }

        timers[event.id]?.invalidate()
        timers[event.id] = timer
    }

    func removeAllScheduled() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    func removeScheduled(for eventId: String) {
        timers[eventId]?.invalidate()
        timers[eventId] = nil
    }

    private func handleMeetingStart(_ event: CalendarEvent) {
        timers[event.id]?.invalidate()
        timers[event.id] = nil

        playSoundIfEnabled()
        onMeetingStart?(event)
    }

    private func playSoundIfEnabled() {
        let enableSound = UserDefaults.standard.object(forKey: "enableSound") as? Bool ?? true
        guard enableSound else { return }

        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
