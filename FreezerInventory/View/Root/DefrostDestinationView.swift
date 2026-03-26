import SwiftData
import SwiftUI

struct DefrostDestinationView: View {
    let productID: UUID

    @Query private var products: [StoredProduct]

    init(productID: UUID) {
        self.productID = productID
        _products = Query(
            filter: #Predicate<StoredProduct> { product in
                product.id == productID
            }
        )
    }

    var body: some View {
        Group {
            if let product = products.first {
                DefrostTimerView(product: product)
            } else {
                Text("Product not found")
                    .font(.sfProMedium(15))
                    .foregroundStyle(AppColors.textGray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.appBackground.ignoresSafeArea())
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

