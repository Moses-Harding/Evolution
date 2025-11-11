//
//  GameConfiguration.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import Foundation

struct GameConfiguration {
    // MARK: - Population Settings
    var initialPopulation: Int = 10
    var initialSpeed: Int = 10
    var initialSenseRange: Int = 150
    var initialSize: Double = 1.0
    var initialFertility: Double = 1.0

    // MARK: - Evolution Parameters
    var minSpeed: Int = 1
    var maxSpeed: Int = 30
    var mutationRange: Int = 2  // Speed can mutate by ±mutationRange

    var minSenseRange: Int = 50
    var maxSenseRange: Int = 400
    var senseRangeMutationRange: Int = 20  // Sense range can mutate by ±senseRangeMutationRange

    var minSize: Double = 0.5
    var maxSize: Double = 2.0
    var sizeMutationRange: Double = 0.15  // Size can mutate by ±sizeMutationRange

    var minFertility: Double = 0.5
    var maxFertility: Double = 1.5
    var fertilityMutationRange: Double = 0.1  // Fertility can mutate by ±fertilityMutationRange

    // MARK: - Food Settings
    var foodPerDay: Int = 5
    var foodSize: Double = 8.0

    // MARK: - Time Settings
    var dayCycleDuration: Double = 30.0  // seconds
    var movementPhaseDuration: Double = 25.0  // seconds

    // MARK: - Reproduction Settings
    var reproductionProbability: Double = 0.7  // 0.0 to 1.0
    var spawnDistance: Double = 30.0  // How far offspring spawn from parent

    // MARK: - Display Settings
    var baseOrganismRadius: Double = 10.0  // Base radius, multiplied by size
    var organismRadius: Double { return baseOrganismRadius }  // For compatibility

    // MARK: - Size Effects
    var sizeSpeedPenalty: Double = 0.5  // How much size reduces speed (0.0-1.0)

    // MARK: - Presets
    static let `default` = GameConfiguration()

    static let fastEvolution = GameConfiguration(
        initialPopulation: 15,
        foodPerDay: 8,
        dayCycleDuration: 20.0,
        movementPhaseDuration: 16.0,
        reproductionProbability: 0.85
    )

    static let slowEvolution = GameConfiguration(
        initialPopulation: 8,
        foodPerDay: 3,
        dayCycleDuration: 60.0,
        movementPhaseDuration: 50.0,
        reproductionProbability: 0.5
    )

    static let highMutation = GameConfiguration(
        mutationRange: 5,
        reproductionProbability: 0.8
    )

    static let extremeSpeed = GameConfiguration(
        minSpeed: 1,
        maxSpeed: 50,
        mutationRange: 3
    )
}
