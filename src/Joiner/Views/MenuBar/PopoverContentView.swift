import SwiftUI

struct PopoverContentView: View {
    @Bindable var viewModel: MenuBarViewModel
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

            // Dismissed events banner
            if viewModel.hasDismissedEvents {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.dismissedCount) dismissed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Restore all") {
                        viewModel.restoreAllDismissed()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Event list or empty state
            if viewModel.sections.isEmpty && viewModel.nextUpEvent == nil {
                emptyStateView
            } else {
                EventListView(
                    sections: viewModel.sections,
                    onJoin: { event in viewModel.joinMeeting(event) },
                    onCopyLink: { event in viewModel.copyLink(event) },
                    onDismiss: { event in viewModel.dismissEvent(event) }
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

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No meetings with video links today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
