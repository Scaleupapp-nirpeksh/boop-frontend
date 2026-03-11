import SwiftUI

extension Font {
    static func nunito(_ weight: NunitoWeight, size: CGFloat) -> Font {
        .custom(BoopFont.family, size: size).weight(weight.swiftUIWeight)
    }

    enum NunitoWeight {
        case regular, medium, semiBold, bold, extraBold

        var swiftUIWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semiBold: return .semibold
            case .bold: return .bold
            case .extraBold: return .heavy
            }
        }
    }
}
