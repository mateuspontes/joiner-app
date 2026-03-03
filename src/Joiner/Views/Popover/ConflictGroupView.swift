import SwiftUI

struct ConflictGroupView: View {
    let group: ConflictGroup
    let onJoin: (CalendarEvent) -> Void
    let onCopyLink: (CalendarEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("Conflict Warning")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            ForEach(group.events) { event in
                EventRowView(
                    event: event,
                    onJoin: { onJoin(event) },
                    onCopyLink: { onCopyLink(event) }
                )
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}
