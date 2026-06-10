import SwiftUI

enum BoopColors {
    // MARK: - Accent (Cinematic Dark — single flat coral / vermilion)
    static let accentColor = Color.dynamic(light: Color(hex: "C0392B"), dark: Color(hex: "FF4D6D"))
    static let brand = accentColor
    static let primary = accentColor
    static let secondary = accentColor
    static let accent = accentColor
    static let brandViolet = accentColor

    // MARK: - Ground & surfaces (dark-first)
    static let ground = Color.dynamic(light: Color(hex: "F7F3EC"), dark: Color(hex: "0C0810"))
    static let background = ground
    static let backgroundBlush = Color.dynamic(light: Color(hex: "EFE9DD"), dark: Color(hex: "14101B"))
    static let backgroundMint = Color.dynamic(light: Color(hex: "EFE9DD"), dark: Color(hex: "14101B"))
    static let surface = Color.dynamic(light: .white, dark: Color(hex: "14101B"))
    static let surfaceSecondary = Color.dynamic(light: Color(hex: "F0EADE"), dark: Color(hex: "1A141F"))
    static let surfaceElevated = Color.dynamic(light: .white, dark: Color(hex: "1A141F"))

    // MARK: - Text
    static let textPrimary = Color.dynamic(light: Color(hex: "1B1B18"), dark: Color(hex: "F4ECF2"))
    static let textSecondary = Color.dynamic(light: Color(hex: "6B6358"), dark: Color.white.opacity(0.62))
    static let textMuted = Color.dynamic(light: Color(hex: "8A7F72"), dark: Color.white.opacity(0.40))
    static let textOnPrimary = Color.white

    // MARK: - Semantic
    static let error = Color.dynamic(light: Color(hex: "C0392B"), dark: Color(hex: "FF6B6B"))
    static let success = Color.dynamic(light: Color(hex: "2E7D5B"), dark: Color(hex: "5BD6A0"))
    static let warning = Color.dynamic(light: Color(hex: "B7791F"), dark: Color(hex: "F0B84E"))

    // MARK: - Dark Cards
    static let cardDark = Color(hex: "1C2332")
    static let cardDarkAlt = Color(hex: "182433")
    static let cardDarkAccent = Color(hex: "1F2637")
    static let cardDarkProfile = Color(hex: "1D2638")
    static let chatBackground = ground
    static let chatBubbleReceived = surface
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
    static let hairline = Color.dynamic(light: Color(hex: "E2DBCF"), dark: Color.white.opacity(0.11))
    static let border = hairline
    static let borderFocus = accentColor

    // MARK: - Gradients (retired — flattened to flat coral accent)
    static let brandGradient = LinearGradient(colors: [accentColor, accentColor], startPoint: .leading, endPoint: .trailing)
    static let primaryGradient = brandGradient
    static let secondaryGradient = brandGradient
    static let warmGradient = brandGradient
    static let sunriseGradient = brandGradient
    static let coralPinkGradient = brandGradient
    static let tealMintGradient = brandGradient
    static let sunsetGradient = brandGradient
    static let highlightGradient = brandGradient

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
