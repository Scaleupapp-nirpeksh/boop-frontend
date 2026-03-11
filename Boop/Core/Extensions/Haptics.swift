import UIKit

enum Haptics {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func light() {
        lightImpact.impactOccurred()
    }

    static func medium() {
        mediumImpact.impactOccurred()
    }

    static func heavy() {
        heavyImpact.impactOccurred()
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func warning() {
        notification.notificationOccurred(.warning)
    }

    static func error() {
        notification.notificationOccurred(.error)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Double-tap celebration pattern for match moments
    static func celebration() {
        heavyImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            heavyImpact.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            notification.notificationOccurred(.success)
        }
    }
}
