import Foundation

enum Constants {
    // MARK: - Google OAuth
    static let googleClientID = "773945224988-772b05fkqkmrlrjf4il0edgg2q116pvv.apps.googleusercontent.com"
    static let googleCalendarScope = "https://www.googleapis.com/auth/calendar.readonly"

    // MARK: - Google Calendar API
    static let calendarAPIBase = "https://www.googleapis.com/calendar/v3"

    // MARK: - Sync
    static let syncIntervalSeconds: TimeInterval = 15 * 60 // 15 minutes
    static let nextUpThresholdMinutes: Int = 15
    static let countdownThresholdMinutes: Int = 30

    // MARK: - Notification
    static let preNotificationMinutes: Int = 5
    static let joinActionIdentifier = "JOIN_NOW"
    static let meetingCategoryIdentifier = "MEETING_REMINDER"

    // MARK: - Keychain
    static let keychainService = "com.joinerapp.tokens"
}
