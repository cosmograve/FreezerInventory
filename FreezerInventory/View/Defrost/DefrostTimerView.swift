import SwiftData
import SwiftUI
import UserNotifications
import Combine
import UIKit

private enum DefrostMethod: String, CaseIterable, Identifiable {
    case fridge = "Fridge"
    case water = "Water"
    case micro = "Micro"

    var id: String { rawValue }
}

private enum DefrostDurationPolicy {
    static func minutes(method: DefrostMethod, weightGrams: Int) -> Int {
        let weight = max(0, weightGrams)

        switch method {
        case .fridge:
            if weight <= 500 {
                return formula(base: 1440, weight: weight, anchor: 500, factor: 1.2)
            }
            if weight <= 1000 {
                return formula(base: 2160, weight: weight, anchor: 1000, factor: 1.5)
            }
            return formula(base: 2880, weight: weight, anchor: 1000, factor: 2.0)

        case .water:
            if weight <= 500 {
                return formula(base: 90, weight: weight, anchor: 500, factor: 0.15)
            }
            if weight <= 1000 {
                return formula(base: 150, weight: weight, anchor: 1000, factor: 0.18)
            }
            return formula(base: 240, weight: weight, anchor: 1000, factor: 0.20)

        case .micro:
            if weight <= 500 {
                return formula(base: 12, weight: weight, anchor: 500, factor: 0.025)
            }
            if weight <= 1000 {
                return formula(base: 22, weight: weight, anchor: 1000, factor: 0.030)
            }
            return formula(base: 35, weight: weight, anchor: 1000, factor: 0.035)
        }
    }

    private static func formula(base: Int, weight: Int, anchor: Int, factor: Double) -> Int {
        let result = Double(base) + Double(weight - anchor) * factor
        return max(1, Int(result.rounded()))
    }
}

