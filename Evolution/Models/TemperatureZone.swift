//
//  TemperatureZone.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation
import CoreGraphics

class TemperatureZone: Identifiable {
    let id: UUID
    var position: CGPoint
    var radius: CGFloat
    var temperature: Double  // Temperature value
    var intensity: Double  // How strongly the zone affects organisms (0.0-1.0)

    init(id: UUID = UUID(), position: CGPoint, radius: CGFloat, temperature: Double, intensity: Double = 1.0) {
        self.id = id
        self.position = position
        self.radius = radius
        self.temperature = temperature
        self.intensity = max(0.0, min(1.0, intensity))
    }

    // Calculate temperature at a given position
    func temperatureAt(position: CGPoint) -> Double {
        let dx = position.x - self.position.x
        let dy = position.y - self.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance >= radius {
            return 0.0  // Outside the zone
        }

        // Temperature decreases with distance from center
        let distanceRatio = distance / radius
        let falloff = 1.0 - distanceRatio  // 1.0 at center, 0.0 at edge

        return temperature * falloff * intensity
    }
}
