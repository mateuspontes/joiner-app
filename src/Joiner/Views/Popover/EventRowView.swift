import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent
    let onJoin: () -> Void
    let onCopyLink: () -> Void
    var onDismiss: (() -> Void)? = nil

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            AccountDot(colorHex: event.calendarColor, size: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.timeRange)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(event.calendarTitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .opacity(event.isPast ? 0.8 : 1)

            Spacer()

            if let link = event.meetingLink {
                HStack(spacing: 4) {
                    if isHovering {
                        if let onDismiss {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Dismiss event")
                        }

                        Button(action: onCopyLink) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .help("Copy link")
                    }

                    platformIcon(link.platform)

                    if !event.isPast {
                        JoinButton(compact: true, action: onJoin)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private func platformIcon(_ platform: MeetingPlatform) -> some View {
        Image(systemName: platform.iconName)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
    }
}
