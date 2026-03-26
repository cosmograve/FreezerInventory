import SwiftData
import SwiftUI

private struct RestockRow: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let rate: String
}

private struct InflowPoint: Identifiable {
    let id = UUID()
    let monthLabel: String
    let count: Int
}

struct StatsView: View {
    @Query(sort: [SortDescriptor(\StoredProduct.createdAt, order: .reverse)])
    private var products: [StoredProduct]

    @Query(sort: [SortDescriptor(\ProductUsageEvent.createdAt, order: .reverse)])
    private var events: [ProductUsageEvent]

    @AppStorage(AppSettingsKey.weightUnit) private var weightUnitRaw = AppSettingsDefault.weightUnit

    private var weightUnit: AppWeightUnit {
        AppWeightUnit(rawValue: weightUnitRaw) ?? .grams
    }

    private var trackedProducts: [StoredProduct] {
        products.filter { $0.disposition != .deleted }
    }

    private var freezerProducts: [StoredProduct] {
        trackedProducts.filter { $0.disposition == .active && $0.status != .done }
    }

    private var totalItemsCount: Int {
        freezerProducts.count
    }

    private var totalWeightGrams: Int {
        freezerProducts.reduce(0) { $0 + $1.weightGrams }
    }

    private var thermalMassKg: Double {
        Double(totalWeightGrams) / 1000.0
    }

    private var thermalMassValue: String {
        switch weightUnit {
        case .grams:
            return "\(totalWeightGrams)"
        case .kilograms:
            return String(format: "%.1f", thermalMassKg)
        }
    }

    private var thermalMassSuffix: String {
        weightUnit.suffix
    }

    private var expiringSoonCount: Int {
        let today = Calendar.current.startOfDay(for: .now)

        return freezerProducts.filter { product in
            let targetDate = product.expirationDate
            let targetDay = Calendar.current.startOfDay(for: targetDate)
            let days = Calendar.current.dateComponents([.day], from: today, to: targetDay).day ?? Int.max
            return (0...7).contains(days)
        }.count
    }

