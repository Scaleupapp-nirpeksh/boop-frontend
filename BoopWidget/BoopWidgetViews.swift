import SwiftUI
import WidgetKit

// MARK: - Cinematic Dark tokens (local — widget is an isolated target without the
// main app's design system). Mirrors BoopColors / BoopTypography.
private enum Cine {
    static let ground = Color(red: 0.047, green: 0.031, blue: 0.063)   // #0C0810
    static let accent = Color(red: 1.0, green: 0.302, blue: 0.427)     // #FF4D6D
    static let textPrimary = Color(red: 0.957, green: 0.925, blue: 0.949) // #F4ECF2
    static let textSecondary = Color.white.opacity(0.62)
    static let textMuted = Color.white.opacity(0.40)
    static let hairline = Color.white.opacity(0.11)
}

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
        VStack(alignment: .leading, spacing: 0) {
            // Tracked uppercase wordmark
            Text("UNMUTEE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Cine.textMuted)

            // Coral section rule
            Rectangle()
                .fill(Cine.accent)
                .frame(width: 24, height: 2)
                .padding(.top, 6)

            Spacer()

            // Connections count — light-weight numeral
            Text("\(entry.connections)")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(Cine.textPrimary)

            Text("CONNECTIONS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Cine.textSecondary)

            // Streak — quiet line, no emoji
            if entry.streak > 0 {
                Text("\(entry.streak)-DAY STREAK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Cine.textMuted)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "boop://discover"))
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(alignment: .top, spacing: 18) {
            // Left column — wordmark + connections
            VStack(alignment: .leading, spacing: 0) {
                Text("UNMUTEE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Cine.textMuted)

                Rectangle()
                    .fill(Cine.accent)
                    .frame(width: 24, height: 2)
                    .padding(.top, 6)

                Spacer()

                Text("\(entry.connections)")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Cine.textPrimary)

                Text("CONNECTIONS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Cine.textSecondary)
            }

            // Hairline divider
            Rectangle()
                .fill(Cine.hairline)
                .frame(width: 1)

            // Right column — stats
            VStack(alignment: .leading, spacing: 0) {
                statRow(value: "\(entry.unreadMessages)", label: "UNREAD")
                hairline
                statRow(
                    value: "\(entry.streak)",
                    label: entry.streakMatchName.map { "WITH \($0.uppercased())" } ?? "DAY STREAK"
                )
                hairline
                statRow(value: "\(entry.questionsAnswered)", label: "ANSWERED")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "boop://home"))
    }

    private var hairline: some View {
        Rectangle()
            .fill(Cine.hairline)
            .frame(height: 1)
    }

    private func statRow(value: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .thin))
                .foregroundStyle(Cine.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Cine.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
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
