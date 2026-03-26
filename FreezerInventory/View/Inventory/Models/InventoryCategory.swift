import SwiftUI

enum InventoryCategory: String, CaseIterable, Identifiable {
    case all
    case veg
    case herbs
    case dish
    case fish
    case milk
    case meat
    case tomat
    case bread

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .veg:
            return "Veg"
        case .herbs:
            return "Herbs"
        case .dish:
            return "Dish"
        case .fish:
            return "Fish"
        case .milk:
            return "Milk"
        case .meat:
            return "Meat"
        case .tomat:
            return "Tomat"
        case .bread:
            return "Bread"
        }
    }

    var emoji: String? {
        switch self {
        case .all:
            return nil
        case .veg:
            return "🥬"
        case .herbs:
            return "🌿"
        case .dish:
            return "🍲"
        case .fish:
            return "🐟"
        case .milk:
            return "🧈"
        case .meat:
            return "🥩"
        case .tomat:
            return "🍎"
        case .bread:
            return "🍞"
        }
    }

    var iconBackground: Color {
        switch self {
        case .all:
            return AppColors.lightBlue
        case .veg, .herbs, .dish, .fish, .milk, .bread:
            return AppColors.warmFFF8EC
        case .meat, .tomat:
            return AppColors.lightBlue
        }
    }
}
