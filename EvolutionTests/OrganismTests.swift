//
//  OrganismTests.swift
//  EvolutionTests
//
//  Created by Claude on 11/10/25.
//

import XCTest
import CoreGraphics
@testable import Evolution

final class OrganismTests: XCTestCase {

    func testOrganismInitialization() {
        let organism = Organism(speed: 15, position: CGPoint(x: 100, y: 100), generation: 0)

        XCTAssertEqual(organism.speed, 15)
        XCTAssertEqual(organism.position.x, 100)
        XCTAssertEqual(organism.position.y, 100)
        XCTAssertEqual(organism.generation, 0)
        XCTAssertFalse(organism.hasFoodToday)
        XCTAssertNil(organism.targetFood)
    }

    func testSpeedClamping() {
        let tooSlow = Organism(speed: -5, position: .zero, generation: 0)
        XCTAssertEqual(tooSlow.speed, 1, "Speed should be clamped to minimum of 1")

        let tooFast = Organism(speed: 100, position: .zero, generation: 0)
        XCTAssertEqual(tooFast.speed, 30, "Speed should be clamped to maximum of 30")
    }

    func testReproduction() {
        let parent = Organism(speed: 10, position: CGPoint(x: 100, y: 100), generation: 5)
        let childPosition = CGPoint(x: 130, y: 100)
        let child = parent.reproduce(at: childPosition)

        XCTAssertEqual(child.generation, 6, "Child generation should be parent + 1")
        XCTAssertEqual(child.position, childPosition)
        XCTAssertTrue(child.speed >= 1 && child.speed <= 30, "Child speed should be in valid range")
        XCTAssertTrue(abs(child.speed - parent.speed) <= 2, "Child speed mutation should be within ±2")
    }

    func testReproductionMaintainsSpeedBounds() {
        // Test edge case: very slow parent
        let slowParent = Organism(speed: 1, position: .zero, generation: 0)
        for _ in 0..<20 {
            let child = slowParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= 1 && child.speed <= 30, "Child speed must stay in bounds")
        }

        // Test edge case: very fast parent
        let fastParent = Organism(speed: 30, position: .zero, generation: 0)
        for _ in 0..<20 {
            let child = fastParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= 1 && child.speed <= 30, "Child speed must stay in bounds")
        }
    }

    func testMovement() {
        let organism = Organism(speed: 10, position: CGPoint(x: 0, y: 0), generation: 0)
        let target = CGPoint(x: 100, y: 0)

        // Move for 1 second
        let newPosition = organism.move(towards: target, deltaTime: 1.0)

        // Should move 10 pixels towards target
        XCTAssertEqual(newPosition.x, 10.0, accuracy: 0.1)
        XCTAssertEqual(newPosition.y, 0.0, accuracy: 0.1)
    }

    func testMovementReachesTarget() {
        let organism = Organism(speed: 10, position: CGPoint(x: 0, y: 0), generation: 0)
        let target = CGPoint(x: 5, y: 0)

        // Move for 1 second - should reach target
        let newPosition = organism.move(towards: target, deltaTime: 1.0)

        XCTAssertEqual(newPosition, target, "Should reach target when close enough")
    }

    func testColorGradient() {
        let slowOrganism = Organism(speed: 1, position: .zero, generation: 0)
        let fastOrganism = Organism(speed: 30, position: .zero, generation: 0)

        // Slow should be more blue
        XCTAssertTrue(slowOrganism.color.blue > slowOrganism.color.red)

        // Fast should be more red
        XCTAssertTrue(fastOrganism.color.red > fastOrganism.color.blue)
    }

    func testEquality() {
        let organism1 = Organism(speed: 10, position: .zero, generation: 0)
        let organism2 = Organism(speed: 15, position: CGPoint(x: 100, y: 100), generation: 5)

        XCTAssertEqual(organism1, organism1)
        XCTAssertNotEqual(organism1, organism2)
    }
}
