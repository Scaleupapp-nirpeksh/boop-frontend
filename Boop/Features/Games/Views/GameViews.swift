import SwiftUI

struct MatchGamesView: View {
    let matchId: String

    @State private var viewModel: MatchGamesViewModel
    @State private var newGameId: String?

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: MatchGamesViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                masthead
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.accentColor)
                }
                liveSection
                gamePicker
                completedSection
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .refreshable {
            await viewModel.load()
        }
        .navigationTitle("Games")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameInvite)) { notification in
            guard let payload = notification.userInfo?["payload"] as? GameInviteSocketEvent,
                  payload.matchId == matchId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameStateChanged)) { _ in
            Task { await viewModel.load() }
        }
        .navigationDestination(isPresented: Binding(
            get: { newGameId != nil },
            set: { if !$0 { newGameId = nil } }
        )) {
            if let newGameId {
                GameSessionView(gameId: newGameId)
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Play Together")
            Text("Shared timing")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text("Both enter, ready up, watch the same 3-2-1, then answer live.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Live (feature block for the first active game)

    @ViewBuilder
    private var liveSection: some View {
        if let game = viewModel.activeGames.first {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowLabel(text: "Live Now")
                    .padding(.bottom, BoopSpacing.sm)
                liveFeatureBlock(game)
                ForEach(viewModel.activeGames.dropFirst()) { extra in
                    NavigationLink {
                        GameSessionView(gameId: extra.gameId)
                    } label: {
                        gameRow(extra)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func liveFeatureBlock(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)
        let title = option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized
        let waiting = game.sync?.waitingForUserNames ?? []

        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            AccentRule()

            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text(option?.subtitle ?? "Live shared round")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                Spacer()
                Text("Builds Comfort".uppercased())
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.accentColor)
            }

            HStack(spacing: BoopSpacing.lg) {
                liveMeta("Round", "\(min(game.currentRound + 1, game.totalRounds)) / \(game.totalRounds)")
                liveMeta("Phase", game.phaseLabel)
                if !waiting.isEmpty, game.status != "completed" {
                    liveMeta("Waiting", waiting.joined(separator: ", "))
                }
            }

            NavigationLink {
                GameSessionView(gameId: game.gameId)
            } label: {
                HStack {
                    Text("Start Talking".uppercased())
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .thin))
                }
                .foregroundStyle(BoopColors.textPrimary)
                .padding(.vertical, BoopSpacing.md)
                .padding(.horizontal, BoopSpacing.lg)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .stroke(BoopColors.accentColor, lineWidth: 1)
                )
            }
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func liveMeta(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
            Text(value)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
        }
    }

    private func gameRow(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)
        let title = option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized

        return VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("\(game.phaseLabel)  ·  Round \(min(game.currentRound + 1, game.totalRounds)) / \(game.totalRounds)".uppercased())
                        .font(BoopTypography.cineCaption)
                        .tracking(1.5)
                        .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    // MARK: - Game picker (hairline rows)

    private var gamePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowLabel(text: "Start A Game")
                .padding(.bottom, BoopSpacing.sm)

            ForEach(GameTypeOption.allCases, id: \.rawValue) { option in
                let blocked = viewModel.isGameTypeBlocked(option.rawValue)
                let cooldown = viewModel.cooldownEnd(for: option.rawValue)

                Button {
                    Task {
                        newGameId = await viewModel.createGame(type: option.rawValue)
                    }
                } label: {
                    gamePickerRow(option, blocked: blocked, cooldown: cooldown)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCreating || blocked)
            }
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
        }
    }

    private func gamePickerRow(_ option: GameTypeOption, blocked: Bool, cooldown: Date?) -> some View {
        let titleColor = blocked ? BoopColors.textMuted : BoopColors.textPrimary
        let metaColor = blocked ? BoopColors.textMuted : BoopColors.textSecondary

        return VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(titleColor)
                    if let cooldown {
                        Text("Available \(cooldown.formatted(.relative(presentation: .named)))".uppercased())
                            .font(BoopTypography.cineCaption)
                            .tracking(1.5)
                            .foregroundStyle(BoopColors.textMuted)
                    } else {
                        Text("\(option.focus)  ·  \(option.timeLabel)".uppercased())
                            .font(BoopTypography.cineCaption)
                            .tracking(1.5)
                            .foregroundStyle(metaColor)
                    }
                }
                Spacer()
                if blocked {
                    Image(systemName: cooldown != nil ? "clock" : "circle.dotted")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    // MARK: - Completed (hairline rows)

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowLabel(text: "Played Together")
                .padding(.bottom, BoopSpacing.sm)

            if viewModel.completedGames.isEmpty {
                Text("Finished games settle here — revisit the energy of what came out of them.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .padding(.vertical, BoopSpacing.md)
            } else {
                ForEach(viewModel.completedGames) { game in
                    NavigationLink {
                        GameSessionView(gameId: game.gameId)
                    } label: {
                        completedRow(game)
                    }
                    .buttonStyle(.plain)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)

                NavigationLink {
                    GameHistoryView(matchId: matchId, games: viewModel.completedGames)
                } label: {
                    HStack {
                        Text("Full game history".uppercased())
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.accentColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .thin))
                            .foregroundStyle(BoopColors.textMuted)
                    }
                    .padding(.vertical, BoopSpacing.md)
                }
            }
        }
    }

    private func completedRow(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)
        let title = option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized
        let canReplay = !viewModel.isGameTypeBlocked(game.gameType)
        let cooldown = viewModel.cooldownEnd(for: game.gameType)

        return VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    HStack(spacing: 6) {
                        Text("\(game.totalRounds) rounds".uppercased())
                        if let completedAt = game.completedAt {
                            Text("·")
                            Text(completedAt.formatted(.relative(presentation: .named)).uppercased())
                        }
                    }
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                if canReplay {
                    Button {
                        Task {
                            newGameId = await viewModel.replayGame(type: game.gameType)
                        }
                    } label: {
                        Text("Replay".uppercased())
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isCreating)
                } else if cooldown != nil {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}

