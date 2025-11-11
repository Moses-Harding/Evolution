//
//  EvolutionaryMilestone.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation

/// Represents a significant evolutionary achievement
struct EvolutionaryMilestone: Identifiable, Equatable {
    let id: UUID
    let type: MilestoneType
    let day: Int
    let organismId: UUID?
    let value: Double
    let description: String

    init(id: UUID = UUID(), type: MilestoneType, day: Int, organismId: UUID? = nil, value: Double, description: String) {
        self.id = id
        self.type = type
        self.day = day
        self.organismId = organismId
        self.value = value
        self.description = description
    }

    enum MilestoneType: String, Codable {
        // Individual organism achievements
        case speedRecord = "Speed Record"
        case senseRecord = "Perception Record"
        case sizeRecord = "Size Record"
        case longevityRecord = "Longevity Record"
        case efficiencyRecord = "Efficiency Record"
        case combatRecord = "Combat Record"

        // Population milestones
        case population25 = "Population: 25"
        case population50 = "Population: 50"
        case population100 = "Population: 100"
        case population200 = "Population: 200"
        case population500 = "Population: 500"

        // Generation milestones
        case generation10 = "Generation 10"
        case generation25 = "Generation 25"
        case generation50 = "Generation 50"
        case generation100 = "Generation 100"
        case generation250 = "Generation 250"
        case generation500 = "Generation 500"
        case generation1000 = "Generation 1000"

        // Species diversity
        case firstSpeciation = "First New Species"
        case species5 = "5 Species"
        case species10 = "10 Species"
        case species20 = "20 Species"

        // Survival milestones
        case day100 = "Day 100 Survival"
        case day250 = "Day 250 Survival"
        case day500 = "Day 500 Survival"
        case day1000 = "Day 1000 Survival"

        // Evolutionary events
        case massExtinction = "Mass Extinction"
        case rapidRadiation = "Rapid Radiation"
        case convergentEvolution = "Convergent Evolution"
        case perfectAdaptation = "Perfect Adaptation"

        var icon: String {
            switch self {
            case .speedRecord: return "⚡️"
            case .senseRecord: return "👁️"
            case .sizeRecord: return "🦖"
            case .longevityRecord: return "🕰️"
            case .efficiencyRecord: return "♻️"
            case .combatRecord: return "⚔️"
            case .population25, .population50, .population100, .population200, .population500: return "📈"
            case .generation10, .generation25, .generation50, .generation100, .generation250, .generation500, .generation1000: return "🧬"
            case .firstSpeciation, .species5, .species10, .species20: return "🌳"
            case .day100, .day250, .day500, .day1000: return "🏆"
            case .massExtinction: return "💀"
            case .rapidRadiation: return "💥"
            case .convergentEvolution: return "🔄"
            case .perfectAdaptation: return "✨"
            }
        }

        var color: String {
            switch self {
            case .speedRecord, .senseRecord, .sizeRecord, .longevityRecord, .efficiencyRecord, .combatRecord:
                return "gold"
            case .population25, .population50, .population100, .population200, .population500:
                return "green"
            case .generation10, .generation25, .generation50, .generation100, .generation250, .generation500, .generation1000:
                return "purple"
            case .firstSpeciation, .species5, .species10, .species20:
                return "blue"
            case .day100, .day250, .day500, .day1000:
                return "orange"
            case .massExtinction:
                return "red"
            case .rapidRadiation, .perfectAdaptation:
                return "cyan"
            case .convergentEvolution:
                return "magenta"
            }
        }
    }
}

/// Tracks evolutionary milestones and records
class EvolutionaryRecords {
    private(set) var milestones: [EvolutionaryMilestone] = []

    // Current records (to prevent duplicate milestone notifications)
    private(set) var speedRecord: Int = 0
    private(set) var senseRecord: Int = 0
    private(set) var sizeRecord: Double = 0.0
    private(set) var longevityRecord: Int = 0  // Age at death
    private(set) var efficiencyRecord: Double = 0.0
    private(set) var aggressionRecord: Double = 0.0
    private(set) var defenseRecord: Double = 0.0

    // Population records
    private(set) var peakPopulation: Int = 0
    private(set) var maxGeneration: Int = 0

    // Milestone flags (one-time events)
    private var achievedPopulationMilestones: Set<Int> = []
    private var achievedGenerationMilestones: Set<Int> = []
    private var achievedSpeciesMilestones: Set<Int> = []
    private var achievedDayMilestones: Set<Int> = []

