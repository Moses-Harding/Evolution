//
//  Organism.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import Foundation
import CoreGraphics

class Organism: Identifiable, Equatable {
    let id: UUID
    var speed: Int
    var senseRange: Int
    var size: Double
    var fertility: Double  // Reproduction probability modifier (0.5-1.5, where 1.0 = base rate)
    var position: CGPoint
    var hasFoodToday: Bool
    var targetFood: Food?
    var generation: Int
    let configuration: GameConfiguration

    init(id: UUID = UUID(), speed: Int, senseRange: Int, size: Double, fertility: Double, position: CGPoint, generation: Int = 0, configuration: GameConfiguration = .default) {
        self.id = id
        self.configuration = configuration
        self.speed = max(configuration.minSpeed, min(configuration.maxSpeed, speed))
        self.senseRange = max(configuration.minSenseRange, min(configuration.maxSenseRange, senseRange))
        self.size = max(configuration.minSize, min(configuration.maxSize, size))
        self.fertility = max(configuration.minFertility, min(configuration.maxFertility, fertility))
        self.position = position
        self.hasFoodToday = false
        self.targetFood = nil
        self.generation = generation
    }

    // Reproduction with mutation
    func reproduce(at newPosition: CGPoint) -> Organism {
        let speedMutation = Int.random(in: -configuration.mutationRange...configuration.mutationRange)
        let childSpeed = max(configuration.minSpeed, min(configuration.maxSpeed, speed + speedMutation))

        let senseRangeMutation = Int.random(in: -configuration.senseRangeMutationRange...configuration.senseRangeMutationRange)
        let childSenseRange = max(configuration.minSenseRange, min(configuration.maxSenseRange, senseRange + senseRangeMutation))

        let sizeMutation = Double.random(in: -configuration.sizeMutationRange...configuration.sizeMutationRange)
        let childSize = max(configuration.minSize, min(configuration.maxSize, size + sizeMutation))

        let fertilityMutation = Double.random(in: -configuration.fertilityMutationRange...configuration.fertilityMutationRange)
        let childFertility = max(configuration.minFertility, min(configuration.maxFertility, fertility + fertilityMutation))

        return Organism(speed: childSpeed, senseRange: childSenseRange, size: childSize, fertility: childFertility, position: newPosition, generation: generation + 1, configuration: configuration)
    }

    // Effective reproduction probability (fertility modifies base rate)
    var effectiveReproductionProbability: Double {
        return min(0.95, max(0.1, configuration.reproductionProbability * fertility))
    }

    // Effective speed accounting for size penalty
    var effectiveSpeed: Double {
        // Larger organisms are slower (size penalty)
        // Formula: baseSpeed * (1 - sizeSpeedPenalty * (size - minSize) / (maxSize - minSize))
        let sizeRange = configuration.maxSize - configuration.minSize
        let sizeRatio = sizeRange > 0 ? (size - configuration.minSize) / sizeRange : 0.0
        let speedMultiplier = 1.0 - (configuration.sizeSpeedPenalty * sizeRatio)
        return Double(speed) * max(0.3, speedMultiplier)  // Minimum 30% of base speed
    }

    // Effective radius for collisions (based on size)
    var effectiveRadius: Double {
        return configuration.baseOrganismRadius * size
    }

    // Calculate movement for this frame
    func move(towards target: CGPoint, deltaTime: TimeInterval) -> CGPoint {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < CGFloat(effectiveSpeed) * CGFloat(deltaTime) {
            return target  // Reached target
        }

        let moveDistance = CGFloat(effectiveSpeed) * CGFloat(deltaTime)
        let moveX = (dx / distance) * moveDistance
        let moveY = (dy / distance) * moveDistance

        return CGPoint(x: position.x + moveX, y: position.y + moveY)
    }

    // Color based on speed (blue=slow, red=fast)
    var color: (red: Double, green: Double, blue: Double) {
        let speedRange = Double(configuration.maxSpeed - configuration.minSpeed)
        let ratio = speedRange > 0 ? Double(speed - configuration.minSpeed) / speedRange : 0.0
        return (red: ratio, green: 0.0, blue: 1.0 - ratio)
    }

    static func == (lhs: Organism, rhs: Organism) -> Bool {
        return lhs.id == rhs.id
    }
}
