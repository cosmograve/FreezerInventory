import SwiftData
import SwiftUI

struct InventoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettingsKey.weightUnit) private var weightUnitRaw = AppSettingsDefault.weightUnit

    @Query(sort: [SortDescriptor(\StoredProduct.frozenDate, order: .reverse)])
    private var products: [StoredProduct]

    @Binding var searchText: String
    let onOpenDefrost: (UUID) -> Void

    @State private var selectedCategory: InventoryCategory = .all
    @State private var isCreateEntryPresented = false
    @State private var openActionProductID: UUID?

    init(
        searchText: Binding<String>,
        onOpenDefrost: @escaping (UUID) -> Void = { _ in }
    ) {
        _searchText = searchText
        self.onOpenDefrost = onOpenDefrost
    }

    private var weightUnit: AppWeightUnit {
        AppWeightUnit(rawValue: weightUnitRaw) ?? .grams
    }

    private var filteredProducts: [StoredProduct] {
        let active = products.filter {
            $0.disposition == .active
        }

        let byCategory: [StoredProduct]
        if selectedCategory == .all {
            byCategory = active
        } else {
            byCategory = active.filter { $0.categoryRaw == selectedCategory.rawValue }
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return byCategory
        }

        return byCategory.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            AppNavigationBar(
                title: "Inventory list",
                trailingSystemImage: "plus",
                onTrailingTap: { isCreateEntryPresented = true }
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    categories

                    if filteredProducts.isEmpty {
                        emptyState
                            .padding(.horizontal, 16)
                    } else {
                        cards
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .sheet(isPresented: $isCreateEntryPresented) {
            NavigationStack {
                CreateEntryView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            try? modelContext.save()
        }
    }

    private var categories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InventoryCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }

    private var cards: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredProducts) { product in
                SwipeRevealRow(
                    id: product.id,
                    openRowID: $openActionProductID,
                    revealWidth: ProductSwipeActionsView.revealWidth
                ) {
                    ProductCard(item: product.asInventoryItem(unit: weightUnit)) {
                        onOpenDefrost(product.id)
                    }
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No products yet")
                .font(.sfProDisplaySemibold(20))
                .foregroundStyle(AppColors.black)
            Text("Tap + to create your first inventory item")
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
}

#Preview {
    InventoryListView(searchText: .constant(""))
        .modelContainer(for: [StoredProduct.self, ProductUsageEvent.self], inMemory: true)
}
