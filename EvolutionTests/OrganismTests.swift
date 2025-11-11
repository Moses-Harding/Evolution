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

    let defaultConfig = GameConfiguration.default

    func testOrganismInitialization() {
        let organism = Organism(speed: 15, senseRange: 150, size: 1.0, fertility: 1.0, position: CGPoint(x: 100, y: 100), generation: 0, configuration: defaultConfig)

        XCTAssertEqual(organism.speed, 15)
        XCTAssertEqual(organism.senseRange, 150)
        XCTAssertEqual(organism.size, 1.0, accuracy: 0.01)
        XCTAssertEqual(organism.fertility, 1.0, accuracy: 0.01)
        XCTAssertEqual(organism.position.x, 100)
        XCTAssertEqual(organism.position.y, 100)
        XCTAssertEqual(organism.generation, 0)
        XCTAssertFalse(organism.hasFoodToday)
        XCTAssertNil(organism.targetFood)
    }

    func testSpeedClamping() {
        let tooSlow = Organism(speed: -5, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooSlow.speed, defaultConfig.minSpeed, "Speed should be clamped to minimum")

        let tooFast = Organism(speed: 100, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooFast.speed, defaultConfig.maxSpeed, "Speed should be clamped to maximum")
    }

    func testSenseRangeClamping() {
        let tooShort = Organism(speed: 10, senseRange: -50, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooShort.senseRange, defaultConfig.minSenseRange, "Sense range should be clamped to minimum")

        let tooLong = Organism(speed: 10, senseRange: 1000, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooLong.senseRange, defaultConfig.maxSenseRange, "Sense range should be clamped to maximum")
    }

    func testSizeClamping() {
        let tooSmall = Organism(speed: 10, senseRange: 150, size: -1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooSmall.size, defaultConfig.minSize, accuracy: 0.01, "Size should be clamped to minimum")

        let tooLarge = Organism(speed: 10, senseRange: 150, size: 10.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooLarge.size, defaultConfig.maxSize, accuracy: 0.01, "Size should be clamped to maximum")
    }

    func testReproduction() {
        let parent = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.0, position: CGPoint(x: 100, y: 100), generation: 5, configuration: defaultConfig)
        let childPosition = CGPoint(x: 130, y: 100)
        let child = parent.reproduce(at: childPosition)

        XCTAssertEqual(child.generation, 6, "Child generation should be parent + 1")
        XCTAssertEqual(child.position, childPosition)
        XCTAssertTrue(child.speed >= defaultConfig.minSpeed && child.speed <= defaultConfig.maxSpeed, "Child speed should be in valid range")
        XCTAssertTrue(abs(child.speed - parent.speed) <= defaultConfig.mutationRange, "Child speed mutation should be within configured range")
        XCTAssertTrue(child.senseRange >= defaultConfig.minSenseRange && child.senseRange <= defaultConfig.maxSenseRange, "Child sense range should be in valid range")
        XCTAssertTrue(abs(child.senseRange - parent.senseRange) <= defaultConfig.senseRangeMutationRange, "Child sense range mutation should be within configured range")
        XCTAssertTrue(child.size >= defaultConfig.minSize && child.size <= defaultConfig.maxSize, "Child size should be in valid range")
        XCTAssertTrue(abs(child.size - parent.size) <= defaultConfig.sizeMutationRange, "Child size mutation should be within configured range")
        XCTAssertTrue(child.fertility >= defaultConfig.minFertility && child.fertility <= defaultConfig.maxFertility, "Child fertility should be in valid range")
        XCTAssertTrue(abs(child.fertility - parent.fertility) <= defaultConfig.fertilityMutationRange, "Child fertility mutation should be within configured range")
    }

    func testReproductionMaintainsSpeedBounds() {
        // Test edge case: very slow parent
        let slowParent = Organism(speed: defaultConfig.minSpeed, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = slowParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= defaultConfig.minSpeed && child.speed <= defaultConfig.maxSpeed, "Child speed must stay in bounds")
        }

        // Test edge case: very fast parent
        let fastParent = Organism(speed: defaultConfig.maxSpeed, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = fastParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= defaultConfig.minSpeed && child.speed <= defaultConfig.maxSpeed, "Child speed must stay in bounds")
        }
    }

    func testReproductionMaintainsSenseRangeBounds() {
        // Test edge case: very short sense range parent
        let shortSenseParent = Organism(speed: 10, senseRange: defaultConfig.minSenseRange, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = shortSenseParent.reproduce(at: .zero)
            XCTAssertTrue(child.senseRange >= defaultConfig.minSenseRange && child.senseRange <= defaultConfig.maxSenseRange, "Child sense range must stay in bounds")
        }

        // Test edge case: very long sense range parent
        let longSenseParent = Organism(speed: 10, senseRange: defaultConfig.maxSenseRange, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = longSenseParent.reproduce(at: .zero)
            XCTAssertTrue(child.senseRange >= defaultConfig.minSenseRange && child.senseRange <= defaultConfig.maxSenseRange, "Child sense range must stay in bounds")
        }
    }

    func testReproductionMaintainsSizeBounds() {
        // Test edge case: very small parent
        let smallParent = Organism(speed: 10, senseRange: 150, size: defaultConfig.minSize, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = smallParent.reproduce(at: .zero)
            XCTAssertTrue(child.size >= defaultConfig.minSize && child.size <= defaultConfig.maxSize, "Child size must stay in bounds")
        }

        // Test edge case: very large parent
        let largeParent = Organism(speed: 10, senseRange: 150, size: defaultConfig.maxSize, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = largeParent.reproduce(at: .zero)
            XCTAssertTrue(child.size >= defaultConfig.minSize && child.size <= defaultConfig.maxSize, "Child size must stay in bounds")
        }
    }

    func testMovement() {
        let organism = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.0, position: CGPoint(x: 0, y: 0), generation: 0, configuration: defaultConfig)
        let target = CGPoint(x: 100, y: 0)

        // Move for 1 second - using effectiveSpeed (size 1.0 with penalty 0.5 gives ~7.5 effective speed)
        let newPosition = organism.move(towards: target, deltaTime: 1.0)

        // Should move toward target based on effective speed
        XCTAssertGreaterThan(newPosition.x, 0)
        XCTAssertEqual(newPosition.y, 0.0, accuracy: 0.1)
    }

    func testMovementReachesTarget() {
        let organism = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.0, position: CGPoint(x: 0, y: 0), generation: 0, configuration: defaultConfig)
        let target = CGPoint(x: 5, y: 0)

        // Move for 1 second - should reach target
        let newPosition = organism.move(towards: target, deltaTime: 1.0)

        XCTAssertEqual(newPosition, target, "Should reach target when close enough")
    }

    func testSizeAffectsSpeed() {
        let smallOrganism = Organism(speed: 10, senseRange: 150, size: 0.5, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        let largeOrganism = Organism(speed: 10, senseRange: 150, size: 2.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)

        // Smaller organisms should be faster
        XCTAssertGreaterThan(smallOrganism.effectiveSpeed, largeOrganism.effectiveSpeed, "Smaller organisms should have higher effective speed")
    }

    func testSizeAffectsRadius() {
        let smallOrganism = Organism(speed: 10, senseRange: 150, size: 0.5, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        let largeOrganism = Organism(speed: 10, senseRange: 150, size: 2.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)

        // Larger organisms should have bigger collision radius
        XCTAssertLessThan(smallOrganism.effectiveRadius, largeOrganism.effectiveRadius, "Larger organisms should have bigger collision radius")
    }

    func testColorGradient() {
        let slowOrganism = Organism(speed: defaultConfig.minSpeed, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        let fastOrganism = Organism(speed: defaultConfig.maxSpeed, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)

        // Slow should be more blue
        XCTAssertTrue(slowOrganism.color.blue > slowOrganism.color.red)

        // Fast should be more red
        XCTAssertTrue(fastOrganism.color.red > fastOrganism.color.blue)
    }

    func testFertilityClamping() {
        let tooLow = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: -1.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooLow.fertility, defaultConfig.minFertility, accuracy: 0.01, "Fertility should be clamped to minimum")

        let tooHigh = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 5.0, position: .zero, generation: 0, configuration: defaultConfig)
        XCTAssertEqual(tooHigh.fertility, defaultConfig.maxFertility, accuracy: 0.01, "Fertility should be clamped to maximum")
    }

    func testReproductionMaintainsFertilityBounds() {
        // Test edge case: very low fertility parent
        let lowFertilityParent = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: defaultConfig.minFertility, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = lowFertilityParent.reproduce(at: .zero)
            XCTAssertTrue(child.fertility >= defaultConfig.minFertility && child.fertility <= defaultConfig.maxFertility, "Child fertility must stay in bounds")
        }

        // Test edge case: very high fertility parent
        let highFertilityParent = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: defaultConfig.maxFertility, position: .zero, generation: 0, configuration: defaultConfig)
        for _ in 0..<20 {
            let child = highFertilityParent.reproduce(at: .zero)
            XCTAssertTrue(child.fertility >= defaultConfig.minFertility && child.fertility <= defaultConfig.maxFertility, "Child fertility must stay in bounds")
        }
    }

    func testEffectiveReproductionProbability() {
        let lowFertility = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 0.5, position: .zero, generation: 0, configuration: defaultConfig)
        let normalFertility = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        let highFertility = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.5, position: .zero, generation: 0, configuration: defaultConfig)

        // Lower fertility should result in lower reproduction probability
        XCTAssertLessThan(lowFertility.effectiveReproductionProbability, normalFertility.effectiveReproductionProbability)
        // Higher fertility should result in higher reproduction probability
        XCTAssertGreaterThan(highFertility.effectiveReproductionProbability, normalFertility.effectiveReproductionProbability)

        // All probabilities should be clamped between 0.1 and 0.95
        XCTAssertGreaterThanOrEqual(lowFertility.effectiveReproductionProbability, 0.1)
        XCTAssertLessThanOrEqual(highFertility.effectiveReproductionProbability, 0.95)
    }

    func testEquality() {
        let organism1 = Organism(speed: 10, senseRange: 150, size: 1.0, fertility: 1.0, position: .zero, generation: 0, configuration: defaultConfig)
        let organism2 = Organism(speed: 15, senseRange: 200, size: 1.5, fertility: 1.2, position: CGPoint(x: 100, y: 100), generation: 5, configuration: defaultConfig)

        XCTAssertEqual(organism1, organism1)
        XCTAssertNotEqual(organism1, organism2)
    }
}
