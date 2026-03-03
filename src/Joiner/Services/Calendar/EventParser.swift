import Foundation

enum EventParser {
    static func parse(
        _ raw: GoogleEventResponse,
        accountEmail: String,
        accountColor: String,
        calendarId: String
    ) -> CalendarEvent? {
        guard let id = raw.id else { return nil }

        // Skip cancelled events
        if raw.status == "cancelled" { return nil }

        // Parse dates
        let isAllDay = raw.start?.date != nil && raw.start?.dateTime == nil

        let startDate: Date
        let endDate: Date

        if let dateTimeStr = raw.start?.dateTime {
            guard let start = parseDateTime(dateTimeStr) else { return nil }
            startDate = start
        } else if let dateStr = raw.start?.date {
            guard let start = parseDateOnly(dateStr) else { return nil }
            startDate = start
        } else {
            return nil
        }

        if let dateTimeStr = raw.end?.dateTime {
            endDate = parseDateTime(dateTimeStr) ?? startDate.addingTimeInterval(3600)
        } else if let dateStr = raw.end?.date {
            endDate = parseDateOnly(dateStr) ?? startDate.addingTimeInterval(86400)
        } else {
            endDate = startDate.addingTimeInterval(3600)
        }

        let title = raw.summary ?? "(No title)"

        // Detect meeting link - check multiple sources
        var meetingLink = detectMeetingLink(from: raw)

        // If no link from conference data, try location and description
        if meetingLink == nil {
            meetingLink = MeetingLinkDetector.detect(in: [raw.location, raw.description])
        }

        return CalendarEvent(
            id: "\(accountEmail)_\(id)",
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: raw.location,
            description: raw.description,
            calendarId: calendarId,
            accountEmail: accountEmail,
            accountColor: accountColor,
            meetingLink: meetingLink,
            isAllDay: isAllDay
        )
    }

    private static func detectMeetingLink(from raw: GoogleEventResponse) -> MeetingLink? {
        // Priority 1: hangoutLink (Google Meet)
        if let hangoutLink = raw.hangoutLink, let url = URL(string: hangoutLink) {
            return MeetingLink(platform: .googleMeet, url: url)
        }

        // Priority 2: Conference data entry points
        if let entryPoints = raw.conferenceData?.entryPoints {
            for entry in entryPoints where entry.entryPointType == "video" {
                if let uri = entry.uri, let url = URL(string: uri) {
                    let platform = detectPlatform(from: uri)
                    return MeetingLink(platform: platform, url: url)
                }
            }
        }

        return nil
    }

    private static func detectPlatform(from urlString: String) -> MeetingPlatform {
        if urlString.contains("meet.google.com") { return .googleMeet }
        if urlString.contains("zoom.us") { return .zoom }
        if urlString.contains("teams.microsoft.com") { return .teams }
        if urlString.contains("slack.com/huddle") { return .slackHuddle }
        return .googleMeet // default for unknown video links
    }

    private static func parseDateTime(_ string: String) -> Date? {
        DateFormatters.iso8601.date(from: string)
            ?? DateFormatters.iso8601Basic.date(from: string)
    }

    private static func parseDateOnly(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }
}
