//
//  DailySnapshot.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import Foundation

struct DailySnapshot: Identifiable {
    let id: UUID
    let day: Int
    let population: Int
    let averageSpeed: Double
    let minSpeed: Int
    let maxSpeed: Int
    let births: Int
    let deaths: Int

    init(day: Int, population: Int, averageSpeed: Double, minSpeed: Int, maxSpeed: Int, births: Int = 0, deaths: Int = 0) {
        self.id = UUID()
        self.day = day
        self.population = population
        self.averageSpeed = averageSpeed
        self.minSpeed = minSpeed
        self.maxSpeed = maxSpeed
        self.births = births
        self.deaths = deaths
    }
}
