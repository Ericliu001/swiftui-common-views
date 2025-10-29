//
//  CircularTimerButton.swift
//  Common
//
//  Created by Eric Liu on 10/29/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A customizable button with a circular progress indicator and timer display.
///
/// This button displays a play icon initially. When tapped, it starts a timer that counts up
/// and shows circular progress based on elapsed time vs total duration. The play icon is
/// replaced with the elapsed time display.
///
/// Example usage:
/// ```swift
/// @State private var elapsed: TimeInterval = 0
///
/// CircularTimerButton(
///     currentElapsed: $elapsed,
///     duration: .seconds(60),
///     onCompletion: {
///         print("Timer completed after \(elapsed) seconds!")
///     }
/// )
/// .frame(width: 100, height: 100)
/// ```
public struct CircularTimerButton: View {
    @State private var progressValue: Double = 0.0
    @Binding private var elapsedTime: TimeInterval
    @State private var isRunning: Bool = false
    @State private var task: Task<Void, Never>?
    @State private var isPressed: Bool = false

    private let duration: Duration
    private let strokeWidth: CGFloat
    private let progressColor: Color
    private let completeColor: Color
    private let enableHaptics: Bool
    private let onCompletion: () -> Void
    private let onStart: (() -> Void)?
    private let onPause: (() -> Void)?
    private let updateInterval: Duration = .milliseconds(16) // ~60 FPS

    /// Creates a circular timer button.
    ///
    /// - Parameters:
    ///   - currentElapsed: A binding to track the current elapsed time in seconds
    ///   - duration: The total duration of the timer
    ///   - strokeWidth: The width of the progress ring
    ///   - progressColor: The color of the progress ring while running
    ///   - completeColor: The color when the timer completes
    ///   - enableHaptics: Whether to enable haptic feedback (default: true)
    ///   - onCompletion: Callback triggered when timer completes
    ///   - onStart: Optional callback when timer starts
    ///   - onPause: Optional callback when timer is paused
    public init(
        currentElapsed: Binding<TimeInterval> = .constant(0),
        duration: Duration = .seconds(60),
        strokeWidth: CGFloat = 4,
        progressColor: Color = .accentColor,
        completeColor: Color = .green,
        enableHaptics: Bool = true,
        onCompletion: @escaping () -> Void = {},
        onStart: (() -> Void)? = nil,
        onPause: (() -> Void)? = nil,
    ) {
        self._elapsedTime = currentElapsed
        self.duration = duration
        self.strokeWidth = strokeWidth
        self.progressColor = progressColor
        self.completeColor = completeColor
        self.enableHaptics = enableHaptics
        self.onCompletion = onCompletion
        self.onStart = onStart
        self.onPause = onPause
    }

    // MARK: - Haptic Feedback

#if canImport(UIKit)
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enableHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enableHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
#else
    private func triggerHaptic(_ style: Any) {}
    private func triggerNotificationHaptic(_ type: Any) {}
#endif

    // MARK: - Time Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Subviews

