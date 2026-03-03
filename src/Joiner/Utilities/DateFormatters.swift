import Foundation

enum DateFormatters {
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso8601Basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func relativeMinutes(from date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Date()) / 60)
        if minutes <= 0 {
            return "Now"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) min"
        }
    }

    static func shortCountdown(minutes: Int) -> String {
        "\(minutes)m"
    }
}
