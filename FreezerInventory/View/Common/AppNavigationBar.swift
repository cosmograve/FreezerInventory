import SwiftUI

struct AppNavigationBar: View {
    let title: String
    var trailingSystemImage: String?
    var onTrailingTap: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.black)

            if let trailingSystemImage {
                HStack {
                    Spacer()
                    Button(action: { onTrailingTap?() }) {
                        Image(systemName: trailingSystemImage)
                            .font(.sfProDisplaySemibold(20))
                            .foregroundStyle(AppColors.black)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }
}
