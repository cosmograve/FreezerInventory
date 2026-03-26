import SwiftUI
import UIKit

extension Font {
    enum AppFontStyle {
        case sfProDisplaySemibold
        case sfProDisplayMedium
        case sfProMedium
        case sfProSemibold
        case sfProDisplayRegular
        case sfProDisplayBold

        fileprivate var fallbackWeight: Font.Weight {
            switch self {
            case .sfProDisplaySemibold:
                return .semibold
            case .sfProDisplayMedium:
                return .medium
            case .sfProMedium:
                return .medium
            case .sfProSemibold:
                return .semibold
            case .sfProDisplayRegular:
                return .regular
            case .sfProDisplayBold:
                return .bold
            }
        }

        fileprivate var fontCandidates: [String] {
            switch self {
            case .sfProDisplaySemibold:
                return ["SFProDisplay-Semibold", "SF Pro Display Semibold", "SFProDisplay-SemiBold"]
            case .sfProDisplayMedium:
                return ["SFProDisplay-Medium", "SF Pro Display Medium"]
            case .sfProMedium:
                return ["SFProText-Medium", "SF Pro Text Medium", "SFPro-Medium", "SFProDisplay-Medium"]
            case .sfProSemibold:
                return ["SFProText-Semibold", "SF Pro Text Semibold", "SFPro-Semibold", "SFProDisplay-Semibold"]
            case .sfProDisplayRegular:
                return ["SFProDisplay-Regular", "SF Pro Display Regular"]
            case .sfProDisplayBold:
                return ["SFProDisplay-Bold", "SF Pro Display Bold"]
            }
        }
    }

    static func sfPro(_ size: CGFloat, _ style: AppFontStyle) -> Font {
        if let fontName = style.fontCandidates.first(where: { UIFont(name: $0, size: size) != nil }) {
            return .custom(fontName, size: size)
        }

        return .system(size: size, weight: style.fallbackWeight, design: .default)
    }

    static func sfProDisplaySemibold(_ size: CGFloat) -> Font {
        sfPro(size, .sfProDisplaySemibold)
    }

    static func sfProDisplayMedium(_ size: CGFloat) -> Font {
        sfPro(size, .sfProDisplayMedium)
    }

    static func sfProMedium(_ size: CGFloat) -> Font {
        sfPro(size, .sfProMedium)
    }

    static func sfProSemibold(_ size: CGFloat) -> Font {
        sfPro(size, .sfProSemibold)
    }

    static func sfProDisplayRegular(_ size: CGFloat) -> Font {
        sfPro(size, .sfProDisplayRegular)
    }

    static func sfProDisplayBold(_ size: CGFloat) -> Font {
        sfPro(size, .sfProDisplayBold)
    }
}
