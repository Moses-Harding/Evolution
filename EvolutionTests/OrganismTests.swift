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

    // Helper function to create organisms with default values
    func createOrganism(
        speed: Int = 10,
        senseRange: Int = 150,
        size: Double = 1.0,
        fertility: Double = 1.0,
        energyEfficiency: Double = 1.0,
        maxAge: Int = 200,
        aggression: Double = 0.5,
        defense: Double = 0.5,
        metabolism: Double = 1.0,
        heatTolerance: Double = 0.5,
        coldTolerance: Double = 0.5,
        position: CGPoint = .zero,
        generation: Int = 0,
        configuration: GameConfiguration? = nil
    ) -> Organism {
        return Organism(
            speed: speed,
            senseRange: senseRange,
            size: size,
            fertility: fertility,
            energyEfficiency: energyEfficiency,
            maxAge: maxAge,
            aggression: aggression,
            defense: defense,
            metabolism: metabolism,
            heatTolerance: heatTolerance,
            coldTolerance: coldTolerance,
            position: position,
            generation: generation,
            configuration: configuration ?? defaultConfig
        )
    }

    func testOrganismInitialization() {
        let organism = createOrganism(speed: 15, senseRange: 150, size: 1.0, fertility: 1.0, position: CGPoint(x: 100, y: 100), generation: 0)

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
        let tooSlow = createOrganism(speed: -5)
        XCTAssertEqual(tooSlow.speed, defaultConfig.minSpeed, "Speed should be clamped to minimum")

        let tooFast = createOrganism(speed: 100)
        XCTAssertEqual(tooFast.speed, defaultConfig.maxSpeed, "Speed should be clamped to maximum")
    }

    func testSenseRangeClamping() {
        let tooShort = createOrganism(senseRange: -50)
        XCTAssertEqual(tooShort.senseRange, defaultConfig.minSenseRange, "Sense range should be clamped to minimum")

        let tooLong = createOrganism(senseRange: 1000)
        XCTAssertEqual(tooLong.senseRange, defaultConfig.maxSenseRange, "Sense range should be clamped to maximum")
    }

    func testSizeClamping() {
        let tooSmall = createOrganism(size: -1.0)
        XCTAssertEqual(tooSmall.size, defaultConfig.minSize, accuracy: 0.01, "Size should be clamped to minimum")

        let tooLarge = createOrganism(size: 10.0)
        XCTAssertEqual(tooLarge.size, defaultConfig.maxSize, accuracy: 0.01, "Size should be clamped to maximum")
    }

    func testReproduction() {
        let parent = createOrganism(speed: 10, position: CGPoint(x: 100, y: 100), generation: 5)
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
        let slowParent = createOrganism(speed: defaultConfig.minSpeed)
        for _ in 0..<20 {
            let child = slowParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= defaultConfig.minSpeed && child.speed <= defaultConfig.maxSpeed, "Child speed must stay in bounds")
        }

        // Test edge case: very fast parent
        let fastParent = createOrganism(speed: defaultConfig.maxSpeed)
        for _ in 0..<20 {
            let child = fastParent.reproduce(at: .zero)
            XCTAssertTrue(child.speed >= defaultConfig.minSpeed && child.speed <= defaultConfig.maxSpeed, "Child speed must stay in bounds")
        }
    }

    func testReproductionMaintainsSenseRangeBounds() {
        // Test edge case: very short sense range parent
        let shortSenseParent = createOrganism(senseRange: defaultConfig.minSenseRange)
        for _ in 0..<20 {
            let child = shortSenseParent.reproduce(at: .zero)
            XCTAssertTrue(child.senseRange >= defaultConfig.minSenseRange && child.senseRange <= defaultConfig.maxSenseRange, "Child sense range must stay in bounds")
        }

        // Test edge case: very long sense range parent
        let longSenseParent = createOrganism(senseRange: defaultConfig.maxSenseRange)
        for _ in 0..<20 {
            let child = longSenseParent.reproduce(at: .zero)
            XCTAssertTrue(child.senseRange >= defaultConfig.minSenseRange && child.senseRange <= defaultConfig.maxSenseRange, "Child sense range must stay in bounds")
        }
    }

    func testReproductionMaintainsSizeBounds() {
        // Test edge case: very small parent
        let smallParent = createOrganism(size: defaultConfig.minSize)
        for _ in 0..<20 {
            let child = smallParent.reproduce(at: .zero)
            XCTAssertTrue(child.size >= defaultConfig.minSize && child.size <= defaultConfig.maxSize, "Child size must stay in bounds")
        }

        // Test edge case: very large parent
        let largeParent = createOrganism(size: defaultConfig.maxSize)
        for _ in 0..<20 {
            let child = largeParent.reproduce(at: .zero)
            XCTAssertTrue(child.size >= defaultConfig.minSize && child.size <= defaultConfig.maxSize, "Child size must stay in bounds")
        }
    }

    func testMovement() {
        let organism = createOrganism(speed: 10, position: CGPoint(x: 0, y: 0))
        let target = CGPoint(x: 100, y: 0)

        // Move for 1 second - using effectiveSpeed (size 1.0 with penalty 0.5 gives ~7.5 effective speed)
        let (newPosition, _) = organism.move(towards: target, deltaTime: 1.0)

        // Should move toward target based on effective speed
        XCTAssertGreaterThan(newPosition.x, 0)
        XCTAssertEqual(newPosition.y, 0.0, accuracy: 0.1)
    }

    func testMovementReachesTarget() {
        let organism = createOrganism(speed: 10, position: CGPoint(x: 0, y: 0))
        let target = CGPoint(x: 5, y: 0)

        // Move for 1 second - should reach target
        let (newPosition, _) = organism.move(towards: target, deltaTime: 1.0)

        XCTAssertEqual(newPosition, target, "Should reach target when close enough")
    }

    func testSizeAffectsSpeed() {
        let smallOrganism = createOrganism(speed: 10, size: 0.5)
        let largeOrganism = createOrganism(speed: 10, size: 2.0)

        // Smaller organisms should be faster
        XCTAssertGreaterThan(smallOrganism.effectiveSpeed, largeOrganism.effectiveSpeed, "Smaller organisms should have higher effective speed")
    }

    func testSizeAffectsRadius() {
        let smallOrganism = createOrganism(size: 0.5)
        let largeOrganism = createOrganism(size: 2.0)

        // Larger organisms should have bigger collision radius
        XCTAssertLessThan(smallOrganism.effectiveRadius, largeOrganism.effectiveRadius, "Larger organisms should have bigger collision radius")
    }

    func testColorGradient() {
        let slowOrganism = createOrganism(speed: defaultConfig.minSpeed)
        let fastOrganism = createOrganism(speed: defaultConfig.maxSpeed)

        // Slow should be more blue
        XCTAssertTrue(slowOrganism.color.blue > slowOrganism.color.red)

        // Fast should be more red
        XCTAssertTrue(fastOrganism.color.red > fastOrganism.color.blue)
    }

    func testFertilityClamping() {
        let tooLow = createOrganism(fertility: -1.0)
        XCTAssertEqual(tooLow.fertility, defaultConfig.minFertility, accuracy: 0.01, "Fertility should be clamped to minimum")

        let tooHigh = createOrganism(fertility: 5.0)
        XCTAssertEqual(tooHigh.fertility, defaultConfig.maxFertility, accuracy: 0.01, "Fertility should be clamped to maximum")
    }

    func testReproductionMaintainsFertilityBounds() {
        // Test edge case: very low fertility parent
        let lowFertilityParent = createOrganism(fertility: defaultConfig.minFertility)
        for _ in 0..<20 {
            let child = lowFertilityParent.reproduce(at: .zero)
            XCTAssertTrue(child.fertility >= defaultConfig.minFertility && child.fertility <= defaultConfig.maxFertility, "Child fertility must stay in bounds")
        }

        // Test edge case: very high fertility parent
        let highFertilityParent = createOrganism(fertility: defaultConfig.maxFertility)
        for _ in 0..<20 {
            let child = highFertilityParent.reproduce(at: .zero)
            XCTAssertTrue(child.fertility >= defaultConfig.minFertility && child.fertility <= defaultConfig.maxFertility, "Child fertility must stay in bounds")
        }
    }

    func testEffectiveReproductionProbability() {
        let lowFertility = createOrganism(fertility: 0.5)
        let normalFertility = createOrganism(fertility: 1.0)
        let highFertility = createOrganism(fertility: 1.5)

        // Lower fertility should result in lower reproduction probability
        XCTAssertLessThan(lowFertility.effectiveReproductionProbability, normalFertility.effectiveReproductionProbability)
        // Higher fertility should result in higher reproduction probability
        XCTAssertGreaterThan(highFertility.effectiveReproductionProbability, normalFertility.effectiveReproductionProbability)

        // All probabilities should be clamped between 0.1 and 0.95
        XCTAssertGreaterThanOrEqual(lowFertility.effectiveReproductionProbability, 0.1)
        XCTAssertLessThanOrEqual(highFertility.effectiveReproductionProbability, 0.95)
    }

    func testTemperatureToleranceClamping() {
        let tooLowHeat = createOrganism(heatTolerance: -1.0)
        XCTAssertEqual(tooLowHeat.heatTolerance, defaultConfig.minHeatTolerance, accuracy: 0.01, "Heat tolerance should be clamped to minimum")

        let tooHighHeat = createOrganism(heatTolerance: 5.0)
        XCTAssertEqual(tooHighHeat.heatTolerance, defaultConfig.maxHeatTolerance, accuracy: 0.01, "Heat tolerance should be clamped to maximum")

        let tooLowCold = createOrganism(coldTolerance: -1.0)
        XCTAssertEqual(tooLowCold.coldTolerance, defaultConfig.minColdTolerance, accuracy: 0.01, "Cold tolerance should be clamped to minimum")

        let tooHighCold = createOrganism(coldTolerance: 5.0)
        XCTAssertEqual(tooHighCold.coldTolerance, defaultConfig.maxColdTolerance, accuracy: 0.01, "Cold tolerance should be clamped to maximum")
    }

    func testReproductionMaintainsTemperatureToleranceBounds() {
        // Test edge case: heat tolerance
        let lowHeatParent = createOrganism(heatTolerance: defaultConfig.minHeatTolerance)
        for _ in 0..<20 {
            let child = lowHeatParent.reproduce(at: .zero)
            XCTAssertTrue(child.heatTolerance >= defaultConfig.minHeatTolerance && child.heatTolerance <= defaultConfig.maxHeatTolerance, "Child heat tolerance must stay in bounds")
        }

        let highHeatParent = createOrganism(heatTolerance: defaultConfig.maxHeatTolerance)
        for _ in 0..<20 {
            let child = highHeatParent.reproduce(at: .zero)
            XCTAssertTrue(child.heatTolerance >= defaultConfig.minHeatTolerance && child.heatTolerance <= defaultConfig.maxHeatTolerance, "Child heat tolerance must stay in bounds")
        }

        // Test edge case: cold tolerance
        let lowColdParent = createOrganism(coldTolerance: defaultConfig.minColdTolerance)
        for _ in 0..<20 {
            let child = lowColdParent.reproduce(at: .zero)
            XCTAssertTrue(child.coldTolerance >= defaultConfig.minColdTolerance && child.coldTolerance <= defaultConfig.maxColdTolerance, "Child cold tolerance must stay in bounds")
        }

        let highColdParent = createOrganism(coldTolerance: defaultConfig.maxColdTolerance)
        for _ in 0..<20 {
            let child = highColdParent.reproduce(at: .zero)
            XCTAssertTrue(child.coldTolerance >= defaultConfig.minColdTolerance && child.coldTolerance <= defaultConfig.maxColdTolerance, "Child cold tolerance must stay in bounds")
        }
    }

    func testEquality() {
        let organism1 = createOrganism(speed: 10)
        let organism2 = createOrganism(speed: 15, senseRange: 200, size: 1.5, fertility: 1.2, position: CGPoint(x: 100, y: 100), generation: 5)

        XCTAssertEqual(organism1, organism1)
        XCTAssertNotEqual(organism1, organism2)
    }

    // MARK: - Spontaneous Mutation System Tests

    func testMutationMultiplierTracking() {
        // Test that normal mutations have multiplier ~1.0
        let parent = createOrganism(speed: 15)
        var normalMutationCount = 0

        // Run multiple reproductions - most should be normal mutations
        for _ in 0..<100 {
            let child = parent.reproduce(at: .zero)
            if child.lastMutationMultiplier == 1.0 {
                normalMutationCount += 1
            }
            XCTAssertGreaterThan(child.lastMutationMultiplier, 0.0, "Mutation multiplier should be positive")
        }

        // Most mutations should be normal (multiplier = 1.0)
        XCTAssertGreaterThan(normalMutationCount, 80, "Most mutations should be normal")
    }

    func testSpontaneousLargeMutationsOccur() {
        // Test that large mutations can occur (though rare)
        let parent = createOrganism(speed: 15)
        var largeMutationFound = false

        // Run many reproductions to find at least one large mutation
        // With 2% probability, we should see at least one in ~150 trials
        for _ in 0..<200 {
            let child = parent.reproduce(at: .zero)
            if child.lastMutationMultiplier >= defaultConfig.largeMutationMultiplierMin {
                largeMutationFound = true
                break
            }
        }

        XCTAssertTrue(largeMutationFound, "At least one large mutation should occur in 200 trials (p=0.02 each)")
    }

    func testSpontaneousMutationsMaintainBounds() {
        // Test that even with spontaneous mutations, all traits stay within valid bounds
        let parent = createOrganism(speed: 15, senseRange: 200, size: 1.5, fertility: 1.2)

        for _ in 0..<100 {
            let child = parent.reproduce(at: .zero)

            // All traits must remain within configured bounds
            XCTAssertGreaterThanOrEqual(child.speed, defaultConfig.minSpeed)
            XCTAssertLessThanOrEqual(child.speed, defaultConfig.maxSpeed)

            XCTAssertGreaterThanOrEqual(child.senseRange, defaultConfig.minSenseRange)
            XCTAssertLessThanOrEqual(child.senseRange, defaultConfig.maxSenseRange)

            XCTAssertGreaterThanOrEqual(child.size, defaultConfig.minSize)
            XCTAssertLessThanOrEqual(child.size, defaultConfig.maxSize)

            XCTAssertGreaterThanOrEqual(child.fertility, defaultConfig.minFertility)
            XCTAssertLessThanOrEqual(child.fertility, defaultConfig.maxFertility)

            XCTAssertGreaterThanOrEqual(child.energyEfficiency, defaultConfig.minEnergyEfficiency)
            XCTAssertLessThanOrEqual(child.energyEfficiency, defaultConfig.maxEnergyEfficiency)

            XCTAssertGreaterThanOrEqual(child.aggression, defaultConfig.minAggression)
            XCTAssertLessThanOrEqual(child.aggression, defaultConfig.maxAggression)

            XCTAssertGreaterThanOrEqual(child.defense, defaultConfig.minDefense)
            XCTAssertLessThanOrEqual(child.defense, defaultConfig.maxDefense)

            XCTAssertGreaterThanOrEqual(child.heatTolerance, defaultConfig.minHeatTolerance)
            XCTAssertLessThanOrEqual(child.heatTolerance, defaultConfig.maxHeatTolerance)

            XCTAssertGreaterThanOrEqual(child.coldTolerance, defaultConfig.minColdTolerance)
            XCTAssertLessThanOrEqual(child.coldTolerance, defaultConfig.maxColdTolerance)
        }
    }

    func testNovelCapabilityDetectionSpeed() {
        // Test detection of speed breakthrough
        let slowParent = createOrganism(speed: 20)
        let fastChild = createOrganism(speed: 26)  // Above threshold (25)

        let capabilities = slowParent.detectNovelCapabilities(child: fastChild)

        XCTAssertTrue(capabilities.contains("⚡ Exceptional Speed"), "Should detect speed breakthrough")
    }

    func testNovelCapabilityDetectionSense() {
        // Test detection of perception breakthrough
        let normalParent = createOrganism(senseRange: 200)
        let perceptiveChild = createOrganism(senseRange: 360)  // Above threshold (350)

        let capabilities = normalParent.detectNovelCapabilities(child: perceptiveChild)

        XCTAssertTrue(capabilities.contains("👁️ Super Perception"), "Should detect perception breakthrough")
    }

    func testNovelCapabilityDetectionSize() {
        // Test detection of size breakthrough
        let normalParent = createOrganism(size: 1.2)
        let giantChild = createOrganism(size: 1.85)  // Above threshold (1.8)

        let capabilities = normalParent.detectNovelCapabilities(child: giantChild)

        XCTAssertTrue(capabilities.contains("🦖 Giant Form"), "Should detect size breakthrough")
    }

    func testNovelCapabilityDetectionCombat() {
        // Test detection of combat breakthroughs
        let normalParent = createOrganism(aggression: 0.5, defense: 0.5)
        let warriorChild = createOrganism(aggression: 0.9, defense: 0.5)  // Aggression above threshold (0.85)
        let defenderChild = createOrganism(aggression: 0.5, defense: 0.9)  // Defense above threshold (0.85)

        let warriorCapabilities = normalParent.detectNovelCapabilities(child: warriorChild)
        let defenderCapabilities = normalParent.detectNovelCapabilities(child: defenderChild)

        XCTAssertTrue(warriorCapabilities.contains("⚔️ Warrior Aggression"), "Should detect aggression breakthrough")
        XCTAssertTrue(defenderCapabilities.contains("🛡️ Fortress Defense"), "Should detect defense breakthrough")
    }

    func testNovelCapabilityDetectionEfficiency() {
        // Test detection of efficiency breakthrough
        let normalParent = createOrganism(energyEfficiency: 1.0)
        let efficientChild = createOrganism(energyEfficiency: 1.45)  // Above threshold (1.4)

        let capabilities = normalParent.detectNovelCapabilities(child: efficientChild)

        XCTAssertTrue(capabilities.contains("♻️ Ultra Efficiency"), "Should detect efficiency breakthrough")
    }

    func testNovelCapabilityNotDetectedWhenBelowThreshold() {
        // Test that capabilities are NOT detected when child is below threshold
        let normalParent = createOrganism(speed: 20, senseRange: 200, size: 1.2)
        let normalChild = createOrganism(speed: 22, senseRange: 220, size: 1.3)

        let capabilities = normalParent.detectNovelCapabilities(child: normalChild)

        XCTAssertTrue(capabilities.isEmpty, "Should not detect capabilities when below thresholds")
    }

    func testSpontaneousMutationDisabled() {
        // Test that when spontaneous mutations are disabled, multiplier is always 1.0
        var configNoSpontaneous = defaultConfig
        configNoSpontaneous.spontaneousMutationEnabled = false

        let parent = createOrganism(speed: 15, configuration: configNoSpontaneous)

        for _ in 0..<50 {
            let child = parent.reproduce(at: .zero)
            XCTAssertEqual(child.lastMutationMultiplier, 1.0, "Mutation multiplier should be 1.0 when spontaneous mutations disabled")
        }
    }

    func testLargeMutationsProduceLargerChanges() {
        // Test that large mutations actually produce larger trait changes
        let parent = createOrganism(speed: 15)
        var largeChangeFound = false

        // Run many reproductions to find a large mutation and verify its effect
        for _ in 0..<200 {
            let child = parent.reproduce(at: .zero)

            // If we found a large mutation, check that the change is substantial
            if child.lastMutationMultiplier >= defaultConfig.largeMutationMultiplierMin {
                // With large mutation multiplier (3-5x), changes can be much larger than normal range
                let speedDiff = abs(child.speed - parent.speed)

                // Normal mutation range is ±2, large should be capable of ±6 to ±10 or more
                if speedDiff > defaultConfig.mutationRange {
                    largeChangeFound = true
                    break
                }
            }
        }

        // Note: This test might occasionally fail due to RNG, but should pass most of the time
        // We're checking if large mutations CAN produce larger changes, not that they always do
        XCTAssertTrue(largeChangeFound, "Large mutations should be capable of producing changes larger than normal range")
    }
}
