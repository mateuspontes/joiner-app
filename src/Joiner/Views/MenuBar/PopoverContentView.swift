import SwiftUI

struct PopoverContentView: View {
    @Bindable var viewModel: MenuBarViewModel
    var authService: GoogleAuthService
    var onSyncRequest: () -> Void
    var onOpenPreferences: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Next Up card
            if let nextUp = viewModel.nextUpEvent {
                NextUpCardView(event: nextUp) {
                    viewModel.joinMeeting(nextUp)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            // Today header
            HStack {
                Text("TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()

                if viewModel.appState.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            // Event list or empty state
            if authService.accounts.isEmpty {
                noAccountsView
            } else {
                EventListView(
                    sections: viewModel.sections,
                    onJoin: { event in viewModel.joinMeeting(event) },
                    onCopyLink: { event in viewModel.copyLink(event) }
                )
            }

            // Footer
            PopoverFooterView(onOpenPreferences: onOpenPreferences)
        }
        .frame(width: 340, height: 500)
        .background(VibrancyBackground())
        .onAppear {
            viewModel.startRefreshing()
        }
        .onDisappear {
            viewModel.stopRefreshing()
        }
    }

    private var noAccountsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No accounts connected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Open Preferences to add a Google account")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button("Open Preferences", action: onOpenPreferences)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
