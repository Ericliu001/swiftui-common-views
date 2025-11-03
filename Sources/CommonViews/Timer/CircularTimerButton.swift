//
//  CircularTimerButton.swift
//  Common
//
//  Created by Eric Liu on 10/29/25.
//

import SwiftUI


public enum CircularTimerButtonStatus {
    case notStarted
    case isStarted
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
/// @State private var status: CircularTimerButtonStatus = .notStarted
///
/// CircularTimerButton(
///     timerSession: $timerSession,
///     status: $status,
///     duration: .seconds(60),
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
    @State private var progressValue: Double = 0.0
    @State private var task: Task<Void, Never>?

    @Binding private var timerSession: TimerSession
    @State private var status: CircularTimerButtonStatus = .notStarted

    private let duration: Duration
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
    ///   - isCompleted: A binding to track completion state
    ///   - duration: The total duration of the timer
    ///   - strokeWidth: The width of the progress ring
    ///   - progressColor: The color of the progress ring while running
    ///   - completeColor: The color when the timer completes
    ///   - onCompletion: Callback triggered when timer completes
    ///   - onStart: Optional callback when timer starts
    ///   - onPause: Optional callback when timer is paused
    public init(
        timerSession: Binding<TimerSession>,
        duration: Duration = .seconds(60),
        updateInterval: Duration = .seconds(1),
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
        self.duration = duration
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
        status == .isStarted || status == .isResumed
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
                Text(formatTime(timerSession.elapsedTime))
                    .font(
                        .system(
                            size: size * 0.25,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .foregroundColor(progressColor)
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
            switch newStatus {
            case .notStarted:
                // Don't change TimerSession status at the init state.
                resetTimer()
            case .isStarted:
                timerSession.start()
                startTimer()
            case .isPaused:
                timerSession.pause()
                pauseTimer()
            case .isResumed:
                timerSession.resume()
                resumeTimer()
            case .isCompleted:
                timerSession.complete()
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
                status = .isResumed
            case .isPaused:
                status = .isPaused
            case .isResumed:
                status = .isResumed
            case .isCompleted:
                status = .isCompleted
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
        guard duration.asSeconds > 0 else {
            status = .isCompleted
                onTimerCompletion?()
            return
        }
    
            onStart?()
        
        resumeTimer()
    }
    
    private func resumeTimer(){
        onResume?()
        task?.cancel()
        task = Task {
            let totalDuration = duration.asSeconds
            
            while !Task.isCancelled {
                guard !Task.isCancelled else { break }
                let elapsedSeconds = timerSession.elapsedTime
                
                // Check if completed
                if elapsedSeconds >= totalDuration {
                    await MainActor.run {
                        status = .isCompleted
                        onTimerCompletion?()
                    }
                    break
                }
                
                await MainActor.run {
                    postProgressValue(elapsedSeconds, totalDuration)
                }
                try? await Task.sleep(for: updateInterval)
            }
        }
    }

    private func postProgressValue(
        _ elapsedSeconds: TimeInterval,
        _ totalDuration: Double
    ) {
        self.progressValue = min(
            elapsedSeconds / totalDuration,
            1.0
        )
        self.onTimeLapse?(elapsedSeconds)
        print("Timelapse \(elapsedSeconds)")
    }
    
    private func pauseTimer() {
        onPause?()
        task?.cancel()
        task = nil
        
        let elapsedSeconds = timerSession.elapsedTime
        let totalDuration = duration.asSeconds
        postProgressValue(elapsedSeconds, totalDuration)
    }

    private func resetTimer() {
        task?.cancel()
        task = nil
        withAnimation(.none) {
            progressValue = 0
        }
    }

    private func completeTimer() {
        progressValue = 1
        task?.cancel()
        task = nil
        onCompletionState?()
    }

    private func handleTap() {
        switch status {
        case .notStarted:
            status = .isStarted
        case .isStarted:
            status = .isPaused
        case .isPaused:
            status = .isResumed
        case .isResumed:
            status = .isPaused
        case .isCompleted:
            print("completed")
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
                isRunning ? formatTime(timerSession.elapsedTime) : ""
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
                        duration: .seconds(30),
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
                        duration: .seconds(0),
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
                        duration: .seconds(10),
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
