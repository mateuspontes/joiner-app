import SwiftUI

struct CountdownBadge: View {
    let text: String
    var isOverdue: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(isOverdue ? .red : .primary)
    }
}
