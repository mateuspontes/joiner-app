import SwiftUI

struct PreferencesView: View {
    @Bindable var viewModel: PreferencesViewModel

    var body: some View {
        TabView {
            CalendarsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }

            AppearanceTabView(viewModel: viewModel)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 480, height: 360)
    }
}
