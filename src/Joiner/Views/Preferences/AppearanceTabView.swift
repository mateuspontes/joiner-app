import SwiftUI

struct AppearanceTabView: View {
    @Bindable var viewModel: PreferencesViewModel

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable meeting notifications", isOn: $viewModel.enablePreNotification)

                Toggle("Play sound at meeting time", isOn: $viewModel.enableSound)

                Toggle("Open Joiner at meeting time", isOn: $viewModel.enableOpenAtMeetingTime)

                Picker("Pre-notification", selection: $viewModel.preNotificationMinutes) {
                    Text("1 minute before").tag(1)
                    Text("3 minutes before").tag(3)
                    Text("5 minutes before").tag(5)
                    Text("10 minutes before").tag(10)
                    Text("15 minutes before").tag(15)
                }
                .disabled(!viewModel.enablePreNotification)
            }

            Section("Menu Bar") {
                Toggle("Show countdown to next meeting", isOn: $viewModel.enableCountdown)
            }

            Section("General") {
                Toggle("Launch Joiner at login", isOn: $viewModel.launchAtLogin)
                    .onChange(of: viewModel.launchAtLogin) { _, newValue in
                        viewModel.setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .onChange(of: viewModel.enableSound) { _, _ in viewModel.savePreferences() }
        .onChange(of: viewModel.enableCountdown) { _, _ in viewModel.savePreferences() }
        .onChange(of: viewModel.enablePreNotification) { _, _ in viewModel.savePreferences() }
        .onChange(of: viewModel.preNotificationMinutes) { _, _ in viewModel.savePreferences() }
        .onChange(of: viewModel.enableOpenAtMeetingTime) { _, _ in viewModel.savePreferences() }
    }
}