struct GameSessionView: View {
    let gameId: String

    @State private var viewModel: GameSessionViewModel

    init(gameId: String) {
        self.gameId = gameId
        _viewModel = State(initialValue: GameSessionViewModel(gameId: gameId))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    if let game = viewModel.game {
                        headerCard(for: game, now: context.date)
                        stageCard(now: context.date)

                        if let round = viewModel.currentRound, game.status == "active", game.sessionPhase != "waiting_room" {
                            roundCard(round, now: context.date)
                        }

                        completedRounds
                    } else if viewModel.isLoading {
                        ProgressView()
                            .tint(BoopColors.accentColor)
                            .frame(maxWidth: .infinity, minHeight: 280)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.lg)
            }
            .boopBackground()
        }
        .navigationTitle(viewModel.game.map { GameTypeOption(rawValue: $0.gameType)?.label ?? "Game" } ?? "Game")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameResponse)) { notification in
            guard let payload = notification.userInfo?["payload"] as? GameResponseSocketEvent,
                  payload.gameId == gameId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameCancelled)) { notification in
            guard let payload = notification.userInfo?["payload"] as? GameCancelledSocketEvent,
                  payload.gameId == gameId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameStateChanged)) { notification in
            guard let payload = notification.userInfo?["payload"] as? GameStateChangedEvent,
                  payload.gameId == gameId else { return }
            viewModel.applyRealtimeState(payload)
        }
    }

    private func headerCard(for game: GameSession, now: Date) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)

        return VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: viewModel.sessionPhaseTitle, color: BoopColors.accentColor)
            Text(option?.label ?? game.gameType)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text(option?.subtitle ?? "Live shared round")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            HStack(spacing: BoopSpacing.lg) {
                headerMeta("Round", "\(min(game.currentRound + 1, game.totalRounds)) / \(game.totalRounds)")
                if viewModel.sessionPhase == "countdown" {
                    headerMeta("Starts In", "\(viewModel.countdownValue(at: now))")
                } else if viewModel.sessionPhase == "live_round" {
                    headerMeta("Remaining", "\(viewModel.roundTimeRemaining(at: now))s")
                } else if viewModel.sessionPhase == "completed",
                          let replayAt = game.sync?.replayAvailableAt {
                    headerMeta("Replay", replayAt.formatted(date: .omitted, time: .shortened))
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headerMeta(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
            Text(value)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func stageCard(now: Date) -> some View {
        switch viewModel.sessionPhase {
        case "waiting_room":
            waitingRoomCard
        case "countdown":
            countdownCard(now: now)
        case "live_round":
            liveInfoCard(now: now)
        case "completed":
            completedCard
        case "cancelled":
            cancelledCard
        default:
            transitionCard
        }
    }

    private var waitingRoomCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            AccentRule()
            Text("The game begins only when both of you are here and ready. Once both tap ready, the same 3-2-1 starts for both screens.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            participantReadiness

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.accentColor)
            }

            HStack(spacing: BoopSpacing.md) {
                BoopButton(
                    title: viewModel.myReady ? "Unready" : "I'm Ready",
                    variant: viewModel.myReady ? .outline : .primary,
                    isLoading: viewModel.isUpdatingReady,
                    fullWidth: false
                ) {
                    Task { await viewModel.setReady(!viewModel.myReady) }
                }

                Button {
                    Task { await viewModel.cancelGame() }
                } label: {
                    Text("Cancel game".uppercased())
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func countdownCard(now: Date) -> some View {
        let countdown = max(1, viewModel.countdownValue(at: now))

        return VStack(spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Starting Together", color: BoopColors.accentColor)

            Text("\(countdown)")
                .font(BoopTypography.cineDisplayXL)
                .foregroundStyle(BoopColors.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: countdown)
                .padding(.vertical, BoopSpacing.sm)

            HairlineProgress(progress: Double(countdown) / 3.0)
                .animation(.easeInOut(duration: 0.4), value: countdown)
                .frame(width: 160)

            Text("Both players are locked in. The timer starts for both of you at the same moment.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BoopSpacing.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func liveInfoCard(now: Date) -> some View {
        let remaining = viewModel.roundTimeRemaining(at: now)
        let progress = viewModel.roundProgress(at: now)

        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Live Round", color: BoopColors.accentColor)
                Spacer()
                Text("\(remaining)s")
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.accentColor)
                    .contentTransition(.numericText())
            }

            HairlineProgress(progress: 1 - progress)

            Text("Answer while the line is alive. If either side misses the timer, the round closes and the game moves on.")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private var completedCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            AccentRule()
            Text("Finished together")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
            Text("You completed this game live. Use the completed rounds below to revisit what came out of it.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            if let game = viewModel.game {
                let completedCount = game.rounds.filter(\.isComplete).count
                let answeredCount = game.rounds.filter { round in
                    round.responses?.contains(where: { $0.userId?.id == AuthManager.shared.currentUser?.id }) == true
                }.count

                HStack(spacing: BoopSpacing.lg) {
                    completionStat(value: "\(completedCount)/\(game.totalRounds)", label: "Rounds")
                    completionStat(value: "\(answeredCount)", label: "You answered")
                    completionStat(value: game.rounds.filter(\.isComplete).count == game.totalRounds ? "Full" : "Partial", label: "Completion")
                }
                .padding(.top, BoopSpacing.xs)
            }
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func completionStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cancelledCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Cancelled", color: BoopColors.accentColor)
            Text("This game was cancelled.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private var transitionCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Syncing")
            Text("Syncing the next round…")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func roundCard(_ round: GameRound, now: Date) -> some View {
        let gameType = viewModel.game?.gameType ?? ""

        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            // Context marker
            HStack(spacing: BoopSpacing.sm) {
                AccentRule()
                if let context = round.prompt.context {
                    Text(context.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            Text(round.prompt.text)
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)

            if let revealPrompt = round.prompt.revealPrompt {
                HStack(alignment: .top, spacing: BoopSpacing.sm) {
                    Rectangle().fill(BoopColors.hairline).frame(width: 1)
                    Text(revealPrompt)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                        .italic()
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            answerInput(for: round)

            if round.waitingForOther == true {
                HStack(spacing: BoopSpacing.sm) {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                        .scaleEffect(0.8)
                    Text("Answer locked. Waiting for the other player…".uppercased())
                        .font(BoopTypography.cineCaption)
                        .tracking(1.5)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, BoopSpacing.sm)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.accentColor)
            }

            if round.waitingForOther != true {
                BoopButton(
                    title: "Lock answer",
                    isLoading: viewModel.isSubmitting,
                    isDisabled: viewModel.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Haptics.medium()
                    Task { await viewModel.submitAnswer() }
                }
            }
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func answerInput(for round: GameRound) -> some View {
        let gameType = viewModel.game?.gameType ?? ""

        if gameType == "would_you_rather",
           let optionA = round.prompt.optionA, let optionB = round.prompt.optionB {
            wouldYouRatherInput(optionA: optionA, optionB: optionB)
        } else if let scale = round.prompt.scale, let min = scale.min, let max = scale.max {
            spectrumSlider(min: min, max: max)
        } else if gameType == "never_have_i_ever" {
            neverHaveIEverInput()
        } else if gameType == "two_truths_a_lie" {
            twoTruthsInput()
        } else if gameType == "blind_reveal" {
            blindRevealInput()
        } else if gameType == "what_would_you_do" {
            whatWouldYouDoInput()
        } else if gameType == "dream_board" {
            dreamBoardInput()
        } else {
            BoopTextField(
                label: "Your answer",
                text: $viewModel.answer,
                placeholder: "Type your answer",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    // MARK: - Would You Rather (card-style options)

    private func wouldYouRatherInput(optionA: String, optionB: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Tap your pick".uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)

            wyrOptionCard(label: optionA, value: "A")
            wyrOptionCard(label: optionB, value: "B")
        }
    }

    private func wyrOptionCard(label: String, value: String) -> some View {
        let isSelected = viewModel.answer == value
        return Button {
            Haptics.selection()
            withAnimation(.spring(duration: 0.25)) { viewModel.answer = value }
        } label: {
            HStack(spacing: BoopSpacing.md) {
                Text(value)
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textMuted)
                    .frame(width: 16)

                Text(label)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(isSelected ? BoopColors.textPrimary : BoopColors.textSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.accentColor)
                        .transition(.opacity)
                }
            }
            .padding(BoopSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(isSelected ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Intimacy Spectrum (slider)

    private func spectrumSlider(min: Int, max: Int) -> some View {
        VStack(spacing: BoopSpacing.md) {
            Text("Where do you land?".uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)

            // Large value display
            Text("\(Int(viewModel.sliderValue))")
                .font(BoopTypography.cineDisplayXL)
                .foregroundStyle(BoopColors.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.2), value: Int(viewModel.sliderValue))

            Text(spectrumLabel(value: Int(viewModel.sliderValue)))
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            // Slider
            Slider(
                value: $viewModel.sliderValue,
                in: Double(min)...Double(max),
                step: 1
            ) {
                Text("Spectrum")
            } minimumValueLabel: {
                Text("\(min)")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            } maximumValueLabel: {
                Text("\(max)")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }
            .tint(BoopColors.accentColor)
            .onChange(of: viewModel.sliderValue) { _, newValue in
                viewModel.answer = "\(Int(newValue))"
            }
            .onAppear {
                if viewModel.answer.isEmpty {
                    let midpoint = (min + max) / 2
                    viewModel.sliderValue = Double(midpoint)
                    viewModel.answer = "\(midpoint)"
                }
            }

            HStack {
                Text("Not at all".uppercased())
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textMuted)
                Spacer()
                Text("Completely".uppercased())
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
        .padding(BoopSpacing.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func spectrumLabel(value: Int) -> String {
        switch value {
        case 1...2: return "Strongly disagree"
        case 3...4: return "Lean no"
        case 5: return "Neutral"
        case 6...7: return "Lean yes"
        case 8...9: return "Strongly agree"
        case 10: return "Absolutely"
        default: return ""
        }
    }

    // MARK: - Never Have I Ever

    private func neverHaveIEverInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Have you ever?".uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
            HStack(spacing: BoopSpacing.sm) {
                neverHaveIEverButton("I Have", value: "I have")
                neverHaveIEverButton("Never", value: "Never")
            }
        }
    }

    // MARK: - Two Truths & A Lie

    private func twoTruthsInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            promptHint("Write all three — two truths and one lie. Mix them up so your partner has to guess which is the lie.")
            BoopTextField(
                label: "Your three statements",
                text: $viewModel.answer,
                placeholder: "1. ...\n2. ...\n3. ...",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    // MARK: - Blind Reveal

    private func blindRevealInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            promptHint("Photos are hidden — personality first.")
            BoopTextField(
                label: "Your answer",
                text: $viewModel.answer,
                placeholder: "Share something real...",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    // MARK: - What Would You Do

    private func whatWouldYouDoInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            promptHint("What would you actually do? Be honest.")
            BoopTextField(
                label: "Your response",
                text: $viewModel.answer,
                placeholder: "I would...",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    // MARK: - Dream Board

    private func dreamBoardInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            promptHint("Dream big — no wrong answers.")
            BoopTextField(
                label: "Your vision",
                text: $viewModel.answer,
                placeholder: "Imagine together...",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    private func promptHint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Rectangle().fill(BoopColors.hairline).frame(width: 1)
            Text(text)
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Completed Rounds (rich display)

    private var completedRounds: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            if let completed = viewModel.game?.rounds.filter(\.isComplete), !completed.isEmpty {
                EyebrowLabel(text: "What Came Out Of It")

                ForEach(completed) { round in
                    completedRoundCard(round)
                }
            }
        }
    }

    private func completedRoundCard(_ round: GameRound) -> some View {
        let gameType = viewModel.game?.gameType ?? ""
        let responses = round.responses ?? []
        let currentUserId = AuthManager.shared.currentUser?.id

        return VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Round \(round.roundNumber)".uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)

            Text(round.prompt.text)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)

            ForEach(responses) { response in
                let isMe = response.userId?.id == currentUserId
                VStack(spacing: 0) {
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        Text(isMe ? "You" : (response.userId?.firstName ?? "Partner"))
                            .font(BoopTypography.cineCaption)
                            .tracking(1)
                            .foregroundStyle(BoopColors.textMuted)
                            .frame(width: 64, alignment: .leading)

                        completedAnswerView(answer: response.answer, gameType: gameType, round: round)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, BoopSpacing.sm)
                }
            }

            // Match indicator for option-based games (the reveal payoff)
            if (gameType == "would_you_rather" || gameType == "never_have_i_ever") && responses.count == 2 {
                let matched = responses[0].answer.lowercased() == responses[1].answer.lowercased()
                revealLine(matched ? "You both picked the same" : "Different picks — interesting contrast", emphasised: matched)
            }

            // Spectrum comparison
            if gameType == "intimacy_spectrum" && responses.count == 2 {
                let val1 = Int(responses[0].answer) ?? 0
                let val2 = Int(responses[1].answer) ?? 0
                let diff = abs(val1 - val2)
                revealLine(diff <= 2 ? "Very aligned — \(diff) apart" : "\(diff) points apart — room to explore", emphasised: diff <= 2)
            }
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
    }

    private func revealLine(_ text: String, emphasised: Bool) -> some View {
        HStack(spacing: BoopSpacing.sm) {
            AccentRule(width: emphasised ? 24 : 12)
            Text(text.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(emphasised ? BoopColors.accentColor : BoopColors.textMuted)
        }
        .padding(.top, BoopSpacing.xs)
    }

    @ViewBuilder
    private func completedAnswerView(answer: String, gameType: String, round: GameRound) -> some View {
        switch gameType {
        case "would_you_rather":
            let optionText = answer.uppercased() == "A" ? (round.prompt.optionA ?? "Option A") : (round.prompt.optionB ?? "Option B")
            HStack(spacing: BoopSpacing.sm) {
                Text(answer.uppercased())
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.accentColor)
                Text(optionText)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        case "intimacy_spectrum":
            if let value = Int(answer) {
                HStack(spacing: BoopSpacing.sm) {
                    Text("\(value)")
                        .font(BoopTypography.cineHeadline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("/ 10")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                    HairlineProgress(progress: Double(value) / 10.0)
                        .frame(maxWidth: 120)
                }
            } else {
                Text(answer)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        case "never_have_i_ever":
            Text(answer)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
        default:
            Text(answer)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
        }
    }

    // MARK: - Readiness

    private var participantReadiness: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.sync?.readyPlayers ?? []) { player in
                VStack(spacing: 0) {
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                    HStack(spacing: BoopSpacing.sm) {
                        Image(systemName: player.isReady ? "checkmark" : "circle")
                            .font(.system(size: 13, weight: .thin))
                            .foregroundStyle(player.isReady ? BoopColors.accentColor : BoopColors.textMuted)
                            .frame(width: 16)

                        Text(player.firstName)
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)

                        Spacer()

                        Text((player.isReady ? "Ready" : "Waiting").uppercased())
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(player.isReady ? BoopColors.accentColor : BoopColors.textMuted)
                    }
                    .padding(.vertical, BoopSpacing.md)
                }
            }
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
        }
    }

    private func neverHaveIEverButton(_ label: String, value: String) -> some View {
        let isSelected = viewModel.answer == value
        return Button {
            Haptics.selection()
            viewModel.answer = value
        } label: {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .stroke(isSelected ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

enum GameTypeOption: String, CaseIterable {
    case wouldYouRather = "would_you_rather"
    case intimacySpectrum = "intimacy_spectrum"
    case neverHaveIEver = "never_have_i_ever"
    case whatWouldYouDo = "what_would_you_do"
    case dreamBoard = "dream_board"
    case twoTruthsALie = "two_truths_a_lie"
    case blindReveal = "blind_reveal"

    var label: String {
        switch self {
        case .wouldYouRather: return "Would You Rather"
        case .intimacySpectrum: return "Intimacy Spectrum"
        case .neverHaveIEver: return "Never Have I Ever"
        case .whatWouldYouDo: return "What Would You Do"
        case .dreamBoard: return "Dream Board"
        case .twoTruthsALie: return "Two Truths & A Lie"
        case .blindReveal: return "Blind Reveal"
        }
    }

    var subtitle: String {
        switch self {
        case .wouldYouRather: return "Fast instincts and playful tradeoffs"
        case .intimacySpectrum: return "Closeness, space, and comfort"
        case .neverHaveIEver: return "Light reveals with chemistry built in"
        case .whatWouldYouDo: return "Values under pressure"
        case .dreamBoard: return "Shared future imagination"
        case .twoTruthsALie: return "Surprise, intuition, and story"
        case .blindReveal: return "Trust before appearance"
        }
    }

    var focus: String {
        switch self {
        case .wouldYouRather: return "Playful"
        case .intimacySpectrum: return "Depth"
        case .neverHaveIEver: return "Warm-up"
        case .whatWouldYouDo: return "Values"
        case .dreamBoard: return "Future"
        case .twoTruthsALie: return "Mystery"
        case .blindReveal: return "Trust"
        }
    }

    var timeLabel: String {
        switch self {
        case .wouldYouRather, .intimacySpectrum, .neverHaveIEver:
            return "30s rounds"
        default:
            return "60s rounds"
        }
    }
}

private extension GameSummary {
    var phaseLabel: String {
        switch sessionPhase {
        case "waiting_room": return "Waiting room"
        case "countdown": return "Countdown"
        case "live_round": return "Live now"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return status.capitalized
        }
    }
}

private extension GameSessionViewModel {
    var sessionPhaseTitle: String {
        switch sessionPhase {
        case "waiting_room": return "Waiting room"
        case "countdown": return "Countdown"
        case "live_round": return "Live round"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return "Syncing"
        }
    }
}
