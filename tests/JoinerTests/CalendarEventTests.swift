import XCTest
@testable import Joiner

final class CalendarEventTests: XCTestCase {

    func testTimeRangeFormatting() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!

        let event = CalendarEvent(
            id: "1",
            title: "Test Meeting",
            startDate: start,
            endDate: end,
            location: nil,
            description: nil,
            calendarId: "cal1",
            accountEmail: "user@test.com",
            accountColor: "#34C759",
            meetingLink: nil,
            isAllDay: false
        )

        XCTAssertEqual(event.timeRange, "17:00 - 18:00")
    }

    func testIsOngoing() {
        let now = Date()
        let event = CalendarEvent(
            id: "2",
            title: "Ongoing",
            startDate: now.addingTimeInterval(-600),
            endDate: now.addingTimeInterval(600),
            location: nil,
            description: nil,
            calendarId: "cal1",
            accountEmail: "user@test.com",
            accountColor: "#FF3B30",
            meetingLink: nil,
            isAllDay: false
        )

        XCTAssertTrue(event.isOngoing)
        XCTAssertTrue(event.hasStarted)
    }

    func testNotYetStarted() {
        let event = CalendarEvent(
            id: "3",
            title: "Future",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            location: nil,
            description: nil,
            calendarId: "cal1",
            accountEmail: "user@test.com",
            accountColor: "#007AFF",
            meetingLink: nil,
            isAllDay: false
        )

        XCTAssertFalse(event.isOngoing)
        XCTAssertFalse(event.hasStarted)
    }

    func testMeetingLinkAttachment() {
        let link = MeetingLink(
            platform: .googleMeet,
            url: URL(string: "https://meet.google.com/abc-defg-hij")!
        )

        var event = CalendarEvent(
            id: "4",
            title: "With Link",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            description: nil,
            calendarId: "cal1",
            accountEmail: "user@test.com",
            accountColor: "#34C759",
            meetingLink: nil,
            isAllDay: false
        )

        XCTAssertNil(event.meetingLink)
        event.meetingLink = link
        XCTAssertNotNil(event.meetingLink)
        XCTAssertEqual(event.meetingLink?.platform, .googleMeet)
    }
}
