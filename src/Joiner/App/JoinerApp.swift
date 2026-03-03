import SwiftUI

@main
struct JoinerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Preferences are managed by AppDelegate via PreferencesWindowController.
        // A minimal Settings scene is kept so SwiftUI doesn't complain about
        // having no scenes — it is never surfaced to the user.
        Settings {
            EmptyView()
        }
    }
}
