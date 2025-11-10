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
    var position: CGPoint
    var hasFoodToday: Bool
    var targetFood: Food?
    var generation: Int
    let configuration: GameConfiguration

    init(id: UUID = UUID(), speed: Int, position: CGPoint, generation: Int = 0, configuration: GameConfiguration = .default) {
        self.id = id
        self.configuration = configuration
        self.speed = max(configuration.minSpeed, min(configuration.maxSpeed, speed))
        self.position = position
        self.hasFoodToday = false
        self.targetFood = nil
        self.generation = generation
    }

    // Reproduction with mutation
    func reproduce(at newPosition: CGPoint) -> Organism {
        let mutation = Int.random(in: -configuration.mutationRange...configuration.mutationRange)
        let childSpeed = max(configuration.minSpeed, min(configuration.maxSpeed, speed + mutation))
        return Organism(speed: childSpeed, position: newPosition, generation: generation + 1, configuration: configuration)
    }

    // Calculate movement for this frame
    func move(towards target: CGPoint, deltaTime: TimeInterval) -> CGPoint {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < CGFloat(speed) * CGFloat(deltaTime) {
            return target  // Reached target
        }

        let moveDistance = CGFloat(speed) * CGFloat(deltaTime)
        let moveX = (dx / distance) * moveDistance
        let moveY = (dy / distance) * moveDistance

        return CGPoint(x: position.x + moveX, y: position.y + moveY)
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
