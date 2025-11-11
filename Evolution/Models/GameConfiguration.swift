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
    var initialEnergy: Double = 100.0
    var initialEnergyEfficiency: Double = 1.0
    var initialMaxAge: Int = 200  // Days
    var initialAggression: Double = 0.5
    var initialDefense: Double = 0.5
    var initialMetabolism: Double = 1.0
    var initialHeatTolerance: Double = 0.5
    var initialColdTolerance: Double = 0.5

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

    var minEnergyEfficiency: Double = 0.5
    var maxEnergyEfficiency: Double = 1.5
    var energyEfficiencyMutationRange: Double = 0.1

    var minMaxAge: Int = 100
    var maxMaxAge: Int = 400
    var maxAgeMutationRange: Int = 20

    var minAggression: Double = 0.0
    var maxAggression: Double = 1.0
    var aggressionMutationRange: Double = 0.1

    var minDefense: Double = 0.0
    var maxDefense: Double = 1.0
    var defenseMutationRange: Double = 0.1

    var minMetabolism: Double = 0.5
    var maxMetabolism: Double = 1.5
    var metabolismMutationRange: Double = 0.1

    var minHeatTolerance: Double = 0.0
    var maxHeatTolerance: Double = 1.0
    var heatToleranceMutationRange: Double = 0.1

    var minColdTolerance: Double = 0.0
    var maxColdTolerance: Double = 1.0
    var coldToleranceMutationRange: Double = 0.1

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

    // MARK: - Energy System
    var maxEnergy: Double = 100.0
    var energyCostPerMove: Double = 0.05  // Energy cost per unit of distance
    var energyGainFromFood: Double = 80.0  // Energy restored when eating
    var starvationThreshold: Double = 0.0  // Die if energy drops to this
    var metabolismEnergyCost: Double = 0.1  // Base energy cost per day cycle

    // MARK: - Combat System
    var foodContestRange: Double = 15.0  // Distance at which organisms can contest food
    var aggressionSuccessBase: Double = 0.5  // Base chance to win food contest

    // MARK: - Temperature System
    var minTemperature: Double = -10.0  // Degrees (arbitrary scale)
    var maxTemperature: Double = 40.0
    var baseTemperature: Double = 20.0  // Comfortable temperature
    var extremeTemperatureThreshold: Double = 15.0  // Distance from base temp to be "extreme"
    var temperatureEnergyMultiplier: Double = 0.02  // Energy cost multiplier per degree outside comfort zone
    var temperatureDeathThreshold: Double = 25.0  // Distance from base temp that causes instant death

    // MARK: - Day/Night Cycle
    var dayNightCycleEnabled: Bool = true
    var dayNightCycleDuration: Double = 60.0  // Seconds for full day/night cycle
    var nightSenseRangeMultiplier: Double = 0.5  // Sense range reduced to 50% at night
    var nightEnergyMultiplier: Double = 0.8  // Energy consumption reduced to 80% at night (rest period)

    // MARK: - Seasonal System
    var seasonsEnabled: Bool = true
    var daysPerSeason: Int = 10  // Number of simulation days per season
    var springFoodMultiplier: Double = 1.3  // 30% more food in spring
    var summerFoodMultiplier: Double = 1.2  // 20% more food in summer
    var fallFoodMultiplier: Double = 0.9  // 10% less food in fall
    var winterFoodMultiplier: Double = 0.6  // 40% less food in winter
    var winterTemperatureOffset: Double = -8.0  // 8 degrees colder in winter
    var summerTemperatureOffset: Double = 6.0  // 6 degrees warmer in summer

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
