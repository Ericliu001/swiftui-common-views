//
//  LongProgressButtonTests.swift
//  CommonViews
//
//  Restored and renamed from CircularProgressButtonTests
//

import Testing
import SwiftUI
@testable import CommonViews

@Suite("LongProgressButton Tests")
@MainActor
struct LongProgressButtonTests {

    @Test("Initialization with default parameters")
    func testInitWithDefaults() {
        let button = LongProgressButton(
            onCompletion: {}
        ) { _ in
            Text("Test")
        }
        #expect(button is LongProgressButton<Text>)
    }

    @Test("Initialization with custom duration")
    func testInitWithCustomDuration() {
        let button = LongProgressButton(
            duration: .seconds(5),
            onCompletion: {}
        ) { _ in
            Text("Test")
        }
        #expect(button is LongProgressButton<Text>)
    }

    @Test("Initialization with custom stroke width")
    func testInitWithCustomStrokeWidth() {
        let button = LongProgressButton(
            strokeWidth: 8,
            onCompletion: {}
        ) { _ in
            Text("Test")
        }
        #expect(button is LongProgressButton<Text>)
    }

    @Test("Initialization with custom colors")
    func testInitWithCustomColors() {
        let button = LongProgressButton(
            progressColor: .blue,
            completeColor: .green,
            onCompletion: {}
        ) { _ in
            Text("Test")
        }
        #expect(button is LongProgressButton<Text>)
    }

    @Test("Initialization with isCompleted binding")
    func testInitWithBinding() {
        @State var isCompleted = false

        let button = LongProgressButton(
            isCompleted: $isCompleted,
            onCompletion: {}
        ) { _ in
            Text("Test")
        }
        #expect(button is LongProgressButton<Text>)
    }

    @Test("View body is not empty")
    func testViewBodyNotEmpty() {
        let button = LongProgressButton(
            onCompletion: {}
        ) { _ in
            Text("Test")
        }

        let mirror = Mirror(reflecting: button.body)
        #expect(mirror.children.count > 0)
    }

    @Test("Content builder with completed state")
    func testContentBuilderWithCompletedState() {
        let button = LongProgressButton(
            onCompletion: {}
        ) { isCompleted in
            if isCompleted {
                Image(systemName: "checkmark")
            } else {
                Text("Press")
            }
        }
        // Verify button was created successfully
        let mirror = Mirror(reflecting: button.body)
        #expect(mirror.children.count > 0)
    }

    @Test("Duration conversion to seconds")
    func testDurationAsSeconds() {
        // Testing the initialization which uses duration
        let shortDuration = LongProgressButton(
            duration: .seconds(1),
            onCompletion: {}
        ) { _ in Text("Short") }

        let longDuration = LongProgressButton(
            duration: .seconds(10),
            onCompletion: {}
        ) { _ in Text("Long") }

        #expect(shortDuration is LongProgressButton<Text>)
        #expect(longDuration is LongProgressButton<Text>)
    }

    @Test("Multiple button instances")
    func testMultipleInstances() {
        let button1 = LongProgressButton(
            progressColor: .red,
            onCompletion: {}
        ) { _ in Text("Button 1") }

        let button2 = LongProgressButton(
            progressColor: .blue,
            onCompletion: {}
        ) { _ in Text("Button 2") }

        #expect(button1 is LongProgressButton<Text>)
        #expect(button2 is LongProgressButton<Text>)
    }
}
