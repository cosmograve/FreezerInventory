import SwiftUI

struct ProductSwipeActionsView: View {
    static let revealWidth: CGFloat = 132

    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            actionButton(
                icon: "trash",
                title: "Delete",
                color: AppColors.redExpire,
                action: onDelete
            )

            actionButton(
                icon: "archivebox",
                title: "Archive",
                color: AppColors.orangeDF5C2E,
                action: onArchive
            )
        }
        .frame(width: Self.revealWidth, alignment: .trailing)
        .padding(.trailing, 2)
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(color))

                Text(title)
                    .font(.sfProMedium(15))
                    .foregroundStyle(AppColors.textGray)
            }
            .frame(width: 62)
        }
        .buttonStyle(.plain)
    }
}
