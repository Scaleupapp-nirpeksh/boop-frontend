import SwiftUI

struct MatchGamesView: View {
    let matchId: String

    @State private var viewModel: MatchGamesViewModel
    @State private var newGameId: String?

    private let columns = [
        GridItem(.flexible(), spacing: BoopSpacing.sm),
        GridItem(.flexible(), spacing: BoopSpacing.sm)
    ]

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: MatchGamesViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                heroCard
                gamePicker
                activeSection
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

    private var heroCard: some View {
        BoopCard(padding: 0, radius: BoopRadius.xxl) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [BoopColors.cardDarkAlt, Color(hex: "21354D"), BoopColors.secondary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)

                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    Text("PLAY TOGETHER")
                        .font(BoopTypography.caption)
                        .fontWeight(.bold)
                        .kerning(1.2)
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text("Shared games, shared timing")
                        .font(BoopTypography.title1)
                        .foregroundStyle(.white)

                    Text("Both players enter, tap ready, see the same 3-2-1, then answer live.")
                        .font(BoopTypography.callout)
                        .foregroundStyle(Color.white.opacity(0.82))

                    HStack(spacing: BoopSpacing.xs) {
                        gameHeroChip("Live sync")
                        gameHeroChip("Round timers")
                        gameHeroChip("Replay later")
                    }
                }
                .padding(BoopSpacing.lg)
            }
        }
    }

    private var gamePicker: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Start a game")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Pick the kind of chemistry you want to explore next.")
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                LazyVGrid(columns: columns, spacing: BoopSpacing.sm) {
                    ForEach(GameTypeOption.allCases, id: \.rawValue) { option in
                        let blocked = viewModel.isGameTypeBlocked(option.rawValue)
                        let cooldown = viewModel.cooldownEnd(for: option.rawValue)

                        Button {
                            Task {
                                newGameId = await viewModel.createGame(type: option.rawValue)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                                HStack {
                                    Text(option.label)
                                        .font(BoopTypography.callout)
                                        .foregroundStyle(blocked ? BoopColors.textMuted : BoopColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if blocked {
                                        Image(systemName: cooldown != nil ? "clock.fill" : "play.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(BoopColors.textMuted)
                                    }
                                }

                                Text(option.subtitle)
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(blocked ? BoopColors.textMuted : BoopColors.textSecondary)
                                    .multilineTextAlignment(.leading)

                                if let cooldown {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 10))
                                        Text("Available \(cooldown.formatted(.relative(presentation: .named)))")
                                    }
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.warning)
                                } else {
                                    HStack(spacing: 6) {
                                        Text(option.focus)
                                        Text("•")
                                        Text(option.timeLabel)
                                    }
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(blocked ? BoopColors.textMuted : option.tint)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(BoopSpacing.md)
                            .background(blocked ? BoopColors.surfaceSecondary.opacity(0.5) : option.tint.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                                    .stroke(blocked ? BoopColors.border : option.tint.opacity(0.18), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isCreating || blocked)
                    }
                }
            }
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Active now")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)

            if viewModel.activeGames.isEmpty {
                emptyCard("No live games yet", "Start one when you want the chat to move from talking to doing.")
            } else {
                ForEach(viewModel.activeGames) { game in
                    NavigationLink {
                        GameSessionView(gameId: game.gameId)
                    } label: {
                        gameSummaryCard(game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Played together")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)

            if viewModel.completedGames.isEmpty {
                emptyCard("No completed games yet", "Finished games show up here so you can revisit the energy of the connection.")
            } else {
                ForEach(viewModel.completedGames) { game in
                    NavigationLink {
                        GameSessionView(gameId: game.gameId)
                    } label: {
                        completedGameCard(game)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    GameHistoryView(matchId: matchId, games: viewModel.completedGames)
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View full game history")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.secondary)
                    .padding(BoopSpacing.md)
                    .background(BoopColors.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }
            }
        }
    }

    private func gameSummaryCard(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(BoopTypography.title3)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text(option?.subtitle ?? "Live game")
                            .font(BoopTypography.footnote)
                            .foregroundStyle(BoopColors.textSecondary)
                    }

                    Spacer()

                    Text(game.phaseLabel)
                        .font(BoopTypography.caption)
                        .foregroundStyle(game.phaseTint)
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, 6)
                        .background(game.phaseTint.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: BoopSpacing.md) {
                    summaryMetric("Round", "\(min(game.currentRound + 1, game.totalRounds))/\(game.totalRounds)")
                    if let waiting = game.sync?.waitingForUserNames, !waiting.isEmpty, game.status != "completed" {
                        summaryMetric("Waiting", waiting.joined(separator: ", "))
                    } else {
                        summaryMetric("Mode", "Together")
                    }
                }
            }
        }
    }

    private func summaryMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
            Text(value)
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
        }
    }

    private func completedGameCard(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)
        let canReplay = !viewModel.isGameTypeBlocked(game.gameType)
        let cooldown = viewModel.cooldownEnd(for: game.gameType)

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(BoopTypography.title3)
                            .foregroundStyle(BoopColors.textPrimary)
                        if let completedAt = game.completedAt {
                            Text(completedAt.formatted(.relative(presentation: .named)))
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(BoopColors.success)
                        Text("\(game.totalRounds) rounds")
                    }
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.success)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, 6)
                    .background(BoopColors.success.opacity(0.12))
                    .clipShape(Capsule())
                }

                Divider()

                HStack(spacing: BoopSpacing.sm) {
                    if canReplay {
                        Button {
                            Task {
                                newGameId = await viewModel.replayGame(type: game.gameType)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Play Again")
                            }
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, BoopSpacing.md)
                            .padding(.vertical, BoopSpacing.sm)
                            .background(option?.tint ?? BoopColors.primary)
                            .clipShape(Capsule())
                        }
                        .disabled(viewModel.isCreating)
                    } else if let cooldown {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text("Replay \(cooldown.formatted(.relative(presentation: .named)))")
                        }
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.warning)
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, 6)
                        .background(BoopColors.warning.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                        Text("View")
                    }
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }

    private func emptyCard(_ title: String, _ body: String) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Text(title)
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(body)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }

    private func gameHeroChip(_ text: String) -> some View {
        Text(text)
            .font(BoopTypography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
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
                            .tint(BoopColors.primary)
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

        return BoopCard(padding: 0, radius: BoopRadius.xxl) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [BoopColors.cardDarkAlt, BoopColors.cardDarkDeepBlue, option?.tint.opacity(0.9) ?? BoopColors.primary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)

                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    Text(viewModel.sessionPhaseTitle.uppercased())
                        .font(BoopTypography.caption)
                        .fontWeight(.bold)
                        .kerning(1.1)
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text(option?.label ?? game.gameType)
                        .font(BoopTypography.title1)
                        .foregroundStyle(.white)

                    Text(option?.subtitle ?? "Live shared round")
                        .font(BoopTypography.callout)
                        .foregroundStyle(Color.white.opacity(0.84))

                    HStack(spacing: BoopSpacing.xs) {
                        heroPill("Round \(min(game.currentRound + 1, game.totalRounds))/\(game.totalRounds)")
                        if viewModel.sessionPhase == "countdown" {
                            heroPill("Starts in \(viewModel.countdownValue(at: now))")
                        } else if viewModel.sessionPhase == "live_round" {
                            heroPill("\(viewModel.roundTimeRemaining(at: now))s left")
                        } else if viewModel.sessionPhase == "completed",
                                  let replayAt = game.sync?.replayAvailableAt {
                            heroPill("Replay after \(replayAt.formatted(date: .omitted, time: .shortened))")
                        }
                    }
                }
                .padding(BoopSpacing.lg)
            }
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
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Waiting room")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("The game begins only when both of you are here and ready. Once both tap ready, the same 3-2-1 starts for both screens.")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)

                participantReadiness

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                HStack(spacing: BoopSpacing.sm) {
                    BoopButton(
                        title: viewModel.myReady ? "Unready" : "I'm Ready",
                        variant: viewModel.myReady ? .outline : .primary,
                        isLoading: viewModel.isUpdatingReady,
                        fullWidth: false
                    ) {
                        Task { await viewModel.setReady(!viewModel.myReady) }
                    }

                    Button("Cancel game") {
                        Task { await viewModel.cancelGame() }
                    }
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.error)
                }
            }
        }
    }

    private func countdownCard(now: Date) -> some View {
        let countdown = max(1, viewModel.countdownValue(at: now))

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                Text("Starting together")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                ZStack {
                    Circle()
                        .stroke(BoopColors.primary.opacity(0.15), lineWidth: 6)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(BoopColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: countdown)

                    Text("\(countdown)")
                        .font(.nunito(.extraBold, size: 56))
                        .foregroundStyle(BoopColors.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: countdown)
                }

                Text("Both players are locked in. The timer starts for both of you at the same moment.")
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func liveInfoCard(now: Date) -> some View {
        let remaining = viewModel.roundTimeRemaining(at: now)
        let progress = viewModel.roundProgress(at: now)

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Live round")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(remaining)s")
                        .font(BoopTypography.title3)
                        .foregroundStyle(BoopColors.primary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(BoopColors.surfaceSecondary)
                        Capsule()
                            .fill(BoopColors.primaryGradient)
                            .frame(width: proxy.size.width * (1 - progress))
                    }
                }
                .frame(height: 12)

                Text("Answer while the bar is alive. If either side misses the timer, the round closes and the game moves on.")
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }

    private var completedCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Finished together")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BoopColors.success)
                }

                Text("You completed this game live. Use the completed rounds below to revisit what came out of it.")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)

                if let game = viewModel.game {
                    let completedCount = game.rounds.filter(\.isComplete).count
                    let answeredCount = game.rounds.filter { round in
                        round.responses?.contains(where: { $0.userId?.id == AuthManager.shared.currentUser?.id }) == true
                    }.count

                    HStack(spacing: BoopSpacing.sm) {
                        completionStat(value: "\(completedCount)/\(game.totalRounds)", label: "Rounds", tint: BoopColors.secondary)
                        completionStat(value: "\(answeredCount)", label: "You answered", tint: BoopColors.primary)
                        completionStat(value: game.rounds.filter(\.isComplete).count == game.totalRounds ? "Full" : "Partial", label: "Completion", tint: BoopColors.accent)
                    }
                }
            }
        }
    }

    private func completionStat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BoopTypography.title3)
                .foregroundStyle(tint)
            Text(label)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BoopSpacing.sm)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
    }

    private var cancelledCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            Text("This game was cancelled.")
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.error)
        }
    }

    private var transitionCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            Text("Syncing the next round...")
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    private func roundCard(_ round: GameRound, now: Date) -> some View {
        let gameType = viewModel.game?.gameType ?? ""

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                // Game-type icon + context badge row
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: gameTypeIcon(gameType))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(gameTypeTint(gameType))

                    if let context = round.prompt.context {
                        Text(context.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(BoopTypography.caption)
                            .foregroundStyle(gameTypeTint(gameType))
                            .padding(.horizontal, BoopSpacing.sm)
                            .padding(.vertical, 5)
                            .background(gameTypeTint(gameType).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(round.prompt.text)
                    .font(BoopTypography.title3)
                    .foregroundStyle(BoopColors.textPrimary)

                if let revealPrompt = round.prompt.revealPrompt {
                    HStack(alignment: .top, spacing: BoopSpacing.xs) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(BoopColors.secondary)
                            .padding(.top, 2)
                        Text(revealPrompt)
                            .font(BoopTypography.footnote)
                            .foregroundStyle(BoopColors.textSecondary)
                            .italic()
                    }
                    .padding(BoopSpacing.sm)
                    .background(BoopColors.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                }

                answerInput(for: round)

                if round.waitingForOther == true {
                    HStack(spacing: BoopSpacing.xs) {
                        ProgressView()
                            .tint(BoopColors.secondary)
                            .scaleEffect(0.8)
                        Text("Answer locked. Waiting for the other player...")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    .padding(BoopSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BoopColors.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
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
        }
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
        VStack(spacing: BoopSpacing.sm) {
            Text("Tap your pick")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)

            wyrOptionCard(label: optionA, value: "A", icon: "a.circle.fill", tint: Color(hex: "FF7A59"))

            HStack {
                Rectangle().fill(BoopColors.border).frame(height: 1)
                Text("or")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
                Rectangle().fill(BoopColors.border).frame(height: 1)
            }

            wyrOptionCard(label: optionB, value: "B", icon: "b.circle.fill", tint: BoopColors.secondary)
        }
    }

    private func wyrOptionCard(label: String, value: String, icon: String, tint: Color) -> some View {
        let isSelected = viewModel.answer == value
        return Button {
            Haptics.selection()
            withAnimation(.spring(duration: 0.25)) { viewModel.answer = value }
        } label: {
            HStack(spacing: BoopSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? .white : tint)

                Text(label)
                    .font(BoopTypography.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : BoopColors.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.9))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(BoopSpacing.md)
            .background(isSelected ? tint : tint.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                    .stroke(isSelected ? tint : tint.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Intimacy Spectrum (slider)

    private func spectrumSlider(min: Int, max: Int) -> some View {
        VStack(spacing: BoopSpacing.md) {
            Text("Where do you land?")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)

            // Large value display
            Text("\(Int(viewModel.sliderValue))")
                .font(.nunito(.extraBold, size: 44))
                .foregroundStyle(spectrumColor(value: viewModel.sliderValue, min: Double(min), max: Double(max)))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.2), value: Int(viewModel.sliderValue))

            Text(spectrumLabel(value: Int(viewModel.sliderValue)))
                .font(BoopTypography.footnote)
                .foregroundStyle(BoopColors.textSecondary)

            // Slider
            VStack(spacing: BoopSpacing.xs) {
                Slider(
                    value: $viewModel.sliderValue,
                    in: Double(min)...Double(max),
                    step: 1
                ) {
                    Text("Spectrum")
                } minimumValueLabel: {
                    Text("\(min)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                } maximumValueLabel: {
                    Text("\(max)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
                .tint(spectrumColor(value: viewModel.sliderValue, min: Double(min), max: Double(max)))
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
            }

            HStack {
                Text("Not at all")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
                Spacer()
                Text("Completely")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
    }

    private func spectrumColor(value: Double, min: Double, max: Double) -> Color {
        let normalized = (value - min) / (max - min)
        if normalized < 0.35 { return BoopColors.primary }
        if normalized < 0.65 { return BoopColors.accent }
        return BoopColors.secondary
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
            Text("Have you ever?")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
            HStack(spacing: BoopSpacing.sm) {
                neverHaveIEverButton("I Have", value: "I have", icon: "hand.thumbsup.fill", tint: BoopColors.secondary)
                neverHaveIEverButton("Never", value: "Never", icon: "hand.thumbsdown.fill", tint: BoopColors.primary)
            }
        }
    }

    // MARK: - Two Truths & A Lie

    private func twoTruthsInput() -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(BoopColors.accent)
                Text("Write all three — two truths and one lie")
                    .font(BoopTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(BoopColors.textSecondary)
            }

            Text("Mix them up so your partner has to guess which is the lie.")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
                .padding(BoopSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BoopColors.accent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))

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
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "1F8A70"))
                Text("Photos are hidden — personality first")
                    .font(BoopTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: "1F8A70"))
            }
            .padding(BoopSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "1F8A70").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))

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
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "5B6CFF"))
                Text("What would you actually do? Be honest.")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
            }

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
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "A66CFF"))
                Text("Dream big — no wrong answers")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
            }

            BoopTextField(
                label: "Your vision",
                text: $viewModel.answer,
                placeholder: "Imagine together...",
                isMultiline: true,
                maxLength: 500
            )
        }
    }

    // MARK: - Completed Rounds (rich display)

    private var completedRounds: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            if let completed = viewModel.game?.rounds.filter(\.isComplete), !completed.isEmpty {
                Text("What came out of it")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

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

        return BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack {
                    Text("Round \(round.roundNumber)")
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Image(systemName: gameTypeIcon(gameType))
                        .font(.system(size: 12))
                        .foregroundStyle(gameTypeTint(gameType))
                }

                Text(round.prompt.text)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)

                Divider()

                ForEach(responses) { response in
                    let isMe = response.userId?.id == currentUserId
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        Circle()
                            .fill(isMe ? BoopColors.primary.opacity(0.15) : BoopColors.secondary.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(response.userId?.firstName?.prefix(1) ?? "?"))
                                    .font(BoopTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(isMe ? BoopColors.primary : BoopColors.secondary)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isMe ? "You" : (response.userId?.firstName ?? "Partner"))
                                .font(BoopTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)

                            completedAnswerView(answer: response.answer, gameType: gameType, round: round)
                        }
                    }
                }

                // Match indicator for option-based games
                if (gameType == "would_you_rather" || gameType == "never_have_i_ever") && responses.count == 2 {
                    let matched = responses[0].answer.lowercased() == responses[1].answer.lowercased()
                    HStack(spacing: BoopSpacing.xs) {
                        Image(systemName: matched ? "heart.fill" : "arrow.left.arrow.right")
                            .font(.system(size: 12))
                        Text(matched ? "You both picked the same!" : "Different picks — interesting contrast")
                            .font(BoopTypography.caption)
                    }
                    .foregroundStyle(matched ? BoopColors.primary : BoopColors.textMuted)
                    .padding(BoopSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(matched ? BoopColors.primary.opacity(0.06) : BoopColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                }

                // Spectrum comparison
                if gameType == "intimacy_spectrum" && responses.count == 2 {
                    let val1 = Int(responses[0].answer) ?? 0
                    let val2 = Int(responses[1].answer) ?? 0
                    let diff = abs(val1 - val2)
                    HStack(spacing: BoopSpacing.xs) {
                        Image(systemName: diff <= 2 ? "equal.circle.fill" : "shuffle")
                            .font(.system(size: 12))
                        Text(diff <= 2 ? "Very aligned (\(diff) apart)" : "\(diff) points apart — room to explore")
                            .font(BoopTypography.caption)
                    }
                    .foregroundStyle(diff <= 2 ? BoopColors.secondary : BoopColors.textMuted)
                    .padding(BoopSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(diff <= 2 ? BoopColors.secondary.opacity(0.06) : BoopColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private func completedAnswerView(answer: String, gameType: String, round: GameRound) -> some View {
        switch gameType {
        case "would_you_rather":
            let optionText = answer.uppercased() == "A" ? (round.prompt.optionA ?? "Option A") : (round.prompt.optionB ?? "Option B")
            HStack(spacing: BoopSpacing.xs) {
                Text(answer.uppercased())
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(answer.uppercased() == "A" ? Color(hex: "FF7A59") : BoopColors.secondary)
                    .clipShape(Circle())
                Text(optionText)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        case "intimacy_spectrum":
            if let value = Int(answer) {
                HStack(spacing: BoopSpacing.xs) {
                    Text("\(value)")
                        .font(BoopTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(spectrumColor(value: Double(value), min: 1, max: 10))
                    Text("/ 10")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BoopColors.surfaceSecondary)
                            Capsule()
                                .fill(spectrumColor(value: Double(value), min: 1, max: 10))
                                .frame(width: proxy.size.width * CGFloat(value) / 10.0)
                        }
                    }
                    .frame(height: 6)
                }
            } else {
                Text(answer)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        case "never_have_i_ever":
            let isHave = answer.lowercased().contains("have")
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: isHave ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isHave ? BoopColors.secondary : BoopColors.primary)
                Text(answer)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        default:
            Text(answer)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textPrimary)
        }
    }

    // MARK: - Game Type Helpers

    private func gameTypeIcon(_ type: String) -> String {
        switch type {
        case "would_you_rather": return "arrow.left.arrow.right"
        case "intimacy_spectrum": return "slider.horizontal.3"
        case "never_have_i_ever": return "hand.raised.fill"
        case "what_would_you_do": return "brain.head.profile.fill"
        case "dream_board": return "cloud.fill"
        case "two_truths_a_lie": return "theatermasks.fill"
        case "blind_reveal": return "eye.slash.fill"
        default: return "gamecontroller.fill"
        }
    }

    private func gameTypeTint(_ type: String) -> Color {
        GameTypeOption(rawValue: type)?.tint ?? BoopColors.secondary
    }

    private var participantReadiness: some View {
        HStack(spacing: BoopSpacing.sm) {
            ForEach(viewModel.sync?.readyPlayers ?? []) { player in
                VStack(spacing: 6) {
                    Circle()
                        .fill(player.isReady ? BoopColors.secondary.opacity(0.18) : BoopColors.surfaceSecondary)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: player.isReady ? "checkmark" : "person.fill")
                                .foregroundStyle(player.isReady ? BoopColors.secondary : BoopColors.textMuted)
                        )

                    Text(player.firstName)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textPrimary)

                    Text(player.isReady ? "Ready" : "Waiting")
                        .font(BoopTypography.caption)
                        .foregroundStyle(player.isReady ? BoopColors.secondary : BoopColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.sm)
                .background(player.isReady ? BoopColors.secondary.opacity(0.08) : BoopColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
            }
        }
    }

    private func heroPill(_ text: String) -> some View {
        Text(text)
            .font(BoopTypography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
    }

    private func neverHaveIEverButton(_ label: String, value: String, icon: String, tint: Color) -> some View {
        Button {
            Haptics.selection()
            viewModel.answer = value
        } label: {
            VStack(spacing: BoopSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(label)
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(viewModel.answer == value ? .white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BoopSpacing.md)
            .background(viewModel.answer == value ? tint : tint.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
        }
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

    var tint: Color {
        switch self {
        case .wouldYouRather: return Color(hex: "FF7A59")
        case .intimacySpectrum: return Color(hex: "4ECDC4")
        case .neverHaveIEver: return Color(hex: "FF6B6B")
        case .whatWouldYouDo: return Color(hex: "5B6CFF")
        case .dreamBoard: return Color(hex: "A66CFF")
        case .twoTruthsALie: return Color(hex: "F7B733")
        case .blindReveal: return Color(hex: "1F8A70")
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

    var phaseTint: Color {
        switch sessionPhase {
        case "waiting_room": return BoopColors.warning
        case "countdown": return BoopColors.primary
        case "live_round": return BoopColors.secondary
        case "completed": return BoopColors.success
        case "cancelled": return BoopColors.error
        default: return BoopColors.textMuted
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
