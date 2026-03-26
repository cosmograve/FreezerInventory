import SwiftUI
import SwiftData

@main
struct FreezerInventoryApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appNotificationDelegate
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: StoredProduct.self, ProductUsageEvent.self)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
