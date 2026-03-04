import XCTest
@testable import Joiner

final class EventListViewModelTests: XCTestCase {

    private func makeEvent(
        id: String = UUID().uuidString,
        title: String = "Test",
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0,
        isAllDay: Bool = false
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
            isAllDay: isAllDay
        )
    }

    func testEmptyEventsProducesEmptySections() {
        let vm = EventListViewModel()
        vm.update(with: [])
        XCTAssertTrue(vm.sections.isEmpty)
    }

    func testSingleEventProducesSingleSection() {
        let vm = EventListViewModel()
        vm.update(with: [
            makeEvent(title: "Standup", startHour: 10, endHour: 10, endMinute: 30)
        ])
        XCTAssertEqual(vm.sections.count, 1)
        if case .single(let event) = vm.sections.first {
            XCTAssertEqual(event.title, "Standup")
        } else {
            XCTFail("Expected single section")
        }
    }

    func testOverlappingEventsGroupedAsConflict() {
        let vm = EventListViewModel()
        vm.update(with: [
            makeEvent(id: "a", title: "Meeting A", startHour: 18, endHour: 18, endMinute: 45),
            makeEvent(id: "b", title: "Meeting B", startHour: 18, endHour: 19),
            makeEvent(id: "c", title: "Meeting C", startHour: 18, endHour: 18, endMinute: 30),
        ])

        XCTAssertEqual(vm.sections.count, 1)
        if case .conflict(let group) = vm.sections.first {
            XCTAssertEqual(group.events.count, 3)
        } else {
            XCTFail("Expected conflict section")
        }
    }

    func testNonOverlappingEventsAreSeparate() {
        let vm = EventListViewModel()
        vm.update(with: [
            makeEvent(id: "a", title: "Morning", startHour: 9, endHour: 10),
            makeEvent(id: "b", title: "Afternoon", startHour: 14, endHour: 15),
        ])

        XCTAssertEqual(vm.sections.count, 2)
    }

    func testAllDayEventsFiltered() {
        let vm = EventListViewModel()
        vm.update(with: [
            makeEvent(id: "allday", title: "Holiday", startHour: 0, endHour: 23, isAllDay: true),
            makeEvent(id: "regular", title: "Standup", startHour: 10, endHour: 10, endMinute: 30),
        ])

        XCTAssertEqual(vm.sections.count, 1)
        if case .single(let event) = vm.sections.first {
            XCTAssertEqual(event.title, "Standup")
        } else {
            XCTFail("Expected single section")
        }
    }
}
