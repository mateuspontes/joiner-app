import Foundation

struct CalendarAccount: Identifiable, Hashable {
    let id: String
    let email: String
    let displayName: String
    var colorHex: String
    var isActive: Bool

    var color: AccountColor {
        AccountColor(rawValue: colorHex) ?? .green
    }
}

enum AccountColor: String, CaseIterable {
    case green = "#34C759"
    case red = "#FF3B30"
    case blue = "#007AFF"
    case orange = "#FF9500"
    case purple = "#AF52DE"
    case teal = "#5AC8FA"
}
