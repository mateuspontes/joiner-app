import EventKit
import Foundation

enum EventParser {
    static func parse(_ ekEvent: EKEvent) -> CalendarEvent? {
        // Skip cancelled events
        guard ekEvent.status != .canceled else { return nil }

        let title = ekEvent.title ?? "(No title)"

        // Detect meeting link from location, notes, and url
        let meetingLink = MeetingLinkDetector.detect(in: [
            ekEvent.location,
            ekEvent.notes,
            ekEvent.url?.absoluteString,
        ])

        // Convert calendar color to hex string
        let colorHex: String
        if let cgColor = ekEvent.calendar.cgColor {
            colorHex = hexString(from: cgColor)
        } else {
            colorHex = "#4285F4"
        }

        return CalendarEvent(
            id: ekEvent.eventIdentifier ?? UUID().uuidString,
            title: title,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            location: ekEvent.location,
            description: ekEvent.notes,
            calendarId: ekEvent.calendar.calendarIdentifier,
            calendarTitle: ekEvent.calendar.title,
            calendarColor: colorHex,
            meetingLink: meetingLink,
            isAllDay: ekEvent.isAllDay
        )
    }

    private static func hexString(from cgColor: CGColor) -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#4285F4"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
