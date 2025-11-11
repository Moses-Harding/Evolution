//
//  Species.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation
import SpriteKit

class Species: Identifiable {
    let id: UUID
    let founderId: UUID  // The organism that founded this species
    var name: String
    var color: SKColor  // Visual identifier for this species
    var population: Int = 0
    var foundedOnDay: Int
    var extinctOnDay: Int?
    var isExtinct: Bool {
        return extinctOnDay != nil
    }

    init(id: UUID, founderId: UUID, name: String, color: SKColor, foundedOnDay: Int) {
        self.id = id
        self.founderId = founderId
        self.name = name
        self.color = color
        self.foundedOnDay = foundedOnDay
    }

    // Palette of highly distinct colors for easy species identification
    static let distinctColors: [SKColor] = [
        SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),      // Red
        SKColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),      // Blue
        SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0),      // Green
        SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),      // Orange
        SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0),      // Purple
        SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),      // Yellow
        SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0),      // Pink
        SKColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0),      // Cyan
        SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0),      // Maroon
        SKColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 1.0),      // Navy
        SKColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0),      // Olive
        SKColor(red: 0.8, green: 0.4, blue: 0.7, alpha: 1.0),      // Magenta
        SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0),      // Lime
        SKColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0),      // Coral
        SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0),      // Sky Blue
        SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0),      // Salmon
        SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0),      // Purple Dark
        SKColor(red: 0.0, green: 0.6, blue: 0.5, alpha: 1.0),      // Teal
        SKColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0),      // Gold
        SKColor(red: 0.9, green: 0.5, blue: 0.8, alpha: 1.0),      // Pink Light
        SKColor(red: 0.3, green: 0.3, blue: 0.8, alpha: 1.0),      // Indigo
        SKColor(red: 0.7, green: 0.3, blue: 0.0, alpha: 1.0),      // Brown
        SKColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0),      // Emerald
        SKColor(red: 0.8, green: 0.0, blue: 0.4, alpha: 1.0),      // Crimson
    ]

    // Track which colors have been used
    static var usedColorIndices: Set<Int> = []
    static var colorCounter: Int = 0

    // Generate a color for a new species with maximum visual distinction
    static func generateColor(for speciesId: UUID) -> SKColor {
        // If we've used all colors, start over with variations
        if usedColorIndices.count >= distinctColors.count {
            usedColorIndices.removeAll()
            colorCounter = 0
        }

        // Find the next unused color
        var colorIndex = colorCounter % distinctColors.count
        while usedColorIndices.contains(colorIndex) {
            colorIndex = (colorIndex + 1) % distinctColors.count
        }

        usedColorIndices.insert(colorIndex)
        colorCounter += 1

        return distinctColors[colorIndex]
    }

    // Reset color tracking (useful when simulation restarts)
    static func resetColorTracking() {
        usedColorIndices.removeAll()
        colorCounter = 0
    }

    // Generate a name for a species based on characteristics
    static func generateName(generation: Int, traits: String) -> String {
        let prefixes = ["Neo", "Proto", "Mega", "Micro", "Ultra", "Hyper", "Paleo", "Eu"]
        let roots = ["thermus", "rapidus", "fortis", "sapiens", "agilis", "robustus", "gracilis", "validus"]
        let suffixes = ["", " alpha", " beta", " gamma", " prime"]

        let prefix = prefixes[abs(traits.hashValue) % prefixes.count]
        let root = roots[abs((traits + String(generation)).hashValue) % roots.count]
        let suffix = suffixes[abs(generation.hashValue) % suffixes.count]

        return "\(prefix)\(root)\(suffix)"
    }
}
