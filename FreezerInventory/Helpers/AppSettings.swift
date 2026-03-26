import Foundation

enum AppSettingsKey {
    static let defaultTemperature = "app.default_temperature"
    static let notifySevenDays = "app.notify_seven_days"
    static let notifyOneDay = "app.notify_one_day"
    static let notifyTimerFinished = "app.notify_timer_finished"
    static let weightUnit = "app.weight_unit"
}

enum AppSettingsDefault {
    static let defaultTemperature: Double = -18
    static let notifySevenDays = true
    static let notifyOneDay = true
    static let notifyTimerFinished = true
    static let weightUnit = AppWeightUnit.grams.rawValue
}

enum AppWeightUnit: String, CaseIterable, Identifiable {
    case grams
    case kilograms

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .grams:
            return "g"
        case .kilograms:
            return "kg"
        }
    }

    var suffix: String {
        switch self {
        case .grams:
            return "g"
        case .kilograms:
            return "kg"
        }
    }

    static var current: AppWeightUnit {
        let rawValue = UserDefaults.standard.string(forKey: AppSettingsKey.weightUnit) ?? AppSettingsDefault.weightUnit
        return AppWeightUnit(rawValue: rawValue) ?? .grams
    }
}

enum AppWeightFormatter {
    static func string(fromGrams grams: Int, unit: AppWeightUnit) -> String {
        switch unit {
        case .grams:
            return "\(grams)g"
        case .kilograms:
            let kilos = Double(grams) / 1000.0
            let value = formatKilos(kilos)
            return "\(value)kg"
        }
    }

    static func grams(fromInput value: String, unit: AppWeightUnit) -> Int {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")

        guard !normalized.isEmpty else { return 0 }

        switch unit {
        case .grams:
            let onlyDigits = normalized.filter { $0.isNumber }
            return max(0, Int(onlyDigits) ?? 0)
        case .kilograms:
            let numericPart = normalized.filter { $0.isNumber || $0 == "." }
            let kilos = Double(numericPart) ?? 0
            return max(0, Int((kilos * 1000).rounded()))
        }
    }

    private static func formatKilos(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        if (value * 10).rounded() == value * 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}
