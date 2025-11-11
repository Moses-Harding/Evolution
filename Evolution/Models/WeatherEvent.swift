//
//  WeatherEvent.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import Foundation
import SpriteKit

enum WeatherEventType: String, CaseIterable {
    case clear = "Clear"
    case rain = "Rain"
    case storm = "Storm"
    case heatwave = "Heatwave"
    case coldSnap = "Cold Snap"
    case fog = "Fog"

    var emoji: String {
        switch self {
        case .clear: return "☀️"
        case .rain: return "🌧️"
        case .storm: return "⛈️"
        case .heatwave: return "🔥"
        case .coldSnap: return "🥶"
        case .fog: return "🌫️"
        }
    }

    var temperatureModifier: Double {
        switch self {
        case .clear: return 0.0
        case .rain: return -2.0
        case .storm: return -4.0
        case .heatwave: return 8.0
        case .coldSnap: return -10.0
        case .fog: return -1.0
        }
    }

    var visibilityModifier: Double {
        switch self {
        case .clear: return 1.0
        case .rain: return 0.8
        case .storm: return 0.6
        case .heatwave: return 1.0
        case .coldSnap: return 0.9
        case .fog: return 0.5
        }
    }

    var movementModifier: Double {
        switch self {
        case .clear: return 1.0
        case .rain: return 0.9
        case .storm: return 0.7
        case .heatwave: return 0.85
        case .coldSnap: return 0.75
        case .fog: return 1.0
        }
    }

    var overlayColor: SKColor {
        switch self {
        case .clear: return .clear
        case .rain: return SKColor(white: 0.4, alpha: 0.2)
        case .storm: return SKColor(white: 0.2, alpha: 0.4)
        case .heatwave: return SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.15)
        case .coldSnap: return SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.25)
        case .fog: return SKColor(white: 0.7, alpha: 0.35)
        }
    }

    var duration: Int {
        // Duration in days
        switch self {
        case .clear: return Int.random(in: 3...6)
        case .rain: return Int.random(in: 1...3)
        case .storm: return 1
        case .heatwave: return Int.random(in: 2...4)
        case .coldSnap: return Int.random(in: 2...3)
        case .fog: return Int.random(in: 1...2)
        }
    }
}

class WeatherEvent {
    var type: WeatherEventType
    var remainingDays: Int

    init(type: WeatherEventType) {
        self.type = type
        self.remainingDays = type.duration
    }

    func decrementDay() {
        remainingDays -= 1
    }

    var isExpired: Bool {
        return remainingDays <= 0
    }
}
