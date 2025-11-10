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
    var speed: Int  // 1-30 range
    var position: CGPoint
    var hasFoodToday: Bool
    var targetFood: Food?
    var generation: Int

    init(id: UUID = UUID(), speed: Int, position: CGPoint, generation: Int = 0) {
        self.id = id
        self.speed = max(1, min(30, speed))  // Clamp to 1-30 range
        self.position = position
        self.hasFoodToday = false
        self.targetFood = nil
        self.generation = generation
    }

    // Reproduction with mutation
    func reproduce(at newPosition: CGPoint) -> Organism {
        let mutation = Int.random(in: -2...2)
        let childSpeed = max(1, min(30, speed + mutation))
        return Organism(speed: childSpeed, position: newPosition, generation: generation + 1)
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
        let ratio = Double(speed - 1) / 29.0  // Normalize to 0-1
        return (red: ratio, green: 0.0, blue: 1.0 - ratio)
    }

    static func == (lhs: Organism, rhs: Organism) -> Bool {
        return lhs.id == rhs.id
    }
}
