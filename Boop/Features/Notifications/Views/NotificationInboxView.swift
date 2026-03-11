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
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.secondary)
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

                    if notification.id != viewModel.notifications.last?.id {
                        Divider()
                            .padding(.leading, 64)
                    }
                }

                if viewModel.hasMore {
                    ProgressView()
                        .padding(BoopSpacing.lg)
                        .task { await viewModel.loadMore() }
                }
            }
            .padding(.horizontal, BoopSpacing.md)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: BoopSpacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(BoopColors.textMuted.opacity(0.5))
                .symbolEffect(.pulse, options: .repeating)

            Text("No notifications yet")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)

            Text("You'll see matches, messages, and activity here.")
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(BoopSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    SkeletonNotificationRow()
                    if i < 5 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.md)
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
            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: notification.typeIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(notification.title)
                            .font(BoopTypography.callout)
                            .fontWeight(notification.read ? .regular : .semibold)
                            .foregroundStyle(BoopColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(notification.timeAgo)
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }

                    Text(notification.body)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Unread dot
                if !notification.read {
                    Circle()
                        .fill(BoopColors.primary)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
            }
            .padding(.vertical, BoopSpacing.sm)
            .padding(.horizontal, BoopSpacing.xs)
            .background(notification.read ? Color.clear : BoopColors.primary.opacity(0.03))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var iconColor: Color {
        switch notification.typeColor {
        case "primary": return BoopColors.primary
        case "secondary": return BoopColors.secondary
        case "accent": return BoopColors.accent
        default: return BoopColors.textMuted
        }
    }
}
