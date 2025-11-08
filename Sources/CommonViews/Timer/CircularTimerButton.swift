//
//  CircularTimerButton.swift
//  Common
//
//  Created by Eric Liu on 10/29/25.
//

import SwiftUI


private enum CircularTimerButtonStatus {
    case notStarted
    case inProgress
    case isPaused
    case isResumed
    case isCompleted
}

/// A customizable button with a circular progress indicator and timer display.
///
/// This button displays a play icon initially. When tapped, it starts a timer that counts up
/// and shows circular progress based on elapsed time vs total duration. The play icon is
/// replaced with the elapsed time display.
///
/// Example usage:
/// ```swift
/// @State private var timerSession = TimerSession(duration: 60)
///
/// CircularTimerButton(
///     timerSession: $timerSession,
///     onStart: {
///         timerSession.start()
///     },
///     onCompletionState: {
///         print("Timer completed after \(timerSession.elapsedTime) seconds!")
///     }
/// )
/// .frame(width: 100, height: 100)
/// ```
public struct CircularTimerButton: View {
    @State private var progressValue: Double = 1.0
    @State private var task: Task<Void, Never>?

    @Binding private var timerSession: TimerSession
    @State private var status: CircularTimerButtonStatus = .notStarted

    private let strokeWidth: CGFloat
    private let progressColor: Color
    private let completeColor: Color
    private let onStart: (() -> Void)?
    private let onPause: (() -> Void)?
    private let onResume: (() -> Void)?
    private let onCompletionState: (() -> Void)?
    private let onTimeLapse: ((TimeInterval) -> Void)?
    private let onTimerCompletion: (() -> Void)?
    private let updateInterval: Duration

    /// Creates a circular timer button.
    ///
    /// - Parameters:
    ///   - timerSession: A binding to the timer session to track elapsed time
    ///   - updateInterval: How frequently the timer updates progress
    ///   - strokeWidth: The width of the progress ring
    ///   - progressColor: The color of the progress ring while running
    ///   - completeColor: The color when the timer completes
    ///   - onStart: Optional callback when timer starts
    ///   - onPause: Optional callback when timer is paused
    ///   - onResume: Optional callback when timer resumes
    ///   - onCompletionState: Callback triggered when the timer finishes
    ///   - onTimerCompletion: Callback fired when the timer reaches the duration boundary
    ///   - onTimeLapse: Callback invoked with elapsed seconds on each tick
    public init(
        timerSession: Binding<TimerSession>,
        updateInterval: Duration = .seconds(0.25),
        strokeWidth: CGFloat = 4,
        progressColor: Color = .accentColor,
        completeColor: Color = .green,
        onStart: (() -> Void)? = nil,
        onPause: (() -> Void)? = nil,
        onResume: (() -> Void)? = nil,
        onCompletionState: (() -> Void)? = nil,
        onTimerCompletion: (() -> Void)? = nil,
        onTimeLapse: ((TimeInterval) -> Void)? = nil,
    ) {
        self._timerSession = timerSession
        self.updateInterval = updateInterval
        self.strokeWidth = strokeWidth
        self.progressColor = progressColor
        self.completeColor = completeColor
        self.onCompletionState = onCompletionState
        self.onTimeLapse = onTimeLapse
        self.onTimerCompletion = onTimerCompletion
        self.onStart = onStart
        self.onPause = onPause
        self.onResume = onResume
    }
    
    private var isCompleted: Bool {
        status == .isCompleted
    }
    
    private var isRunning: Bool {
        status == .inProgress || status == .isResumed
    }

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
                .stroke(isCompleted ? completeColor.opacity(0.2) : progressColor.opacity(0.2), lineWidth: strokeWidth)
                .frame(
                    width: size - strokeWidth,
                    height: size - strokeWidth
                )
                .glassEffect()

