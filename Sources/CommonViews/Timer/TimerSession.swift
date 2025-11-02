//
//  File.swift
//  Common
//
//  Created by Eric Liu on 11/1/25.
//

import Foundation
import SwiftUI

private extension BinaryInteger {
    var double: Double { Double(self) }
}
private extension BinaryFloatingPoint {
    var double: Double { Double(self) }
}

public enum TimerStatus {
    case notStarted
    case inProgress
    case isPaused
    case isResumed
    case isCompleted
}

@Observable
public class TimerSession {
    public let id: UUID
    /// total duration in seconds (TimeInterval) - remains TimeInterval for compatibility
    public var duration: TimeInterval    // total seconds
    public var startTime: ContinuousClock.Instant?         // when it started (nil if not started)
    public var status: TimerStatus
    private var pausedAt: ContinuousClock.Instant?         // when it was paused
    private var pausedDuration: Duration = .zero

    // Calculated field: current time - startTime (frozen when paused)
    public var elapsedTime: TimeInterval {
        guard let startTime = startTime else {
            return 0
        }

        let dur: Duration = ContinuousClock.now - startTime - pausedDuration
        // Convert Duration to seconds as Double
        return dur.components.seconds.double + dur.components.attoseconds.double / 1e18
    }

    public init(
        id: UUID = UUID(),
        duration: TimeInterval,
        startTime: ContinuousClock.Instant? = nil,
        status: TimerStatus = .notStarted
    ) {
        self.id = id
        self.duration = duration
        self.startTime = startTime
        self.status = status
    }

    // MARK: - Utility Functions

    /// Starts the timer from the beginning
    public func start() {
        startTime = ContinuousClock.now
        status = .inProgress
    }

    /// Pauses the timer, preserving elapsed time
    public func pause() {
        guard status == .inProgress || status == .isResumed else { return }
        pausedAt = ContinuousClock.now
        status = .isPaused
    }

    /// Resumes the timer from where it was paused
    public func resume() {
        guard status == .isPaused, let pausedAt = pausedAt else { return }

        // Adjust startTime to account for the paused duration
        let delta: Duration = ContinuousClock.now - pausedAt
        pausedDuration += delta

        self.pausedAt = nil
        status = .isResumed
    }

    /// Resets the timer to its initial state
    public func reset() {
        startTime = nil
        pausedAt = nil
        pausedDuration = .zero
        status = .notStarted
    }

    /// Completes the timer
    public func complete() {
        startTime = nil
        pausedAt = nil
        pausedDuration = .zero
        status = .isCompleted
    }
}
