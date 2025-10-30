//
//  CircularProgressButton.swift
//  Common
//
//  Created by Eric Liu on 9/25/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A customizable button with a circular progress indicator activated by long press.
///
/// This button displays a circular progress ring that fills during a long press gesture.
/// When the press duration is completed, the `onCompletion` callback is triggered.
///
/// Example usage:
/// ```swift
/// CircularProgressButton(
///     duration: .seconds(2),
///     onCompletion: {
///         print("Action completed!")
///     }
/// ) { isCompleted in
///     Image(systemName: isCompleted ? "checkmark" : "hand.tap")
/// }
/// .frame(width: 100, height: 100)
/// ```
public struct CircularProgressButton<Content: View>: View {
    @State private var progressValue: Double = 0.0
    @State private var isPressed: Bool = false
    @State private var task: Task<Void, Never>?
    @Binding private var isCompleted: Bool

    private let onCompletion: () -> Void
    private let onPressStart: (() -> Void)?
    private let onPressCancel: (() -> Void)?
    private let duration: Duration
    private let strokeWidth: CGFloat
    private let progressColor: Color
    private let completeColor: Color
    private let backgroundColor: Color
    private let content: (_ isCompleted: Bool) -> Content
    private let enableHaptics: Bool
    private let updateInterval: Duration = .milliseconds(8) // ~60 FPS updates

    /// Creates a circular progress button.
    ///
    /// - Parameters:
    ///   - isCompleted: A binding that sets the completion state
    ///   - duration: The duration required to complete the long press
    ///   - strokeWidth: The width of the progress ring
    ///   - progressColor: The color of the progress ring while pressing
    ///   - completeColor: The color when the action is completed
    ///   - backgroundColor: The background color of the button
    ///   - enableHaptics: Whether to enable haptic feedback (default: true)
    ///   - onCompletion: Callback triggered when long press completes
    ///   - onPressStart: Optional callback when press begins
    ///   - onPressCancel: Optional callback when press is cancelled
    ///   - content: The view builder for button content, receives completion state
    public init(
        isCompleted: Binding<Bool> = .constant(false),
        duration: Duration = .seconds(3),
        strokeWidth: CGFloat = 4,
        progressColor: Color = .accentColor,
        completeColor: Color  = .green,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        enableHaptics: Bool = true,
        onCompletion: @escaping () -> Void,
        onPressStart: (() -> Void)? = nil,
        onPressCancel: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (_ isCompleted: Bool) -> Content
    ) {
        self.onCompletion = onCompletion
        self.onPressStart = onPressStart
        self.onPressCancel = onPressCancel
        self.duration = duration
        self.strokeWidth = strokeWidth
        self.progressColor = progressColor
        self.completeColor = completeColor
        self.backgroundColor = backgroundColor
        self.content = content
        self._isCompleted = isCompleted
        self.enableHaptics = enableHaptics
    }

