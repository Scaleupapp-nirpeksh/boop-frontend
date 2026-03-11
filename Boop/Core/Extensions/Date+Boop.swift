import Foundation

extension Date {
    /// Smart chat timestamp: "Just now", "5m", "2h", "Yesterday", "Mon", or "12/3"
    var chatTimestamp: String {
        let now = Date()
        let seconds = now.timeIntervalSince(self)

        if seconds < 60 {
            return "Just now"
        }
        if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        }
        if seconds < 86400 && Calendar.current.isDateInToday(self) {
            return "\(Int(seconds / 3600))h"
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        }
        if seconds < 604800 { // within 7 days
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: self)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: self)
    }
}
