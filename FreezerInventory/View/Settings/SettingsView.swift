import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage(AppSettingsKey.defaultTemperature) private var defaultTemperature = AppSettingsDefault.defaultTemperature
    @AppStorage(AppSettingsKey.notifySevenDays) private var notifySevenDays = AppSettingsDefault.notifySevenDays
    @AppStorage(AppSettingsKey.notifyOneDay) private var notifyOneDay = AppSettingsDefault.notifyOneDay
    @AppStorage(AppSettingsKey.notifyTimerFinished) private var notifyTimerFinished = AppSettingsDefault.notifyTimerFinished
    @AppStorage(AppSettingsKey.weightUnit) private var selectedUnitRaw = AppSettingsDefault.weightUnit

    private var selectedUnit: AppWeightUnit {
        AppWeightUnit(rawValue: selectedUnitRaw) ?? .grams
    }

    var body: some View {
        VStack(spacing: 10) {
            AppNavigationBar(title: "Settings")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Storage temperature")
                            .font(.sfProDisplaySemibold(17))
                            .foregroundStyle(AppColors.black)
                        Spacer()
                        Text("\(Int(defaultTemperature)) C")
                            .font(.sfProDisplaySemibold(24))
                            .foregroundStyle(AppColors.black)
                    }

                    VStack(spacing: 6) {
                        Slider(value: $defaultTemperature, in: -24 ... -10, step: 1)
                            .tint(AppColors.blue0088FF)

                        HStack {
                            Text("-24")
                                .font(.sfProDisplaySemibold(17))
                                .foregroundStyle(AppColors.textGray)
                            Spacer()
                            Text("-10")
                                .font(.sfProDisplaySemibold(17))
                                .foregroundStyle(AppColors.textGray)
                        }
                    }

                    Text("Notifications")
                        .font(.sfProDisplaySemibold(17))
                        .foregroundStyle(AppColors.black)

                    settingToggleRow(
                        title: "7 days before expiration",
                        subtitle: "Early warning for inventory rotation",
                        isOn: $notifySevenDays
                    )

                    settingToggleRow(
                        title: "1 day before expiration",
                        subtitle: "Critical alert for immediate action",
                        isOn: $notifyOneDay
                    )

                    settingToggleRow(
                        title: "Timer finished",
                        subtitle: "Alert when defrost timer ends",
                        isOn: $notifyTimerFinished
                    )

                    Text("Weight units")
                        .font(.sfProDisplaySemibold(17))
                        .foregroundStyle(AppColors.black)

                    HStack(spacing: 10) {
                        unitButton(.grams)
                        unitButton(.kilograms)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .onChange(of: notifySevenDays) { _, newValue in
            if newValue {
                requestNotificationPermission()
            } else {
                removePendingNotifications { identifier in
                    identifier.hasPrefix("expiration-") && identifier.hasSuffix("-7d")
                }
            }
        }
        .onChange(of: notifyOneDay) { _, newValue in
            if newValue {
                requestNotificationPermission()
            } else {
                removePendingNotifications { identifier in
                    identifier.hasPrefix("expiration-") && identifier.hasSuffix("-1d")
                }
            }
        }
        .onChange(of: notifyTimerFinished) { _, newValue in
            if newValue {
                requestNotificationPermission()
            } else {
                removePendingNotifications { identifier in
                    identifier.hasPrefix("defrost-ready-")
                }
            }
        }
    }

    private func settingToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sfProDisplaySemibold(17))
                    .foregroundStyle(AppColors.black)
                Text(subtitle)
                    .font(.sfProDisplayRegular(15))
                    .foregroundStyle(AppColors.textGray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.green1ECF66)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.white)
        )
    }

    private func unitButton(_ unit: AppWeightUnit) -> some View {
        Button {
            selectedUnitRaw = unit.rawValue
        } label: {
            Text(unit.shortLabel)
                .font(.sfProDisplaySemibold(38))
                .foregroundStyle(selectedUnit == unit ? AppColors.white : AppColors.black)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selectedUnit == unit
                              ? AnyShapeStyle(AppColors.blueButtonGradient)
                              : AnyShapeStyle(AppColors.white))
                )
        }
        .buttonStyle(.plain)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func removePendingNotifications(where matches: @escaping (String) -> Bool) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter(matches)

            guard !identifiers.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
}

#Preview {
    SettingsView()
}
