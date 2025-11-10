//
//  FoodTests.swift
//  EvolutionTests
//
//  Created by Claude on 11/10/25.
//

import XCTest
import CoreGraphics
@testable import Evolution

final class FoodTests: XCTestCase {

    func testFoodInitialization() {
        let position = CGPoint(x: 50, y: 75)
        let food = Food(position: position)

        XCTAssertEqual(food.position, position)
        XCTAssertFalse(food.isClaimed, "Food should not be claimed initially")
    }

    func testFoodClaiming() {
        let food = Food(position: .zero)

        XCTAssertFalse(food.isClaimed)

        food.isClaimed = true
        XCTAssertTrue(food.isClaimed)
    }

    func testEquality() {
        let food1 = Food(position: .zero)
        let food2 = Food(position: CGPoint(x: 100, y: 100))

        XCTAssertEqual(food1, food1)
        XCTAssertNotEqual(food1, food2)
    }
}
