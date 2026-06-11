import WidgetKit
import SwiftUI

@main
struct BoopWidgetBundle: WidgetBundle {
    var body: some Widget {
        BoopWidget()
    }
}

struct BoopWidget: Widget {
    let kind: String = "BoopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BoopWidgetProvider()) { entry in
            BoopWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.047, green: 0.031, blue: 0.063) // #0C0810 — cinematic ground
                }
        }
        .configurationDisplayName("Boop")
        .description("See your connections at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
