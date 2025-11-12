//
//  File.swift
//  Common
//
//  Created by Eric Liu on 11/1/25.
//

import Foundation
import SwiftUI


public extension Duration {
    /// Converts this ``Duration`` instance into a ``TimeInterval`` (in seconds).
    ///
    /// A ``TimeInterval`` in Foundation represents a number of seconds as a `Double`,
    /// while ``Duration`` stores time as integer seconds and attoseconds (1 attosecond = 1e−18 seconds).
    ///
    /// This method correctly converts both components into a precise `Double` value.
    ///
    /// Example:
    /// ```swift
    /// let d = Duration.seconds(2) + .attoseconds(500_000_000_000_000_000)
    /// print(d.toTimeInterval()) // 2.5
    /// ```
    ///
    /// - Returns: A `TimeInterval` representing the same span of time as this `Duration`.
    func toTimeInterval() -> TimeInterval {
        let (seconds, attoseconds) = self.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
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
        
        let referenceTime: ContinuousClock.Instant
        if status == .isPaused, let pausedAt {
            referenceTime = pausedAt
        } else {
            referenceTime = ContinuousClock.now
        }

        let dur = referenceTime - startTime - pausedDuration
        return dur.toTimeInterval()
    }
    
    public var timeRemaining: TimeInterval {
        max(0, duration - elapsedTime)
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
        status = .isResumed
        
        guard let pausedAt = pausedAt else { return }
        

        // Adjust startTime to account for the paused duration
        let delta: Duration = ContinuousClock.now - pausedAt
        pausedDuration += delta

        self.pausedAt = nil
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
