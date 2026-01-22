//
//  TimerSession.swift
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

public enum TimerStatus: String, Codable {
    case notStarted
    case inProgress
    case isPaused
    case isResumed
    case isCompleted
}

public struct TimerSession: Codable {
    public let id: UUID
    /// total duration in seconds (TimeInterval) - remains TimeInterval for compatibility
    public var duration: TimeInterval    // total seconds
    public var startTime: Date?         // when it started (nil if not started)
    public var status: TimerStatus
    private var pausedAt: Date?         // when it was paused
    private var pausedDuration: TimeInterval = .zero
    public var alarmId: UUID?

    // Calculated field: current time - startTime (frozen when paused)
    public var elapsedTime: TimeInterval {
        guard let startTime = startTime else {
            return 0
        }
        
        let referenceTime: Date
        if status == .isPaused, let pausedAt {
            referenceTime = pausedAt
        } else {
            referenceTime = Date()
        }

        let dur = referenceTime.timeIntervalSince(startTime) - pausedDuration
        return dur
    }
    
    public var timeRemaining: TimeInterval {
        max(0, duration - elapsedTime)
    }

    public init(
        id: UUID = UUID(),
        duration: TimeInterval,
        startTime: Date? = nil,
        status: TimerStatus = .notStarted
    ) {
        self.id = id
        self.duration = duration
        self.startTime = startTime
        self.status = status
    }

    // MARK: - Utility Functions

    /// Starts the timer from the beginning
    public mutating func start() {
        startTime = Date()
        status = .inProgress
    }

    /// Pauses the timer, preserving elapsed time
    public mutating func pause() {
        guard status == .inProgress || status == .isResumed else { return }
        pausedAt = Date()
        status = .isPaused
    }

    /// Resumes the timer from where it was paused
    public mutating func resume() {
        status = .isResumed
        
        guard let pausedAt = pausedAt else { return }
        

        // Adjust startTime to account for the paused duration
        let delta: TimeInterval = Date().timeIntervalSince(pausedAt)
        pausedDuration += delta

        self.pausedAt = nil
    }

    /// Resets the timer to its initial state
    public mutating func reset() {
        startTime = nil
        pausedAt = nil
        pausedDuration = .zero
        status = .notStarted
    }

    /// Completes the timer
    public mutating func complete() {
        startTime = nil
        pausedAt = nil
        pausedDuration = .zero
        status = .isCompleted
    }
}
