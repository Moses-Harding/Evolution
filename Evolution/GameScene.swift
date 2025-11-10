//
//  GameScene.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SpriteKit
import Combine

class GameScene: SKScene {

    // MARK: - Constants
    private let dayCycleDuration: TimeInterval = 30.0  // Reduced from 60s
    private let movementPhaseDuration: TimeInterval = 25.0  // Reduced from 50s
    private let reproductionProbability: Double = 0.7
    private let spawnDistance: CGFloat = 30.0
    private let organismRadius: CGFloat = 10.0
    private let foodSize: CGFloat = 8.0

    // MARK: - Game State
    private var organisms: [Organism] = []
    private var food: [Food] = []
    private var organismNodes: [UUID: SKShapeNode] = [:]
    private var foodNodes: [UUID: SKShapeNode] = [:]

    private var currentDay: Int = 0
    private var dayTimer: TimeInterval = 0.0
    private var isMovementPhase: Bool = true

    // Speed control
    var timeScale: Double = 1.0  // Can be set to 2.0 for super speed

    // MARK: - Statistics
    var statistics: GameStatistics = GameStatistics()

    // MARK: - Publishers
    let statisticsPublisher = PassthroughSubject<GameStatistics, Never>()

    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupInitialPopulation()
        spawnFood()
        updateStatistics()
    }

    private func setupInitialPopulation() {
        for _ in 0..<10 {
            let randomX = CGFloat.random(in: 50...(size.width - 50))
            let randomY = CGFloat.random(in: 50...(size.height - 50))
            let organism = Organism(speed: 10, position: CGPoint(x: randomX, y: randomY), generation: 0)
            addOrganism(organism)
        }
    }

    private func spawnFood() {
        // Clear old food
        for foodNode in foodNodes.values {
            foodNode.removeFromParent()
        }
        food.removeAll()
        foodNodes.removeAll()

        // Spawn 5 new food items at random positions
        for _ in 0..<5 {
            let randomX = CGFloat.random(in: 20...(size.width - 20))
            let randomY = CGFloat.random(in: 20...(size.height - 20))
            let foodItem = Food(position: CGPoint(x: randomX, y: randomY))
            addFood(foodItem)
        }
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = (1.0 / 60.0) * timeScale  // Apply time scale

        dayTimer += deltaTime

        if dayTimer >= dayCycleDuration {
            // End of day - handle reproduction and death
            endDay()
            dayTimer = 0.0
            currentDay += 1
            isMovementPhase = true
            statistics.currentDay = currentDay
            showDayTransition()
        } else if dayTimer >= movementPhaseDuration && isMovementPhase {
            // End movement phase
            isMovementPhase = false
        }

        if isMovementPhase {
            updateOrganisms(deltaTime: deltaTime)
            checkCollisions()

            // Auto-advance if all food is eaten
            if allFoodClaimed() {
                dayTimer = movementPhaseDuration
                isMovementPhase = false
            }
        }
    }

    private func allFoodClaimed() -> Bool {
        return food.allSatisfy { $0.isClaimed }
    }

    private func updateOrganisms(deltaTime: TimeInterval) {
        for organism in organisms {
            // Find nearest unclaimed food if no target
            if organism.targetFood == nil || organism.targetFood!.isClaimed {
                organism.targetFood = findNearestUnclaimedFood(for: organism)
            }

            // Move towards target food
            if let target = organism.targetFood, !organism.hasFoodToday {
                let newPosition = organism.move(towards: target.position, deltaTime: deltaTime)
                organism.position = newPosition

                // Update visual node
                if let node = organismNodes[organism.id] {
                    node.position = newPosition
                }
            }
        }
    }

    private func findNearestUnclaimedFood(for organism: Organism) -> Food? {
        var nearest: Food?
        var nearestDistance: CGFloat = .infinity

        for foodItem in food where !foodItem.isClaimed {
            let dx = foodItem.position.x - organism.position.x
            let dy = foodItem.position.y - organism.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < nearestDistance {
                nearestDistance = distance
                nearest = foodItem
            }
        }

        return nearest
    }

    private func checkCollisions() {
        for organism in organisms where !organism.hasFoodToday {
            if let target = organism.targetFood {
                let dx = target.position.x - organism.position.x
                let dy = target.position.y - organism.position.y
                let distance = sqrt(dx * dx + dy * dy)

                let collisionDistance = organismRadius + (foodSize / 2)
                if distance < collisionDistance {
                    // Collision detected!
                    organism.hasFoodToday = true
                    target.isClaimed = true

                    // Update visual feedback
                    if let foodNode = foodNodes[target.id] {
                        foodNode.alpha = 0.3
                    }
                    if let organismNode = organismNodes[organism.id] {
                        organismNode.strokeColor = .yellow
                        organismNode.lineWidth = 2
                    }
                }
            }
        }
    }

    private func endDay() {
        var births = 0
        var deaths = 0

        // Handle deaths (organisms that didn't eat)
        let survivors = organisms.filter { organism in
            if organism.hasFoodToday {
                return true
            } else {
                deaths += 1
                removeOrganism(organism, animated: true)
                return false
            }
        }

        organisms = survivors

        // Handle reproduction
        var newborns: [(organism: Organism, parentPosition: CGPoint)] = []
        for organism in organisms {
            if organism.hasFoodToday && Double.random(in: 0...1) < reproductionProbability {
                let angle = Double.random(in: 0...(2 * .pi))
                let offsetX = cos(angle) * spawnDistance
                let offsetY = sin(angle) * spawnDistance
                let childPosition = CGPoint(
                    x: organism.position.x + CGFloat(offsetX),
                    y: organism.position.y + CGFloat(offsetY)
                )

                // Clamp to scene bounds
                let clampedPosition = CGPoint(
                    x: max(20, min(size.width - 20, childPosition.x)),
                    y: max(20, min(size.height - 20, childPosition.y))
                )

                let child = organism.reproduce(at: clampedPosition)
                newborns.append((child, organism.position))
                births += 1
            }

            // Reset for next day
            organism.hasFoodToday = false
            organism.targetFood = nil

            // Reset visual state
            if let node = organismNodes[organism.id] {
                node.strokeColor = .clear
                node.lineWidth = 0
            }
        }

        // Add newborns with reproduction animation
        for (newborn, parentPosition) in newborns {
            addOrganism(newborn, animated: true)
            showReproductionAnimation(from: parentPosition, to: newborn.position)
        }

        // Update statistics
        statistics.births = births
        statistics.deaths = deaths
        updateStatistics()

        // Spawn new food for next day
        spawnFood()
    }

    // MARK: - Organism Management
    private func addOrganism(_ organism: Organism, animated: Bool = false) {
        organisms.append(organism)

        let node = SKShapeNode(circleOfRadius: organismRadius)
        let color = organism.color
        node.fillColor = SKColor(red: color.red, green: color.green, blue: color.blue, alpha: 1.0)
        node.strokeColor = .clear
        node.position = organism.position

        if animated {
            node.setScale(0.1)
            node.run(SKAction.scale(to: 1.0, duration: 0.3))
        }

        organismNodes[organism.id] = node
        addChild(node)
    }

    private func removeOrganism(_ organism: Organism, animated: Bool = false) {
        if let node = organismNodes[organism.id] {
            if animated {
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let shrink = SKAction.scale(to: 0.1, duration: 0.5)
                let group = SKAction.group([fadeOut, shrink])
                let remove = SKAction.removeFromParent()
                node.run(SKAction.sequence([group, remove]))
            } else {
                node.removeFromParent()
            }
            organismNodes.removeValue(forKey: organism.id)
        }
    }

    // MARK: - Food Management
    private func addFood(_ foodItem: Food) {
        food.append(foodItem)

        let node = SKShapeNode(rectOf: CGSize(width: foodSize, height: foodSize))
        node.fillColor = .green
        node.strokeColor = .clear
        node.position = foodItem.position

        foodNodes[foodItem.id] = node
        addChild(node)
    }

    // MARK: - Statistics
    private func updateStatistics() {
        statistics.currentDay = currentDay
        statistics.population = organisms.count

        if organisms.isEmpty {
            statistics.averageSpeed = 0.0
            statistics.minSpeed = 0
            statistics.maxSpeed = 0
        } else {
            let speeds = organisms.map { $0.speed }
            statistics.averageSpeed = Double(speeds.reduce(0, +)) / Double(speeds.count)
            statistics.minSpeed = speeds.min() ?? 0
            statistics.maxSpeed = speeds.max() ?? 0
        }

        statistics.organisms = organisms.map { organism in
            OrganismInfo(
                id: organism.id,
                speed: organism.speed,
                generation: organism.generation,
                hasFoodToday: organism.hasFoodToday
            )
        }

        // Create snapshot
        let snapshot = DailySnapshot(
            day: currentDay,
            population: statistics.population,
            averageSpeed: statistics.averageSpeed,
            minSpeed: statistics.minSpeed,
            maxSpeed: statistics.maxSpeed,
            births: statistics.births,
            deaths: statistics.deaths
        )
        statistics.dailySnapshots.append(snapshot)

        // Publish update
        statisticsPublisher.send(statistics)
    }

    // MARK: - Animations
    private func showDayTransition() {
        // Create day transition label
        let label = SKLabelNode(text: "Day \(currentDay)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 48
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 1000
        label.alpha = 0

        addChild(label)

        // Animate
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])

        label.run(sequence)
    }

    private func showReproductionAnimation(from parentPosition: CGPoint, to childPosition: CGPoint) {
        // Create a line from parent to child
        let path = CGMutablePath()
        path.move(to: parentPosition)
        path.addLine(to: childPosition)

        let line = SKShapeNode(path: path)
        line.strokeColor = .cyan
        line.lineWidth = 2
        line.alpha = 0
        line.zPosition = 5

        addChild(line)

        // Pulse animation
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, fadeOut, remove])

        line.run(sequence)

        // Add pulse at parent
        let pulse = SKShapeNode(circleOfRadius: organismRadius * 1.5)
        pulse.strokeColor = .cyan
        pulse.lineWidth = 2
        pulse.fillColor = .clear
        pulse.position = parentPosition
        pulse.alpha = 0.8
        pulse.zPosition = 5

        addChild(pulse)

        let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
        let pulseOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([scaleUp, pulseOut])
        let removeParent = SKAction.removeFromParent()

        pulse.run(SKAction.sequence([group, removeParent]))
    }
}

// MARK: - Supporting Types
struct GameStatistics {
    var currentDay: Int = 0
    var population: Int = 0
    var averageSpeed: Double = 0.0
    var minSpeed: Int = 0
    var maxSpeed: Int = 0
    var births: Int = 0
    var deaths: Int = 0
    var organisms: [OrganismInfo] = []
    var dailySnapshots: [DailySnapshot] = []
}

struct OrganismInfo: Identifiable {
    let id: UUID
    let speed: Int
    let generation: Int
    let hasFoodToday: Bool
}
