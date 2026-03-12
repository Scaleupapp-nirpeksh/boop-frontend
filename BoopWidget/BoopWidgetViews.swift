import SwiftUI
import WidgetKit

struct BoopWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BoopWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("boop")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.31, green: 0.80, blue: 0.77)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
            }

            Spacer()

            // Connections count
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.connections)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.31, green: 0.80, blue: 0.77))
                Text("connections")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Streak
            if entry.streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)-day streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(4)
        .widgetURL(URL(string: "boop://discover"))
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left column — branding + connections
            VStack(alignment: .leading, spacing: 8) {
                Text("boop")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.31, green: 0.80, blue: 0.77)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.connections)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.31, green: 0.80, blue: 0.77))
                    Text("connections")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Right column — stats
            VStack(alignment: .leading, spacing: 10) {
                statRow(
                    icon: "envelope.fill",
                    iconColor: Color(red: 1.0, green: 0.42, blue: 0.42),
                    value: "\(entry.unreadMessages)",
                    label: "unread"
                )

                statRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(entry.streak)",
                    label: entry.streakMatchName.map { "with \($0)" } ?? "day streak"
                )

                statRow(
                    icon: "questionmark.circle.fill",
                    iconColor: Color(red: 1.0, green: 0.85, blue: 0.24),
                    value: "\(entry.questionsAnswered)",
                    label: "answered"
                )

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
        .widgetURL(URL(string: "boop://home"))
    }

    private func statRow(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
                .frame(width: 16)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview(as: .systemSmall) {
    BoopWidget()
} timeline: {
    BoopWidgetEntry(date: .now, connections: 5, unreadMessages: 3, streak: 12, streakMatchName: "Priya", questionsAnswered: 34)
}

#Preview(as: .systemMedium) {
    BoopWidget()
} timeline: {
    BoopWidgetEntry(date: .now, connections: 5, unreadMessages: 3, streak: 12, streakMatchName: "Priya", questionsAnswered: 34)
}
