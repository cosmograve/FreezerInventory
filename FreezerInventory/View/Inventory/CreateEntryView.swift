import SwiftData
import SwiftUI
import UserNotifications
import UIKit

struct CreateEntryView: View {
    private enum Field: Hashable {
        case name
        case weight
        case note
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettingsKey.defaultTemperature) private var defaultStorageTemperature = AppSettingsDefault.defaultTemperature
    @AppStorage(AppSettingsKey.notifySevenDays) private var notifySevenDays = AppSettingsDefault.notifySevenDays
    @AppStorage(AppSettingsKey.notifyOneDay) private var notifyOneDay = AppSettingsDefault.notifyOneDay
    @AppStorage(AppSettingsKey.weightUnit) private var weightUnitRaw = AppSettingsDefault.weightUnit

    @State private var name = ""
    @State private var selectedCategory: InventoryCategory = .meat
    @State private var freezeDate = Date()
    @State private var weight = ""
    @State private var temperature: Double = AppSettingsDefault.defaultTemperature
    @State private var note = ""
    @State private var didInitializeTemperature = false
    @State private var showNameError = false
    @State private var showWeightError = false
    @FocusState private var focusedField: Field?

    private let categoryOrder: [InventoryCategory] = [.meat, .veg, .herbs, .dish, .fish, .milk, .tomat, .bread]

    private var weightUnit: AppWeightUnit {
        AppWeightUnit(rawValue: weightUnitRaw) ?? .grams
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.progressTrack)
                .frame(width: 44, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ZStack {
                Text("Create Entry")
                    .font(.sfProSemibold(17))
                    .foregroundStyle(AppColors.black)

                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.textGray)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(AppColors.progressTrack.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Name")
                    requiredField(
                        placeholder: "Product name",
                        text: $name,
                        showError: showNameError,
                        field: .name
                    )

                    sectionTitle("Category")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categoryOrder) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(category.emoji ?? "❄️")
                                            .font(.system(size: 26))
                                        Text(category.title)
                                            .font(.sfProDisplayMedium(15))
                                    }
                                    .foregroundStyle(selectedCategory == category ? AppColors.white : AppColors.black)
                                    .frame(width: 90, height: 90)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(selectedCategory == category ? AppColors.blue0088FF : AppColors.progressTrack.opacity(0.35))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal, -16)
                    .contentMargins(.horizontal, 16, for: .scrollContent)

                    sectionTitle("Date")
                    HStack {
                        DatePicker(
                            "",
                            selection: $freezeDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(AppColors.blue0088FF)
                        .font(.sfProDisplayRegular(17))

                        Spacer()

                        Image(systemName: "calendar")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.textGray)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.progressTrack.opacity(0.35))
                    )

                    sectionTitle("Weight")
                    requiredField(
                        placeholder: weightPlaceholder,
                        text: $weight,
                        showError: showWeightError,
                        keyboardType: .decimalPad,
                        field: .weight
                    )

                    HStack {
                        sectionTitle("Storage temperature")
                        Spacer()
                        Text("\(Int(temperature)) C")
                            .font(.sfProDisplaySemibold(24))
                            .foregroundStyle(AppColors.black)
                    }

                    temperatureSlider

                    sectionTitle("Note (optional)")
                    TextField("Add specific storage instructions...", text: $note, axis: .vertical)
                        .font(.sfProDisplayRegular(17))
                        .foregroundStyle(AppColors.black)
                        .focused($focusedField, equals: .note)
                        .padding(16)
                        .frame(minHeight: 96, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppColors.progressTrack.opacity(0.35))
                        )

                    Button(action: saveEntry) {
                        Text("Save")
                            .font(.sfProDisplaySemibold(17))
                            .foregroundStyle(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.blueButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .font(.sfProDisplaySemibold(17))
                .tint(AppColors.blue0088FF)
            }
        }
        .onAppear {
            guard !didInitializeTemperature else { return }
            temperature = defaultStorageTemperature
            didInitializeTemperature = true
        }
        .onChange(of: name) { _, newValue in
            if showNameError, !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showNameError = false
            }
        }
        .onChange(of: weight) { _, newValue in
            if showWeightError, AppWeightFormatter.grams(fromInput: newValue, unit: weightUnit) > 0 {
                showWeightError = false
            }
        }
    }

    private var temperatureSlider: some View {
        VStack(spacing: 6) {
            Slider(value: $temperature, in: -24 ... -10, step: 1)
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
    }

    private var weightPlaceholder: String {
        switch weightUnit {
        case .grams:
            return "0 g"
        case .kilograms:
            return "0 kg"
        }
    }

    private func sectionTitle(_ value: String) -> some View {
        Text(value)
            .font(.sfProDisplaySemibold(17))
            .foregroundStyle(AppColors.black)
    }

    private func requiredField(
        placeholder: String,
        text: Binding<String>,
        showError: Bool,
        keyboardType: UIKeyboardType = .default,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(placeholder, text: text)
                .font(.sfProMedium(17))
                .foregroundStyle(AppColors.black)
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppColors.progressTrack.opacity(0.35))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(showError ? AppColors.redExpire : Color.clear, lineWidth: 1.5)
                )

            if showError {
                Text("You need to fill in this field")
                    .font(.sfProMedium(13))
                    .foregroundStyle(AppColors.redExpire)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func saveEntry() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWeight = AppWeightFormatter.grams(fromInput: weight, unit: weightUnit)
        let isNameValid = !trimmedName.isEmpty
        let isWeightValid = normalizedWeight > 0

        showNameError = !isNameValid
        showWeightError = !isWeightValid

        guard isNameValid, isWeightValid else { return }

        let temp = Int(temperature.rounded())
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let expiration = StorageDurationPolicy.expirationDate(
            frozenDate: freezeDate,
            categoryRaw: selectedCategory.rawValue,
            temperatureC: temp
        )

        let newProduct = StoredProduct(
            name: trimmedName,
            categoryRaw: selectedCategory.rawValue,
            weightGrams: normalizedWeight,
            frozenDate: freezeDate,
            storageTemperatureC: temp,
            note: normalizedNote,
            expirationDate: expiration,
            status: .frozen,
            disposition: .active
        )

        modelContext.insert(newProduct)
        try? modelContext.save()
        scheduleExpirationNotifications(for: newProduct)
        dismiss()
    }

    private func scheduleExpirationNotifications(for product: StoredProduct) {
        guard notifySevenDays || notifyOneDay else { return }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }

        if notifySevenDays {
            scheduleExpirationNotification(
                center: center,
                product: product,
                daysBeforeExpiration: 7,
                identifierSuffix: "7d",
                body: "\(product.name) expires in 7 days."
            )
        }

        if notifyOneDay {
            scheduleExpirationNotification(
                center: center,
                product: product,
                daysBeforeExpiration: 1,
                identifierSuffix: "1d",
                body: "\(product.name) expires tomorrow."
            )
        }
    }

    private func scheduleExpirationNotification(
        center: UNUserNotificationCenter,
        product: StoredProduct,
        daysBeforeExpiration: Int,
        identifierSuffix: String,
        body: String
    ) {
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBeforeExpiration, to: product.expirationDate) else {
            return
        }
        guard triggerDate > .now else { return }

        let identifier = "expiration-\(product.id.uuidString)-\(identifierSuffix)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

        let content = UNMutableNotificationContent()
        content.title = "Expiration reminder"
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}

#Preview {
    CreateEntryView()
}
