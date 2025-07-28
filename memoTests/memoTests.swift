//
//  memoTests.swift
//  memoTests
//
//  Created by Gabriel Gad Costa Weyers on 01/04/25.
//

import Testing
@testable import memo

struct memoTests {

    @Test func example() async throws {
        // Simple sanity test template generated with the project
    }

    /// Verifies that the `Color.toHex()` helper returns the expected hex string
    /// representation for a given color.
    @Test func colorToHex() async throws {
        #expect(Color.red.toHex() == "#FF0000")
    }

}
