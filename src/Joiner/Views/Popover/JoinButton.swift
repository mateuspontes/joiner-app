import SwiftUI

struct JoinButton: View {
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("JOIN")
                .font(.system(size: compact ? 11 : 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, compact ? 10 : 20)
                .padding(.vertical, compact ? 4 : 8)
                .background(
                    RoundedRectangle(cornerRadius: compact ? 4 : 8)
                        .fill(Color.green)
                )
        }
        .buttonStyle(.plain)
    }
}
