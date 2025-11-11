//
//  GameScene.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SpriteKit
import Combine

class GameScene: SKScene {

    // MARK: - Configuration
    private let configuration: GameConfiguration

    // MARK: - Game State
    private var organisms: [Organism] = []
    private var food: [Food] = []
    private var organismNodes: [UUID: SKShapeNode] = [:]
    private var foodNodes: [UUID: SKShapeNode] = [:]
    private var corpsePositions: [CGPoint] = []  // Store positions of dead organisms

    private var currentDay: Int = 0

    // Speed control
    var timeScale: Double = 1.0  // Can be set to 2.0 for super speed

    // MARK: - Statistics
    var statistics: GameStatistics = GameStatistics()

    // MARK: - Publishers
    let statisticsPublisher = PassthroughSubject<GameStatistics, Never>()

    // MARK: - Initialization
    init(size: CGSize, configuration: GameConfiguration) {
        self.configuration = configuration
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.configuration = .default
        super.init(coder: aDecoder)
    }

    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = .black

        // Configure view for background execution
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = false

        setupInitialPopulation()
        spawnFood()
        updateStatistics()
    }

    private func setupInitialPopulation() {
        for _ in 0..<configuration.initialPopulation {
            let randomX = CGFloat.random(in: 50...(size.width - 50))
            let randomY = CGFloat.random(in: 50...(size.height - 50))
            let organism = Organism(
                speed: configuration.initialSpeed,
                position: CGPoint(x: randomX, y: randomY),
                generation: 0,
                configuration: configuration
            )
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

        // First, spawn food at corpse positions (corpses from previous day)
        for corpsePosition in corpsePositions {
            let foodItem = Food(position: corpsePosition)
            addFood(foodItem)
        }
        corpsePositions.removeAll()  // Clear corpse positions after spawning

        // Then spawn regular food items based on configuration
        for _ in 0..<configuration.foodPerDay {
            let randomX = CGFloat.random(in: 20...(size.width - 20))
            let randomY = CGFloat.random(in: 20...(size.height - 20))
            let foodItem = Food(position: CGPoint(x: randomX, y: randomY))
            addFood(foodItem)
        }
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = (1.0 / 60.0) * timeScale  // Apply time scale

        // Check if day should end
        if shouldEndDay() {
            // End of day - handle reproduction and death
            endDay()
            currentDay += 1
            statistics.currentDay = currentDay
            showDayTransition()
            spawnFood()
            resetOrganismsForNewDay()
        } else {
            // Continue movement and collision detection
            updateOrganisms(deltaTime: deltaTime)
            checkCollisions()
        }
    }

    private func shouldEndDay() -> Bool {
        // Day ends when either all food is eaten OR all organisms have eaten
        return allFoodClaimed() || allOrganismsFed()
    }

    private func allOrganismsFed() -> Bool {
        // Need at least one organism, and all must have food
        return !organisms.isEmpty && organisms.allSatisfy { $0.hasFoodToday }
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

                let collisionDistance = CGFloat(configuration.organismRadius) + CGFloat(configuration.foodSize / 2)
                if distance < collisionDistance {
                    // Collision detected!
                    organism.hasFoodToday = true
                    target.isClaimed = true

                    // Update visual feedback with animation
                    if let foodNode = foodNodes[target.id] {
                        // Animate food being consumed
                        let shrink = SKAction.scale(to: 0.3, duration: 0.2)
                        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.2)
                        let group = SKAction.group([shrink, fadeOut])
                        foodNode.run(group)
                    }

                    if let organismNode = organismNodes[organism.id] {
                        // Celebrate with pulse and color
                        organismNode.strokeColor = .yellow
                        organismNode.lineWidth = 3

                        // Pulse animation
                        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
                        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
                        let pulse = SKAction.sequence([scaleUp, scaleDown])
                        organismNode.run(pulse)
                    }

                    // Add celebration particles and effects
                    addFeedingCelebration(at: organism.position, color: organism.color)
                }
            }
        }
    }

    private func endDay() {
        var births = 0
        var deaths = 0
        corpsePositions.removeAll()  // Clear previous corpse positions

        // Handle reproduction for all organisms that ate today
        let fedOrganisms = organisms.filter { $0.hasFoodToday }
        for organism in fedOrganisms {
            if Double.random(in: 0...1) < configuration.reproductionProbability {
                let angle = Double.random(in: 0...(2 * .pi))
                let offsetX = cos(angle) * configuration.spawnDistance
                let offsetY = sin(angle) * configuration.spawnDistance
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

                // Show dramatic reproduction with buildup -> POP -> split
                showDramaticReproduction(parent: organism, child: child, childPosition: clampedPosition)

                births += 1
            }
        }

        // Handle deaths (organisms that didn't eat)
        let survivors = organisms.filter { organism in
            if organism.hasFoodToday {
                return true
            } else {
                deaths += 1
                corpsePositions.append(organism.position)  // Store corpse position
                removeOrganism(organism, animated: true)
                return false
            }
        }

        organisms = survivors

        // Update statistics
        statistics.births = births
        statistics.deaths = deaths
        updateStatistics()
    }

    private func resetOrganismsForNewDay() {
        // Reset all organisms for next day
        for organism in organisms {
            organism.hasFoodToday = false
            organism.targetFood = nil

            // Reset visual state
            if let node = organismNodes[organism.id] {
                node.strokeColor = .clear
                node.lineWidth = 0
            }
        }

        // Reset births counter for next day
        statistics.births = 0
    }

    // MARK: - Organism Management
    private func addOrganism(_ organism: Organism, animated: Bool = false) {
        organisms.append(organism)

        let node = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius))
        let color = organism.color
        node.fillColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1.0)
        node.strokeColor = .clear
        node.position = organism.position

        if animated {
            // Start small and invisible
            node.setScale(0.1)
            node.alpha = 0

            // Create elastic bounce effect
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.25)
            scaleUp.timingMode = .easeOut
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.15)
            scaleNormal.timingMode = .easeInEaseOut

            // Rotation animation
            let rotateLeft = SKAction.rotate(byAngle: .pi / 4, duration: 0.2)
            let rotateRight = SKAction.rotate(byAngle: -.pi / 2, duration: 0.2)
            let rotateBack = SKAction.rotate(byAngle: .pi / 4, duration: 0.1)
            let rotation = SKAction.sequence([rotateLeft, rotateRight, rotateBack])

            // Fade in
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)

            // Combine animations
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown, scaleNormal])
            let group = SKAction.group([scaleSequence, rotation, fadeIn])

            node.run(group)

            // Add particle burst effect
            addBirthParticles(at: organism.position, color: color)

            // Add expanding glow ring
            addGlowRing(at: organism.position, color: color)
        }

        organismNodes[organism.id] = node
        addChild(node)
    }

    private func removeOrganism(_ organism: Organism, animated: Bool = false) {
        if let node = organismNodes[organism.id] {
            if animated {
                // Get organism color for particles
                let color = organism.color

                // Dramatic spin and shrink
                let spin = SKAction.rotate(byAngle: .pi * 4, duration: 0.6)
                let shrink = SKAction.scale(to: 0.01, duration: 0.6)
                shrink.timingMode = .easeIn

                // Fade with color shift to darker
                let fadeOut = SKAction.fadeOut(withDuration: 0.6)

                // Combine animations
                let group = SKAction.group([spin, shrink, fadeOut])
                let remove = SKAction.removeFromParent()

                node.run(SKAction.sequence([group, remove]))

                // Add death particles
                addDeathParticles(at: organism.position, color: color)

                // Add implosion ring effect
                addImplosionRing(at: organism.position, color: color)
            } else {
                node.removeFromParent()
            }
            organismNodes.removeValue(forKey: organism.id)
        }
    }

    // MARK: - Food Management
    private func addFood(_ foodItem: Food, animated: Bool = true) {
        food.append(foodItem)

        let foodSize = CGFloat(configuration.foodSize)
        let node = SKShapeNode(rectOf: CGSize(width: foodSize, height: foodSize))
        node.fillColor = .green
        node.strokeColor = .clear
        node.position = foodItem.position

        if animated {
            // Start from above and drop down
            let startY = foodItem.position.y + 100
            node.position = CGPoint(x: foodItem.position.x, y: startY)
            node.alpha = 0
            node.setScale(0.5)

            // Drop animation with bounce
            let moveDown = SKAction.move(to: foodItem.position, duration: 0.4)
            moveDown.timingMode = .easeOut

            // Bounce effect
            let bounceUp = SKAction.moveBy(x: 0, y: 5, duration: 0.1)
            let bounceDown = SKAction.moveBy(x: 0, y: -5, duration: 0.1)
            let bounce = SKAction.sequence([bounceUp, bounceDown])

            // Scale and fade
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)

            // Rotation for interest
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)

            // Combine
            let moveSequence = SKAction.sequence([moveDown, bounce])
            let scaleSequence = SKAction.sequence([scaleUp, scaleNormal])
            let group = SKAction.group([moveSequence, scaleSequence, fadeIn, rotate])

            node.run(group)

            // Add sparkle effect
            addSparkles(at: foodItem.position)
        }

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
        label.setScale(0.3)

        addChild(label)

        // Create dramatic entrance with multiple effects
        let fadeIn = SKAction.fadeIn(withDuration: 0.4)
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.4)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        scaleDown.timingMode = .easeInEaseOut

        // Rotation for drama
        let rotateIn = SKAction.rotate(byAngle: .pi / 8, duration: 0.4)
        let rotateBack = SKAction.rotate(byAngle: -.pi / 8, duration: 0.2)

        // Color pulse
        let colorize = SKAction.colorize(with: .cyan, colorBlendFactor: 0.5, duration: 0.3)
        let uncolorize = SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)

        // Entrance sequence
        let entrance = SKAction.group([
            fadeIn,
            SKAction.sequence([scaleUp, scaleDown]),
            SKAction.sequence([rotateIn, rotateBack]),
            SKAction.sequence([colorize, uncolorize])
        ])

        // Wait and exit
        let wait = SKAction.wait(forDuration: 0.6)

        // Dramatic exit
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let scaleOut = SKAction.scale(to: 2.0, duration: 0.4)
        scaleOut.timingMode = .easeIn
        let exit = SKAction.group([fadeOut, scaleOut])

        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([entrance, wait, exit, remove])

        label.run(sequence)

        // Add expanding circle effect
        addDayTransitionRing(at: CGPoint(x: size.width / 2, y: size.height / 2))
    }

    private func showDramaticReproduction(parent: Organism, child: Organism, childPosition: CGPoint) {
        guard let parentNode = organismNodes[parent.id] else { return }

        let parentPosition = parent.position

        // PHASE 1: Gradual buildup (0.6s) - parent grows and glows
        let buildupDuration = 0.6

        // Growing glow effect around parent
        for i in 0..<5 {
            let delay = Double(i) * 0.12
            let glowRing = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius))
            glowRing.strokeColor = .cyan
            glowRing.lineWidth = 2
            glowRing.fillColor = .clear
            glowRing.position = parentPosition
            glowRing.alpha = 0
            glowRing.zPosition = 4
            glowRing.glowWidth = 15

            addChild(glowRing)

            let wait = SKAction.wait(forDuration: delay)
            let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.8, duration: 0.5)
            scaleUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let group = SKAction.group([scaleUp, fadeOut])
            let remove = SKAction.removeFromParent()

            glowRing.run(SKAction.sequence([wait, fadeIn, group, remove]))
        }

        // Parent node grows and pulses
        let parentGrow = SKAction.scale(to: 1.5, duration: buildupDuration)
        parentGrow.timingMode = .easeInEaseOut

        // Pulsing brightness effect
        let brighten = SKAction.colorize(with: .white, colorBlendFactor: 0.4, duration: buildupDuration)
        brighten.timingMode = .easeIn

        let buildupGroup = SKAction.group([parentGrow, brighten])

        // PHASE 2: POP! (0.2s) - dramatic burst
        let popDelay = SKAction.wait(forDuration: buildupDuration)

        // Create massive explosion of particles
        let popAction = SKAction.run { [weak self] in
            guard let self = self else { return }

            // Flash effect
            let flash = SKShapeNode(circleOfRadius: CGFloat(self.configuration.organismRadius) * 3)
            flash.fillColor = .white
            flash.strokeColor = .clear
            flash.position = parentPosition
            flash.alpha = 0
            flash.zPosition = 20
            flash.setScale(0.5)

            self.addChild(flash)

            let flashIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
            let flashScale = SKAction.scale(to: 2.0, duration: 0.15)
            let flashOut = SKAction.fadeOut(withDuration: 0.1)
            let flashGroup = SKAction.group([flashScale, SKAction.sequence([flashIn, flashOut])])
            flash.run(SKAction.sequence([flashGroup, SKAction.removeFromParent()]))

            // Explosion particles
            for _ in 0..<30 {
                let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
                particle.fillColor = SKColor(
                    red: CGFloat.random(in: 0.5...1.0),
                    green: CGFloat.random(in: 0.8...1.0),
                    blue: 1.0,
                    alpha: 1.0
                )
                particle.strokeColor = .white
                particle.lineWidth = 1
                particle.position = parentPosition
                particle.zPosition = 15
                particle.glowWidth = 5

                self.addChild(particle)

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 50...100)
                let endX = parentPosition.x + cos(angle) * distance
                let endY = parentPosition.y + sin(angle) * distance

                let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.5)
                move.timingMode = .easeOut
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let spin = SKAction.rotate(byAngle: .pi * CGFloat.random(in: 2...6), duration: 0.5)
                let shrink = SKAction.scale(to: 0.1, duration: 0.5)
                let group = SKAction.group([move, fadeOut, spin, shrink])

                particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
            }

            // Multiple expanding shockwave rings
            for i in 0..<4 {
                let delay = Double(i) * 0.05
                let shockwave = SKShapeNode(circleOfRadius: CGFloat(self.configuration.organismRadius))
                shockwave.strokeColor = .cyan
                shockwave.lineWidth = 4
                shockwave.fillColor = .clear
                shockwave.position = parentPosition
                shockwave.alpha = 0
                shockwave.zPosition = 18
                shockwave.glowWidth = 20

                self.addChild(shockwave)

                let wait = SKAction.wait(forDuration: delay)
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
                let expand = SKAction.scale(to: 5.0, duration: 0.4)
                expand.timingMode = .easeOut
                let fadeOut = SKAction.fadeOut(withDuration: 0.4)
                let group = SKAction.group([expand, fadeOut])

                shockwave.run(SKAction.sequence([wait, fadeIn, group, SKAction.removeFromParent()]))
            }
        }

        // PHASE 3: Split (0.4s) - organisms fly apart
        let splitDelay = SKAction.wait(forDuration: 0.15)
        let splitAction = SKAction.run { [weak self] in
            guard let self = self else { return }

            // Add child organism now
            self.addOrganism(child, animated: false)

            guard let childNode = self.organismNodes[child.id] else { return }

            // Calculate direction vector from parent to child
            let dx = childPosition.x - parentPosition.x
            let dy = childPosition.y - parentPosition.y
            let distance = sqrt(dx * dx + dy * dy)
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance

            // Start both at parent position
            childNode.position = parentPosition
            childNode.setScale(0.3)
            childNode.alpha = 0

            // Push parent backward
            let parentPushDistance: CGFloat = 20
            let parentPushX = parentPosition.x - normalizedDx * parentPushDistance
            let parentPushY = parentPosition.y - normalizedDy * parentPushDistance
            let parentPush = SKAction.move(to: CGPoint(x: parentPushX, y: parentPushY), duration: 0.2)
            parentPush.timingMode = .easeOut
            let parentReturn = SKAction.move(to: parentPosition, duration: 0.3)
            parentReturn.timingMode = .easeInEaseOut

            // Parent returns to normal size
            let parentShrink = SKAction.scale(to: 1.0, duration: 0.3)
            parentShrink.timingMode = .easeOut
            let parentUncolorize = SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)

            let parentSequence = SKAction.sequence([
                parentPush,
                SKAction.group([parentReturn, parentShrink, parentUncolorize])
            ])

            parentNode.run(parentSequence)

            // Child flies to position
            let childFadeIn = SKAction.fadeIn(withDuration: 0.1)
            let childGrowInitial = SKAction.scale(to: 0.8, duration: 0.2)
            childGrowInitial.timingMode = .easeOut
            let childMove = SKAction.move(to: childPosition, duration: 0.3)
            childMove.timingMode = .easeOut

            // Child bounces into final position
            let childBounceGrow = SKAction.scale(to: 1.3, duration: 0.15)
            let childBounceShrink = SKAction.scale(to: 1.0, duration: 0.2)
            childBounceShrink.timingMode = .easeInEaseOut

            // Spinning during flight
            let childSpin = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)

            let childSequence = SKAction.sequence([
                SKAction.group([childFadeIn, childGrowInitial]),
                SKAction.group([childMove, childSpin]),
                SKAction.sequence([childBounceGrow, childBounceShrink])
            ])

            childNode.run(childSequence)

            // Trail particles between parent and child
            for i in 0..<15 {
                let delay = Double(i) * 0.03
                let trailParticle = SKShapeNode(circleOfRadius: 3)
                trailParticle.fillColor = .cyan
                trailParticle.strokeColor = .white
                trailParticle.lineWidth = 1
                trailParticle.position = parentPosition
                trailParticle.alpha = 0
                trailParticle.zPosition = 10
                trailParticle.glowWidth = 5

                self.addChild(trailParticle)

                let wait = SKAction.wait(forDuration: delay)
                let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.1)
                let moveToChild = SKAction.move(to: childPosition, duration: 0.3)
                moveToChild.timingMode = .easeOut
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let shrink = SKAction.scale(to: 0.1, duration: 0.5)

                trailParticle.run(SKAction.sequence([
                    wait,
                    fadeIn,
                    SKAction.group([moveToChild, fadeOut, shrink]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        // Combine all phases
        let fullSequence = SKAction.sequence([
            buildupGroup,
            popDelay,
            popAction,
            splitDelay,
            splitAction
        ])

        parentNode.run(fullSequence)
    }

    private func showReproductionAnimation(from parentPosition: CGPoint, to childPosition: CGPoint) {
        // Animated energy beam from parent to child
        let path = CGMutablePath()
        path.move(to: parentPosition)
        path.addLine(to: childPosition)

        let line = SKShapeNode(path: path)
        line.strokeColor = .cyan
        line.lineWidth = 3
        line.alpha = 0
        line.zPosition = 5
        line.glowWidth = 10

        addChild(line)

        // Animated line with pulse
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
        let pulse1 = SKAction.fadeAlpha(to: 0.5, duration: 0.1)
        let pulse2 = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let pulse3 = SKAction.fadeAlpha(to: 0.5, duration: 0.1)
        let pulse4 = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, pulse1, pulse2, pulse3, pulse4, fadeOut, remove])

        // Line width animation
        let thicken = SKAction.customAction(withDuration: 0.4) { node, time in
            if let shapeLine = node as? SKShapeNode {
                shapeLine.lineWidth = 3 + sin(time * 10) * 2
            }
        }

        line.run(sequence)
        line.run(thicken)

        // Multiple expanding rings at parent
        for i in 0..<3 {
            let delay = Double(i) * 0.15
            let pulse = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius) * 1.5)
            pulse.strokeColor = .cyan
            pulse.lineWidth = 3
            pulse.fillColor = .clear
            pulse.position = parentPosition
            pulse.alpha = 0
            pulse.zPosition = 5
            pulse.glowWidth = 8

            addChild(pulse)

            let wait = SKAction.wait(forDuration: delay)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 3.0, duration: 0.5)
            scaleUp.timingMode = .easeOut
            let pulseOut = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([scaleUp, pulseOut])
            let removeRing = SKAction.removeFromParent()

            pulse.run(SKAction.sequence([wait, fadeIn, group, removeRing]))
        }

        // Sparkle at child position
        addReproductionSparkles(at: childPosition)

        // Energy particles traveling from parent to child
        addEnergyParticles(from: parentPosition, to: childPosition)
    }

    // MARK: - Particle Effects
    private func addBirthParticles(at position: CGPoint, color: (red: Double, green: Double, blue: Double)) {
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1.0)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 10

            addChild(particle)

            // Random direction
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...60)
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.6)
            let fadeOut = SKAction.fadeOut(withDuration: 0.6)
            let shrink = SKAction.scale(to: 0.1, duration: 0.6)
            let group = SKAction.group([move, fadeOut, shrink])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
        }
    }

    private func addGlowRing(at position: CGPoint, color: (red: Double, green: Double, blue: Double)) {
        let ring = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius))
        ring.strokeColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 0.8)
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.position = position
        ring.zPosition = 8
        ring.glowWidth = 10

        addChild(ring)

        let scaleUp = SKAction.scale(to: 3.0, duration: 0.5)
        scaleUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([scaleUp, fadeOut])
        let remove = SKAction.removeFromParent()

        ring.run(SKAction.sequence([group, remove]))
    }

    private func addDeathParticles(at position: CGPoint, color: (red: Double, green: Double, blue: Double)) {
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1.0)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 10

            addChild(particle)

            // Explosive outward motion
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...80)
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            // Fast then slow
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.8)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let spin = SKAction.rotate(byAngle: .pi * CGFloat.random(in: 2...4), duration: 0.8)
            let group = SKAction.group([move, fadeOut, spin])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
        }
    }

    private func addImplosionRing(at position: CGPoint, color: (red: Double, green: Double, blue: Double)) {
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius) * 3)
            ring.strokeColor = SKColor(red: CGFloat(color.red * 0.5), green: CGFloat(color.green * 0.5), blue: CGFloat(color.blue * 0.5), alpha: 0.6)
            ring.lineWidth = 2
            ring.fillColor = .clear
            ring.position = position
            ring.zPosition = 8

            addChild(ring)

            let delay = Double(i) * 0.1
            let wait = SKAction.wait(forDuration: delay)
            let scaleDown = SKAction.scale(to: 0.1, duration: 0.5)
            scaleDown.timingMode = .easeIn
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([scaleDown, fadeOut])
            let remove = SKAction.removeFromParent()

            ring.run(SKAction.sequence([wait, group, remove]))
        }
    }

    private func addSparkles(at position: CGPoint) {
        for _ in 0..<8 {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = .yellow
            sparkle.strokeColor = .white
            sparkle.lineWidth = 1
            sparkle.position = position
            sparkle.zPosition = 15
            sparkle.alpha = 0

            addChild(sparkle)

            let delay = TimeInterval.random(in: 0...0.3)
            let wait = SKAction.wait(forDuration: delay)

            // Quick flash
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let flash = SKAction.sequence([fadeIn, fadeOut])

            // Small movement
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance: CGFloat = 15
            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.3)

            let group = SKAction.group([flash, move])
            let remove = SKAction.removeFromParent()

            sparkle.run(SKAction.sequence([wait, group, remove]))
        }
    }

    private func addFeedingCelebration(at position: CGPoint, color: (red: Double, green: Double, blue: Double)) {
        // Burst of colored particles
        for _ in 0..<15 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1.0)
            particle.strokeColor = .yellow
            particle.lineWidth = 1
            particle.position = position
            particle.zPosition = 12

            addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...40)
            let endX = position.x + cos(angle) * distance
            let endY = position.y + sin(angle) * distance

            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.4)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.1, duration: 0.4)
            let group = SKAction.group([move, fadeOut, scale])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
        }

        // Expanding success ring
        let ring = SKShapeNode(circleOfRadius: CGFloat(configuration.organismRadius))
        ring.strokeColor = .yellow
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.position = position
        ring.zPosition = 11
        ring.glowWidth = 8

        addChild(ring)

        let scaleUp = SKAction.scale(to: 2.5, duration: 0.4)
        scaleUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([scaleUp, fadeOut])
        let remove = SKAction.removeFromParent()

        ring.run(SKAction.sequence([group, remove]))
    }

    private func addDayTransitionRing(at position: CGPoint) {
        for i in 0..<4 {
            let ring = SKShapeNode(circleOfRadius: 50)
            ring.strokeColor = .white
            ring.lineWidth = 3
            ring.fillColor = .clear
            ring.position = position
            ring.zPosition = 999
            ring.alpha = 0
            ring.glowWidth = 15

            addChild(ring)

            let delay = Double(i) * 0.2
            let wait = SKAction.wait(forDuration: delay)
            let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.2)
            let scaleUp = SKAction.scale(to: 8.0, duration: 1.2)
            scaleUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.6)
            let scaleAndFade = SKAction.group([scaleUp, fadeOut])
            let remove = SKAction.removeFromParent()

            ring.run(SKAction.sequence([wait, fadeIn, scaleAndFade, remove]))
        }
    }

    private func addReproductionSparkles(at position: CGPoint) {
        for _ in 0..<10 {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = .cyan
            sparkle.strokeColor = .white
            sparkle.lineWidth = 1
            sparkle.position = position
            sparkle.zPosition = 15
            sparkle.alpha = 0

            addChild(sparkle)

            let delay = TimeInterval.random(in: 0...0.2)
            let wait = SKAction.wait(forDuration: delay)

            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let flash = SKAction.sequence([fadeIn, fadeOut])

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance: CGFloat = 20
            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.4)

            let group = SKAction.group([flash, move])
            let remove = SKAction.removeFromParent()

            sparkle.run(SKAction.sequence([wait, group, remove]))
        }
    }

    private func addEnergyParticles(from start: CGPoint, to end: CGPoint) {
        for i in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = .cyan
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.position = start
            particle.zPosition = 6
            particle.alpha = 0
            particle.glowWidth = 5

            addChild(particle)

            let delay = Double(i) * 0.05
            let wait = SKAction.wait(forDuration: delay)

            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let move = SKAction.move(to: end, duration: 0.4)
            move.timingMode = .easeInEaseOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.1)
            let shrink = SKAction.scale(to: 0.3, duration: 0.5)

            let moveAndFade = SKAction.sequence([fadeIn, move, fadeOut])
            let group = SKAction.group([moveAndFade, shrink])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([wait, group, remove]))
        }
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
