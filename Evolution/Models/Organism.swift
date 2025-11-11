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
    var speciesId: UUID  // Identifies which species this organism belongs to
    var lastMutationMultiplier: Double  // Tracks mutation magnitude from birth (for visual feedback)
    let configuration: GameConfiguration

    init(id: UUID = UUID(), speed: Int, senseRange: Int, size: Double, fertility: Double, energyEfficiency: Double, maxAge: Int, aggression: Double, defense: Double, metabolism: Double, heatTolerance: Double, coldTolerance: Double, position: CGPoint, energy: Double? = nil, age: Int = 0, generation: Int = 0, speciesId: UUID? = nil, lastMutationMultiplier: Double = 1.0, configuration: GameConfiguration = .default) {
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
        self.speciesId = speciesId ?? id  // If no species ID provided, this is the founder of a new species
        self.lastMutationMultiplier = lastMutationMultiplier
    }

    // Calculate genetic distance to another organism (0.0 = identical, 1.0 = maximum difference)
    func geneticDistance(to other: Organism) -> Double {
        // Normalize each trait difference to 0-1 range, then average
        var totalDistance = 0.0
        var traitCount = 0

        // Speed distance
        let speedRange = Double(configuration.maxSpeed - configuration.minSpeed)
        if speedRange > 0 {
            totalDistance += abs(Double(speed - other.speed)) / speedRange
            traitCount += 1
        }

        // Sense range distance
        let senseRange = Double(configuration.maxSenseRange - configuration.minSenseRange)
        if senseRange > 0 {
            totalDistance += abs(Double(self.senseRange - other.senseRange)) / senseRange
            traitCount += 1
        }

        // Size distance
        let sizeRange = configuration.maxSize - configuration.minSize
        if sizeRange > 0 {
            totalDistance += abs(size - other.size) / sizeRange
            traitCount += 1
        }

        // Fertility distance
        let fertilityRange = configuration.maxFertility - configuration.minFertility
        if fertilityRange > 0 {
            totalDistance += abs(fertility - other.fertility) / fertilityRange
            traitCount += 1
        }

        // Energy efficiency distance
        let efficiencyRange = configuration.maxEnergyEfficiency - configuration.minEnergyEfficiency
        if efficiencyRange > 0 {
            totalDistance += abs(energyEfficiency - other.energyEfficiency) / efficiencyRange
            traitCount += 1
        }

        // Max age distance
        let maxAgeRange = Double(configuration.maxMaxAge - configuration.minMaxAge)
        if maxAgeRange > 0 {
            totalDistance += abs(Double(maxAge - other.maxAge)) / maxAgeRange
            traitCount += 1
        }

        // Aggression distance
        totalDistance += abs(aggression - other.aggression)
        traitCount += 1

        // Defense distance
        totalDistance += abs(defense - other.defense)
        traitCount += 1

        // Metabolism distance
        let metabolismRange = configuration.maxMetabolism - configuration.minMetabolism
        if metabolismRange > 0 {
            totalDistance += abs(metabolism - other.metabolism) / metabolismRange
            traitCount += 1
        }

        // Heat tolerance distance
        totalDistance += abs(heatTolerance - other.heatTolerance)
        traitCount += 1

        // Cold tolerance distance
        totalDistance += abs(coldTolerance - other.coldTolerance)
        traitCount += 1

        return traitCount > 0 ? totalDistance / Double(traitCount) : 0.0
    }

    // Check if this organism can reproduce with another (based on genetic distance)
    func canReproduceWith(_ other: Organism) -> Bool {
        let distance = geneticDistance(to: other)
        // If genetic distance exceeds threshold, they are different species and cannot reproduce
        return distance < configuration.speciationThreshold
    }

    // MARK: - Spontaneous Mutation Helpers

    /// Determines if a spontaneous trait reset should occur for this reproduction event
    private func shouldResetTrait() -> Bool {
        guard configuration.spontaneousMutationEnabled else { return false }
        return Double.random(in: 0.0...1.0) < configuration.traitResetProbability
    }

    /// Calculates the mutation multiplier (1.0 = normal, higher = rare large mutation)
    private func calculateMutationMultiplier() -> Double {
        guard configuration.spontaneousMutationEnabled else { return 1.0 }

        let roll = Double.random(in: 0.0...1.0)

        if roll < configuration.massiveMutationProbability {
            // Massive mutation event (very rare)
            return Double.random(in: configuration.massiveMutationMultiplierMin...configuration.massiveMutationMultiplierMax)
        } else if roll < configuration.largeMutationProbability {
            // Large mutation event (rare)
            return Double.random(in: configuration.largeMutationMultiplierMin...configuration.largeMutationMultiplierMax)
        } else {
            // Normal mutation
            return 1.0
        }
    }

    /// Applies mutation to an integer trait with optional spontaneous reset
    private func mutateIntTrait(_ parentValue: Int, mutationRange: Int, min: Int, max: Int, multiplier: Double) -> Int {
        if shouldResetTrait() {
            // Spontaneous reset: completely re-randomize
            return Int.random(in: min...max)
        }

        // Apply normal mutation with multiplier
        let scaledRange = Int(Double(mutationRange) * multiplier)
        let mutation = Int.random(in: -scaledRange...scaledRange)
        return Swift.max(min, Swift.min(max, parentValue + mutation))
    }

    /// Applies mutation to a double trait with optional spontaneous reset
    private func mutateDoubleTrait(_ parentValue: Double, mutationRange: Double, min: Double, max: Double, multiplier: Double) -> Double {
        if shouldResetTrait() {
            // Spontaneous reset: completely re-randomize
            return Double.random(in: min...max)
        }

        // Apply normal mutation with multiplier
        let scaledRange = mutationRange * multiplier
        let mutation = Double.random(in: -scaledRange...scaledRange)
        return Swift.max(min, Swift.min(max, parentValue + mutation))
    }

    /// Detects novel capabilities that emerged in the child compared to parent
    func detectNovelCapabilities(child: Organism) -> [String] {
        var capabilities: [String] = []

        // Speed breakthrough
        if child.speed >= configuration.speedCapabilityThreshold && speed < configuration.speedCapabilityThreshold {
            capabilities.append("⚡ Exceptional Speed")
        }

        // Perception breakthrough
        if child.senseRange >= configuration.senseCapabilityThreshold && senseRange < configuration.senseCapabilityThreshold {
            capabilities.append("👁️ Super Perception")
        }

        // Size breakthrough
        if child.size >= configuration.sizeCapabilityThreshold && size < configuration.sizeCapabilityThreshold {
            capabilities.append("🦖 Giant Form")
        }

        // Combat breakthrough (aggression)
        if child.aggression >= configuration.combatCapabilityThreshold && aggression < configuration.combatCapabilityThreshold {
            capabilities.append("⚔️ Warrior Aggression")
        }

        // Combat breakthrough (defense)
        if child.defense >= configuration.combatCapabilityThreshold && defense < configuration.combatCapabilityThreshold {
            capabilities.append("🛡️ Fortress Defense")
        }

        // Efficiency breakthrough
        if child.energyEfficiency >= configuration.efficiencyCapabilityThreshold && energyEfficiency < configuration.efficiencyCapabilityThreshold {
            capabilities.append("♻️ Ultra Efficiency")
        }

        return capabilities
    }

    // Reproduction with mutation
    func reproduce(at newPosition: CGPoint) -> Organism {
        // Calculate mutation multiplier once for this reproduction event
        // This determines if this is a normal, large, or massive mutation event
        let mutationMultiplier = calculateMutationMultiplier()

        // Apply mutations to all traits using the unified mutation system
        let childSpeed = mutateIntTrait(
            speed,
            mutationRange: configuration.mutationRange,
            min: configuration.minSpeed,
            max: configuration.maxSpeed,
            multiplier: mutationMultiplier
        )

        let childSenseRange = mutateIntTrait(
            senseRange,
            mutationRange: configuration.senseRangeMutationRange,
            min: configuration.minSenseRange,
            max: configuration.maxSenseRange,
            multiplier: mutationMultiplier
        )

        let childSize = mutateDoubleTrait(
            size,
            mutationRange: configuration.sizeMutationRange,
            min: configuration.minSize,
            max: configuration.maxSize,
            multiplier: mutationMultiplier
        )

        let childFertility = mutateDoubleTrait(
            fertility,
            mutationRange: configuration.fertilityMutationRange,
            min: configuration.minFertility,
            max: configuration.maxFertility,
            multiplier: mutationMultiplier
        )

        let childEnergyEfficiency = mutateDoubleTrait(
            energyEfficiency,
            mutationRange: configuration.energyEfficiencyMutationRange,
            min: configuration.minEnergyEfficiency,
            max: configuration.maxEnergyEfficiency,
            multiplier: mutationMultiplier
        )

        let childMaxAge = mutateIntTrait(
            maxAge,
            mutationRange: configuration.maxAgeMutationRange,
            min: configuration.minMaxAge,
            max: configuration.maxMaxAge,
            multiplier: mutationMultiplier
        )

        let childAggression = mutateDoubleTrait(
            aggression,
            mutationRange: configuration.aggressionMutationRange,
            min: configuration.minAggression,
            max: configuration.maxAggression,
            multiplier: mutationMultiplier
        )

        let childDefense = mutateDoubleTrait(
            defense,
            mutationRange: configuration.defenseMutationRange,
            min: configuration.minDefense,
            max: configuration.maxDefense,
            multiplier: mutationMultiplier
        )

        let childMetabolism = mutateDoubleTrait(
            metabolism,
            mutationRange: configuration.metabolismMutationRange,
            min: configuration.minMetabolism,
            max: configuration.maxMetabolism,
            multiplier: mutationMultiplier
        )

        let childHeatTolerance = mutateDoubleTrait(
            heatTolerance,
            mutationRange: configuration.heatToleranceMutationRange,
            min: configuration.minHeatTolerance,
            max: configuration.maxHeatTolerance,
            multiplier: mutationMultiplier
        )

        let childColdTolerance = mutateDoubleTrait(
            coldTolerance,
            mutationRange: configuration.coldToleranceMutationRange,
            min: configuration.minColdTolerance,
            max: configuration.maxColdTolerance,
            multiplier: mutationMultiplier
        )

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
            speciesId: speciesId,  // Inherit parent's species ID
            lastMutationMultiplier: mutationMultiplier,  // Store mutation magnitude for tracking
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

    // Effective max age (fertility reduces lifespan through pleiotropy)
    var effectiveMaxAge: Int {
        guard configuration.pleiotropyEnabled else { return maxAge }

        // Higher fertility = shorter lifespan (trade-off)
        let fertilityPenalty = (fertility - 1.0) * configuration.fertilityLongevityTradeoff
        let ageMultiplier = 1.0 - fertilityPenalty
        return Int(Double(maxAge) * max(0.5, ageMultiplier))  // At least 50% of base lifespan
    }

    // Effective defense (aggression reduces defense through pleiotropy)
    var effectiveDefense: Double {
        guard configuration.pleiotropyEnabled else { return defense }

        // Higher aggression = lower defense (trade-off)
        let aggressionPenalty = aggression * configuration.aggressionDefenseTradeoff
        return max(0.0, defense - aggressionPenalty)
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

        // Pleiotropy: Larger sense range costs more energy to maintain
        var senseEnergyCost = 1.0
        if configuration.pleiotropyEnabled {
            senseEnergyCost = 1.0 + (Double(self.senseRange) * configuration.senseEnergyTradeoff)
        }

        let energyCost = Double(moveDistance) * configuration.energyCostPerMove * terrainEnergyCost * senseEnergyCost / energyEfficiency

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
        return isStarving || age >= effectiveMaxAge
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