    private var monthlyEvents: [ProductUsageEvent] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        return events.filter { $0.createdAt >= monthStart }
    }

    private var consumedCount: Int {
        monthlyEvents.filter { $0.eventType == .used }.count
    }

    private var wastedCount: Int {
        monthlyEvents.filter { $0.eventType == .wasted }.count
    }

    private var inflow: [InflowPoint] {
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        let currentMonthStart = monthStart(for: .now)
        guard !trackedProducts.isEmpty else {
            return [InflowPoint(monthLabel: monthFormatter.string(from: currentMonthStart), count: 0)]
        }

        var countsByMonth: [Date: Int] = [:]
        for product in trackedProducts {
            let month = monthStart(for: product.createdAt)
            countsByMonth[month, default: 0] += 1
        }

        let earliestMonthWithData = countsByMonth.keys.min() ?? currentMonthStart
        var points: [InflowPoint] = []
        var cursor = currentMonthStart

        while points.count < 7 && cursor >= earliestMonthWithData {
            let count = countsByMonth[cursor] ?? 0
            points.append(
                InflowPoint(
                    monthLabel: monthFormatter.string(from: cursor),
                    count: count
                )
            )

            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return points
    }

    private var maxInflowCount: Int {
        max(1, inflow.map(\.count).max() ?? 1)
    }

    private var maxInflowScale: Int {
        maxInflowCount + 1
    }

    private var inflowScaleTicks: [Int] {
        let top = maxInflowScale
        let step = max(1, Int(ceil(Double(top - 1) / 3.0)))
        let values = [top, top - step, top - (step * 2), 1]
        return Array(Set(values.map { max(1, $0) })).sorted(by: >)
    }

    private var topRestocks: [RestockRow] {
        let grouped = Dictionary(grouping: trackedProducts, by: { $0.name })
        let sorted = grouped.sorted { lhs, rhs in lhs.value.count > rhs.value.count }

        return sorted.prefix(3).map { name, items in
            let first = items.first
            let category = InventoryCategory(rawValue: first?.categoryRaw ?? "") ?? .meat
            return RestockRow(
                emoji: category.emoji ?? "❄️",
                title: name,
                subtitle: category.title,
                rate: "\(items.count) /month"
            )
        }
    }

    private func monthStart(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    var body: some View {
        VStack(spacing: 10) {
            AppNavigationBar(title: "Stats")

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        metricCard(title: "TOTAL ITEMS", value: "\(totalItemsCount)", suffix: "Units")
                        metricCard(title: "THERMAL MASS", value: thermalMassValue, suffix: thermalMassSuffix)
                    }

                    VStack(spacing: 6) {
                        Text("EXPIRING SOON (< 7 DAYS)")
                            .font(.sfProDisplaySemibold(17))
                            .foregroundStyle(AppColors.textGray)
                        Text("\(expiringSoonCount)")
                            .font(.sfProDisplaySemibold(38))
                            .foregroundStyle(AppColors.black)
                        Text("Units")
                            .font(.sfProDisplayRegular(17))
                            .foregroundStyle(AppColors.textGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.pinkFFBFBF)
                    )

                    HStack {
                        Circle()
                            .fill(AppColors.blue0088FF)
                            .frame(width: 10, height: 10)
                        Text("This Month")
                            .font(.sfProDisplaySemibold(20))
                            .foregroundStyle(AppColors.black)
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        metricCard(title: "CONSUMED", value: "\(consumedCount)", suffix: "Units")
                        metricCard(title: "WASTED", value: "\(wastedCount)", suffix: "Units")
                    }

                    if !trackedProducts.isEmpty {
                        stockInflowCard
                        topRestocksCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
    }

    private func metricCard(title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.textGray)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.sfProDisplaySemibold(38))
                    .foregroundStyle(AppColors.black)
                Text(suffix)
                    .font(.sfProDisplayRegular(17))
                    .foregroundStyle(AppColors.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.white)
        )
    }

    private var stockInflowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STOCK INFLOW")
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.textGray)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(inflowScaleTicks.enumerated()), id: \.offset) { index, value in
                        Text("\(value)")
                            .font(.sfProDisplayRegular(11))
                            .foregroundStyle(AppColors.textGray)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        if index != inflowScaleTicks.count - 1 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: 24, height: 130)

                ZStack(alignment: .bottomLeading) {
                    VStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(AppColors.progressTrack.opacity(0.45))
                                .frame(height: 1)
                        }
                    }

                    HStack(alignment: .bottom, spacing: 18) {
                        ForEach(inflow) { point in
                            chartPoint(for: point)
                        }
                    }
                    .padding(.leading, 18)
                    .padding(.trailing, 10)
                }
                .frame(height: 130)
            }

            HStack(spacing: 16) {
                Text(" ")
                    .frame(width: 24)
                ForEach(inflow) { point in
                    Text(point.monthLabel)
                        .font(.sfProDisplayRegular(13))
                        .foregroundStyle(AppColors.black)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.white)
        )
    }

    private func chartPoint(for point: InflowPoint) -> some View {
        let normalized = CGFloat(point.count) / CGFloat(maxInflowScale)
        let height = max(8, normalized * 86)

        return VStack(spacing: 4) {
            if point.count > 0 {
                Text("\(point.count) items")
                    .font(.sfProDisplayRegular(11))
                    .foregroundStyle(AppColors.textGray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(AppColors.progressTrack.opacity(0.5))
                    )
            } else {
                Spacer(minLength: 0)
                    .frame(height: 18)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: AppColors.blue0088FF, location: 0),
                            .init(color: AppColors.blue0088FF.opacity(0.62), location: 0.45),
                            .init(color: AppColors.white.opacity(0.85), location: 0.88),
                            .init(color: AppColors.white, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: height)
                .overlay(alignment: .top) {
                    Circle()
                        .fill(AppColors.white)
                        .frame(width: 10, height: 10)
                        .padding(.top, 2)
                }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var topRestocksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP 3 RESTOCKS")
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.textGray)

            if topRestocks.isEmpty {
                Text("No data yet")
                    .font(.sfProDisplayRegular(15))
                    .foregroundStyle(AppColors.textGray)
            } else {
                ForEach(topRestocks) { restock in
                    HStack(spacing: 10) {
                        Text(restock.emoji)
                            .font(.system(size: 20))
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppColors.lightBlue)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(restock.title)
                                .font(.sfProDisplaySemibold(17))
                                .foregroundStyle(AppColors.black)
                            Text(restock.subtitle)
                                .font(.sfProDisplayRegular(13))
                                .foregroundStyle(AppColors.textGray)
                        }

                        Spacer()

                        Text(restock.rate)
                            .font(.sfProDisplayRegular(13))
                            .foregroundStyle(AppColors.blue002C92)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.white)
        )
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [StoredProduct.self, ProductUsageEvent.self], inMemory: true)
}
