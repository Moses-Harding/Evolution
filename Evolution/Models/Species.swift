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

    // Generate a color for a new species based on a seed
    static func generateColor(for speciesId: UUID) -> SKColor {
        // Use UUID bytes to generate consistent but varied colors
        let uuidString = speciesId.uuidString
        let hash = abs(uuidString.hashValue)

        // Generate hue, saturation, brightness
        let hue = Double(hash % 360) / 360.0
        let saturation = Double((hash / 360) % 40 + 60) / 100.0  // 0.6-1.0
        let brightness = Double((hash / 14400) % 30 + 70) / 100.0  // 0.7-1.0

        return SKColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1.0)
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
