//
//  TraitCorrelation.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation

/// Represents a detected correlation between two traits
struct TraitCorrelation: Identifiable, Equatable {
    let id: UUID
    let trait1: TraitType
    let trait2: TraitType
    let correlationCoefficient: Double  // -1.0 to 1.0 (Pearson correlation)
    let strength: CorrelationStrength
    let sampleSize: Int
    let detectedOnDay: Int

    init(id: UUID = UUID(), trait1: TraitType, trait2: TraitType, correlationCoefficient: Double, sampleSize: Int, detectedOnDay: Int) {
        self.id = id
        self.trait1 = trait1
        self.trait2 = trait2
        self.correlationCoefficient = correlationCoefficient
        self.sampleSize = sampleSize
        self.detectedOnDay = detectedOnDay
        self.strength = TraitCorrelation.calculateStrength(coefficient: correlationCoefficient)
    }

    enum CorrelationStrength: String {
        case veryStrong = "Very Strong"
        case strong = "Strong"
        case moderate = "Moderate"
        case weak = "Weak"
        case veryWeak = "Very Weak"
        case none = "None"

        var icon: String {
            switch self {
            case .veryStrong: return "🔥"
            case .strong: return "⚡"
            case .moderate: return "➡️"
            case .weak: return "→"
            case .veryWeak, .none: return "·"
            }
        }
    }

    enum TraitType: String, CaseIterable {
        case speed = "Speed"
        case senseRange = "Perception"
        case size = "Size"
        case fertility = "Fertility"
        case energyEfficiency = "Efficiency"
        case aggression = "Aggression"
        case defense = "Defense"
        case metabolism = "Metabolism"
        case heatTolerance = "Heat Tolerance"
        case coldTolerance = "Cold Tolerance"

        var shortName: String {
            switch self {
            case .speed: return "SPD"
            case .senseRange: return "PER"
            case .size: return "SIZ"
            case .fertility: return "FER"
            case .energyEfficiency: return "EFF"
            case .aggression: return "AGG"
            case .defense: return "DEF"
            case .metabolism: return "MET"
            case .heatTolerance: return "HOT"
            case .coldTolerance: return "COLD"
            }
        }
    }

    static func calculateStrength(coefficient: Double) -> CorrelationStrength {
        let absCoef = abs(coefficient)
        if absCoef >= 0.8 {
            return .veryStrong
        } else if absCoef >= 0.6 {
            return .strong
        } else if absCoef >= 0.4 {
            return .moderate
        } else if absCoef >= 0.2 {
            return .weak
        } else if absCoef > 0.0 {
            return .veryWeak
        } else {
            return .none
        }
    }

    var isPositive: Bool {
        return correlationCoefficient > 0
    }

    var description: String {
        let direction = isPositive ? "↑" : "↓"
        return "\(trait1.rawValue) \(direction) \(trait2.rawValue): \(strength.rawValue) (\(String(format: "%.2f", correlationCoefficient)))"
    }
}

/// Analyzes trait correlations in organism populations
class TraitCorrelationAnalyzer {
    private var detectedCorrelations: [TraitCorrelation] = []
    private let minimumSampleSize: Int = 20  // Need at least 20 organisms for reliable correlation
    private let significanceThreshold: Double = 0.3  // Only report correlations >= 0.3

    /// Analyze current population and detect significant correlations
    func analyzePopulation(_ organisms: [Organism], currentDay: Int) -> [TraitCorrelation] {
        guard organisms.count >= minimumSampleSize else { return [] }

        var newCorrelations: [TraitCorrelation] = []

        // Extract trait data
        let traitData = extractTraitData(from: organisms)

        // Calculate correlations for all trait pairs
        let traits = TraitCorrelation.TraitType.allCases
        for i in 0..<traits.count {
            for j in (i+1)..<traits.count {
                let trait1 = traits[i]
                let trait2 = traits[j]

                guard let values1 = traitData[trait1],
                      let values2 = traitData[trait2] else {
                    continue
                }

                // Calculate Pearson correlation coefficient
                if let coefficient = pearsonCorrelation(values1, values2) {
                    // Only report significant correlations
                    if abs(coefficient) >= significanceThreshold {
                        let correlation = TraitCorrelation(
                            trait1: trait1,
                            trait2: trait2,
                            correlationCoefficient: coefficient,
                            sampleSize: organisms.count,
                            detectedOnDay: currentDay
                        )

                        // Check if this is a new or significantly changed correlation
                        if isNewSignificantCorrelation(correlation) {
                            newCorrelations.append(correlation)
                            detectedCorrelations.append(correlation)
                        }
                    }
                }
            }
        }

        return newCorrelations
    }

