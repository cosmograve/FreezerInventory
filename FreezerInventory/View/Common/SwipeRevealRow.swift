import SwiftUI

struct SwipeRevealRow<Content: View, Actions: View>: View {
    let id: UUID
    @Binding var openRowID: UUID?
    let revealWidth: CGFloat
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    init(
        id: UUID,
        openRowID: Binding<UUID?>,
        revealWidth: CGFloat,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.id = id
        _openRowID = openRowID
        self.revealWidth = revealWidth
        self.content = content
        self.actions = actions
    }

    var body: some View {
        let resolvedOffset = clamped(baseOffset + dragOffset)

        ZStack(alignment: .trailing) {
            actions()
                .frame(width: revealWidth, alignment: .trailing)

            content()
                .contentShape(Rectangle())
                .offset(x: resolvedOffset)
                .gesture(dragGesture)
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.24, dampingFraction: 0.9), value: baseOffset)
        .onChange(of: openRowID) { _, newValue in
            guard newValue != id, baseOffset != 0 else { return }
            baseOffset = 0
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    state = 0
                    return
                }
                state = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let closeThreshold = revealWidth * 0.24
                let translation = value.translation.width
                let predicted = value.predictedEndTranslation.width

                if baseOffset < 0 {
                    let shouldClose = translation > closeThreshold || predicted > closeThreshold
                    baseOffset = shouldClose ? 0 : -revealWidth
                    openRowID = shouldClose ? nil : id
                } else {
                    let shouldOpen = translation < -closeThreshold || predicted < -closeThreshold
                    baseOffset = shouldOpen ? -revealWidth : 0
                    openRowID = shouldOpen ? id : nil
                }
            }
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(0, max(-revealWidth, value))
    }
}
