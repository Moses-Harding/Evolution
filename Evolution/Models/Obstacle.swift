//
//  Obstacle.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation
import CoreGraphics

enum ObstacleType {
    case wall       // Solid rectangular barrier
    case rock       // Circular obstacle
    case hazard     // Dangerous area that kills organisms
}

class Obstacle: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var size: CGSize       // Width and height for rectangular obstacles
    var radius: CGFloat    // Radius for circular obstacles
    var type: ObstacleType
    var rotation: CGFloat  // Rotation angle in radians

    init(id: UUID = UUID(), position: CGPoint, size: CGSize = CGSize(width: 50, height: 50), radius: CGFloat = 25, type: ObstacleType = .wall, rotation: CGFloat = 0) {
        self.id = id
        self.position = position
        self.size = size
        self.radius = radius
        self.type = type
        self.rotation = rotation
    }

    // Check if a point is inside this obstacle
    func contains(point: CGPoint) -> Bool {
        switch type {
        case .wall:
            // Rectangle collision (ignoring rotation for now)
            let minX = position.x - size.width / 2
            let maxX = position.x + size.width / 2
            let minY = position.y - size.height / 2
            let maxY = position.y + size.height / 2
            return point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY

        case .rock, .hazard:
            // Circle collision
            let dx = point.x - position.x
            let dy = point.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            return distance <= radius
        }
    }

    // Check if an organism at a given position with a given radius collides with this obstacle
    func collidesWith(organismPosition: CGPoint, organismRadius: CGFloat) -> Bool {
        switch type {
        case .wall:
            // Rectangle-circle collision
            // Find closest point on rectangle to circle center
            let closestX = max(position.x - size.width / 2, min(organismPosition.x, position.x + size.width / 2))
            let closestY = max(position.y - size.height / 2, min(organismPosition.y, position.y + size.height / 2))

            let dx = organismPosition.x - closestX
            let dy = organismPosition.y - closestY
            let distance = sqrt(dx * dx + dy * dy)

            return distance < organismRadius

        case .rock, .hazard:
            // Circle-circle collision
            let dx = organismPosition.x - position.x
            let dy = organismPosition.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            return distance < (radius + organismRadius)
        }
    }

    static func == (lhs: Obstacle, rhs: Obstacle) -> Bool {
        return lhs.id == rhs.id
    }
}
