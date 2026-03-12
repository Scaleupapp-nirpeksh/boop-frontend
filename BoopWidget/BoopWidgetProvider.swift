import WidgetKit
import SwiftUI

struct BoopWidgetEntry: TimelineEntry {
    let date: Date
    let connections: Int
    let unreadMessages: Int
    let streak: Int
    let streakMatchName: String?
    let questionsAnswered: Int
}

struct BoopWidgetProvider: TimelineProvider {
    private static let suiteName = "group.com.influhitch.boop"

    func placeholder(in context: Context) -> BoopWidgetEntry {
        BoopWidgetEntry(
            date: Date(),
            connections: 3,
            unreadMessages: 2,
            streak: 7,
            streakMatchName: "Priya",
            questionsAnswered: 24
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BoopWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BoopWidgetEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> BoopWidgetEntry {
        let defaults = UserDefaults(suiteName: Self.suiteName)
        return BoopWidgetEntry(
            date: Date(),
            connections: defaults?.integer(forKey: "widget_connections") ?? 0,
            unreadMessages: defaults?.integer(forKey: "widget_unread") ?? 0,
            streak: defaults?.integer(forKey: "widget_streak") ?? 0,
            streakMatchName: defaults?.string(forKey: "widget_streak_name"),
            questionsAnswered: defaults?.integer(forKey: "widget_questions") ?? 0
        )
    }
}