            // Progress ring
            Circle()
                .trim(
                    from: 0,
                    to: isCompleted ? 0 : progressValue
                )
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
        }
    }

    private func buttonContent(size: CGFloat) -> some View {
        Group {
            if isCompleted {
                // Completed state
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(completeColor)
            } else if isRunning {
                // Running state - show timer
                ZStack(alignment: .top) {
                    Text(formatTime(timerSession.timeRemaining))
                        .font(
                            .system(
                                size: size * 0.25,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )
                        .foregroundColor(progressColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Image(systemName: "pause.fill")
                        .font(.system(size: size * 0.18, weight: .semibold))
                        .foregroundColor(progressColor)
                        .padding(size * 0.06)
                }
            } else {
                // Initial state - show play button
                Image(systemName: "play.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(progressColor)
            }
        }
        .frame(width: size * 0.9, height: size * 0.9)
    }

    private func buttonView(size: CGFloat) -> some View {
        ZStack {
            progressRing(size: size)
            buttonContent(size: size)
        }
        .onChange(of: status) {_, newStatus in
            // Don't change TimerSession status.
            switch newStatus {
            case .notStarted:
                resetTimer()
            case .inProgress:
                startTimer()
            case .isPaused:
                pauseTimer()
            case .isResumed:
                resumeTimer()
            case .isCompleted:
                completeTimer()
            default:
                return
            }
        }
        .onChange(of: timerSession.status, initial: true) {_, newStatus in
            switch newStatus {
            case .notStarted:
                status = .notStarted
            case .inProgress:
                status = .inProgress
            case .isPaused:
                status = .isPaused
            case .isResumed:
                status = .isResumed
            case .isCompleted:
                status = .isCompleted
            }
        }
        .onAppear{
            if status == .isResumed || status == .inProgress {
                resumeTimer()
            }
        }
        .onDisappear {
            // Cancel Tasks
            task?.cancel()
            task = nil
        }
    }

    // MARK: - Timer Control

    private func startTimer() {
        onStart?()
        guard timerSession.duration > 0 else {
            status = .isCompleted
            onTimerCompletion?()
            return
        }
    
        
        resumeTimer()
    }
    
    private func resumeTimer(){
        onResume?()
        task?.cancel()
        task = Task {
            while !Task.isCancelled {
                guard !Task.isCancelled else { break }
                let remainingTime = timerSession.timeRemaining
                let totalDuration = timerSession.duration
                
                // Check if completed
                if remainingTime <= 0 {
                    await MainActor.run {
                        status = .isCompleted
                        onTimerCompletion?()
                    }
                    break
                }
                
                await MainActor.run {
                    postProgressValue(remainingTime, totalDuration)
                }
                try? await Task.sleep(for: updateInterval)
            }
        }
    }

    private func postProgressValue(
        _ remainingSeconds: TimeInterval,
        _ totalDuration: Double
    ) {
        if totalDuration <= 0 {
            self.progressValue = 1.0
        } else {
            self.progressValue = min(
                remainingSeconds / totalDuration,
                1.0
            )
        }
        self.onTimeLapse?(remainingSeconds)
    }
    
    private func pauseTimer() {
        onPause?()
        task?.cancel()
        task = nil
        
        let remainingSeconds = timerSession.timeRemaining
        let totalDuration = timerSession.duration
        postProgressValue(remainingSeconds, totalDuration)
    }

    private func resetTimer() {
        task?.cancel()
        task = nil
        withAnimation(.none) {
            progressValue = 1
        }
    }

    private func completeTimer() {
        onCompletionState?()
        progressValue = 0
        task?.cancel()
        task = nil
    }

    private func handleTap() {
        switch status {
        case .notStarted:
            if timerSession.duration <= .zero {
                timerSession.complete()
            } else {
                timerSession.start()
            }
        case .inProgress, .isResumed:
            timerSession.pause()
        case .isPaused:
            timerSession.resume()
        case .isCompleted:
            timerSession.complete()
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
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            progressValue >= 1 ? "Completed" :
                isRunning ? "Timer running" : "Start timer"
        )
        .accessibilityValue(
            progressValue >= 1 ? "Done" :
                isRunning ? formatTime(timerSession.timeRemaining) : ""
        )
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
struct CircularTimerButtonPreviewHost: View {
    @State private var message = ""
    @State private var status1: CircularTimerButtonStatus = .notStarted
    @State private var status2: CircularTimerButtonStatus = .notStarted
    @State private var status3: CircularTimerButtonStatus = .notStarted
    @State private var timerSession1 = TimerSession(duration: 30)
    @State private var timerSession2 = TimerSession(duration: 0)
    @State private var timerSession3 = TimerSession(duration: 10)

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                HStack {

                    Text("Timer Buttons")
                        .font(.title)

                    Button("Reset All") {
                        status1 = .notStarted
                        status2 = .notStarted
                        status3 = .notStarted
                        timerSession1.reset()
                        timerSession2.reset()
                        timerSession3.reset()
                        message = ""
                    }.buttonStyle(.borderedProminent)
                }

                VStack(spacing: 10) {
                    Text("30 Second Timer")
                        .font(.headline)
                    CircularTimerButton(
                        timerSession: $timerSession1,
                        updateInterval: .seconds(0.1),
                        onStart: {
                            message = "Timer started..."
                            timerSession1.start()
                        },
                        onPause: {
                            message = "Timer paused"
                            timerSession1.pause()
                        },
                        onResume: {
                            timerSession1.resume()
                        },
                        onCompletionState: {
                            message = "30 second timer completed!"
                            timerSession1.complete()
                        }
                    )
                    .frame(width: 150, height: 150)
                    Text(
                        "Elapsed: \(String(format: "%.1f", timerSession1.elapsedTime))s"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    Text("0 Second Timer")
                        .font(.headline)
                    CircularTimerButton(
                        timerSession: $timerSession2,
                        strokeWidth: 6,
                        progressColor: .blue,
                        onStart: {
                            timerSession2.start()
                        },
                        onPause: {
                            timerSession2.pause()
                        },
                        onResume: {
                            timerSession2.resume()
                        },
                        onCompletionState: {
                            message = "0 second timer completed!"
                            timerSession2.complete()
                        }
                    )
                    .frame(width: 120, height: 120)
                }

                VStack(spacing: 10) {
                    Text("Custom Style (10s)")
                        .font(.headline)
                    CircularTimerButton(
                        timerSession: $timerSession3,
                        updateInterval: .seconds(0.1),
                        strokeWidth: 8,
                        progressColor: .purple,
                        completeColor: .orange,
                        onStart: {
                            timerSession3.start()
                        },
                        onPause: {
                            timerSession3.pause()
                        },
                        onResume: {
                            timerSession3.resume()
                        },
                        onCompletionState: {
                            message = "10 second timer completed!"
                            timerSession3.complete()
                        }
                    )
                    .frame(width: 100, height: 100)
                    Text(
                        "Elapsed: \(String(format: "%.1f", timerSession3.elapsedTime))s"
                    )
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
