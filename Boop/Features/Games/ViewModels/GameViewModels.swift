import Foundation

@Observable
final class MatchGamesViewModel {
    let matchId: String

    var games: [GameSummary] = []
    var isLoading = false
    var isCreating = false
    var errorMessage: String?

    init(matchId: String) {
        self.matchId = matchId
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: MatchGamesResponse = try await APIClient.shared.request(.getGamesForMatch(matchId: matchId))
            games = response.games
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load games."
        }
    }

    @MainActor
    func createGame(type: String) async -> String? {
        isCreating = true
        defer { isCreating = false }

        do {
            let response: GameActionResponse = try await APIClient.shared.request(
                .createGame(CreateGameRequest(matchId: matchId, gameType: type))
            )
            await load()
            errorMessage = nil
            return response.gameId
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not start the game."
        }
        return nil
    }

    var activeGames: [GameSummary] {
        games.filter { $0.status == "pending" || $0.status == "active" }
    }

    var completedGames: [GameSummary] {
        games.filter { $0.status == "completed" }
    }

    /// Returns the earliest replay-available date for a given game type, or nil if no cooldown
    func cooldownEnd(for gameType: String) -> Date? {
        // Check if there's an active/pending game of this type
        if games.contains(where: { $0.gameType == gameType && ($0.status == "pending" || $0.status == "active") }) {
            return nil // Can't replay — active game exists
        }
        // Find the most recent completed game of this type with a cooldown
        let completed = games
            .filter { $0.gameType == gameType && $0.status == "completed" }
            .compactMap { $0.sync?.replayAvailableAt }
            .sorted()
            .last
        guard let replayAt = completed, replayAt > Date() else { return nil }
        return replayAt
    }

    /// Whether a game type is currently on cooldown or has an active game
    func isGameTypeBlocked(_ gameType: String) -> Bool {
        if games.contains(where: { $0.gameType == gameType && ($0.status == "pending" || $0.status == "active") }) {
            return true
        }
        if let cooldown = cooldownEnd(for: gameType), cooldown > Date() {
            return true
        }
        return false
    }

    /// Replay a completed game type (just calls createGame)
    @MainActor
    func replayGame(type: String) async -> String? {
        return await createGame(type: type)
    }
}

@Observable
final class GameSessionViewModel {
    let gameId: String

    var game: GameSession?
    var answer = ""
    var sliderValue: Double = 5.0
    var isLoading = false
    var isSubmitting = false
    var isUpdatingReady = false
    var errorMessage: String?

    init(gameId: String) {
        self.gameId = gameId
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: GameSession = try await APIClient.shared.request(.getGame(gameId: gameId))
            game = response
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load this game."
        }
    }

    @MainActor
    func setReady(_ ready: Bool) async {
        isUpdatingReady = true
        defer { isUpdatingReady = false }

        do {
            let response: GameActionResponse = try await APIClient.shared.request(
                .setGameReady(gameId: gameId, ready: ready)
            )
            merge(sessionPhase: response.sessionPhase, sync: response.sync)
            await load()
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not update ready state."
        }
    }

    @MainActor
    func submitAnswer() async {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response: SubmitGameRoundResponse = try await APIClient.shared.request(
                .submitGameResponse(gameId: gameId, answer: trimmed)
            )
            answer = ""
            merge(sessionPhase: response.sessionPhase, sync: response.sync)
            await load()
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not submit this round."
        }
    }

    @MainActor
    func cancelGame() async {
        do {
            let _: GameActionResponse = try await APIClient.shared.request(.cancelGame(gameId: gameId))
            await load()
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not cancel this game."
        }
    }

    @MainActor
    func applyRealtimeState(_ event: GameStateChangedEvent) {
        guard event.gameId == gameId else { return }
        merge(sessionPhase: event.sessionPhase, sync: event.sync)
        Task { await load() }
    }

    var currentRound: GameRound? {
        guard let game, game.currentRound < game.rounds.count else { return nil }
        return game.rounds[game.currentRound]
    }

    var sync: GameSyncState? {
        game?.sync
    }

    var sessionPhase: String {
        game?.sessionPhase ?? "waiting_room"
    }

    var myReady: Bool {
        sync?.myReady ?? false
    }

    var allReady: Bool {
        sync?.allReady ?? false
    }

    var waitingForNames: [String] {
        sync?.waitingForUserNames ?? []
    }

    func countdownValue(at now: Date) -> Int {
        guard let end = sync?.countdownEndsAt else { return 0 }
        return max(0, Int(ceil(end.timeIntervalSince(now))))
    }

    func roundTimeRemaining(at now: Date) -> Int {
        guard let end = sync?.roundEndsAt else { return 0 }
        return max(0, Int(ceil(end.timeIntervalSince(now))))
    }

    func roundProgress(at now: Date) -> Double {
        guard let start = sync?.roundStartedAt,
              let end = sync?.roundEndsAt else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / total, 0), 1)
    }

    private func merge(sessionPhase: String?, sync: GameSyncState?) {
        guard var game else { return }
        game = GameSession(
            gameId: game.gameId,
            gameType: game.gameType,
            status: game.status,
            totalRounds: game.totalRounds,
            currentRound: game.currentRound,
            rounds: game.rounds,
            participants: game.participants,
            createdBy: game.createdBy,
            completedAt: game.completedAt,
            createdAt: game.createdAt,
            sessionPhase: sessionPhase ?? game.sessionPhase,
            sync: sync ?? game.sync
        )
        self.game = game
    }
}
