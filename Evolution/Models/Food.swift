//
//  Food.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import Foundation
import CoreGraphics

class Food: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var isClaimed: Bool

    init(id: UUID = UUID(), position: CGPoint) {
        self.id = id
        self.position = position
        self.isClaimed = false
    }

    static func == (lhs: Food, rhs: Food) -> Bool {
        return lhs.id == rhs.id
    }
}
