import SwiftUI

struct ActiveSeason {
    let key: String
    let title: String
    let subtitle: String
    let emoji: String
    let tint: Color

    private static let seasons: [ActiveSeason] = [
        ActiveSeason(
            key: "valentines_2026",
            title: "Valentine's Special",
            subtitle: "Limited-time love questions unlocked!",
            emoji: "\u{1F498}",
            tint: Color(hex: "E8477C")
        ),
        ActiveSeason(
            key: "holi_2026",
            title: "Holi Festival",
            subtitle: "Colourful connection questions are live!",
            emoji: "\u{1F308}",
            tint: Color(hex: "9B59B6")
        ),
        ActiveSeason(
            key: "summer_2026",
            title: "Summer Vibes",
            subtitle: "Seasonal summer prompts are here!",
            emoji: "\u{2600}\u{FE0F}",
            tint: Color(hex: "F39C12")
        ),
        ActiveSeason(
            key: "monsoon_2026",
            title: "Monsoon Magic",
            subtitle: "Rainy day questions unlocked!",
            emoji: "\u{1F327}\u{FE0F}",
            tint: Color(hex: "3498DB")
        ),
        ActiveSeason(
            key: "diwali_2026",
            title: "Diwali Celebration",
            subtitle: "Festival of lights questions are live!",
            emoji: "\u{1FA94}",
            tint: Color(hex: "E67E22")
        ),
        ActiveSeason(
            key: "christmas_2026",
            title: "Winter Warmth",
            subtitle: "Holiday season prompts unlocked!",
            emoji: "\u{1F384}",
            tint: Color(hex: "27AE60")
        ),
    ]

    static var current: ActiveSeason? {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        let day = cal.component(.day, from: now)

        let ranges: [(key: String, startMonth: Int, startDay: Int, endMonth: Int, endDay: Int)] = [
            ("valentines_2026", 2, 7, 2, 21),
            ("holi_2026", 3, 10, 3, 20),
            ("summer_2026", 5, 1, 5, 31),
            ("monsoon_2026", 7, 1, 7, 31),
            ("diwali_2026", 10, 15, 10, 30),
            ("christmas_2026", 12, 20, 12, 31),
        ]

        for range in ranges {
            guard range.key.hasSuffix("\(year)") else { continue }
            let start = range.startMonth * 100 + range.startDay
            let end = range.endMonth * 100 + range.endDay
            let today = month * 100 + day
            if today >= start && today <= end {
                return seasons.first { $0.key == range.key }
            }
        }
        return nil
    }
}
