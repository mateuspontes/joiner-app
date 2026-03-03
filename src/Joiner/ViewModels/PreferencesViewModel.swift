import Foundation
import ServiceManagement

@Observable
final class PreferencesViewModel {
    var authService: GoogleAuthService
    var enableSound = true
    var enableCountdown = true
    var enablePreNotification = true
    var preNotificationMinutes = 5
    var launchAtLogin = false

    var onAccountAdded: (() -> Void)?

    init(authService: GoogleAuthService) {
        self.authService = authService
        loadPreferences()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func addAccount() async {
        do {
            _ = try await authService.signIn()
            onAccountAdded?()
        } catch {
            print("Sign in failed: \(error)")
        }
    }

    func removeAccount(_ account: CalendarAccount) {
        authService.signOut(account: account)
    }

    func loadPreferences() {
        enableSound = UserDefaults.standard.object(forKey: "enableSound") as? Bool ?? true
        enableCountdown = UserDefaults.standard.object(forKey: "enableCountdown") as? Bool ?? true
        enablePreNotification = UserDefaults.standard.object(forKey: "enablePreNotification") as? Bool ?? true
        preNotificationMinutes = UserDefaults.standard.object(forKey: "preNotificationMinutes") as? Int ?? 5
    }

    func savePreferences() {
        UserDefaults.standard.set(enableSound, forKey: "enableSound")
        UserDefaults.standard.set(enableCountdown, forKey: "enableCountdown")
        UserDefaults.standard.set(enablePreNotification, forKey: "enablePreNotification")
        UserDefaults.standard.set(preNotificationMinutes, forKey: "preNotificationMinutes")
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            print("Launch at login failed: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
