import SwiftUI

struct ProductCard: View {
    let item: InventoryItem
    let onPrimaryAction: (() -> Void)?

    init(item: InventoryItem, onPrimaryAction: (() -> Void)? = nil) {
        self.item = item
        self.onPrimaryAction = onPrimaryAction
    }

    var body: some View {
        VStack(spacing: 12) {
            topRow
            infoRow
            progressRow

            if let actionTitle = item.status.actionTitle,
               let gradient = item.status.actionGradient {
                Button(action: { onPrimaryAction?() }) {
                    Text(actionTitle)
                        .font(.sfProMedium(17))
                        .foregroundStyle(item.status.actionTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(gradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.white)
        )
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 10) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.sfProDisplaySemibold(20))
                    .foregroundStyle(AppColors.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(item.weightText)
                    .font(.sfProMedium(15))
                    .foregroundStyle(AppColors.textGray)
            }

            Spacer(minLength: 8)
            statusBadge
        }
    }

    private var iconView: some View {
        Text(item.category.emoji ?? "❄️")
            .font(.system(size: 30))
            .frame(width: 54, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(item.category.iconBackground)
            )
    }

    private var statusBadge: some View {
        Text("\(item.status.emoji) \(item.status.title)")
            .font(.sfProSemibold(14))
            .foregroundStyle(item.status.badgeTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(item.status.badgeBackground)
            )
    }

    private var infoRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(leftInfoTitle)
                    .font(.sfProSemibold(15))
                    .foregroundStyle(AppColors.textGray)

                Text(item.frozenDateText)
                    .font(.sfProSemibold(14))
                    .foregroundStyle(AppColors.black)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(rightInfoTitle)
                    .font(.sfProSemibold(15))
                    .foregroundStyle(AppColors.textGray)

                Text(item.eatByText)
                    .font(.sfProSemibold(14))
                    .foregroundStyle(item.eatByColor)
            }
        }
    }

    private var leftInfoTitle: String {
        item.status == .done ? "DEFROSTED" : "FROZEN DATE"
    }

    private var rightInfoTitle: String {
        item.status == .done ? "USE WITHIN" : "EAT BY"
    }

    private var progressRow: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.progressTrack)

                Capsule()
                    .fill(item.status.progressColor)
                    .frame(width: max(4, proxy.size.width * item.progress))
            }
        }
        .frame(height: 6)
    }
}
