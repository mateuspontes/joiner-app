import Foundation

final class GoogleCalendarAPIClient {
    private let baseURL = Constants.calendarAPIBase
    private let session = URLSession.shared

    // MARK: - Calendar List

    func fetchCalendarList(accessToken: String) async throws -> [GoogleCalendarInfo] {
        let url = URL(string: "\(baseURL)/users/me/calendarList")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let decoded = try JSONDecoder().decode(CalendarListResponse.self, from: data)
        return decoded.items ?? []
    }

    // MARK: - Events

    func fetchEvents(
        calendarId: String,
        accessToken: String,
        date: Date = Date()
    ) async throws -> [GoogleEventResponse] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var components = URLComponents(string: "\(baseURL)/calendars/\(calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: DateFormatters.iso8601Basic.string(from: startOfDay)),
            URLQueryItem(name: "timeMax", value: DateFormatters.iso8601Basic.string(from: endOfDay)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "50"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let decoded = try JSONDecoder().decode(EventListResponse.self, from: data)
        return decoded.items ?? []
    }

    // MARK: - Validation

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw CalendarAPIError.invalidResponse
        }
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw CalendarAPIError.unauthorized
        case 403:
            throw CalendarAPIError.forbidden
        case 429:
            throw CalendarAPIError.rateLimited
        default:
            throw CalendarAPIError.httpError(http.statusCode)
        }
    }
}

// MARK: - API Response Models

struct CalendarListResponse: Decodable {
    let items: [GoogleCalendarInfo]?
}

struct GoogleCalendarInfo: Decodable, Identifiable {
    let id: String
    let summary: String?
    let backgroundColor: String?
    let foregroundColor: String?
    let selected: Bool?
    let primary: Bool?
    let accessRole: String?
}

struct EventListResponse: Decodable {
    let items: [GoogleEventResponse]?
}

struct GoogleEventResponse: Decodable {
    let id: String?
    let summary: String?
    let description: String?
    let location: String?
    let start: EventDateTime?
    let end: EventDateTime?
    let status: String?
    let htmlLink: String?
    let hangoutLink: String?
    let conferenceData: ConferenceData?
}

struct EventDateTime: Decodable {
    let dateTime: String?
    let date: String?
    let timeZone: String?
}

struct ConferenceData: Decodable {
    let entryPoints: [EntryPoint]?
}

struct EntryPoint: Decodable {
    let entryPointType: String?
    let uri: String?
    let label: String?
}

enum CalendarAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case rateLimited
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Google Calendar API"
        case .unauthorized: return "Authentication expired. Please sign in again."
        case .forbidden: return "Access denied to calendar"
        case .rateLimited: return "Too many requests. Please wait."
        case .httpError(let code): return "HTTP error \(code)"
        }
    }
}
