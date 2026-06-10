import SwiftUI

enum BoopColors {
    // MARK: - Brand (Electric Heart)
    static let brand = Color.dynamic(light: Color(hex: "FF4D6D"), dark: Color(hex: "FF5C7A"))      // coral
    static let brandViolet = Color.dynamic(light: Color(hex: "A23DE8"), dark: Color(hex: "B65CF0")) // violet
    static let primary = brand          // repoint legacy name
    static let secondary = brandViolet  // repoint legacy name (was mint)
    static let accent = Color.dynamic(light: Color(hex: "FF8A5C"), dark: Color(hex: "FFA06E"))      // warm ember

    // MARK: - Backgrounds (adaptive)
    static let background = Color.dynamic(light: Color(hex: "FFFBF7"), dark: Color(hex: "120A16"))
    static let backgroundBlush = Color.dynamic(light: Color(hex: "FFF1EB"), dark: Color(hex: "1A0F1E"))
    static let backgroundMint = Color.dynamic(light: Color(hex: "F3E8F0"), dark: Color(hex: "1A0F22"))
    static let surface = Color.dynamic(light: .white, dark: Color(hex: "1C1124"))
    static let surfaceSecondary = Color.dynamic(light: Color(hex: "F8F4F0"), dark: Color(hex: "241630"))
    static let surfaceElevated = Color.dynamic(light: Color(hex: "FFFCFA"), dark: Color(hex: "241630"))

    // MARK: - Text (adaptive)
    static let textPrimary = Color.dynamic(light: Color(hex: "2A1A2E"), dark: Color(hex: "F4ECF2"))
    static let textSecondary = Color.dynamic(light: Color(hex: "6B5B70"), dark: Color(hex: "B3A4BC"))
    static let textMuted = Color.dynamic(light: Color(hex: "9B8FA5"), dark: Color(hex: "8A7A93"))
    static let textOnPrimary = Color.white

    // MARK: - Semantic
    static let error = Color(hex: "E74C3C")
    static let success = Color(hex: "2ECC71")
    static let warning = Color(hex: "F39C12")

    // MARK: - Dark Cards
    static let cardDark = Color(hex: "1C2332")
    static let cardDarkAlt = Color(hex: "182433")
    static let cardDarkAccent = Color(hex: "1F2637")
    static let cardDarkProfile = Color(hex: "1D2638")
    static let chatBackground = Color.dynamic(light: Color(hex: "F6F2EE"), dark: Color(hex: "160C1C"))
    static let chatBubbleReceived = Color.dynamic(light: .white, dark: Color(hex: "241630"))
    static let overlayLight = Color.white.opacity(0.12)
    static let overlayMedium = Color.white.opacity(0.3)

    // MARK: - Dark Gradient Mid-tones
    static let cardDarkMidBlue = Color(hex: "253452")
    static let cardDarkDeepBlue = Color(hex: "233852")
    static let cardDarkSlate = Color(hex: "36415E")
    static let cardDarkNavy = Color(hex: "294A62")
    static let cardDarkOcean = Color(hex: "345778")
    static let cardDarkDiscover = Color(hex: "1B3141")

    // MARK: - Tinted Surfaces
    static let surfaceWarm = Color(hex: "F4F1ED")
    static let surfaceMintLight = Color(hex: "EEF8F7")
    static let surfaceGoldenLight = Color(hex: "FFF6E8")
    static let surfaceGoldenBanner = Color(hex: "FFF6DA")
    static let surfacePinkLight = Color(hex: "FFECEA")
    static let surfaceBlushLight = Color(hex: "FFF3F1")
    static let goldenAccent = Color(hex: "D4A017")

    // MARK: - Borders
    static let border = Color.dynamic(light: Color(hex: "EEE6EE"), dark: Color(hex: "2E2238"))
    static let borderFocus = primary

    // MARK: - Gradients
    static let brandGradient = LinearGradient(
        colors: [brand, brandViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let primaryGradient = brandGradient   // repoint legacy name (BoopButton uses this)

    static let secondaryGradient = LinearGradient(
        colors: [brandViolet, Color(hex: "C97DF5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FFD93D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coralPinkGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FF9A9E")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let sunriseGradient = LinearGradient(
        colors: [Color(hex: "FFF4ED"), Color(hex: "FFF9F5"), Color(hex: "F1FFFC")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tealMintGradient = LinearGradient(
        colors: [Color(hex: "4ECDC4"), Color(hex: "A8EDEA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunsetGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FF9A9E"), Color(hex: "FFD93D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let highlightGradient = LinearGradient(
        colors: [primary.opacity(0.18), secondary.opacity(0.16), accent.opacity(0.18)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Dimension Colors
    static func dimensionColor(for dimension: String) -> Color {
        switch dimension {
        case "emotional_vulnerability": return Color(hex: "FF6B6B")  // Coral
        case "attachment_patterns": return Color(hex: "E056A0")      // Rose
        case "life_vision": return Color(hex: "4ECDC4")              // Teal
        case "conflict_resolution": return Color(hex: "FF8C42")      // Orange
        case "love_expression": return Color(hex: "F56FAD")          // Pink
        case "intimacy_comfort": return Color(hex: "9B5DE5")         // Purple
        case "lifestyle_rhythm": return Color(hex: "00BBF9")         // Sky Blue
        case "growth_mindset": return Color(hex: "2ECC71")           // Green
        default: return secondary
        }
    }
}
