import SwiftUI

struct NextUpCardView: View {
    let event: CalendarEvent
    let onJoin: () -> Void

    @State private var minutesLeft: Int = 0
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Up")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 8) {
                AccountDot(colorHex: event.accountColor, size: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("from \(event.accountEmail)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }

            Text(statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            Button(action: onJoin) {
                Text("JOIN")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.white)
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(event.meetingLink == nil)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.gradient)
        )
        .padding(.horizontal, 12)
        .onAppear { updateMinutes() }
        .onReceive(timer) { _ in updateMinutes() }
    }

    private var statusText: String {
        if event.isOngoing {
            return "Happening now"
        }
        return "Starting in \(DateFormatters.relativeMinutes(from: event.startDate))"
    }

    private func updateMinutes() {
        minutesLeft = max(0, Int(event.startDate.timeIntervalSince(Date()) / 60))
    }
}
