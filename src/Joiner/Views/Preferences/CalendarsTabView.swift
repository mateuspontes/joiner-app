import SwiftUI

struct CalendarsTabView: View {
    @Bindable var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar Visibility")
                .font(.headline)

            if !viewModel.eventKitService.hasAccess {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Calendar access not granted")
                            .foregroundStyle(.secondary)
                        Text("Grant access in System Settings > Privacy & Security > Calendars.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                Spacer()
            } else if viewModel.calendars.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No calendars found")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedSources, id: \.source) { group in
                            calendarSection(source: group.source, calendars: group.calendars)
                        }
                    }
                }
            }
        }
        .padding(20)
        .onAppear {
            viewModel.fetchCalendars()
        }
    }

    private struct SourceGroup {
        let source: String
        let calendars: [CalendarInfo]
    }

    private var groupedSources: [SourceGroup] {
        let grouped = Dictionary(grouping: viewModel.calendars, by: \.sourceName)
        return grouped.keys.sorted().map { key in
            SourceGroup(source: key, calendars: grouped[key]!)
        }
    }

    @ViewBuilder
    private func calendarSection(source: String, calendars: [CalendarInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(source)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(calendars) { calendar in
                calendarRow(calendar)
            }
        }
    }

    @ViewBuilder
    private func calendarRow(_ calendar: CalendarInfo) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: calendar.backgroundColor ?? "#4285F4") ?? .blue)
                .frame(width: 10, height: 10)

            Text(calendar.summary)
                .lineLimit(1)

            Spacer()

            Toggle("", isOn: Binding(
                get: { calendar.isVisible },
                set: { _ in viewModel.toggleCalendar(calendar) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.vertical, 2)
    }
}

