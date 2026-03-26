import Foundation
import SwiftUI

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 3:
            a = 255
            r = ((value >> 8) & 0xF) * 17
            g = ((value >> 4) & 0xF) * 17
            b = (value & 0xF) * 17
        case 6:
            a = 255
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        case 8:
            a = (value >> 24) & 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        default:
            a = 255
            r = 0
            g = 0
            b = 0
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: min(max(Double(a) / 255 * opacity, 0), 1)
        )
    }

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: min(max(opacity, 0), 1)
        )
    }
}

enum AppColors {
    static let white = Color(hex: "FFFFFF")
    static let black = Color(hex: "000000")

    static let appBackground = Color(hex: "EFEFF1")
    static let tabBarBackground = Color(hex: "F7F7F7")
    static let tabBarBorder = Color(hex: "FFFFFF")
    static let tabBarSelected = Color(hex: "0088FF")
    static let tabBarSelectedBackground = Color(hex: "EDEDED")
    static let tabBarUnselected = Color(hex: "404040")
    static let textGray = Color(hex: "404040")
    static let primaryBlue = Color(hex: "0088FF")
    static let textFieldBlack50 = Color(hex: "000000", opacity: 0.5)
    static let timerButtonBackground = Color(hex: "747480", opacity: 0.08)
    static let progressTrack = Color(hex: "D9D9D9")
    static let redExpire = Color(hex: "FF4000")

    static let lightBlue = Color(hex: "EFF6FF")
    static let blue195EFF = Color(hex: "195EFF")
    static let blue005CAD = Color(hex: "005CAD")
    static let blue0088FF = Color(hex: "0088FF")
    static let orangeDF5C2E = Color(hex: "DF5C2E")
    static let warmFFF8EC = Color(hex: "FFF8EC")
    static let orangeAD4200 = Color(hex: "AD4200")
    static let green1ECF66 = Color(hex: "1ECF66")
    static let mintE3FFF0 = Color(hex: "E3FFF0")
    static let pinkFFBFBF = Color(hex: "FFBFBF")
    static let blue002C92 = Color(hex: "002C92")

    static let blueButtonGradient = LinearGradient(
        colors: [
            Color(hex: "0088FF"),
            Color(hex: "1AA7E1")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let orangeButtonGradient = LinearGradient(
        colors: [
            Color(hex: "FF6F00"),
            Color(hex: "E1731A")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let greenButtonGradient = LinearGradient(
        colors: [
            Color(hex: "1ECF66"),
            Color(hex: "00923B")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let startDefrostCardGradient = LinearGradient(
        colors: [
            Color(hex: "9FD8F3"),
            Color(hex: "83C9EA")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let viewCardGradient = LinearGradient(
        colors: [
            Color(hex: "F3C69E"),
            Color(hex: "E8B789")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
