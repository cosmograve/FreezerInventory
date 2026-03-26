import SwiftData
import SwiftUI

struct BasketView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettingsKey.weightUnit) private var weightUnitRaw = AppSettingsDefault.weightUnit

    @Query(sort: [SortDescriptor(\StoredProduct.defrostedAt, order: .reverse), SortDescriptor(\StoredProduct.createdAt, order: .reverse)])
    private var products: [StoredProduct]

    @Binding var searchText: String
    @State private var openActionProductID: UUID?

    private var weightUnit: AppWeightUnit {
        AppWeightUnit(rawValue: weightUnitRaw) ?? .grams
    }

    private var filteredProducts: [StoredProduct] {
        let basketItems = products.filter {
            $0.disposition == .active && $0.status == .done
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return basketItems
        }

        return basketItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            AppNavigationBar(title: "Basket")

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if filteredProducts.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredProducts) { product in
                            basketRow(product)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .task(id: products.map(\.id)) {
            purgeExpiredDefrostedProducts()
        }
    }

    private func basketRow(_ product: StoredProduct) -> some View {
        SwipeRevealRow(
            id: product.id,
            openRowID: $openActionProductID,
            revealWidth: ProductSwipeActionsView.revealWidth
        ) {
            ProductCard(item: product.asInventoryItem(unit: weightUnit))
        } actions: {
            ProductSwipeActionsView(
                onArchive: {
                    openActionProductID = nil
                    archiveAsWasted(product)
                },
                onDelete: {
                    openActionProductID = nil
                    deletePermanently(product)
                }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Basket is empty")
                .font(.sfProDisplaySemibold(20))
                .foregroundStyle(AppColors.black)
            Text("Defrosted products will appear here")
                .font(.sfProMedium(15))
                .foregroundStyle(AppColors.textGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.white.opacity(0.65))
        )
    }

    private func archiveAsWasted(_ product: StoredProduct) {
        guard product.disposition != .archived else { return }

        product.disposition = .archived
        product.archivedAt = .now
        product.deletedAt = nil

        modelContext.insert(
            ProductUsageEvent(
                eventType: .wasted,
                productName: product.name,
                weightGrams: product.weightGrams
            )
        )

        try? modelContext.save()
    }

    private func deletePermanently(_ product: StoredProduct) {
        modelContext.delete(product)
        try? modelContext.save()
    }

    private func purgeExpiredDefrostedProducts() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { return }

        let staleProducts = products.filter { product in
            guard product.disposition == .active, product.status == .done else { return false }
            guard let defrostedAt = product.defrostedAt else { return false }
            return defrostedAt <= cutoff
        }

        guard !staleProducts.isEmpty else { return }

        for product in staleProducts {
            product.disposition = .archived
            product.archivedAt = .now
            product.deletedAt = nil
            modelContext.insert(
                ProductUsageEvent(
                    eventType: .wasted,
                    productName: product.name,
                    weightGrams: product.weightGrams
                )
            )
        }

        try? modelContext.save()
    }
}

#Preview {
    BasketView(searchText: .constant(""))
        .modelContainer(for: [StoredProduct.self, ProductUsageEvent.self], inMemory: true)
}
