import SwiftUI

struct StatusItemView: View {
    var countdownText: String?
    var isOverdue: Bool
    var showIcon: Bool

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: "video.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOverdue ? .red : .primary)
            }

            if let countdown = countdownText {
                Text(countdown)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(isOverdue ? .red : .primary)
            }
        }
    }
}
