import SwiftUI

@Observable
class NotificationInboxViewModel {
    var notifications: [NotificationItem] = []
    var unreadCount = 0
    var isLoading = false
    var currentPage = 1
    var totalPages = 1
    var hasMore: Bool { currentPage < totalPages }

    // MARK: - Load

    @MainActor
    func loadNotifications(refresh: Bool = false) async {
        if refresh { currentPage = 1 }
        guard !isLoading else { return }
        isLoading = true

        do {
            let response: NotificationsResponse = try await APIClient.shared.request(
                .getNotifications(page: currentPage)
            )
            if refresh {
                notifications = response.notifications
            } else if currentPage > 1 {
                notifications.append(contentsOf: response.notifications)
            } else {
                notifications = response.notifications
            }
            unreadCount = response.unreadCount
            totalPages = response.totalPages
        } catch {
            // Non-critical
        }

        isLoading = false
    }

    @MainActor
    func loadMore() async {
        guard hasMore, !isLoading else { return }
        currentPage += 1
        await loadNotifications()
    }

    // MARK: - Unread Count (lightweight poll)

    @MainActor
    func refreshUnreadCount() async {
        do {
            let response: UnreadCountResponse = try await APIClient.shared.request(.getUnreadNotificationCount)
            unreadCount = response.unreadCount
        } catch {
            // Non-critical
        }
    }

    // MARK: - Mark Read

    @MainActor
    func markAsRead(_ notification: NotificationItem) async {
        guard !notification.read else { return }
        do {
            try await APIClient.shared.requestVoid(.markNotificationRead(notificationId: notification.id))
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                // Create updated copy
                let old = notifications[index]
                let updated = NotificationItem(
                    _id: old._id, type: old.type, title: old.title, body: old.body,
                    data: old.data, read: true, createdAt: old.createdAt
                )
                notifications[index] = updated
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            // Non-critical
        }
    }

    @MainActor
    func markAllAsRead() async {
        do {
            try await APIClient.shared.requestVoid(.markAllNotificationsRead)
            notifications = notifications.map { n in
                NotificationItem(
                    _id: n._id, type: n.type, title: n.title, body: n.body,
                    data: n.data, read: true, createdAt: n.createdAt
                )
            }
            unreadCount = 0
        } catch {
            // Non-critical
        }
    }

    // MARK: - Delete

    @MainActor
    func deleteNotification(_ notification: NotificationItem) async {
        do {
            try await APIClient.shared.requestVoid(.deleteNotification(notificationId: notification.id))
            notifications.removeAll { $0.id == notification.id }
            if !notification.read {
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            // Non-critical
        }
    }

    // MARK: - Badge

    @MainActor
    func updateAppBadge() {
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount) }
    }

    @MainActor
    func clearAppBadge() {
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
    }
}
