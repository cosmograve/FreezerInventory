import SwiftUI

struct CapsuleTabBar: View {
    @Binding var selectedTab: RootTab
    let showsSearchButton: Bool
    let onSearchTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(RootTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 17, weight: .semibold))
                            Text(tab.title)
                                .font(.sfProMedium(10))
                        }
                        .foregroundStyle(selectedTab == tab ? AppColors.tabBarSelected : AppColors.tabBarUnselected)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedTab == tab ? selectedTabBackground : Color.clear)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .fill(selectedTab == tab ? AppColors.black.opacity(0.07) : Color.clear)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(selectedTab == tab ? AppColors.white.opacity(0.55) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                Capsule(style: .continuous)
                    .fill(tabBarFillStyle)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tabBarBorderColor, lineWidth: 1)
            )
            .shadow(color: AppColors.black.opacity(usesLiquidGlass ? 0.08 : 0), radius: 10, y: 3)

            if showsSearchButton {
                Button(action: onSearchTap) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppColors.tabBarUnselected)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(searchButtonFillStyle))
                        .overlay(Circle().stroke(tabBarBorderColor, lineWidth: 1))
                        .shadow(color: AppColors.black.opacity(usesLiquidGlass ? 0.08 : 0), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var usesLiquidGlass: Bool {
        true
    }

    private var tabBarFillStyle: AnyShapeStyle {
        if usesLiquidGlass {
            return AnyShapeStyle(.ultraThinMaterial)
        }
        return AnyShapeStyle(AppColors.tabBarBackground)
    }

    private var searchButtonFillStyle: AnyShapeStyle {
        if usesLiquidGlass {
            return AnyShapeStyle(.ultraThinMaterial)
        }
        return AnyShapeStyle(AppColors.tabBarBackground)
    }

    private var tabBarBorderColor: Color {
        usesLiquidGlass ? AppColors.white.opacity(0.55) : AppColors.tabBarBorder
    }

    private var selectedTabBackground: Color {
        AppColors.tabBarSelectedBackground
    }
}
