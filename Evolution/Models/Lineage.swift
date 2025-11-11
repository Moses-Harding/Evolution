//
//  Lineage.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation

/// Represents a notable family lineage in the simulation
struct Lineage: Identifiable {
    let id: UUID
    let founderId: UUID  // Original ancestor
    var founderGeneration: Int
    var currentDescendants: Set<UUID>  // Currently alive descendants
    var totalDescendants: Int  // All-time total (including dead)
    var peakPopulation: Int  // Maximum simultaneous descendants
    var foundedOnDay: Int
    var extinctOnDay: Int?  // nil if still alive
    var dominanceScore: Double  // Metric of lineage success

    init(founderId: UUID, founderGeneration: Int, foundedOnDay: Int) {
        self.id = UUID()
        self.founderId = founderId
        self.founderGeneration = founderGeneration
        self.currentDescendants = [founderId]
        self.totalDescendants = 1
        self.peakPopulation = 1
        self.foundedOnDay = foundedOnDay
        self.extinctOnDay = nil
        self.dominanceScore = 0.0
    }

    var isExtinct: Bool {
        return extinctOnDay != nil
    }

    var age: Int {
        if let extinctDay = extinctOnDay {
            return extinctDay - foundedOnDay
        }
        return 0  // Will be calculated with current day
    }

    mutating func addDescendant(_ organismId: UUID) {
        currentDescendants.insert(organismId)
        totalDescendants += 1
        if currentDescendants.count > peakPopulation {
            peakPopulation = currentDescendants.count
        }
    }

    mutating func removeDescendant(_ organismId: UUID) {
        currentDescendants.remove(organismId)
    }

    mutating func markExtinct(day: Int) {
        extinctOnDay = day
    }

    /// Calculate dominance score based on multiple factors
    mutating func calculateDominanceScore(totalPopulation: Int, currentDay: Int) {
        let populationRatio = totalPopulation > 0 ? Double(currentDescendants.count) / Double(totalPopulation) : 0.0
        let longevity = Double(currentDay - foundedOnDay)
        let totalSuccess = Double(totalDescendants)
        let peak = Double(peakPopulation)

        // Weighted formula: emphasizes current dominance and longevity
        dominanceScore = (populationRatio * 100.0) + (longevity * 0.5) + (totalSuccess * 0.1) + (peak * 0.5)
    }
}

/// Tracks and manages organism lineages
class LineageTracker {
    private var lineages: [UUID: Lineage] = [:]  // Keyed by founder ID
    private var organismToLineage: [UUID: UUID] = [:]  // Maps organism ID to founder ID

    /// Register a new organism and assign to lineage
    func registerOrganism(_ organism: Organism, parentId: UUID?, currentDay: Int) {
        if let parentId = parentId, let founderIdForParent = organismToLineage[parentId] {
            // Organism inherits parent's lineage
            organismToLineage[organism.id] = founderIdForParent
            lineages[founderIdForParent]?.addDescendant(organism.id)
        } else {
            // New lineage founder (initial population or speciation event)
            var newLineage = Lineage(
                founderId: organism.id,
                founderGeneration: organism.generation,
                foundedOnDay: currentDay
            )
            newLineage.calculateDominanceScore(totalPopulation: 1, currentDay: currentDay)
            lineages[organism.id] = newLineage
            organismToLineage[organism.id] = organism.id
        }
    }

    /// Record an organism's death
    func recordDeath(organismId: UUID, currentDay: Int) {
        guard let founderId = organismToLineage[organismId] else { return }

        // Remove from lineage
        lineages[founderId]?.removeDescendant(organismId)
        organismToLineage.removeValue(forKey: organismId)

        // Check if lineage went extinct
        if lineages[founderId]?.currentDescendants.isEmpty == true {
            lineages[founderId]?.markExtinct(day: currentDay)
        }
    }

    /// Update dominance scores for all active lineages
    func updateDominanceScores(totalPopulation: Int, currentDay: Int) {
        for (founderId, _) in lineages.filter({ !$0.value.isExtinct }) {
            lineages[founderId]?.calculateDominanceScore(totalPopulation: totalPopulation, currentDay: currentDay)
        }
    }

    /// Get the top N dominant lineages currently alive
    func getTopLineages(count: Int) -> [Lineage] {
        let activeLineages = lineages.values.filter { !$0.isExtinct }
        return Array(activeLineages.sorted { $0.dominanceScore > $1.dominanceScore }.prefix(count))
    }

    /// Get all extinct lineages
    func getExtinctLineages() -> [Lineage] {
        return lineages.values.filter { $0.isExtinct }
    }

    /// Get lineage for a specific organism
    func getLineage(for organismId: UUID) -> Lineage? {
        guard let founderId = organismToLineage[organismId] else { return nil }
        return lineages[founderId]
    }

    /// Get founder ID for an organism
    func getFounderId(for organismId: UUID) -> UUID? {
        return organismToLineage[organismId]
    }

    /// Check if two organisms are from the same lineage
    func areSameLineage(organismId1: UUID, organismId2: UUID) -> Bool {
        guard let founder1 = organismToLineage[organismId1],
              let founder2 = organismToLineage[organismId2] else {
            return false
        }
        return founder1 == founder2
    }

    /// Get lineage statistics
    func getStatistics() -> LineageStatistics {
        let active = lineages.values.filter { !$0.isExtinct }
        let extinct = lineages.values.filter { $0.isExtinct }

        let mostSuccessful = active.max { $0.totalDescendants < $1.totalDescendants }
        let longestLived = extinct.max { $0.age < $1.age }
        let largestPeak = lineages.values.max { $0.peakPopulation < $1.peakPopulation }

        return LineageStatistics(
            activeLineagesCount: active.count,
            extinctLineagesCount: extinct.count,
            mostSuccessfulLineage: mostSuccessful,
            longestLivedLineage: longestLived,
            largestPeakLineage: largestPeak,
            averageLineageAge: extinct.isEmpty ? 0.0 : Double(extinct.map { $0.age }.reduce(0, +)) / Double(extinct.count)
        )
    }

    /// Reset all lineage data
    func reset() {
        lineages.removeAll()
        organismToLineage.removeAll()
    }

    /// Get total number of lineages
    var totalLineages: Int {
        return lineages.count
    }

    /// Get count of active lineages
    var activeLineagesCount: Int {
        return lineages.values.filter { !$0.isExtinct }.count
    }
}

/// Summary statistics for lineages
struct LineageStatistics {
    let activeLineagesCount: Int
    let extinctLineagesCount: Int
    let mostSuccessfulLineage: Lineage?
    let longestLivedLineage: Lineage?
    let largestPeakLineage: Lineage?
    let averageLineageAge: Double
}
