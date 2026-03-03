import Foundation

@Observable
final class CalendarSyncService {
    private let apiClient = GoogleCalendarAPIClient()
    private let authService: GoogleAuthService

    var isSyncing = false
    var lastError: String?

    init(authService: GoogleAuthService) {
        self.authService = authService
    }

    func syncAllAccounts() async -> [CalendarEvent] {
        isSyncing = true
        defer { isSyncing = false }
        lastError = nil

        var allEvents: [CalendarEvent] = []

        for account in authService.accounts where account.isActive {
            do {
                let events = try await syncAccount(account)
                allEvents.append(contentsOf: events)
            } catch {
                lastError = "Failed to sync \(account.email): \(error.localizedDescription)"
            }
        }

        // Sort by start date
        allEvents.sort { $0.startDate < $1.startDate }
        return allEvents
    }

    private func syncAccount(_ account: CalendarAccount) async throws -> [CalendarEvent] {
        let accessToken = try await authService.getAccessToken(for: account.id)

        // Get all calendars for this account
        let calendars = try await apiClient.fetchCalendarList(accessToken: accessToken)
        let selectedCalendars = calendars.filter { $0.selected ?? false }

        var events: [CalendarEvent] = []

        for calendar in selectedCalendars {
            let rawEvents = try await apiClient.fetchEvents(
                calendarId: calendar.id,
                accessToken: accessToken
            )

            let parsed = rawEvents.compactMap { raw -> CalendarEvent? in
                EventParser.parse(raw, accountEmail: account.email, accountColor: account.colorHex, calendarId: calendar.id)
            }

            events.append(contentsOf: parsed)
        }

        return events
    }
}
