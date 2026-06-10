import SwiftUI

enum BoopFont {
    static let family = "Nunito"
}

enum BoopTypography {
    static let largeTitle = Font.nunito(.extraBold, size: 34)
    static let title1 = Font.nunito(.bold, size: 28)
    static let title2 = Font.nunito(.bold, size: 22)
    static let title3 = Font.nunito(.semiBold, size: 20)
    static let headline = Font.nunito(.semiBold, size: 17)
    static let body = Font.nunito(.regular, size: 17)
    static let callout = Font.nunito(.medium, size: 16)
    static let subheadline = Font.nunito(.medium, size: 15)
    static let footnote = Font.nunito(.regular, size: 13)
    static let caption = Font.nunito(.regular, size: 12)

    // MARK: - Cinematic ramp (system font, light weights)
    static let cineDisplayXL = Font.system(size: 42, weight: .thin)
    static let cineDisplay = Font.system(size: 32, weight: .light)
    static let cineTitle = Font.system(size: 25, weight: .light)
    static let cineHeadline = Font.system(size: 19, weight: .light)
    static let cineLabel = Font.system(size: 11, weight: .semibold)   // use UPPERCASE + .tracking(2) at call site / via EyebrowLabel
    static let cineBody = Font.system(size: 15, weight: .regular)
    static let cineBodyLight = Font.system(size: 15, weight: .light)
    static let cineCaption = Font.system(size: 11, weight: .regular)
}