    /// Check for new records and return any new milestones achieved
    func checkRecords(organisms: [Organism], currentDay: Int, speciesCount: Int) -> [EvolutionaryMilestone] {
        var newMilestones: [EvolutionaryMilestone] = []

        guard !organisms.isEmpty else { return newMilestones }

        // Check trait records
        for organism in organisms {
            // Speed record
            if organism.speed > speedRecord {
                speedRecord = organism.speed
                let milestone = EvolutionaryMilestone(
                    type: .speedRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: Double(organism.speed),
                    description: "New speed record: \(organism.speed)"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }

            // Sense record
            if organism.senseRange > senseRecord {
                senseRecord = organism.senseRange
                let milestone = EvolutionaryMilestone(
                    type: .senseRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: Double(organism.senseRange),
                    description: "New perception record: \(organism.senseRange)"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }

            // Size record
            if organism.size > sizeRecord {
                sizeRecord = organism.size
                let milestone = EvolutionaryMilestone(
                    type: .sizeRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: organism.size,
                    description: "New size record: \(String(format: "%.2f", organism.size))"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }

            // Efficiency record
            if organism.energyEfficiency > efficiencyRecord {
                efficiencyRecord = organism.energyEfficiency
                let milestone = EvolutionaryMilestone(
                    type: .efficiencyRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: organism.energyEfficiency,
                    description: "New efficiency record: \(String(format: "%.2f", organism.energyEfficiency))"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }

            // Combat records
            if organism.aggression > aggressionRecord {
                aggressionRecord = organism.aggression
                let milestone = EvolutionaryMilestone(
                    type: .combatRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: organism.aggression,
                    description: "New aggression record: \(String(format: "%.2f", organism.aggression))"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }

            if organism.defense > defenseRecord {
                defenseRecord = organism.defense
                let milestone = EvolutionaryMilestone(
                    type: .combatRecord,
                    day: currentDay,
                    organismId: organism.id,
                    value: organism.defense,
                    description: "New defense record: \(String(format: "%.2f", organism.defense))"
                )
                newMilestones.append(milestone)
                milestones.append(milestone)
            }
        }

        // Check population milestones
        let population = organisms.count
        if population > peakPopulation {
            peakPopulation = population
        }

        newMilestones.append(contentsOf: checkPopulationMilestone(population: population, day: currentDay))

        // Check generation milestones
        let currentMaxGen = organisms.map { $0.generation }.max() ?? 0
        if currentMaxGen > maxGeneration {
            maxGeneration = currentMaxGen
            newMilestones.append(contentsOf: checkGenerationMilestone(generation: currentMaxGen, day: currentDay))
        }

        // Check species milestones
        newMilestones.append(contentsOf: checkSpeciesMilestone(speciesCount: speciesCount, day: currentDay))

        // Check day survival milestones
        newMilestones.append(contentsOf: checkDayMilestone(day: currentDay))

        return newMilestones
    }

    /// Record longevity when an organism dies of old age
    func recordLongevity(organism: Organism, currentDay: Int) -> EvolutionaryMilestone? {
        if organism.age > longevityRecord {
            longevityRecord = organism.age
            let milestone = EvolutionaryMilestone(
                type: .longevityRecord,
                day: currentDay,
                organismId: organism.id,
                value: Double(organism.age),
                description: "New longevity record: \(organism.age) days"
            )
            milestones.append(milestone)
            return milestone
        }
        return nil
    }

    /// Record a mass extinction event
    func recordMassExtinction(previousPopulation: Int, newPopulation: Int, day: Int) -> EvolutionaryMilestone? {
        let extinctionRate = Double(previousPopulation - newPopulation) / Double(previousPopulation)
        if extinctionRate >= 0.5 {  // 50% or more died
            let milestone = EvolutionaryMilestone(
                type: .massExtinction,
                day: day,
                organismId: nil,
                value: extinctionRate,
                description: "Mass extinction: \(Int(extinctionRate * 100))% population loss"
            )
            milestones.append(milestone)
            return milestone
        }
        return nil
    }

    /// Record first speciation event
    func recordFirstSpeciation(day: Int, newSpeciesId: UUID) -> EvolutionaryMilestone? {
        if achievedSpeciesMilestones.isEmpty {
            let milestone = EvolutionaryMilestone(
                type: .firstSpeciation,
                day: day,
                organismId: newSpeciesId,
                value: 1.0,
                description: "First new species emerged!"
            )
            milestones.append(milestone)
            achievedSpeciesMilestones.insert(1)
            return milestone
        }
        return nil
    }

    private func checkPopulationMilestone(population: Int, day: Int) -> [EvolutionaryMilestone] {
        var newMilestones: [EvolutionaryMilestone] = []

        let thresholds: [(Int, EvolutionaryMilestone.MilestoneType)] = [
            (25, .population25),
            (50, .population50),
            (100, .population100),
            (200, .population200),
            (500, .population500)
        ]

        for (threshold, type) in thresholds {
            if population >= threshold && !achievedPopulationMilestones.contains(threshold) {
                achievedPopulationMilestones.insert(threshold)
                let milestone = EvolutionaryMilestone(
                    type: type,
                    day: day,
                    organismId: nil,
                    value: Double(population),
                    description: "Population reached \(threshold)!"
                )
                milestones.append(milestone)
                newMilestones.append(milestone)
            }
        }

        return newMilestones
    }

    private func checkGenerationMilestone(generation: Int, day: Int) -> [EvolutionaryMilestone] {
        var newMilestones: [EvolutionaryMilestone] = []

        let thresholds: [(Int, EvolutionaryMilestone.MilestoneType)] = [
            (10, .generation10),
            (25, .generation25),
            (50, .generation50),
            (100, .generation100),
            (250, .generation250),
            (500, .generation500),
            (1000, .generation1000)
        ]

        for (threshold, type) in thresholds {
            if generation >= threshold && !achievedGenerationMilestones.contains(threshold) {
                achievedGenerationMilestones.insert(threshold)
                let milestone = EvolutionaryMilestone(
                    type: type,
                    day: day,
                    organismId: nil,
                    value: Double(generation),
                    description: "Generation \(threshold) reached!"
                )
                milestones.append(milestone)
                newMilestones.append(milestone)
            }
        }

        return newMilestones
    }

    private func checkSpeciesMilestone(speciesCount: Int, day: Int) -> [EvolutionaryMilestone] {
        var newMilestones: [EvolutionaryMilestone] = []

        let thresholds: [(Int, EvolutionaryMilestone.MilestoneType)] = [
            (5, .species5),
            (10, .species10),
            (20, .species20)
        ]

        for (threshold, type) in thresholds {
            if speciesCount >= threshold && !achievedSpeciesMilestones.contains(threshold) {
                achievedSpeciesMilestones.insert(threshold)
                let milestone = EvolutionaryMilestone(
                    type: type,
                    day: day,
                    organismId: nil,
                    value: Double(speciesCount),
                    description: "\(threshold) species coexisting!"
                )
                milestones.append(milestone)
                newMilestones.append(milestone)
            }
        }

        return newMilestones
    }

    private func checkDayMilestone(day: Int) -> [EvolutionaryMilestone] {
        var newMilestones: [EvolutionaryMilestone] = []

        let thresholds: [(Int, EvolutionaryMilestone.MilestoneType)] = [
            (100, .day100),
            (250, .day250),
            (500, .day500),
            (1000, .day1000)
        ]

        for (threshold, type) in thresholds {
            if day == threshold && !achievedDayMilestones.contains(threshold) {
                achievedDayMilestones.insert(threshold)
                let milestone = EvolutionaryMilestone(
                    type: type,
                    day: day,
                    organismId: nil,
                    value: Double(day),
                    description: "Survived \(threshold) days!"
                )
                milestones.append(milestone)
                newMilestones.append(milestone)
            }
        }

        return newMilestones
    }

    /// Get recent milestones (last N)
    func recentMilestones(count: Int = 10) -> [EvolutionaryMilestone] {
        return Array(milestones.suffix(count))
    }

    /// Get all milestones of a specific type
    func milestones(ofType type: EvolutionaryMilestone.MilestoneType) -> [EvolutionaryMilestone] {
        return milestones.filter { $0.type == type }
    }

    /// Clear all records (for reset)
    func reset() {
        milestones.removeAll()
        speedRecord = 0
        senseRecord = 0
        sizeRecord = 0.0
        longevityRecord = 0
        efficiencyRecord = 0.0
        aggressionRecord = 0.0
        defenseRecord = 0.0
        peakPopulation = 0
        maxGeneration = 0
        achievedPopulationMilestones.removeAll()
        achievedGenerationMilestones.removeAll()
        achievedSpeciesMilestones.removeAll()
        achievedDayMilestones.removeAll()
    }
}
