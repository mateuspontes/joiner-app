import Foundation

struct MeetingLinkDetector {
    private static let patterns: [(MeetingPlatform, String)] = [
        (.googleMeet, #"https?://meet\.google\.com/[a-z\-]+"#),
        (.zoom, #"https?://[\w.-]*zoom\.us/(?:j|my)/[\w./?=&%\-]+"#),
        (.teams, #"https?://teams\.microsoft\.com/l/meetup-join/[\w./?=&%\-]+"#),
        (.slackHuddle, #"https?://[\w.-]*slack\.com/huddle/[\w./?=&%\-]+"#),
    ]

    static func detect(in texts: [String?]) -> MeetingLink? {
        let combined = texts.compactMap { $0 }.joined(separator: " ")
        guard !combined.isEmpty else { return nil }

        for (platform, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(combined.startIndex..., in: combined)
            if let match = regex.firstMatch(in: combined, range: range),
               let matchRange = Range(match.range, in: combined),
               let url = URL(string: String(combined[matchRange])) {
                return MeetingLink(platform: platform, url: url)
            }
        }
        return nil
    }
}
