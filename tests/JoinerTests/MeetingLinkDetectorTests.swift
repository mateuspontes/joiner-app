import XCTest
@testable import Joiner

final class MeetingLinkDetectorTests: XCTestCase {

    func testDetectsGoogleMeetLink() {
        let link = MeetingLinkDetector.detect(in: [
            "Join at https://meet.google.com/abc-defg-hij"
        ])
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.platform, .googleMeet)
        XCTAssertEqual(link?.url.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testDetectsZoomLink() {
        let link = MeetingLinkDetector.detect(in: [
            "Zoom: https://zoom.us/j/123456789?pwd=abc123"
        ])
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.platform, .zoom)
    }

    func testDetectsTeamsLink() {
        let link = MeetingLinkDetector.detect(in: [
            "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc"
        ])
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.platform, .teams)
    }

    func testDetectsSlackHuddleLink() {
        let link = MeetingLinkDetector.detect(in: [
            "https://app.slack.com/huddle/T123/C456"
        ])
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.platform, .slackHuddle)
    }

    func testReturnsNilForNoLink() {
        let link = MeetingLinkDetector.detect(in: [
            "Just a regular meeting with no video link"
        ])
        XCTAssertNil(link)
    }

    func testReturnsNilForEmptyInput() {
        let link = MeetingLinkDetector.detect(in: [nil, nil])
        XCTAssertNil(link)
    }

    func testDetectsLinkFromLocationField() {
        let link = MeetingLinkDetector.detect(in: [
            "https://meet.google.com/xyz-abcd-efg",
            nil
        ])
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.platform, .googleMeet)
    }

    func testPrioritizesGoogleMeetOverZoom() {
        let link = MeetingLinkDetector.detect(in: [
            "Meet: https://meet.google.com/abc-defg-hij and Zoom: https://zoom.us/j/123"
        ])
        XCTAssertEqual(link?.platform, .googleMeet)
    }
}
