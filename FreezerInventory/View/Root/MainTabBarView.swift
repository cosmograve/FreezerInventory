import SwiftUI
import SwiftData
import UIKit

struct MainTabBarView: View {
    let onOpenDefrost: (UUID) -> Void
    private let tabBarOverlayHeight: CGFloat = 84

    @State private var selectedTab: RootTab = .main

    @State private var inventorySearchText = ""
    @State private var basketSearchText = ""

    @State private var isInventorySearchPresented = false
    @State private var isBasketSearchPresented = false
    @State private var keyboardHeight: CGFloat = 0

    init(onOpenDefrost: @escaping (UUID) -> Void = { _ in }) {
        self.onOpenDefrost = onOpenDefrost
    }

    var body: some View {
        rootContent
    }

    private var rootContent: some View {
        ZStack(alignment: .bottom) {
            legacyContent

            if isActiveSearchPresented {
                searchOverlay
                    .padding(.bottom, searchBottomInset)
                    .zIndex(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { _, newValue in
            if !newValue.showsSearchButton {
                closeSearchBars()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            let height = max(0, screenHeight - frame.minY)
            withAnimation(.easeOut(duration: 0.2)) {
                keyboardHeight = height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                keyboardHeight = 0
            }
        }
    }

    private var legacyContent: some View {
        ZStack(alignment: .bottom) {
            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: tabBarOverlayHeight)
                }

            CapsuleTabBar(
                selectedTab: $selectedTab,
                showsSearchButton: selectedTab.showsSearchButton,
                onSearchTap: toggleSearch
            )
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var searchOverlay: some View {
        IOS26SearchBar(
            text: activeSearchTextBinding,
            placeholder: "Find",
            onClose: closeActiveSearch
        )
    }

    private var searchBottomInset: CGFloat {
        if keyboardHeight > 0 {
            return keyboardHeight + 2
        }
        return tabBarOverlayHeight + 2
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .main:
            InventoryListView(
                searchText: $inventorySearchText,
                onOpenDefrost: onOpenDefrost
            )
        case .stats:
            StatsView()
        case .basket:
            BasketView(searchText: $basketSearchText)
        case .settings:
            SettingsView()
        }
    }

    private func toggleSearch() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedTab {
            case .main:
                isInventorySearchPresented.toggle()
                if !isInventorySearchPresented { inventorySearchText = "" }
                isBasketSearchPresented = false
            case .basket:
                isBasketSearchPresented.toggle()
                if !isBasketSearchPresented { basketSearchText = "" }
                isInventorySearchPresented = false
            case .stats, .settings:
                break
            }
        }

        if !isActiveSearchPresented {
            keyboardHeight = 0
            dismissKeyboard()
        }
    }

    private func closeSearchBars() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isInventorySearchPresented = false
            isBasketSearchPresented = false
            inventorySearchText = ""
            basketSearchText = ""
            keyboardHeight = 0
        }
        dismissKeyboard()
    }

    private var isActiveSearchPresented: Bool {
        switch selectedTab {
        case .main:
            return isInventorySearchPresented
        case .basket:
            return isBasketSearchPresented
        case .stats, .settings:
            return false
        }
    }

    private var activeSearchTextBinding: Binding<String> {
        switch selectedTab {
        case .main:
            return $inventorySearchText
        case .basket:
            return $basketSearchText
        case .stats, .settings:
            return .constant("")
        }
    }

    private func closeActiveSearch() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedTab {
            case .main:
                isInventorySearchPresented = false
                inventorySearchText = ""
            case .basket:
                isBasketSearchPresented = false
                basketSearchText = ""
            case .stats, .settings:
                break
            }
        }
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    MainTabBarView()
        .modelContainer(for: [StoredProduct.self, ProductUsageEvent.self], inMemory: true)
}
