
//
//  TimerSessionTests.swift
//  CommonViewsTests
//
//  Created by Eric Liu on 11/15/25.
//

import Testing
import Foundation
@testable import CommonViews

@Suite("TimerSession Tests")
struct TimerSessionTests {

    @Test("Initialization defaults")
    func testInitialization() {
        let session = TimerSession(duration: 60)
        #expect(session.duration == 60)
        #expect(session.status == .notStarted)
        #expect(session.elapsedTime == 0)
        #expect(session.timeRemaining == 60)
        #expect(session.startTime == nil)
    }

    @Test("Start timer")
    func testStart() {
        var session = TimerSession(duration: 60)
        session.start()
        
        #expect(session.status == .inProgress)
        #expect(session.startTime != nil)
        
        // Elapsed time should be close to 0 immediately after start
        #expect(session.elapsedTime >= 0 && session.elapsedTime < 0.1)
    }

    @Test("Pause timer")
    func testPause() async throws {
        var session = TimerSession(duration: 60)
        session.start()
        
        // Wait a bit
        try await Task.sleep(for: .milliseconds(100))
        
        session.pause()
        let elapsedAfterPause = session.elapsedTime
        
        #expect(session.status == .isPaused)
        #expect(elapsedAfterPause > 0)
        
        // Wait more to ensure elapsed time doesn't increase while paused
        try await Task.sleep(for: .milliseconds(100))
        
        // Allow for small floating point differences, but it should be very close
        #expect(abs(session.elapsedTime - elapsedAfterPause) < 0.01)
    }

    @Test("Resume timer")
    func testResume() async throws {
        var session = TimerSession(duration: 60)
        session.start()
        try await Task.sleep(for: .milliseconds(50))
        session.pause()
        
        let elapsedAtPause = session.elapsedTime
        
        try await Task.sleep(for: .milliseconds(50))
        session.resume()
        
        #expect(session.status == .isResumed)
        
        // Should resume from approximately where it left off
        // We can't guarantee exact equality due to execution time, but it should be greater than or equal
        #expect(session.elapsedTime >= elapsedAtPause)
    }

    @Test("Reset timer")
    func testReset() {
        var session = TimerSession(duration: 60)
        session.start()
        session.reset()
        
        #expect(session.status == .notStarted)
        #expect(session.startTime == nil)
        #expect(session.elapsedTime == 0)
        #expect(session.timeRemaining == 60)
    }

    @Test("Complete timer")
    func testComplete() {
        var session = TimerSession(duration: 60)
        session.start()
        session.complete()
        
        #expect(session.status == .isCompleted)
        #expect(session.startTime == nil)
    }

    @Test("Codable conformance")
    func testCodable() throws {
        var session = TimerSession(duration: 120)
        session.start()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        
        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(TimerSession.self, from: data)
        
        #expect(decodedSession.id == session.id)
        #expect(decodedSession.duration == session.duration)
        #expect(decodedSession.status == session.status)
        
        // Start time should be preserved (allowing for tiny precision loss during encode/decode if any)
        if let originalStart = session.startTime, let decodedStart = decodedSession.startTime {
            #expect(abs(originalStart.timeIntervalSince(decodedStart)) < 0.001)
        } else {
            #expect(session.startTime == nil && decodedSession.startTime == nil)
        }
    }
    
    @Test("Elapsed time calculation after simulated app restart (persistence)")
    func testPersistenceLogic() async throws {
        // 1. Start timer
        var session = TimerSession(duration: 300) // 5 minutes
        session.start()
        let initialStartTime = session.startTime!
        
        // 2. Simulate "saving" (encoding)
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        
        // 3. Simulate time passing while app is "closed"
        try await Task.sleep(for: .milliseconds(200))
        
        // 4. Simulate "loading" (decoding)
        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(TimerSession.self, from: data)
        
        // 5. Verify state
        #expect(decodedSession.status == .inProgress)
        // Calculating elapsed time on the decoded session should reflect the time passed since original start
        // Current time - original start time
        let currentElapsed = Date().timeIntervalSince(initialStartTime)
        
        // The decoded session's calculated elapsed time should match closely to actual time passed
        #expect(abs(decodedSession.elapsedTime - currentElapsed) < 0.1)
    }
}
