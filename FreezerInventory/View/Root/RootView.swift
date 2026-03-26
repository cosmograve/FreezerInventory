import SwiftUI
import SwiftData

struct RootView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainTabBarView { productID in
                navigationPath.append(RootNavigationRoute.defrost(productID))
            }
            .navigationDestination(for: RootNavigationRoute.self) { route in
                switch route {
                case let .defrost(productID):
                    DefrostDestinationView(productID: productID)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [StoredProduct.self, ProductUsageEvent.self], inMemory: true)
}
