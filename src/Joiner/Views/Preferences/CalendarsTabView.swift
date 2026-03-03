import SwiftUI

struct CalendarsTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar Visibility")
                .font(.headline)

            Text("Calendar visibility is managed through your Google Calendar settings. Calendars marked as visible in Google Calendar will automatically appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("To hide a calendar, uncheck it in your Google Calendar sidebar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}
