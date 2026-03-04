import XCTest
@testable import Joiner

final class ConflictGroupTests: XCTestCase {

    private func makeEvent(
        id: String = UUID().uuidString,
        title: String = "Test",
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0
    ) -> CalendarEvent {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: today)!
        let end = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: today)!

        return CalendarEvent(
            id: id,
            title: title,
            startDate: start,
            endDate: end,
            location: nil,
            description: nil,
            calendarId: "cal1",
            calendarTitle: "test@test.com",
            calendarColor: "#34C759",
            meetingLink: nil,
            isAllDay: false
        )
    }

    func testConflictGroupTimeRange() {
        let events = [
            makeEvent(title: "A", startHour: 18, endHour: 18, endMinute: 45),
            makeEvent(title: "B", startHour: 18, endHour: 19),
        ]
        let group = ConflictGroup(events: events)
        XCTAssertTrue(group.timeRange.contains("18:00"))
        XCTAssertTrue(group.timeRange.contains("19:00"))
    }

    func testEventSectionIdentifiers() {
        let event = makeEvent(id: "evt1", startHour: 10, endHour: 11)
        let single = EventSection.single(event)
        XCTAssertEqual(single.id, "evt1")

        let group = ConflictGroup(events: [event])
        let conflict = EventSection.conflict(group)
        XCTAssertFalse(conflict.id.isEmpty)
    }
}