    /// Extract trait values from organisms
    private func extractTraitData(from organisms: [Organism]) -> [TraitCorrelation.TraitType: [Double]] {
        var data: [TraitCorrelation.TraitType: [Double]] = [:]

        data[.speed] = organisms.map { Double($0.speed) }
        data[.senseRange] = organisms.map { Double($0.senseRange) }
        data[.size] = organisms.map { $0.size }
        data[.fertility] = organisms.map { $0.fertility }
        data[.energyEfficiency] = organisms.map { $0.energyEfficiency }
        data[.aggression] = organisms.map { $0.aggression }
        data[.defense] = organisms.map { $0.defense }
        data[.metabolism] = organisms.map { $0.metabolism }
        data[.heatTolerance] = organisms.map { $0.heatTolerance }
        data[.coldTolerance] = organisms.map { $0.coldTolerance }

        return data
    }

    /// Calculate Pearson correlation coefficient
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double? {
        guard x.count == y.count && x.count > 1 else { return nil }

        let n = Double(x.count)

        // Calculate means
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        // Calculate standard deviations and covariance
        var covariance = 0.0
        var varianceX = 0.0
        var varianceY = 0.0

        for i in 0..<x.count {
            let devX = x[i] - meanX
            let devY = y[i] - meanY
            covariance += devX * devY
            varianceX += devX * devX
            varianceY += devY * devY
        }

        // Avoid division by zero
        guard varianceX > 0 && varianceY > 0 else { return nil }

        let correlation = covariance / sqrt(varianceX * varianceY)
        return correlation
    }

    /// Check if correlation is new or significantly different from previous detection
    private func isNewSignificantCorrelation(_ newCorrelation: TraitCorrelation) -> Bool {
        // Check if we've already detected this trait pair
        for existing in detectedCorrelations {
            if (existing.trait1 == newCorrelation.trait1 && existing.trait2 == newCorrelation.trait2) ||
               (existing.trait1 == newCorrelation.trait2 && existing.trait2 == newCorrelation.trait1) {
                // Already detected this pair
                // Only report again if correlation strength changed significantly (>0.2 difference)
                if abs(existing.correlationCoefficient - newCorrelation.correlationCoefficient) > 0.2 {
                    return true
                }
                return false
            }
        }
        // New correlation pair
        return true
    }

    /// Get top N strongest correlations
    func getTopCorrelations(count: Int) -> [TraitCorrelation] {
        let sorted = detectedCorrelations.sorted { abs($0.correlationCoefficient) > abs($1.correlationCoefficient) }
        return Array(sorted.prefix(count))
    }

    /// Get all detected correlations
    func getAllCorrelations() -> [TraitCorrelation] {
        return detectedCorrelations
    }

    /// Get correlations involving a specific trait
    func getCorrelations(for trait: TraitCorrelation.TraitType) -> [TraitCorrelation] {
        return detectedCorrelations.filter { $0.trait1 == trait || $0.trait2 == trait }
    }

    /// Reset all correlation data
    func reset() {
        detectedCorrelations.removeAll()
    }

    /// Get interesting insights from correlations
    func getInsights() -> [String] {
        var insights: [String] = []

        // Find strongest positive correlation
        if let strongest = detectedCorrelations.filter({ $0.isPositive }).max(by: { $0.correlationCoefficient < $1.correlationCoefficient }) {
            if strongest.strength == .veryStrong || strongest.strength == .strong {
                insights.append("High \(strongest.trait1.rawValue) strongly associated with high \(strongest.trait2.rawValue)")
            }
        }

        // Find strongest negative correlation
        if let strongest = detectedCorrelations.filter({ !$0.isPositive }).min(by: { $0.correlationCoefficient < $1.correlationCoefficient }) {
            if strongest.strength == .veryStrong || strongest.strength == .strong {
                insights.append("High \(strongest.trait1.rawValue) associated with low \(strongest.trait2.rawValue)")
            }
        }

        // Look for trade-off patterns (size vs speed, aggression vs defense, etc.)
        let tradeoffs: [(TraitCorrelation.TraitType, TraitCorrelation.TraitType, String)] = [
            (.size, .speed, "Size-Speed trade-off detected"),
            (.aggression, .defense, "Aggression-Defense trade-off detected"),
            (.fertility, .energyEfficiency, "Fertility-Efficiency trade-off detected"),
            (.size, .metabolism, "Size affects metabolism")
        ]

        for (trait1, trait2, message) in tradeoffs {
            if let correlation = detectedCorrelations.first(where: {
                ($0.trait1 == trait1 && $0.trait2 == trait2) ||
                ($0.trait1 == trait2 && $0.trait2 == trait1)
            }) {
                if !correlation.isPositive && correlation.strength.rawValue != "Weak" {
                    insights.append(message)
                }
            }
        }

        return insights
    }
}
