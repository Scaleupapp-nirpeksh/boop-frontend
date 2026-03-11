import Foundation

@Observable
final class AuthManager: @unchecked Sendable {
    static let shared = AuthManager()

    private(set) var currentUser: User?
    private(set) var isAuthenticated = false
    private(set) var isLoading = true
    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?

    var accessToken: String? {
        cachedAccessToken ?? KeychainManager.load(key: .accessToken)
    }

    private var isRefreshing = false
    private let refreshLock = NSLock()

    private init() {}

    // MARK: - Bootstrap

    @MainActor
    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }

        guard let tokens = KeychainManager.loadTokens() else {
            cachedAccessToken = nil
            cachedRefreshToken = nil
            isAuthenticated = false
            return
        }
        cachedAccessToken = tokens.accessToken
        cachedRefreshToken = tokens.refreshToken

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.me)
            currentUser = wrapper.user
            isAuthenticated = true
        } catch {
            // Token invalid — try refresh
            let refreshed = await refreshTokenIfNeeded()
            if refreshed {
                do {
                    let wrapper: UserWrapper = try await APIClient.shared.request(.me)
                    currentUser = wrapper.user
                    isAuthenticated = true
                } catch {
                    clearAuth()
                }
            } else {
                clearAuth()
            }
        }
    }

    // MARK: - Login

    @MainActor
    func handleLoginSuccess(response: VerifyOTPResponse) {
        let pair = TokenPair(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        cachedAccessToken = response.accessToken
        cachedRefreshToken = response.refreshToken
        KeychainManager.saveTokens(pair)
        currentUser = response.user
        isLoading = false
        isAuthenticated = true
    }

    // MARK: - Token Refresh

    func refreshTokenIfNeeded() async -> Bool {
        refreshLock.lock()
        if isRefreshing {
            refreshLock.unlock()
            try? await Task.sleep(for: .milliseconds(500))
            return accessToken != nil
        }
        isRefreshing = true
        refreshLock.unlock()

        defer {
            refreshLock.lock()
            isRefreshing = false
            refreshLock.unlock()
        }

        guard let refreshToken = cachedRefreshToken ?? KeychainManager.load(key: .refreshToken) else {
            return false
        }

        do {
            let response: RefreshTokenResponse = try await APIClient.shared.request(
                .refreshToken(RefreshTokenRequest(refreshToken: refreshToken))
            )
            // Backend refresh returns only a new accessToken (keeps same refreshToken)
            cachedAccessToken = response.accessToken
            KeychainManager.save(key: .accessToken, value: response.accessToken)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Fetch current user

    @MainActor
    func fetchCurrentUser() async {
        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.me)
            currentUser = wrapper.user
        } catch {
            // Silently fail — user data will be stale
        }
    }

    // MARK: - Logout

    @MainActor
    func logout() {
        Task.detached {
            try? await APIClient.shared.requestVoid(.logout)
        }
        clearAuth()
    }

    // MARK: - Update User

    @MainActor
    func updateUser(_ user: User) {
        currentUser = user
    }

    // MARK: - Private

    @MainActor
    private func clearAuth() {
        KeychainManager.clearTokens()
        cachedAccessToken = nil
        cachedRefreshToken = nil
        currentUser = nil
        isAuthenticated = false
    }
}
