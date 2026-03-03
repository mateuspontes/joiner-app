import SwiftUI

struct AccountsTabView: View {
    @Bindable var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected Google Accounts")
                .font(.headline)

            if viewModel.authService.accounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No accounts connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add a Google account to see your calendar events")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.authService.accounts) { account in
                        HStack(spacing: 12) {
                            AccountDot(colorHex: account.colorHex, size: 12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                Text(account.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Remove") {
                                viewModel.removeAccount(account)
                            }
                            .foregroundStyle(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }

            HStack {
                Spacer()
                Button {
                    Task { await viewModel.addAccount() }
                } label: {
                    Label("Add Google Account", systemImage: "plus")
                }
                .controlSize(.large)
            }
        }
        .padding(20)
    }
}
