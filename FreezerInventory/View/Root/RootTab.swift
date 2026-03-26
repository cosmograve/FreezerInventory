import Foundation

enum RootTab: String, CaseIterable, Hashable, Identifiable {
    case main
    case stats
    case basket
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .main:
            return "Main"
        case .stats:
            return "Stats"
        case .basket:
            return "Basket"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .main:
            return "snowflake"
        case .stats:
            return "chart.bar.fill"
        case .basket:
            return "basket"
        case .settings:
            return "gearshape.fill"
        }
    }

    var showsSearchButton: Bool {
        self == .main || self == .basket
    }
}
