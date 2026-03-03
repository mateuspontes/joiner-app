import Foundation
import GoogleSignIn
import AppKit

// @MainActor ensures all mutations to `accounts` happen on the main thread,
// which is required for @Observable to reliably trigger SwiftUI view updates
// through NSHostingController.
@MainActor
@Observable
final class GoogleAuthService {
    var accounts: [CalendarAccount] = []
    var isSigningIn = false

    // Keeps live GIDGoogleUser references for token refresh (in-memory only)
    private var userSessions: [String: GIDGoogleUser] = [:]

    private let calendarScope = Constants.googleCalendarScope

    func signIn() async throws -> CalendarAccount {
        isSigningIn = true
        defer { isSigningIn = false }

        print("[GoogleAuthService] signIn() called, accounts.count = \(accounts.count)")

        guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
            print("[GoogleAuthService] ERROR: no window available")
            throw AuthError.noWindow
        }
        print("[GoogleAuthService] presenting OAuth on window: \(window)")

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: [calendarScope]
            )
        } catch {
            print("[GoogleAuthService] GIDSignIn failed: \(error)")
            throw error
        }

        let user = result.user
        print("[GoogleAuthService] signed in as: \(user.profile?.email ?? "unknown")")

        let account = CalendarAccount(
            id: user.userID ?? UUID().uuidString,
            email: user.profile?.email ?? "unknown",
            displayName: user.profile?.name ?? "Unknown",
            colorHex: nextAccountColor().rawValue,
            isActive: true
        )

        // Keep live user reference for token refresh
        userSessions[account.id] = user

        // Update accounts on the main thread for reliable SwiftUI observation
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        print("[GoogleAuthService] accounts.count after append = \(accounts.count)")

        // Persist tokens and metadata to Keychain (best-effort — non-fatal)
        try? KeychainService.shared.storeToken(
            user.refreshToken.tokenString,
            forAccountId: account.id,
            type: .refresh
        )
        try? KeychainService.shared.storeToken(
            user.accessToken.tokenString,
            forAccountId: account.id,
            type: .access
        )
        KeychainService.shared.storeMetadata(forAccountId: account.id, key: "email", value: account.email)
        KeychainService.shared.storeMetadata(forAccountId: account.id, key: "displayName", value: account.displayName)
        KeychainService.shared.storeMetadata(forAccountId: account.id, key: "color", value: account.colorHex)

        return account
    }

    func signOut(account: CalendarAccount) {
        userSessions.removeValue(forKey: account.id)
        if GIDSignIn.sharedInstance.currentUser?.userID == account.id {
            GIDSignIn.sharedInstance.signOut()
        }
        try? KeychainService.shared.deleteTokens(forAccountId: account.id)
        accounts.removeAll { $0.id == account.id }
    }

    func restoreSessions() async {
        print("[GoogleAuthService] restoreSessions() start")
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            if let user = GIDSignIn.sharedInstance.currentUser, let userId = user.userID {
                userSessions[userId] = user
                print("[GoogleAuthService] restored GIDSignIn session for: \(user.profile?.email ?? userId)")
            }
        } catch {
            print("[GoogleAuthService] no previous GIDSignIn session: \(error)")
        }

        let storedIds = KeychainService.shared.allAccountIds()
        print("[GoogleAuthService] found \(storedIds.count) account(s) in Keychain: \(storedIds)")
        for accountId in storedIds {
            guard KeychainService.shared.getToken(forAccountId: accountId, type: .access) != nil else { continue }
            let account = CalendarAccount(
                id: accountId,
                email: KeychainService.shared.getMetadata(forAccountId: accountId, key: "email") ?? "unknown",
                displayName: KeychainService.shared.getMetadata(forAccountId: accountId, key: "displayName") ?? "Unknown",
                colorHex: KeychainService.shared.getMetadata(forAccountId: accountId, key: "color") ?? AccountColor.green.rawValue,
                isActive: true
            )
            if !accounts.contains(where: { $0.id == account.id }) {
                accounts.append(account)
            }
        }
        print("[GoogleAuthService] restoreSessions() done, accounts.count = \(accounts.count)")
    }

    /// Returns a valid access token for the given account, refreshing if possible.
    func getAccessToken(for accountId: String) async throws -> String {
        if let user = userSessions[accountId] {
            try await user.refreshTokensIfNeeded()
            try? KeychainService.shared.storeToken(
                user.accessToken.tokenString,
                forAccountId: accountId,
                type: .access
            )
            return user.accessToken.tokenString
        }

        guard let token = KeychainService.shared.getToken(forAccountId: accountId, type: .access) else {
            throw AuthError.noToken
        }
        return token
    }

    private func nextAccountColor() -> AccountColor {
        let usedColors = Set(accounts.map(\.colorHex))
        return AccountColor.allCases.first { !usedColors.contains($0.rawValue) } ?? .green
    }
}

enum AuthError: LocalizedError {
    case noWindow
    case noToken
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .noWindow: return "No window available for sign-in"
        case .noToken: return "No access token found"
        case .tokenExpired: return "Access token has expired"
        }
    }
}
