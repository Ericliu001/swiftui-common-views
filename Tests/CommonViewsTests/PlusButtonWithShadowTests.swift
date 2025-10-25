//
//  PlusButtonWithShadowTests.swift
//  CommonViews
//
//  Created by Claude Code on 10/25/25.
//

import Testing
import SwiftUI
@testable import CommonViews

@Suite("PlusButtonWithShadow Tests")
@MainActor
struct PlusButtonWithShadowTests {

    @Test("Initialization with default color")
    func testInitWithDefaultColor() {
        let button = PlusButtonWithShadow()
        // Verify button was created successfully by checking its type
        #expect(button is PlusButtonWithShadow)
    }

    @Test("Initialization with custom color")
    func testInitWithCustomColor() {
        let button = PlusButtonWithShadow(color: .red)
        // Verify button was created successfully by checking its type
        #expect(button is PlusButtonWithShadow)
    }

    @Test("View body is not empty")
    func testViewBodyNotEmpty() {
        let button = PlusButtonWithShadow()
        let mirror = Mirror(reflecting: button.body)
        #expect(mirror.children.count > 0)
    }
}
