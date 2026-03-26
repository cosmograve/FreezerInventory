import SwiftUI

struct CategoryChip: View {
    let category: InventoryCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let emoji = category.emoji {
                    Text(emoji)
                        .font(.system(size: 15))
                }

                Text(category.title)
                    .font(.sfProSemibold(17))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AppColors.white : AppColors.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppColors.blue0088FF : AppColors.white)
            )
        }
        .buttonStyle(.plain)
    }
}
