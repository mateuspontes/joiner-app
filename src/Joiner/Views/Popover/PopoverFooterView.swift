import SwiftUI

struct PopoverFooterView: View {
    var onOpenPreferences: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            footerButton(
                icon: "gearshape",
                title: "Accounts & Preferences...",
                shortcut: "⌘⇧P",
                action: onOpenPreferences
            )

            footerButton(
                icon: "power",
                title: "Quit Joiner",
                shortcut: "⌘⇧Q"
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func footerButton(
        icon: String,
        title: String,
        shortcut: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
