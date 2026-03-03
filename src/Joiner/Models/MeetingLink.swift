import Foundation

struct MeetingLink: Hashable {
    let platform: MeetingPlatform
    let url: URL
}

enum MeetingPlatform: String, CaseIterable {
    case googleMeet = "Google Meet"
    case zoom = "Zoom"
    case teams = "Microsoft Teams"
    case slackHuddle = "Slack Huddle"

    var iconName: String {
        switch self {
        case .googleMeet: return "video.fill"
        case .zoom: return "video.badge.checkmark"
        case .teams: return "person.3.fill"
        case .slackHuddle: return "headphones"
        }
    }
}