struct DefrostTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettingsKey.weightUnit) private var weightUnitRaw = AppSettingsDefault.weightUnit
    @AppStorage(AppSettingsKey.notifyTimerFinished) private var notifyTimerFinished = AppSettingsDefault.notifyTimerFinished

    let product: StoredProduct

    @State private var method: DefrostMethod = .fridge
    @State private var totalSeconds: Int = 12 * 60
    @State private var secondsRemaining: Int = 12 * 60
    @State private var isRunning = false
    @State private var runUntil: Date?
    @State private var showReadyAlert = false
    @State private var isRestoringTimerState = false
    @State private var showCustomTimeSheet = false
    @State private var customMinutesInput = ""

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timerNotificationID: String {
        "defrost-ready-\(product.id.uuidString)"
    }

    private var weightUnit: AppWeightUnit {
        AppWeightUnit(rawValue: weightUnitRaw) ?? .grams
    }

    var body: some View {
        let item = product.asInventoryItem(unit: weightUnit)

        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    icon(item: item)

                    Text(item.name)
                        .font(.sfProDisplaySemibold(24))
                        .foregroundStyle(AppColors.black)

                    Text(item.weightText)
                        .font(.sfProDisplaySemibold(17))
                        .foregroundStyle(AppColors.textGray)

                    if !trimmedNote.isEmpty {
                        Text("Note:")
                            .font(.sfProDisplaySemibold(17))
                            .foregroundStyle(AppColors.black)

                        Text(trimmedNote)
                            .font(.sfProDisplayRegular(17))
                            .foregroundStyle(AppColors.textGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Text("SELECT METHOD")
                        .font(.sfProDisplaySemibold(18))
                        .foregroundStyle(AppColors.black)

                    methodControl
                    timerRing

                    if isRunning {
                        runningControls
                    } else {
                        stoppedControls
                    }

                    startButton
                    finishButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showCustomTimeSheet) {
            NavigationStack {
                DefrostMinutesSheet(
                    text: $customMinutesInput,
                    onApply: {
                        applyCustomMinutesInput()
                    }
                )
                .toolbar(.hidden, for: .navigationBar)
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            restoreTimerState()
            refreshRemainingTime(forceFromPersisted: true)
            if notifyTimerFinished {
                requestNotificationPermission()
            }
        }
        .onChange(of: method) { _, _ in
            guard !isRunning, !isRestoringTimerState else { return }
            applyRecommendedDuration(resetRemaining: true)
            persistTimerState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                refreshRemainingTime(forceFromPersisted: true)
            case .inactive, .background:
                if isRunning {
                    refreshRemainingTime(forceFromPersisted: true)
                    persistTimerState()
                }
            @unknown default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refreshRemainingTime(forceFromPersisted: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if isRunning {
                refreshRemainingTime(forceFromPersisted: true)
                persistTimerState()
            }
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            refreshRemainingTime()
        }
        .onDisappear {
            if isRunning {
                refreshRemainingTime(forceFromPersisted: true)
                persistTimerState()
            } else {
                cancelCompletionNotification()
            }
        }
        .alert("Time to cook!", isPresented: $showReadyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your \(product.name) has finished defrosting")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        ZStack {
            Text("Arctic curator")
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.black)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.textGray)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.progressTrack.opacity(0.7))
                .frame(height: 1)
        }
    }

    private func icon(item: InventoryItem) -> some View {
        Text(item.category.emoji ?? "❄️")
            .font(.system(size: 40))
            .frame(width: 96, height: 96)
            .background(
                Circle()
                    .stroke(AppColors.blue0088FF, lineWidth: 2)
                    .background(Circle().fill(AppColors.lightBlue.opacity(0.35)))
            )
    }

    private var methodControl: some View {
        HStack(spacing: 0) {
            ForEach(DefrostMethod.allCases) { value in
                Button {
                    method = value
                } label: {
                    Text(value.rawValue)
                        .font(method == value ? .sfProDisplaySemibold(14) : .sfProDisplayMedium(14))
                        .foregroundStyle(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(method == value ? AppColors.white : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(AppColors.progressTrack.opacity(0.55)))
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.progressTrack.opacity(0.65), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppColors.blueButtonGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .animation(.linear(duration: 0.95), value: secondsRemaining)

            VStack(spacing: 6) {
                Text("TIME REMAINING")
                    .font(.sfProDisplaySemibold(timerCaptionFontSize))
                    .foregroundStyle(AppColors.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(timeString)
                    .font(.sfProDisplayBold(timerValueFontSize))
                    .foregroundStyle(AppColors.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
                    .monospacedDigit()

                Text("ends at \(endTimeString)")
                    .font(.sfProDisplaySemibold(timerCaptionFontSize))
                    .foregroundStyle(AppColors.textGray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: timerRingDiameter - 46)
        }
        .frame(width: timerRingDiameter, height: timerRingDiameter)
    }

    private var stoppedControls: some View {
        HStack(spacing: 10) {
            Button {
                totalSeconds = max(60, totalSeconds - 60)
                secondsRemaining = totalSeconds
                persistTimerState()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppColors.progressTrack.opacity(0.55)))
            }
            .buttonStyle(.plain)

            Button {
                openCustomTimeEditor()
            } label: {
                Text(timeString)
                    .font(.sfProMedium(24))
                    .foregroundStyle(AppColors.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.progressTrack.opacity(0.5))
                    )
            }
            .buttonStyle(.plain)

            Button {
                totalSeconds += 60
                secondsRemaining = totalSeconds
                persistTimerState()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppColors.progressTrack.opacity(0.55)))
            }
            .buttonStyle(.plain)
        }
    }

    private var runningControls: some View {
        HStack(spacing: 10) {
            Button {
                pauseTimer()
            } label: {
                Text("⏸ Pause")
                    .font(.sfProMedium(17))
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.blueButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                resetTimerToRecommended()
            } label: {
                Text("↻ Reset")
                    .font(.sfProMedium(17))
                    .foregroundStyle(AppColors.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.timerButtonBackground)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var startButton: some View {
        Button {
            startTimer()
        } label: {
            Text("▶ Start")
                .font(.sfProMedium(17))
                .foregroundStyle(AppColors.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.greenButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(isRunning ? 0.6 : 1)
        .disabled(isRunning)
    }

    private var finishButton: some View {
        Button {
            product.status = .done
            product.defrostedAt = .now
            clearPersistedTimerState()
            try? modelContext.save()
            runUntil = nil
            isRunning = false
            cancelCompletionNotification()
            dismiss()
        } label: {
            Text("FINISH DEFROSTING")
                .font(.sfProMedium(17))
                .foregroundStyle(AppColors.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.blueButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func startTimer() {
        guard !isRunning, secondsRemaining > 0 else { return }

        isRunning = true
        runUntil = Date().addingTimeInterval(TimeInterval(secondsRemaining))

        if product.status != .done {
            product.status = .defrost
        }

        persistTimerState()
        scheduleCompletionNotification(after: secondsRemaining)
    }

    private func pauseTimer() {
        refreshRemainingTime()
        isRunning = false
        runUntil = nil
        cancelCompletionNotification()
        persistTimerState()
    }

    private func refreshRemainingTime(forceFromPersisted: Bool = false) {
        if forceFromPersisted, runUntil == nil, let persistedRunUntil = product.defrostRunUntil {
            runUntil = persistedRunUntil
            if persistedRunUntil > .now {
                isRunning = true
            }
        }

        guard isRunning, let runUntil else { return }

        let remaining = max(0, Int(ceil(runUntil.timeIntervalSinceNow)))
        secondsRemaining = remaining

        guard remaining == 0 else { return }

        completeDefrost()
    }

    private func applyRecommendedDuration(resetRemaining: Bool) {
        let minutes = DefrostDurationPolicy.minutes(method: method, weightGrams: product.weightGrams)
        let seconds = max(60, minutes * 60)
        totalSeconds = seconds
        if resetRemaining {
            secondsRemaining = seconds
        }
    }

    private func restoreTimerState() {
        isRestoringTimerState = true
        defer { isRestoringTimerState = false }

        if let storedMethodRaw = product.defrostMethodRaw,
           let storedMethod = DefrostMethod(rawValue: storedMethodRaw) {
            method = storedMethod
        }

        let recommendedSeconds = max(60, DefrostDurationPolicy.minutes(method: method, weightGrams: product.weightGrams) * 60)
        totalSeconds = max(60, product.defrostTotalSeconds ?? recommendedSeconds)

        if let persistedRunUntil = product.defrostRunUntil {
            let remaining = max(0, Int(ceil(persistedRunUntil.timeIntervalSinceNow)))
            if remaining > 0 {
                isRunning = true
                runUntil = persistedRunUntil
                secondsRemaining = remaining
                if product.defrostIsRunning != true {
                    product.defrostIsRunning = true
                    try? modelContext.save()
                }
                return
            }

            completeDefrost()
            return
        }

        if product.defrostIsRunning == true {
            if let persistedRemaining = product.defrostRemainingSeconds, persistedRemaining > 0 {
                isRunning = true
                secondsRemaining = min(persistedRemaining, totalSeconds)
                runUntil = Date().addingTimeInterval(TimeInterval(secondsRemaining))
                persistTimerState()
                return
            }
        }

        isRunning = false
        runUntil = nil
        if let persistedRemaining = product.defrostRemainingSeconds, persistedRemaining > 0 {
            secondsRemaining = min(persistedRemaining, totalSeconds)
        } else {
            secondsRemaining = totalSeconds
        }
    }

    private func persistTimerState() {
        product.defrostMethodRaw = method.rawValue
        product.defrostTotalSeconds = totalSeconds
        product.defrostRemainingSeconds = secondsRemaining
        product.defrostRunUntil = runUntil
        product.defrostIsRunning = isRunning
        try? modelContext.save()
    }

    private func clearPersistedTimerState() {
        product.defrostMethodRaw = nil
        product.defrostTotalSeconds = nil
        product.defrostRemainingSeconds = nil
        product.defrostRunUntil = nil
        product.defrostIsRunning = false
    }

    private func resetTimerToRecommended() {
        isRunning = false
        runUntil = nil
        applyRecommendedDuration(resetRemaining: true)
        cancelCompletionNotification()
        persistTimerState()
    }

    private func completeDefrost() {
        isRunning = false
        runUntil = nil
        secondsRemaining = 0

        if product.status != .done {
            product.status = .done
        }
        if product.defrostedAt == nil {
            product.defrostedAt = .now
        }

        clearPersistedTimerState()
        cancelCompletionNotification()
        try? modelContext.save()
        showReadyAlert = true
    }

    private func openCustomTimeEditor() {
        guard !isRunning else { return }
        let currentMinutes = max(1, Int(ceil(Double(secondsRemaining) / 60.0)))
        customMinutesInput = "\(currentMinutes)"
        showCustomTimeSheet = true
    }

    private func applyCustomMinutesInput() {
        let digits = customMinutesInput.filter(\.isNumber)
        guard let minutes = Int(digits), minutes > 0 else { return }

        let newSeconds = max(60, minutes * 60)
        totalSeconds = newSeconds
        secondsRemaining = newSeconds
        runUntil = nil
        isRunning = false
        cancelCompletionNotification()
        persistTimerState()
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        let ratio = CGFloat(secondsRemaining) / CGFloat(totalSeconds)
        return min(1, max(0, ratio))
    }

    private var timerRingDiameter: CGFloat {
        min(UIScreen.main.bounds.width - 60, 260)
    }

    private var timerCaptionFontSize: CGFloat {
        max(12, min(14, timerRingDiameter * 0.055))
    }

    private var timerValueFontSize: CGFloat {
        let base = max(36, min(52, timerRingDiameter * 0.20))
        switch timeString.count {
        case ...5:
            return base
        case 6...8:
            return max(32, base - 8)
        default:
            return max(28, base - 14)
        }
    }

    private var trimmedNote: String {
        product.note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var timeString: String {
        if secondsRemaining >= 3600 {
            let hours = secondsRemaining / 3600
            let minutes = (secondsRemaining % 3600) / 60
            let seconds = secondsRemaining % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var endTimeString: String {
        let targetDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: targetDate).lowercased()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleCompletionNotification(after seconds: Int) {
        guard notifyTimerFinished, seconds > 0 else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [timerNotificationID])

        let content = UNMutableNotificationContent()
        content.title = "Time to cook!"
        content.body = "Your \(product.name) has finished defrosting"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: timerNotificationID, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationID])
    }
}

private struct DefrostMinutesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let onApply: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Set time (minutes)")
                .font(.sfProDisplaySemibold(17))
                .foregroundStyle(AppColors.black)

            TextField("Minutes", text: $text)
                .font(.sfProDisplayRegular(17))
                .keyboardType(.numberPad)
                .focused($isFocused)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.progressTrack.opacity(0.35))
                )

            Button {
                onApply()
                dismiss()
            } label: {
                Text("Apply")
                    .font(.sfProDisplaySemibold(17))
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.blueButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
                .font(.sfProDisplaySemibold(17))
                .tint(AppColors.blue0088FF)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
