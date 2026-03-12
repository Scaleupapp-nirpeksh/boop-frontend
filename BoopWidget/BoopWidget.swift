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
                    Color(red: 1.0, green: 0.976, blue: 0.961) // #FFF9F5
                }
        }
        .configurationDisplayName("Boop")
        .description("See your connections at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
