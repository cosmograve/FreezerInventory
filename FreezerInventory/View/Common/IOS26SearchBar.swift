import SwiftUI

struct IOS26SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onClose: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.black.opacity(0.75))

                TextField(placeholder, text: $text)
                    .font(.sfProMedium(17))
                    .foregroundStyle(AppColors.black)
                    .focused($isFocused)
                    .tint(AppColors.blue0088FF)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.black.opacity(0.42))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppColors.white.opacity(0.55), lineWidth: 1)
            )

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppColors.blue0088FF)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Circle()
                            .fill(AppColors.blue0088FF.opacity(0.08))
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.white.opacity(0.45), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }
}
