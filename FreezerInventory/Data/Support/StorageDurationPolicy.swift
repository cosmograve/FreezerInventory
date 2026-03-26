import Foundation

enum StorageDurationPolicy {
    static func baseDays(for categoryRaw: String) -> Int {
        switch categoryRaw {
        case "meat":
            return 274
        case "fish":
            return 183
        case "veg":
            return 365
        case "herbs":
            return 183
        case "dish":
            return 122
        case "milk":
            return 183
        case "tomat":
            return 305
        case "bread":
            return 183
        default:
            return 183
        }
    }

    static func storageDays(categoryRaw: String, temperatureC: Int) -> Int {
        let base = Double(baseDays(for: categoryRaw))
        let adjusted = temperatureC == -18 ? base : base * 0.8
        return max(1, Int(adjusted.rounded(.toNearestOrAwayFromZero)))
    }

    static func expirationDate(frozenDate: Date, categoryRaw: String, temperatureC: Int) -> Date {
        let days = storageDays(categoryRaw: categoryRaw, temperatureC: temperatureC)
        return Calendar.current.date(byAdding: .day, value: days, to: frozenDate) ?? frozenDate
    }
}
