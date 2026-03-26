import Foundation
import SwiftUI

extension StoredProduct {
    var inventoryCategory: InventoryCategory {
        InventoryCategory(rawValue: categoryRaw) ?? .meat
    }

    func asInventoryItem(referenceDate: Date = .now, unit: AppWeightUnit = .grams) -> InventoryItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        let today = Calendar.current.startOfDay(for: referenceDate)
        let effectiveStartDate: Date
        let effectiveEndDate: Date
        let frozenDateText: String
        let eatByText: String
        let eatByColor: Color

        if status == .done {
            let defrostDate = defrostedAt ?? frozenDate
            let defrostDay = Calendar.current.startOfDay(for: defrostDate)
            let useByDate = Calendar.current.date(byAdding: .day, value: 7, to: defrostDate) ?? defrostDate
            let useByDay = Calendar.current.startOfDay(for: useByDate)

            effectiveStartDate = defrostDay
            effectiveEndDate = useByDay
            frozenDateText = formatter.string(from: defrostDate)

            let daysToUse = Calendar.current.dateComponents([.day], from: today, to: useByDay).day ?? 0

            if daysToUse < 0 {
                eatByText = "EXPIRED"
                eatByColor = AppColors.redExpire
            } else if daysToUse == 0 {
                eatByText = "TODAY"
                eatByColor = AppColors.redExpire
            } else if daysToUse == 1 {
                eatByText = "1 DAY LEFT"
                eatByColor = AppColors.redExpire
            } else {
                eatByText = "\(daysToUse) DAYS LEFT"
                eatByColor = daysToUse <= 2 ? AppColors.redExpire : AppColors.green1ECF66
            }
        } else {
            let expirationDay = Calendar.current.startOfDay(for: expirationDate)
            let frozenDay = Calendar.current.startOfDay(for: frozenDate)
            let daysToExpire = Calendar.current.dateComponents([.day], from: today, to: expirationDay).day ?? 0

            effectiveStartDate = frozenDay
            effectiveEndDate = expirationDay
            frozenDateText = formatter.string(from: frozenDate)

            if daysToExpire < 0 {
                eatByText = "EXPIRED"
                eatByColor = AppColors.redExpire
            } else {
                eatByText = formatter.string(from: expirationDate)
                if daysToExpire <= 2 {
                    eatByColor = AppColors.redExpire
                } else if daysToExpire <= 7 {
                    eatByColor = AppColors.orangeDF5C2E
                } else {
                    eatByColor = AppColors.green1ECF66
                }
            }
        }

        let fullInterval = max(1, effectiveEndDate.timeIntervalSince(effectiveStartDate))
        let elapsedInterval = max(0, today.timeIntervalSince(effectiveStartDate))
        let progress = min(1, CGFloat(elapsedInterval / fullInterval))

        return InventoryItem(
            id: id,
            name: name,
            weightText: AppWeightFormatter.string(fromGrams: weightGrams, unit: unit),
            frozenDateText: frozenDateText,
            eatByText: eatByText,
            eatByColor: eatByColor,
            status: ProductStatus(storageStatus: status),
            category: inventoryCategory,
            progress: progress
        )
    }
}