    // MARK: - Haptic Feedback

#if canImport(UIKit)
    private func triggerHaptic(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle
    ) {
        guard enableHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func triggerNotificationHaptic(
        _ type: UINotificationFeedbackGenerator.FeedbackType
    ) {
        guard enableHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
#else
    private func triggerHaptic(_ style: Any) {}
    private func triggerNotificationHaptic(_ type: Any) {}
#endif

    // MARK: - Subviews

    private func progressRing(size: CGFloat) -> some View {
        ZStack {
            // Base circle
            Circle()
                .fill(backgroundColor)
                .background(.regularMaterial, in: Circle())

            // Progress ring background
            Circle()
                .stroke(progressColor.opacity(0.2), lineWidth: strokeWidth)
                .frame(
                    width: size - strokeWidth,
                    height: size - strokeWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: isCompleted ? 1 : progressValue)
                .stroke(
                    isCompleted ? completeColor : progressColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // Start from top
                .frame(
                    width: size - strokeWidth,
                    height: size - strokeWidth
                )
                .animation(.linear(duration: 0.16), value: progressValue)
                .animation(.easeInOut(duration: 0.4), value: isCompleted)
        }
    }

    private func buttonContent(size: CGFloat) -> some View {
        Group {
            if isCompleted {
                content(true)
            } else {
                content(false)
            }
        }
        .frame(width: size * 0.9, height: size * 0.9)
        .foregroundColor(
            isCompleted ? completeColor : progressColor
        )
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private func buttonView(size: CGFloat) -> some View {
        ZStack {
            progressRing(size: size)
            buttonContent(size: size)
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(
            .spring(response: 0.2, dampingFraction: 0.7),
            value: isPressed
        )
    }

    private func handleCompletion() {
#if canImport(UIKit)
        triggerNotificationHaptic(.success)
#endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCompleted = true
        }
        onCompletion()
    }

    private func handlePress(pressing: Bool) {
        isPressed = pressing
        task?.cancel()

        if pressing && !isCompleted {
            // Press started
#if canImport(UIKit)
            triggerHaptic(.light)
#endif
            onPressStart?()

            task = Task {
                let startTime = ContinuousClock.now
                let totalDuration = duration.asSeconds

                while !Task.isCancelled {
                    try? await Task.sleep(for: updateInterval)

                    // Calculate elapsed time since press started
                    let elapsed = ContinuousClock.now - startTime
                    let elapsedSeconds = Double(elapsed.components.seconds) +
                        Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000

                    // Calculate progress directly from elapsed time (no accumulation errors)
                    let calculatedProgress = min(elapsedSeconds / totalDuration, 1.0)

                    await MainActor.run {
                        self.progressValue = calculatedProgress
                    }

                    // Exit when complete
                    if calculatedProgress >= 1.0 {
                        break
                    }
                }

                await MainActor.run {
                    // Reset progress value
                    self.progressValue = 0
                }
            }
        } else if !pressing && !isCompleted && progressValue > 0 {
            // Press cancelled
#if canImport(UIKit)
            triggerHaptic(.rigid)
#endif
            onPressCancel?()
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            buttonView(size: size)
            .onChange(of: isCompleted) { _, newValue in
                task?.cancel()
                withAnimation {
                    if newValue {
                        progressValue = 1
                    } else {
                        progressValue = 0
                    }
                    isPressed = false
                }
            }
            .onLongPressGesture(
                minimumDuration: duration.asSeconds,
                maximumDistance: 50
            ) {
                handleCompletion()
            } onPressingChanged: { pressing in
                handlePress(pressing: pressing)
            }
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isCompleted ? "Completed" : "Action button")
        .accessibilityHint(isCompleted ? "" : "Press and hold to complete")
        .accessibilityValue(
            isCompleted ? "Done" : "\(Int(progressValue * 100))%"
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // Accessibility action for users who can't long press
            guard !isCompleted else { return }
            handleCompletion()
        }
    }
}

private extension Duration {
    var asSeconds: Double {
        let comps = self.components
        return Double(comps.seconds) + Double(
            comps.attoseconds
        ) / 1_000_000_000_000_000_000
    }
}


#if DEBUG
struct CircularProgressButtonPreviewHost: View {
    @State private var message = ""
    @State var isCompletedBasic = false
    @State var isCompletedIcons = false
    @State var isCompletedCustomStyle = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic example
                Text("Basic")
                    .font(.title2)
                CircularProgressButton(
                    isCompleted: $isCompletedBasic,
                    duration: .seconds(1.5),
                    onCompletion: {
                        message = "Basic completed!"
                    }
                ) { isCompleted in
                    if isCompleted {
                        Button(action: {
                            isCompletedBasic = false
                            message = ""
                        }) {
                            Text("Done")
                        }
                    } else {
                        Text("Hold to\nComplete!")
                            .fontWeight(.bold)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 200, height: 200)

                Text("Icons")
                    .font(.title3)
                CircularProgressButton(
                    isCompleted: $isCompletedIcons,
                    duration: .seconds(2),
                    strokeWidth: 12,
                    progressColor: .blue,
                    enableHaptics: true,
                    onCompletion: {
                        message = "Haptics completed!"
                    },
                    onPressStart: {
                        message = "Press started..."
                    },
                    onPressCancel: {
                        message = "Press cancelled"
                    }
                ) { isCompleted in
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.title)
                    } else {
                        Image(systemName: "hand.tap")
                            .font(.title)
                    }
                }
                .frame(width: 150, height: 150)

                // Custom styling
                Text("Custom Style")
                    .font(.title3)
                CircularProgressButton(
                    isCompleted: $isCompletedCustomStyle,
                    duration: .seconds(1),
                    strokeWidth: 8,
                    progressColor: .purple,
                    completeColor: .orange,
                    backgroundColor: .white,
                    onCompletion: {
                        message = "Custom style completed!"
                    }
                ) { isCompleted in
                    if isCompleted {
                        VStack {
                            Image(systemName: "star.fill" )
                            Text("Done!")
                                .font(.caption)
                        }
                    } else {
                        VStack {
                            Image(systemName:  "star")
                            Text("Hold")
                                .font(.caption)
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            .padding(50)
        }
    }
}

#Preview {
    CircularProgressButtonPreviewHost()
}
#endif



