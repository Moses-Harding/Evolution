//
//  Terrain.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation
import CoreGraphics
import SpriteKit

enum TerrainType: String, CaseIterable {
    case grass = "Grass"
    case sand = "Sand"
    case water = "Water"
    case mud = "Mud"
    case rock = "Rock"

    var speedMultiplier: Double {
        switch self {
        case .grass: return 1.0  // Normal speed
        case .sand: return 0.7   // 30% slower
        case .water: return 0.5  // 50% slower
        case .mud: return 0.6    // 40% slower
        case .rock: return 0.8   // 20% slower
        }
    }

    var color: SKColor {
        switch self {
        case .grass: return SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 0.4)
        case .sand: return SKColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 0.4)
        case .water: return SKColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 0.4)
        case .mud: return SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 0.4)
        case .rock: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        }
    }

    var strokeColor: SKColor {
        switch self {
        case .grass: return SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 0.6)
        case .sand: return SKColor(red: 0.8, green: 0.7, blue: 0.4, alpha: 0.6)
        case .water: return SKColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 0.6)
        case .mud: return SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.6)
        case .rock: return SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6)
        }
    }
}

class TerrainPatch: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGSize
    var type: TerrainType

    init(id: UUID = UUID(), position: CGPoint, size: CGSize, type: TerrainType) {
        self.id = id
        self.position = position
        self.size = size
        self.type = type
    }

    // Check if a point is within this terrain patch
    func contains(point: CGPoint) -> Bool {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        return point.x >= position.x - halfWidth &&
               point.x <= position.x + halfWidth &&
               point.y >= position.y - halfHeight &&
               point.y <= position.y + halfHeight
    }

    // Get movement speed multiplier at a position
    func speedMultiplierAt(position: CGPoint) -> Double {
        if contains(point: position) {
            return type.speedMultiplier
        }
        return 1.0  // No effect if outside patch
    }
}
