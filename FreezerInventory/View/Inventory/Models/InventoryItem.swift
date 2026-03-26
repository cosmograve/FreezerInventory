import SwiftUI

struct InventoryItem: Identifiable {
    let id: UUID
    let name: String
    let weightText: String
    let frozenDateText: String
    let eatByText: String
    let eatByColor: Color
    let status: ProductStatus
    let category: InventoryCategory
    let progress: CGFloat
}

extension InventoryItem {
    static let preview = InventoryItem(
        id: UUID(),
        name: "Angus Beef Ribs",
        weightText: "850g",
        frozenDateText: "15.03.2025",
        eatByText: "15.09.2025",
        eatByColor: AppColors.green1ECF66,
        status: .frozen,
        category: .meat,
        progress: 0.38
    )
}
