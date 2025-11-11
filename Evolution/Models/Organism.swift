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
    var energyEfficiency: Double  // Reduces energy consumption (0.5-1.5, where 1.0 = normal)
    var maxAge: Int  // Maximum lifespan in days
    var aggression: Double  // Ability to contest food (0.0-1.0)
    var defense: Double  // Resistance to aggression (0.0-1.0)
    var metabolism: Double  // Energy consumption rate (0.5-1.5, where 1.0 = normal)
    var heatTolerance: Double  // Tolerance to high temperatures (0.0-1.0)
    var coldTolerance: Double  // Tolerance to low temperatures (0.0-1.0)

    var position: CGPoint
    var energy: Double
    var age: Int  // Current age in days
    var hasFoodToday: Bool
    var targetFood: Food?
    var generation: Int
    let configuration: GameConfiguration

    init(id: UUID = UUID(), speed: Int, senseRange: Int, size: Double, fertility: Double, energyEfficiency: Double, maxAge: Int, aggression: Double, defense: Double, metabolism: Double, heatTolerance: Double, coldTolerance: Double, position: CGPoint, energy: Double? = nil, age: Int = 0, generation: Int = 0, configuration: GameConfiguration = .default) {
        self.id = id
        self.configuration = configuration
        self.speed = max(configuration.minSpeed, min(configuration.maxSpeed, speed))
        self.senseRange = max(configuration.minSenseRange, min(configuration.maxSenseRange, senseRange))
        self.size = max(configuration.minSize, min(configuration.maxSize, size))
        self.fertility = max(configuration.minFertility, min(configuration.maxFertility, fertility))
        self.energyEfficiency = max(configuration.minEnergyEfficiency, min(configuration.maxEnergyEfficiency, energyEfficiency))
        self.maxAge = max(configuration.minMaxAge, min(configuration.maxMaxAge, maxAge))
        self.aggression = max(configuration.minAggression, min(configuration.maxAggression, aggression))
        self.defense = max(configuration.minDefense, min(configuration.maxDefense, defense))
        self.metabolism = max(configuration.minMetabolism, min(configuration.maxMetabolism, metabolism))
        self.heatTolerance = max(configuration.minHeatTolerance, min(configuration.maxHeatTolerance, heatTolerance))
        self.coldTolerance = max(configuration.minColdTolerance, min(configuration.maxColdTolerance, coldTolerance))
        self.position = position
        self.energy = energy ?? configuration.initialEnergy
        self.age = age
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

        let energyEfficiencyMutation = Double.random(in: -configuration.energyEfficiencyMutationRange...configuration.energyEfficiencyMutationRange)
        let childEnergyEfficiency = max(configuration.minEnergyEfficiency, min(configuration.maxEnergyEfficiency, energyEfficiency + energyEfficiencyMutation))

        let maxAgeMutation = Int.random(in: -configuration.maxAgeMutationRange...configuration.maxAgeMutationRange)
        let childMaxAge = max(configuration.minMaxAge, min(configuration.maxMaxAge, maxAge + maxAgeMutation))

        let aggressionMutation = Double.random(in: -configuration.aggressionMutationRange...configuration.aggressionMutationRange)
        let childAggression = max(configuration.minAggression, min(configuration.maxAggression, aggression + aggressionMutation))

        let defenseMutation = Double.random(in: -configuration.defenseMutationRange...configuration.defenseMutationRange)
        let childDefense = max(configuration.minDefense, min(configuration.maxDefense, defense + defenseMutation))

        let metabolismMutation = Double.random(in: -configuration.metabolismMutationRange...configuration.metabolismMutationRange)
        let childMetabolism = max(configuration.minMetabolism, min(configuration.maxMetabolism, metabolism + metabolismMutation))

        let heatToleranceMutation = Double.random(in: -configuration.heatToleranceMutationRange...configuration.heatToleranceMutationRange)
        let childHeatTolerance = max(configuration.minHeatTolerance, min(configuration.maxHeatTolerance, heatTolerance + heatToleranceMutation))

        let coldToleranceMutation = Double.random(in: -configuration.coldToleranceMutationRange...configuration.coldToleranceMutationRange)
        let childColdTolerance = max(configuration.minColdTolerance, min(configuration.maxColdTolerance, coldTolerance + coldToleranceMutation))

        return Organism(
            speed: childSpeed,
            senseRange: childSenseRange,
            size: childSize,
            fertility: childFertility,
            energyEfficiency: childEnergyEfficiency,
            maxAge: childMaxAge,
            aggression: childAggression,
            defense: childDefense,
            metabolism: childMetabolism,
            heatTolerance: childHeatTolerance,
            coldTolerance: childColdTolerance,
            position: newPosition,
            energy: configuration.initialEnergy * 0.8,  // Start with 80% energy
            age: 0,
            generation: generation + 1,
            configuration: configuration
        )
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
    func move(towards target: CGPoint, deltaTime: TimeInterval, terrainMultiplier: Double = 1.0) -> (newPosition: CGPoint, energyCost: Double) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        // Apply terrain modifier to effective speed
        let modifiedSpeed = effectiveSpeed * terrainMultiplier

        if distance < CGFloat(modifiedSpeed) * CGFloat(deltaTime) {
            // Calculate energy cost for actual distance moved
            let actualDistance = distance
            let energyCost = Double(actualDistance) * configuration.energyCostPerMove / energyEfficiency
            return (target, energyCost)  // Reached target
        }

        let moveDistance = CGFloat(modifiedSpeed) * CGFloat(deltaTime)
        let moveX = (dx / distance) * moveDistance
        let moveY = (dy / distance) * moveDistance

        // Calculate energy cost based on distance moved and efficiency
        // Difficult terrain costs more energy (inverse of speed multiplier)
        let terrainEnergyCost = 2.0 - terrainMultiplier  // 1.0 for normal, up to 2.0 for difficult
        let energyCost = Double(moveDistance) * configuration.energyCostPerMove * terrainEnergyCost / energyEfficiency

        return (CGPoint(x: position.x + moveX, y: position.y + moveY), energyCost)
    }

    // Energy management
    func consumeEnergy(_ amount: Double) {
        energy = max(0, energy - amount * metabolism)
    }

    func gainEnergy(_ amount: Double) {
        energy = min(configuration.maxEnergy, energy + amount)
    }

    var isStarving: Bool {
        return energy <= configuration.starvationThreshold
    }

    var isDead: Bool {
        return isStarving || age >= maxAge
    }

    func incrementAge() {
        age += 1
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
