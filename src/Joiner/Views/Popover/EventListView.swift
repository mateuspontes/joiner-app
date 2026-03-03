import SwiftUI

struct EventListView: View {
    let sections: [EventSection]
    let onJoin: (CalendarEvent) -> Void
    let onCopyLink: (CalendarEvent) -> Void

    var body: some View {
        if sections.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(sections) { section in
                        switch section {
                        case .single(let event):
                            EventRowView(
                                event: event,
                                onJoin: { onJoin(event) },
                                onCopyLink: { onCopyLink(event) }
                            )
                        case .conflict(let group):
                            ConflictGroupView(
                                group: group,
                                onJoin: onJoin,
                                onCopyLink: onCopyLink
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No more events today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
