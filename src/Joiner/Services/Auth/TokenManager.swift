import Foundation
import GoogleSignIn

actor TokenManager {
    static let shared = TokenManager()

    private var refreshTasks: [String: Task<String, Error>] = [:]

    func getValidToken(for accountId: String) async throws -> String {
        // If already refreshing, wait for the existing task
        if let existingTask = refreshTasks[accountId] {
            return try await existingTask.value
        }

        // Try the current GIDSignIn user first
        if let user = await MainActor.run(body: { GIDSignIn.sharedInstance.currentUser }) {
            let task = Task<String, Error> {
                try await user.refreshTokensIfNeeded()
                return user.accessToken.tokenString
            }
            refreshTasks[accountId] = task

            do {
                let token = try await task.value
                refreshTasks[accountId] = nil
                return token
            } catch {
                refreshTasks[accountId] = nil
                throw error
            }
        }

        // Fall back to stored token
        guard let token = KeychainService.shared.getToken(forAccountId: accountId, type: .access) else {
            throw AuthError.noToken
        }
        return token
    }
}
