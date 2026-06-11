import SwiftUI

struct NotificationInboxView: View {
    @State private var viewModel = NotificationInboxViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                loadingState
            } else if viewModel.notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.notifications.isEmpty && viewModel.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Read All") {
                        Task { await viewModel.markAllAsRead() }
                    }
                    .font(BoopTypography.cineCaption)
                    .tracking(1)
                    .foregroundStyle(BoopColors.accentColor)
                }
            }
        }
        .task {
            await viewModel.loadNotifications(refresh: true)
            viewModel.clearAppBadge()
        }
        .refreshable {
            await viewModel.loadNotifications(refresh: true)
        }
        .boopBackground()
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification) {
                        Task { await viewModel.markAsRead(notification) }
                        handleTap(notification)
                    } onDelete: {
                        Task { await viewModel.deleteNotification(notification) }
                    }
                }

                if viewModel.hasMore {
                    ProgressView()
                        .tint(BoopColors.textMuted)
                        .padding(BoopSpacing.lg)
                        .task { await viewModel.loadMore() }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            AccentRule()

            Text("No notifications yet")
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)

            Text("Matches, messages, and activity will surface here.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .boopBackground()
    }

    // MARK: - Loading

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonNotificationRow()
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
    }

    // MARK: - Tap Handling (deep link)

    private func handleTap(_ notification: NotificationItem) {
        guard let data = notification.data else { return }

        switch notification.type {
        case "new_message":
            if let matchId = data.matchId {
                NotificationRouter.shared.pendingDestination = .chat(matchId: matchId)
                NotificationRouter.shared.selectedTab = 2
            }
        case "new_match", "like_received", "reveal_request", "photos_revealed", "stage_advanced":
            if let matchId = data.matchId {
                NotificationRouter.shared.pendingDestination = .match(matchId: matchId)
                NotificationRouter.shared.selectedTab = 0
            }
        case "game_invite":
            if let gameId = data.gameId {
                NotificationRouter.shared.pendingDestination = .game(gameId: gameId)
                NotificationRouter.shared.selectedTab = 0
            }
        default:
            break
        }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: NotificationItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)

                HStack(alignment: .top, spacing: BoopSpacing.md) {
                    Image(systemName: notification.typeIcon)
                        .font(.system(size: 16, weight: .thin))
                        .foregroundStyle(notification.read ? BoopColors.textMuted : BoopColors.accentColor)
                        .frame(width: 22)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(notification.title)
                                .font(BoopTypography.cineBody)
                                .foregroundStyle(BoopColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(notification.timeAgo)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textMuted)
                        }

                        Text(notification.body)
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    // Unread dot
                    if !notification.read {
                        Circle()
                            .fill(BoopColors.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                    }
                }
                .padding(.vertical, BoopSpacing.md)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