    private func progressRing(size: CGFloat) -> some View {
        ZStack {
            // Progress ring background
            Circle()
                .stroke(progressColor.opacity(0.2), lineWidth: strokeWidth)
                .frame(
                    width: size - strokeWidth,
                    height: size - strokeWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progressValue >= 1 ? 1 : progressValue)
                .stroke(
                    progressValue >= 1 ? completeColor : progressColor,
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
        }
    }

    private func buttonContent(size: CGFloat) -> some View {
        Group {
            if progressValue >= 1 {
                // Completed state
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundColor(completeColor)
            } else if isRunning {
                // Running state - show timer
                Text(formatTime(elapsedTime))
                    .font(.system(size: size * 0.25, weight: .semibold, design: .monospaced))
                    .foregroundColor(progressColor)
            } else {
                // Initial state - show play button
                Image(systemName: "play.fill")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundColor(progressColor)
            }
        }
        .frame(width: size * 0.9, height: size * 0.9)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private func buttonView(size: CGFloat) -> some View {
        ZStack {
            progressRing(size: size)
            buttonContent(size: size)
        }
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(
            .spring(response: 0.2, dampingFraction: 0.7),
            value: isPressed
        )
    }

    // MARK: - Timer Control

    private func startTimer() {
        guard !isRunning else { return }

#if canImport(UIKit)
        triggerHaptic(.light)
#endif

        isRunning = true
        onStart?()

        task = Task {
            let startTime = ContinuousClock.now
            let totalDuration = duration.asSeconds
            let resumeFromTime = elapsedTime

            while !Task.isCancelled {
                try? await Task.sleep(for: updateInterval)

                // Calculate elapsed time since timer started
                let elapsed = ContinuousClock.now - startTime
                let elapsedSeconds = Double(elapsed.components.seconds) +
                    Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000

                let currentElapsed = resumeFromTime + elapsedSeconds

                await MainActor.run {
                    self.elapsedTime = min(currentElapsed, totalDuration)
                    self.progressValue = min(currentElapsed / totalDuration, 1.0)
                }

                // Check if completed
                if currentElapsed >= totalDuration {
                    await MainActor.run {
                        handleCompletion()
                    }
                    break
                }
            }
        }
    }

    private func pauseTimer() {
        guard isRunning else { return }

#if canImport(UIKit)
        triggerHaptic(.rigid)
#endif

        isRunning = false
        task?.cancel()
        onPause?()
    }

    private func resetTimer() {
        task?.cancel()
        isRunning = false
        elapsedTime = 0
        progressValue = 0
    }

    private func handleCompletion() {
#if canImport(UIKit)
        triggerNotificationHaptic(.success)
#endif

        isRunning = false
        task?.cancel()
        onCompletion()
    }

    private func handleTap() {
        if progressValue >= 1 {
            // Reset if completed
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                resetTimer()
            }
        } else if isRunning {
            // Pause if running
            pauseTimer()
        } else {
            // Start if not running
            startTimer()
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            buttonView(size: size)
                .contentShape(Circle())
                .onTapGesture {
                    handleTap()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isPressed = true
                        }
                        .onEnded { _ in
                            isPressed = false
                        }
                )
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            progressValue >= 1 ? "Completed" :
            isRunning ? "Timer running" : "Start timer"
        )
        .accessibilityValue(
            progressValue >= 1 ? "Done" :
            isRunning ? formatTime(elapsedTime) : ""
        )
        .accessibilityAddTraits(.isButton)
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
struct CircularTimerButtonPreviewHost: View {
    @State private var message = ""
    @State private var elapsed1: TimeInterval = 0
    @State private var elapsed2: TimeInterval = 0
    @State private var elapsed3: TimeInterval = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Timer Buttons")
                    .font(.title)

                VStack(spacing: 10) {
                    Text("30 Second Timer")
                        .font(.headline)
                    CircularTimerButton(
                        currentElapsed: $elapsed1,
                        duration: .seconds(30),
                        onCompletion: {
                            message = "30 second timer completed!"
                        },
                        onStart: {
                            message = "Timer started..."
                        },
                        onPause: {
                            message = "Timer paused"
                        }
                    )
                    .frame(width: 150, height: 150)
                    Text("Elapsed: \(String(format: "%.1f", elapsed1))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    Text("1 Minute Timer")
                        .font(.headline)
                    CircularTimerButton(
                        currentElapsed: $elapsed2,
                        duration: .seconds(60),
                        strokeWidth: 6,
                        progressColor: .blue,
                        onCompletion: {
                            message = "1 minute timer completed!"
                        }
                    )
                    .frame(width: 120, height: 120)
                    Text("Elapsed: \(String(format: "%.1f", elapsed2))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    Text("Custom Style (10s)")
                        .font(.headline)
                    CircularTimerButton(
                        currentElapsed: $elapsed3,
                        duration: .seconds(10),
                        strokeWidth: 8,
                        progressColor: .purple,
                        completeColor: .orange,
                        onCompletion: {
                            message = "10 second timer completed!"
                        }
                    )
                    .frame(width: 100, height: 100)
                    Text("Elapsed: \(String(format: "%.1f", elapsed3))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(50)
        }
    }
}

#Preview {
    CircularTimerButtonPreviewHost()
}
#endif
