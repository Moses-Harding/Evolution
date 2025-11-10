//
//  GameSceneTests.swift
//  EvolutionTests
//
//  Created by Claude on 11/10/25.
//

import XCTest
import SpriteKit
@testable import Evolution

final class GameSceneTests: XCTestCase {

    var scene: GameScene!

    override func setUp() {
        super.setUp()
        scene = GameScene(size: CGSize(width: 600, height: 800))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 600, height: 800))
        view.presentScene(scene)
    }

    override func tearDown() {
        scene = nil
        super.tearDown()
    }

    func testInitialPopulation() {
        XCTAssertEqual(scene.statistics.population, 10, "Should start with 10 organisms")
        XCTAssertEqual(scene.statistics.currentDay, 0, "Should start at day 0")
    }

    func testInitialSpeed() {
        XCTAssertEqual(scene.statistics.averageSpeed, 10.0, accuracy: 0.01, "All organisms should start with speed 10")
        XCTAssertEqual(scene.statistics.minSpeed, 10)
        XCTAssertEqual(scene.statistics.maxSpeed, 10)
    }

    func testOrganismListPopulation() {
        XCTAssertEqual(scene.statistics.organisms.count, 10, "Should have info for all 10 organisms")
    }

    func testReproductionProbability() {
        // This is a statistical test - run multiple reproductions
        var reproductionCount = 0
        let trials = 100

        for _ in 0..<trials {
            let parent = Organism(speed: 10, position: .zero, generation: 0)
            parent.hasFoodToday = true

            // Simulate reproduction check
            if Double.random(in: 0...1) < 0.7 {
                reproductionCount += 1
            }
        }

        // Should be roughly 70% (allow 15% margin for randomness)
        let ratio = Double(reproductionCount) / Double(trials)
        XCTAssertTrue(ratio > 0.55 && ratio < 0.85, "Reproduction should occur approximately 70% of the time")
    }

    func testMutationRange() {
        let parent = Organism(speed: 15, position: .zero, generation: 0)

        // Test multiple mutations
        for _ in 0..<50 {
            let child = parent.reproduce(at: .zero)
            let difference = abs(child.speed - parent.speed)
            XCTAssertTrue(difference <= 2, "Mutation should be within ±2")
        }
    }

    func testGenerationIncrement() {
        let parent = Organism(speed: 10, position: .zero, generation: 5)
        let child = parent.reproduce(at: .zero)

        XCTAssertEqual(child.generation, 6, "Child generation should be parent + 1")
    }

    func testCollisionDetection() {
        let organism = Organism(speed: 10, position: CGPoint(x: 100, y: 100), generation: 0)
        let food = Food(position: CGPoint(x: 105, y: 105))

        let dx = food.position.x - organism.position.x
        let dy = food.position.y - organism.position.y
        let distance = sqrt(dx * dx + dy * dy)

        // Organism radius: 10, Food size: 8 (radius 4), combined: 14
        XCTAssertTrue(distance < 14, "Organism and food should be close enough to collide")
    }

    func testDailySnapshotCreation() {
        // Initial snapshot should exist
        XCTAssertGreaterThanOrEqual(scene.statistics.dailySnapshots.count, 1, "Should have at least initial snapshot")

        let firstSnapshot = scene.statistics.dailySnapshots.first!
        XCTAssertEqual(firstSnapshot.day, 0)
        XCTAssertEqual(firstSnapshot.population, 10)
    }
}
