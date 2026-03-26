import SwiftUI

enum ProductStatus {
    case frozen
    case defrost
    case done

    init(storageStatus: ProductStorageStatus) {
        switch storageStatus {
        case .frozen:
            self = .frozen
        case .defrost:
            self = .defrost
        case .done:
            self = .done
        }
    }

    var storageStatus: ProductStorageStatus {
        switch self {
        case .frozen:
            return .frozen
        case .defrost:
            return .defrost
        case .done:
            return .done
        }
    }

    var title: String {
        switch self {
        case .frozen:
            return "FROZEN"
        case .defrost:
            return "DEFROST"
        case .done:
            return "DONE"
        }
    }

    var emoji: String {
        switch self {
        case .frozen:
            return "🧊"
        case .defrost:
            return "💧"
        case .done:
            return "✅"
        }
    }

    var badgeBackground: Color {
        switch self {
        case .frozen:
            return AppColors.lightBlue
        case .defrost:
            return AppColors.warmFFF8EC
        case .done:
            return AppColors.mintE3FFF0
        }
    }

    var badgeTextColor: Color {
        switch self {
        case .frozen:
            return AppColors.blue0088FF
        case .defrost:
            return AppColors.orangeDF5C2E
        case .done:
            return AppColors.green1ECF66
        }
    }

    var actionTitle: String? {
        switch self {
        case .frozen:
            return "Start Defrost"
        case .defrost:
            return "View"
        case .done:
            return nil
        }
    }

    var actionGradient: LinearGradient? {
        switch self {
        case .frozen:
            return AppColors.startDefrostCardGradient
        case .defrost:
            return AppColors.viewCardGradient
        case .done:
            return nil
        }
    }

    var actionTextColor: Color {
        switch self {
        case .frozen:
            return AppColors.blue005CAD
        case .defrost:
            return AppColors.orangeAD4200
        case .done:
            return AppColors.black
        }
    }

    var progressColor: Color {
        switch self {
        case .frozen:
            return AppColors.green1ECF66
        case .defrost:
            return AppColors.orangeDF5C2E
        case .done:
            return AppColors.redExpire
        }
    }
}
