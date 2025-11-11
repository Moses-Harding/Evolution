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
    private var obstacles: [Obstacle] = []
    private var temperatureZones: [TemperatureZone] = []
    private var terrainPatches: [TerrainPatch] = []
    private var species: [UUID: Species] = [:]  // Track all species by ID
    private var organismNodes: [UUID: SKShapeNode] = [:]
    private var senseRangeNodes: [UUID: SKShapeNode] = [:]  // Visual sense range indicators
    private var energyBarNodes: [UUID: (background: SKShapeNode, bar: SKShapeNode)] = [:]  // Energy bars
    private var trailNodes: [UUID: [SKShapeNode]] = [:]  // Movement trails
    private var foodNodes: [UUID: SKShapeNode] = [:]
    private var obstacleNodes: [UUID: SKShapeNode] = [:]
    private var temperatureZoneNodes: [UUID: SKShapeNode] = [:]
    private var terrainNodes: [UUID: SKShapeNode] = [:]
    private var corpsePositions: [CGPoint] = []  // Store positions of dead organisms

    // Selection
    private var selectedOrganismId: UUID?
    private var selectionIndicator: SKShapeNode?

    // Drag state for obstacles
    private var draggedObstacle: Obstacle?
    private var dragPreview: SKShapeNode?
    private var dragStartPosition: CGPoint?
    private var isCreatingNewObstacle: Bool = false

    private var currentDay: Int = 0
    private var currentSeason: Season = .spring
    private var currentWeather: WeatherEvent = WeatherEvent(type: .clear)
    private var dayNightProgress: Double = 0.0  // 0.0 = midnight, 0.5 = noon, 1.0 = midnight
    var showSenseRanges: Bool = true  // Toggle for sense range visualization
    var showTrails: Bool = true  // Toggle for movement trails
    private let maxTrailLength: Int = 20  // Maximum trail segments per organism
    var showEliteHighlights: Bool = false  // Toggle for elite organism highlighting (disabled by default)
    private var dayNightOverlay: SKShapeNode?  // Visual overlay for day/night
    private var weatherOverlay: SKShapeNode?  // Visual overlay for weather effects

    // Obstacle placement mode
    var isPlacingObstacles: Bool = false
    var currentObstacleType: ObstacleType = .wall

    // Food distribution patterns
    enum FoodPattern {
        case random      // Completely random
        case clustered   // Food spawns in clusters
        case scattered   // Food maximally spread out
        case ring        // Food spawns in a ring pattern
    }
    private var currentFoodPattern: FoodPattern = .random
    private let patternChangeInterval: Int = 10  // Change pattern every N days

    // Speed control
    var timeScale: Double = 1.0  // Can be set to 2.0 for super speed

    // MARK: - Statistics
    var statistics: GameStatistics = GameStatistics()

    // MARK: - Publishers
    let statisticsPublisher = PassthroughSubject<GameStatistics, Never>()
    let selectedOrganismPublisher = PassthroughSubject<Organism?, Never>()

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

        // Enable user interaction for tap detection
        isUserInteractionEnabled = true

        // Configure view for background execution
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = false

        setupInitialPopulation()
        spawnFood()
        spawnTemperatureZones()
        spawnTerrainPatches()
        setupDayNightOverlay()
        setupWeatherOverlay()
        updateStatistics()
        // Legend is now shown on demand via button
    }

    // MARK: - Playable Bounds and Safe Areas
    private var safeAreaInsets: UIEdgeInsets = .zero
    private let margin: CGFloat = 20

    private var playableMinX: CGFloat {
        return safeAreaInsets.left + margin
    }

    private var playableMaxX: CGFloat {
        return size.width - safeAreaInsets.right - margin
    }

    private var playableMinY: CGFloat {
        return safeAreaInsets.bottom + margin  // SpriteKit origin is bottom-left
    }

    private var playableMaxY: CGFloat {
        return size.height - safeAreaInsets.top - margin
    }

    // MARK: - Layout Updates
    func updateLayoutForNewSize(_ newSize: CGSize, safeAreaInsets: UIEdgeInsets = .zero) {
        // Update safe area insets
        self.safeAreaInsets = safeAreaInsets

        // Update legend position to respect safe area
        if let legend = childNode(withName: "legend") {
            // Position legend below safe area (accounting for top safe area)
            let legendX = newSize.width - safeAreaInsets.right - 120
            let legendY = newSize.height - safeAreaInsets.top - 80
            legend.position = CGPoint(x: legendX, y: legendY)
        }

        // Reposition any organisms that are now out of bounds
        for organism in organisms {
            if organism.position.x < playableMinX || organism.position.x > playableMaxX ||
               organism.position.y < playableMinY || organism.position.y > playableMaxY {
                // Clamp position to playable bounds
                organism.position.x = max(playableMinX, min(playableMaxX, organism.position.x))
                organism.position.y = max(playableMinY, min(playableMaxY, organism.position.y))

                // Update the visual node
                if let node = organismNodes[organism.id] {
                    node.position = organism.position
                }
            }
        }

        // Reposition any food that is now out of bounds
        for foodItem in food {
            if foodItem.position.x < playableMinX || foodItem.position.x > playableMaxX ||
               foodItem.position.y < playableMinY || foodItem.position.y > playableMaxY {
                // Clamp position to playable bounds
                foodItem.position.x = max(playableMinX, min(playableMaxX, foodItem.position.x))
                foodItem.position.y = max(playableMinY, min(playableMaxY, foodItem.position.y))

                // Update the visual node
                if let node = foodNodes[foodItem.id] {
                    node.position = foodItem.position
                }
            }
        }
    }

    private func showLegend() {
        // Remove existing legend if any
        childNode(withName: "legend")?.removeFromParent()

        let legend = SKNode()
        legend.name = "legend"
        legend.zPosition = 100

        // Position in top right corner
        let legendX = size.width - 120
        let legendY = size.height - 80
        legend.position = CGPoint(x: legendX, y: legendY)

        // Create semi-transparent background
        let background = SKShapeNode(rectOf: CGSize(width: 240, height: 200), cornerRadius: 8)
        background.fillColor = SKColor(white: 0.0, alpha: 0.8)
        background.strokeColor = SKColor(white: 0.4, alpha: 0.9)
        background.lineWidth = 2
        legend.addChild(background)

        // Title
        let title = SKLabelNode(text: "KEY")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = .cyan
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -110, y: 90)
        legend.addChild(title)

        // Helper to add legend items
        var yPos: CGFloat = 65
        func addLegendItem(color: SKColor, shape: String = "circle", text: String) {
            // Create indicator based on shape
            let indicator: SKShapeNode
            if shape == "circle" {
                indicator = SKShapeNode(circleOfRadius: 6)
                indicator.fillColor = color
                indicator.strokeColor = .white
                indicator.lineWidth = 1
            } else if shape == "square" {
                indicator = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
                indicator.fillColor = color
                indicator.strokeColor = .white
                indicator.lineWidth = 1
            } else { // rectangle
                indicator = SKShapeNode(rectOf: CGSize(width: 14, height: 8))
                indicator.fillColor = color
                indicator.strokeColor = .white
                indicator.lineWidth = 1
            }
            indicator.position = CGPoint(x: -105, y: yPos)
            legend.addChild(indicator)

            // Text label
            let label = SKLabelNode(text: text)
            label.fontName = "Courier"
            label.fontSize = 9
            label.fontColor = .white
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: -90, y: yPos - 3)
            legend.addChild(label)

            yPos -= 16
        }

        // Organisms
        addLegendItem(color: .blue, text: "Slow organism")
        addLegendItem(color: .red, text: "Fast organism")
        addLegendItem(color: .green, text: "Food resource")
        addLegendItem(color: SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.4), text: "Sense range (tapped)")

        // Obstacles
        addLegendItem(color: .gray, shape: "rectangle", text: "Wall (blocks)")
        addLegendItem(color: SKColor.brown, shape: "circle", text: "Rock (blocks)")
        addLegendItem(color: .red, shape: "square", text: "Hazard (kills)")

        // Add instructions at bottom
        let instructionText = """
        Tap organism to see stats
        and sense range
        """
        let instructions = SKLabelNode(text: instructionText)
        instructions.fontName = "Courier"
        instructions.fontSize = 8
        instructions.fontColor = .gray
        instructions.horizontalAlignmentMode = .center
        instructions.numberOfLines = 2
        instructions.position = CGPoint(x: 0, y: -95)
        legend.addChild(instructions)

        addChild(legend)
    }

    private func setupInitialPopulation() {
        for _ in 0..<configuration.initialPopulation {
            // Use playable bounds, or default if not yet set
            let minX = playableMinX > 0 ? playableMinX : 50
            let maxX = playableMaxX > minX ? playableMaxX : size.width - 50
            let minY = playableMinY > 0 ? playableMinY : 50
            let maxY = playableMaxY > minY ? playableMaxY : size.height - 50

            let randomX = CGFloat.random(in: minX...max(minX + 1, maxX))
            let randomY = CGFloat.random(in: minY...max(minY + 1, maxY))

            // Create founder organism (each starts its own species)
            let organism = Organism(
                speed: configuration.initialSpeed,
                senseRange: configuration.initialSenseRange,
                size: configuration.initialSize,
                fertility: configuration.initialFertility,
                energyEfficiency: configuration.initialEnergyEfficiency,
                maxAge: configuration.initialMaxAge,
                aggression: configuration.initialAggression,
                defense: configuration.initialDefense,
                metabolism: configuration.initialMetabolism,
                heatTolerance: configuration.initialHeatTolerance,
                coldTolerance: configuration.initialColdTolerance,
                position: CGPoint(x: randomX, y: randomY),
                generation: 0,
                configuration: configuration
            )

            // Create species for this organism
            registerSpecies(for: organism, foundedOnDay: 0)
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

        // Change food pattern periodically
        if currentDay > 0 && currentDay % patternChangeInterval == 0 {
            rotateFoodPattern()
        }

        // First, spawn food at corpse positions (corpses from previous day)
        for corpsePosition in corpsePositions {
            let foodItem = Food(position: corpsePosition)
            addFood(foodItem)
        }
        corpsePositions.removeAll()  // Clear corpse positions after spawning

        // Calculate seasonal food amount
        let seasonalFoodCount = getSeasonalFoodCount()

        // Then spawn regular food items based on current pattern
        let positions = generateFoodPositions(count: seasonalFoodCount, pattern: currentFoodPattern)
        for position in positions {
            let foodItem = Food(position: position)
            addFood(foodItem)
        }
    }

    private func rotateFoodPattern() {
        let patterns: [FoodPattern] = [.random, .clustered, .scattered, .ring]
        if let currentIndex = patterns.firstIndex(of: currentFoodPattern) {
            let nextIndex = (currentIndex + 1) % patterns.count
            currentFoodPattern = patterns[nextIndex]

            // Show pattern change notification
            showPatternChangeNotification()
        }
    }

    private func generateFoodPositions(count: Int, pattern: FoodPattern) -> [CGPoint] {
        var positions: [CGPoint] = []

        // Use playable bounds
        let minX = playableMinX > 0 ? playableMinX : 30
        let maxX = playableMaxX > minX ? playableMaxX : size.width - 30
        let minY = playableMinY > 0 ? playableMinY : 30
        let maxY = playableMaxY > minY ? playableMaxY : size.height - 30

        // If scene is too small, just return center positions
        if maxX <= minX || maxY <= minY {
            for _ in 0..<count {
                positions.append(CGPoint(x: size.width / 2, y: size.height / 2))
            }
            return positions
        }

        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        switch pattern {
        case .random:
            for _ in 0..<count {
                let x = CGFloat.random(in: minX...maxX)
                let y = CGFloat.random(in: minY...maxY)
                positions.append(CGPoint(x: x, y: y))
            }

        case .clustered:
            // Create 2-3 clusters
            let clusterCount = Int.random(in: 2...3)
            let itemsPerCluster = count / clusterCount

            for _ in 0..<clusterCount {
                let clusterX = CGFloat.random(in: minX...maxX)
                let clusterY = CGFloat.random(in: minY...maxY)
                let clusterRadius: CGFloat = min(80, (maxX - minX) / 4, (maxY - minY) / 4)

                for _ in 0..<itemsPerCluster {
                    let angle = CGFloat.random(in: 0...(2 * .pi))
                    let radius = CGFloat.random(in: 0...clusterRadius)
                    let x = clusterX + cos(angle) * radius
                    let y = clusterY + sin(angle) * radius
                    let clampedX = max(minX, min(maxX, x))
                    let clampedY = max(minY, min(maxY, y))
                    positions.append(CGPoint(x: clampedX, y: clampedY))
                }
            }

            // Add remaining items randomly
            for _ in positions.count..<count {
                let x = CGFloat.random(in: minX...maxX)
                let y = CGFloat.random(in: minY...maxY)
                positions.append(CGPoint(x: x, y: y))
            }

        case .scattered:
            // Divide area into grid and place one item per cell
            let cols = max(1, Int(sqrt(Double(count))))
            let rows = max(1, (count + cols - 1) / cols)
            let cellWidth = max(1, (maxX - minX) / CGFloat(cols))
            let cellHeight = max(1, (maxY - minY) / CGFloat(rows))

            for i in 0..<count {
                let col = i % cols
                let row = i / cols
                let cellX = minX + CGFloat(col) * cellWidth
                let cellY = minY + CGFloat(row) * cellHeight
                let x = cellX + CGFloat.random(in: 0...min(cellWidth, maxX - cellX))
                let y = cellY + CGFloat.random(in: 0...min(cellHeight, maxY - cellY))
                positions.append(CGPoint(x: x, y: y))
            }

        case .ring:
            // Spawn food in a ring around the center
            let radius = min(maxX - minX, maxY - minY) / 3
            for i in 0..<count {
                let angle = (2 * .pi * CGFloat(i)) / CGFloat(count)
                let radiusVariation = CGFloat.random(in: -min(30, radius/2)...min(30, radius/2))
                let x = centerX + cos(angle) * (radius + radiusVariation)
                let y = centerY + sin(angle) * (radius + radiusVariation)
                let clampedX = max(minX, min(maxX, x))
                let clampedY = max(minY, min(maxY, y))
                positions.append(CGPoint(x: clampedX, y: clampedY))
            }
        }

        return positions
    }

    private func showPatternChangeNotification() {
        let patternName: String
        switch currentFoodPattern {
        case .random: patternName = "Random"
        case .clustered: patternName = "Clustered"
        case .scattered: patternName = "Scattered"
        case .ring: patternName = "Ring"
        }

        let label = SKLabelNode(text: "Environment: \(patternName)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 24
        label.fontColor = .cyan
        // Position below safe area
        let centerX = (playableMinX + playableMaxX) / 2
        let topY = playableMaxY > 0 ? playableMaxY - 30 : size.height - 50
        label.position = CGPoint(x: centerX, y: topY)
        label.zPosition = 1000
        label.alpha = 0

        addChild(label)

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    // MARK: - Day/Night Cycle
    private func setupDayNightOverlay() {
        // Create overlay that covers entire scene
        dayNightOverlay = SKShapeNode(rectOf: size)
        guard let overlay = dayNightOverlay else { return }

        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0.0
        overlay.zPosition = 100  // Above everything except UI
        overlay.isUserInteractionEnabled = false

        addChild(overlay)
    }

    private func updateDayNightCycle(deltaTime: Double) {
        guard configuration.dayNightCycleEnabled else { return }

        // Progress through day/night cycle
        dayNightProgress += deltaTime / configuration.dayNightCycleDuration
        dayNightProgress = dayNightProgress.truncatingRemainder(dividingBy: 1.0)

        // Update visual overlay
        updateDayNightVisuals()
    }

    private func updateDayNightVisuals() {
        guard let overlay = dayNightOverlay else { return }

        // Calculate darkness level based on time of day
        // 0.0 (midnight) = darkest, 0.5 (noon) = brightest
        let darknessLevel = getDarknessLevel()
        overlay.alpha = darknessLevel * 0.5  // Max 50% opacity at midnight
    }

    private func getDarknessLevel() -> Double {
        // Smooth transition using cosine
        // dayNightProgress: 0.0 = midnight, 0.5 = noon, 1.0 = midnight
        // Returns: 0.0 = full brightness (noon), 1.0 = full darkness (midnight)
        let angle = dayNightProgress * 2.0 * .pi
        let brightness = (cos(angle) + 1.0) / 2.0  // 0.0 at midnight, 1.0 at noon
        return 1.0 - brightness
    }

    private func isNightTime() -> Bool {
        let darknessLevel = getDarknessLevel()
        return darknessLevel > 0.3  // Night if more than 30% dark
    }

    private func getEffectiveSenseRange(for organism: Organism) -> Int {
        var multiplier = 1.0

        // Apply night time modifier
        if isNightTime() && configuration.dayNightCycleEnabled {
            multiplier *= configuration.nightSenseRangeMultiplier
        }

        // Apply weather visibility modifier
        multiplier *= getWeatherVisibilityModifier()

        return Int(Double(organism.senseRange) * multiplier)
    }

    private func getDayNightEnergyMultiplier() -> Double {
        if isNightTime() && configuration.dayNightCycleEnabled {
            return configuration.nightEnergyMultiplier
        }
        return 1.0
    }

    // MARK: - Weather System
    private func setupWeatherOverlay() {
        // Create weather overlay that covers entire scene
        weatherOverlay = SKShapeNode(rectOf: size)
        guard let overlay = weatherOverlay else { return }

        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = currentWeather.type.overlayColor
        overlay.strokeColor = .clear
        overlay.zPosition = 99  // Below day/night overlay but above everything else
        overlay.isUserInteractionEnabled = false

        addChild(overlay)
    }

    private func updateWeather() {
        // Decrement current weather duration
        currentWeather.decrementDay()

        // Check if weather has expired
        if currentWeather.isExpired {
            // Generate new weather event
            let weatherTypes = WeatherEventType.allCases
            let newWeatherType = weatherTypes.randomElement() ?? .clear
            currentWeather = WeatherEvent(type: newWeatherType)

            // Show weather transition
            showWeatherTransition()
            updateWeatherVisuals()
        }
    }

    private func updateWeatherVisuals() {
        guard let overlay = weatherOverlay else { return }

        // Animate overlay color change
        let colorChange = SKAction.customAction(withDuration: 1.0) { [weak self] node, elapsed in
            guard let self = self, let shape = node as? SKShapeNode else { return }
            let progress = elapsed / 1.0
            // Smoothly transition to new weather color
            let oldAlpha = shape.alpha
            let targetColor = self.currentWeather.type.overlayColor
            shape.fillColor = targetColor
            shape.alpha = oldAlpha * (1.0 - progress) + targetColor.components.alpha * progress
        }

        overlay.run(colorChange)
    }

    private func showWeatherTransition() {
        let label = SKLabelNode(text: "\(currentWeather.type.emoji) \(currentWeather.type.rawValue)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 28
        label.fontColor = .white
        let centerX = (playableMinX + playableMaxX) / 2
        let middleY = (playableMinY + playableMaxY) / 2
        label.position = CGPoint(x: centerX, y: middleY)
        label.zPosition = 1000
        label.alpha = 0

        addChild(label)

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    private func getWeatherVisibilityModifier() -> Double {
        return currentWeather.type.visibilityModifier
    }

    private func getWeatherMovementModifier() -> Double {
        return currentWeather.type.movementModifier
    }

    private func getWeatherTemperatureModifier() -> Double {
        return currentWeather.type.temperatureModifier
    }

    // MARK: - Seasonal System
    private func updateSeason() {
        guard configuration.seasonsEnabled else { return }

        let newSeason = getSeason(for: currentDay)
        if newSeason != currentSeason {
            currentSeason = newSeason
            showSeasonTransition()
        }
    }

    private func getSeason(for day: Int) -> Season {
        let dayInYear = day % (configuration.daysPerSeason * 4)
        let seasonIndex = dayInYear / configuration.daysPerSeason
        return Season.allCases[min(seasonIndex, 3)]
    }

    private func getSeasonalFoodCount() -> Int {
        guard configuration.seasonsEnabled else {
            return configuration.foodPerDay
        }

        let multiplier: Double
        switch currentSeason {
        case .spring: multiplier = configuration.springFoodMultiplier
        case .summer: multiplier = configuration.summerFoodMultiplier
        case .fall: multiplier = configuration.fallFoodMultiplier
        case .winter: multiplier = configuration.winterFoodMultiplier
        }

        return max(1, Int(Double(configuration.foodPerDay) * multiplier))
    }

    private func getSeasonalTemperatureOffset() -> Double {
        guard configuration.seasonsEnabled else { return 0.0 }

        switch currentSeason {
        case .spring: return 0.0
        case .summer: return configuration.summerTemperatureOffset
        case .fall: return 0.0
        case .winter: return configuration.winterTemperatureOffset
        }
    }

    private func showSeasonTransition() {
        let label = SKLabelNode(text: "\(currentSeason.emoji) \(currentSeason.rawValue)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 36
        label.fontColor = currentSeason.color
        let centerX = (playableMinX + playableMaxX) / 2
        let topY = playableMaxY > 0 ? playableMaxY - 80 : size.height - 100
        label.position = CGPoint(x: centerX, y: topY)
        label.zPosition = 1000
        label.alpha = 0
        label.setScale(0.5)

        addChild(label)

        // Dramatic entrance
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let entrance = SKAction.group([fadeIn, SKAction.sequence([scaleUp, scaleDown])])

        // Wait and exit
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let scaleOut = SKAction.scale(to: 1.5, duration: 0.5)
        let exit = SKAction.group([fadeOut, scaleOut])

        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([entrance, wait, exit, remove])

        label.run(sequence)
    }

    // MARK: - Species Management
    private func registerSpecies(for organism: Organism, foundedOnDay: Int) {
        // Check if species already exists
        if species[organism.speciesId] == nil {
            // Create new species
            let color = Species.generateColor(for: organism.speciesId)
            let traits = "\(organism.speed)-\(organism.senseRange)-\(Int(organism.size * 10))"
            let name = Species.generateName(generation: organism.generation, traits: traits)

            let newSpecies = Species(
                id: organism.speciesId,
                founderId: organism.id,
                name: name,
                color: color,
                foundedOnDay: foundedOnDay
            )

            species[organism.speciesId] = newSpecies
        }

        // Update population count
        species[organism.speciesId]?.population += 1
    }

    private func updateSpeciesPopulations() {
        // Reset all populations
        for speciesId in species.keys {
            species[speciesId]?.population = 0
        }

        // Count organisms in each species
        for organism in organisms {
            species[organism.speciesId]?.population += 1
        }

        // Mark extinct species
        for (speciesId, speciesData) in species {
            if speciesData.population == 0 && !speciesData.isExtinct {
                species[speciesId]?.extinctOnDay = currentDay
            }
        }
    }

    private func detectSpeciation(parent: Organism, child: Organism) -> Bool {
        guard configuration.speciationEnabled else { return false }

        // Check if child has diverged enough to form new species
        let distance = child.geneticDistance(to: parent)

        // If genetic distance exceeds threshold, child founds a new species
        if distance >= configuration.speciationThreshold {
            // Assign new species ID to child (child becomes founder)
            return true
        }

        return false
    }

    private func getSpeciesColor(for organism: Organism) -> SKColor {
        return species[organism.speciesId]?.color ?? Species.generateColor(for: organism.speciesId)
    }

    // MARK: - Terrain Management
    private func spawnTerrainPatches() {
        // Clear old terrain
        for node in terrainNodes.values {
            node.removeFromParent()
        }
        terrainPatches.removeAll()
        terrainNodes.removeAll()

        // Use playable bounds
        let minX = playableMinX > 0 ? playableMinX : 30
        let maxX = playableMaxX > minX ? playableMaxX : size.width - 30
        let minY = playableMinY > 0 ? playableMinY : 30
        let maxY = playableMaxY > minY ? playableMaxY : size.height - 30

        // Create 3-5 terrain patches of various types
        let patchCount = Int.random(in: 3...5)

        for _ in 0..<patchCount {
            let randomX = CGFloat.random(in: minX...maxX)
            let randomY = CGFloat.random(in: minY...maxY)
            let width = CGFloat.random(in: 80...180)
            let height = CGFloat.random(in: 80...180)

            // Random terrain type (excluding grass which is default)
            let nonGrassTypes: [TerrainType] = [.sand, .water, .mud, .rock]
            let randomType = nonGrassTypes.randomElement() ?? .sand

            let patch = TerrainPatch(
                position: CGPoint(x: randomX, y: randomY),
                size: CGSize(width: width, height: height),
                type: randomType
            )

            addTerrainPatch(patch)
        }
    }

    private func addTerrainPatch(_ patch: TerrainPatch) {
        terrainPatches.append(patch)

        // Create visual node for terrain patch
        let node = SKShapeNode(rectOf: patch.size, cornerRadius: 10)
        node.fillColor = patch.type.color
        node.strokeColor = patch.type.strokeColor
        node.lineWidth = 2
        node.position = patch.position
        node.zPosition = 0.3  // Below temperature zones but above background

        terrainNodes[patch.id] = node
        addChild(node)
    }

    private func getTerrainSpeedMultiplier(at position: CGPoint) -> Double {
        // Check all terrain patches at this position
        // If multiple patches overlap, use the most restrictive (lowest) multiplier
        var lowestMultiplier = 1.0

        for patch in terrainPatches {
            let multiplier = patch.speedMultiplierAt(position: position)
            if multiplier < lowestMultiplier {
                lowestMultiplier = multiplier
            }
        }

        return lowestMultiplier
    }

    // MARK: - Temperature Zone Management
    private func spawnTemperatureZones() {
        // Clear old zones
        for node in temperatureZoneNodes.values {
            node.removeFromParent()
        }
        temperatureZones.removeAll()
        temperatureZoneNodes.removeAll()

        // Use playable bounds
        let minX = playableMinX > 0 ? playableMinX : 30
        let maxX = playableMaxX > minX ? playableMaxX : size.width - 30
        let minY = playableMinY > 0 ? playableMinY : 30
        let maxY = playableMaxY > minY ? playableMaxY : size.height - 30

        // Create 2-4 temperature zones
        let zoneCount = Int.random(in: 2...4)

        for _ in 0..<zoneCount {
            let randomX = CGFloat.random(in: minX...maxX)
            let randomY = CGFloat.random(in: minY...maxY)
            let radius = CGFloat.random(in: 80...150)

            // Random temperature (hot or cold)
            let isHot = Bool.random()
            let temperature: Double
            if isHot {
                temperature = Double.random(in: 10...20)  // Hot zone
            } else {
                temperature = Double.random(in: -20...(-10))  // Cold zone
            }

            let zone = TemperatureZone(
                position: CGPoint(x: randomX, y: randomY),
                radius: radius,
                temperature: temperature,
                intensity: Double.random(in: 0.6...1.0)
            )

            addTemperatureZone(zone)
        }
    }

    private func addTemperatureZone(_ zone: TemperatureZone) {
        temperatureZones.append(zone)

        // Create visual node for temperature zone
        let node = SKShapeNode(circleOfRadius: zone.radius)

        // Color based on temperature
        if zone.temperature > 0 {
            // Hot zone - red/orange gradient
            let intensity = CGFloat(min(1.0, abs(zone.temperature) / 20.0))
            node.fillColor = SKColor(red: 1.0, green: 0.3 * (1.0 - intensity), blue: 0.0, alpha: 0.15)
            node.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.3)
        } else {
            // Cold zone - blue/cyan gradient
            let intensity = CGFloat(min(1.0, abs(zone.temperature) / 20.0))
            node.fillColor = SKColor(red: 0.0, green: 0.3 * (1.0 - intensity), blue: 1.0, alpha: 0.15)
            node.strokeColor = SKColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.3)
        }

        node.lineWidth = 2
        node.position = zone.position
        node.zPosition = 0.5  // Below organisms but above background

        // Add gentle pulsing animation
        let scaleUp = SKAction.scale(to: 1.05, duration: 2.0)
        let scaleDown = SKAction.scale(to: 0.95, duration: 2.0)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        let forever = SKAction.repeatForever(pulse)
        node.run(forever, withKey: "temperaturePulse")

        temperatureZoneNodes[zone.id] = node
        addChild(node)
    }

    private func getTemperatureAt(position: CGPoint) -> Double {
        // Start with base temperature + seasonal offset + weather modifier
        var totalTemperature = configuration.baseTemperature
            + getSeasonalTemperatureOffset()
            + getWeatherTemperatureModifier()

        // Add effects from all temperature zones
        for zone in temperatureZones {
            totalTemperature += zone.temperatureAt(position: position)
        }

        return totalTemperature
    }

    private func applyTemperatureEffects() {
        let dayNightMultiplier = getDayNightEnergyMultiplier()

        for organism in organisms {
            let currentTemp = getTemperatureAt(position: organism.position)
            let tempDifference = abs(currentTemp - configuration.baseTemperature)

            // Check for extreme temperature death
            if tempDifference > configuration.temperatureDeathThreshold {
                // Instant death from extreme temperature
                let isTooHot = currentTemp > configuration.baseTemperature
                let tolerance = isTooHot ? organism.heatTolerance : organism.coldTolerance

                // Tolerance reduces the effective temperature difference
                let effectiveDifference = tempDifference * (1.0 - tolerance)

                if effectiveDifference > configuration.temperatureDeathThreshold {
                    // Mark for death
                    organism.consumeEnergy(organism.energy)  // Drain all energy
                }
            } else if tempDifference > 0 {
                // Apply energy cost based on temperature and day/night
                let isTooHot = currentTemp > configuration.baseTemperature
                let tolerance = isTooHot ? organism.heatTolerance : organism.coldTolerance

                // Tolerance reduces energy cost
                let effectiveDifference = tempDifference * (1.0 - tolerance * 0.8)
                let energyCost = effectiveDifference * configuration.temperatureEnergyMultiplier * dayNightMultiplier

                organism.consumeEnergy(energyCost)
            }
        }
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = (1.0 / 60.0) * timeScale  // Apply time scale

        // Update day/night cycle
        updateDayNightCycle(deltaTime: deltaTime)

        // Check if day should end
        if shouldEndDay() {
            // End of day - handle reproduction and death
            print("DEBUG: Starting day transition from day \(currentDay)")
            endDay()
            currentDay += 1
            statistics.currentDay = currentDay
            updateSeason()  // Check for season change
            updateWeather()  // Check for weather change
            showDayTransition()
            spawnFood()
            resetOrganismsForNewDay()
        } else {
            // Continue movement and collision detection
            updateOrganisms(deltaTime: deltaTime)
            checkCollisions()
            checkHazardCollisions()
            applyTemperatureEffects()
            updateEnergyBars()
        }

        // Update selection indicator position
        if let selectedId = selectedOrganismId,
           let organism = organisms.first(where: { $0.id == selectedId }),
           let indicator = selectionIndicator {
            indicator.position = organism.position
        }
    }

    private func shouldEndDay() -> Bool {
        // Day ends when:
        // 1. All food is claimed, OR
        // 2. All organisms have eaten
        let foodClaimed = allFoodClaimed()
        let organismsFed = allOrganismsFed()
        let shouldEnd = foodClaimed || organismsFed

        if shouldEnd {
            print("DEBUG: Day \(currentDay) ending - Food claimed: \(foodClaimed), All fed: \(organismsFed)")
            print("DEBUG: Food status - Total: \(food.count), Claimed: \(food.filter { $0.isClaimed }.count)")
            print("DEBUG: Organism status - Total: \(organisms.count), Fed: \(organisms.filter { $0.hasFoodToday }.count)")
        }

        return shouldEnd
    }

    private func allOrganismsFed() -> Bool {
        // Need at least one organism, and all must have food
        return !organisms.isEmpty && organisms.allSatisfy { $0.hasFoodToday }
    }

    private func allFoodClaimed() -> Bool {
        return food.allSatisfy { $0.isClaimed }
    }

    private func updateOrganisms(deltaTime: TimeInterval) {
        let unclaimedFoodCount = food.filter { !$0.isClaimed }.count
        let organismCount = organisms.count

        // Log every 60 frames (once per second at 60 FPS)
        if Int(currentDay * 60) % 60 == 0 {
            print("DEBUG: Day \(currentDay) - Organisms: \(organismCount), Unclaimed food: \(unclaimedFoodCount)")
        }

        for organism in organisms {
            // Find nearest unclaimed food if no target
            if organism.targetFood == nil || organism.targetFood!.isClaimed {
                organism.targetFood = findNearestUnclaimedFood(for: organism)
            }

            // Move towards target food
            if let target = organism.targetFood, !organism.hasFoodToday {
                let oldPosition = organism.position
                let terrainMultiplier = getTerrainSpeedMultiplier(at: organism.position)
                let weatherMultiplier = getWeatherMovementModifier()
                let combinedMultiplier = terrainMultiplier * weatherMultiplier
                let (var newPosition, energyCost) = organism.move(towards: target.position, deltaTime: deltaTime, terrainMultiplier: combinedMultiplier)

                // Clamp to playable bounds
                newPosition.x = max(playableMinX, min(playableMaxX, newPosition.x))
                newPosition.y = max(playableMinY, min(playableMaxY, newPosition.y))

                // Check for obstacle collisions and adjust position if needed
                var collided = false
                for obstacle in obstacles {
                    if obstacle.collidesWith(organismPosition: newPosition, organismRadius: CGFloat(organism.effectiveRadius)) {
                        // Collision detected - revert to old position
                        newPosition = oldPosition
                        collided = true
                        // Clear target to find a new path next frame
                        organism.targetFood = nil
                        break
                    }
                }

                organism.position = newPosition

                // Consume energy only if actually moved
                if !collided {
                    organism.consumeEnergy(energyCost)
                }

                // Add trail segment if position changed significantly
                if showTrails {
                    let dx = newPosition.x - oldPosition.x
                    let dy = newPosition.y - oldPosition.y
                    let distance = sqrt(dx * dx + dy * dy)
                    if distance > 2.0 {  // Only add trail if moved at least 2 pixels
                        addTrailSegment(for: organism, from: oldPosition, to: newPosition)
                    }
                }

                // Update visual node
                if let node = organismNodes[organism.id] {
                    node.position = newPosition
                }

                // Update sense range indicator (position and size for day/night) - only for selected organism
                if let senseNode = senseRangeNodes[organism.id] {
                    senseNode.position = newPosition

                    // Update sense range size based on time of day
                    let effectiveSenseRange = getEffectiveSenseRange(for: organism)
                    let targetRadius = CGFloat(effectiveSenseRange)
                    if abs(senseNode.path?.boundingBox.width ?? 0 - targetRadius * 2) > 1.0 {
                        // Recreate node with new radius (animated transition would be smoother but more complex)
                        senseNode.removeFromParent()
                        let newSenseNode = SKShapeNode(circleOfRadius: targetRadius)
                        newSenseNode.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.5)
                        newSenseNode.lineWidth = 2
                        newSenseNode.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.1)
                        newSenseNode.position = newPosition
                        newSenseNode.zPosition = 1
                        senseRangeNodes[organism.id] = newSenseNode
                        addChild(newSenseNode)
                    }
                }

                // Update selection indicator position if this organism is selected
                if organism.id == selectedOrganismId {
                    selectionIndicator?.position = newPosition
                }
            }
        }
    }

    private func addTrailSegment(for organism: Organism, from: CGPoint, to: CGPoint) {
        // Create trail segment
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)

        let trail = SKShapeNode(path: path)
        let color = organism.color
        trail.strokeColor = SKColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 0.3)
        trail.lineWidth = 1.5
        trail.zPosition = 0.5

        addChild(trail)

        // Add to trail tracking
        if trailNodes[organism.id] == nil {
            trailNodes[organism.id] = []
        }
        trailNodes[organism.id]?.append(trail)

        // Fade out trail segment over time
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        trail.run(SKAction.sequence([fadeOut, remove]))

        // Remove old trail segments if too many
        if let trails = trailNodes[organism.id], trails.count > maxTrailLength {
            let oldTrail = trails.first
            oldTrail?.removeFromParent()
            trailNodes[organism.id]?.removeFirst()
        }
    }

    private func findNearestUnclaimedFood(for organism: Organism) -> Food? {
        var nearest: Food?
        var nearestDistance: CGFloat = .infinity
        let effectiveSenseRange = getEffectiveSenseRange(for: organism)
        let maxSenseDistance = CGFloat(effectiveSenseRange)

        for foodItem in food where !foodItem.isClaimed {
            let dx = foodItem.position.x - organism.position.x
            let dy = foodItem.position.y - organism.position.y
            let distance = sqrt(dx * dx + dy * dy)

            // Only consider food within sense range
            if distance <= maxSenseDistance && distance < nearestDistance {
                nearestDistance = distance
                nearest = foodItem
            }
        }

        return nearest
    }

    private func resolveFoodContest(for organism: Organism, food: Food) -> Organism {
        // Find all organisms within contest range of this food
        var contestants: [Organism] = []

        for other in organisms where !other.hasFoodToday {
            let dx = food.position.x - other.position.x
            let dy = food.position.y - other.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < configuration.foodContestRange {
                contestants.append(other)
            }
        }

        // If only one contestant, they win automatically
        if contestants.count <= 1 {
            return organism
        }

        // Multiple contestants - resolve with aggression vs defense
        var winner = contestants[0]
        var highestScore: Double = 0.0

        for contestant in contestants {
            // Calculate contest score: aggression + random factor - opponents' defense
            let aggressionBonus = contestant.aggression * 50  // 0-50 points from aggression
            let randomFactor = Double.random(in: 0...30)  // Random element
            let sizeBonus = (contestant.size - 1.0) * 10  // Larger organisms have advantage

            // Defense reduces others' effectiveness against this contestant
            let defenseReduction = (1.0 - contestant.defense) * 20  // 0-20 penalty

            let contestScore = aggressionBonus + randomFactor + sizeBonus - defenseReduction

            if contestScore > highestScore {
                highestScore = contestScore
                winner = contestant
            }
        }

        // Visual feedback for contest
        if winner.id != organism.id && contestants.contains(where: { $0.id == organism.id }) {
            // This organism lost the contest - show red flash
            if let node = organismNodes[organism.id] {
                let originalColor = node.fillColor
                node.fillColor = SKColor.red
                let resetColor = SKAction.run {
                    node.fillColor = originalColor
                }
                let wait = SKAction.wait(forDuration: 0.2)
                node.run(SKAction.sequence([wait, resetColor]))
            }
        }

        return winner
    }

    private func updateEnergyBars() {
        for organism in organisms {
            guard let energyBar = energyBarNodes[organism.id] else { continue }

            let barWidth: CGFloat = 20
            let barOffsetY: CGFloat = CGFloat(organism.effectiveRadius) + 5

            // Update positions
            energyBar.background.position = CGPoint(x: organism.position.x, y: organism.position.y + barOffsetY)
            energyBar.bar.position = CGPoint(x: organism.position.x, y: organism.position.y + barOffsetY)

            // Update bar width and color based on current energy
            let energyRatio = organism.energy / configuration.maxEnergy
            let currentBarWidth = barWidth * CGFloat(energyRatio)

            // Recreate the bar with new width
            energyBar.bar.removeFromParent()
            let newEnergyBar = SKShapeNode(rectOf: CGSize(width: currentBarWidth, height: 3))
            let energyColor = getEnergyColor(ratio: energyRatio)
            newEnergyBar.fillColor = energyColor
            newEnergyBar.strokeColor = .clear
            newEnergyBar.position = CGPoint(x: organism.position.x, y: organism.position.y + barOffsetY)
            newEnergyBar.zPosition = 12
            addChild(newEnergyBar)

            energyBarNodes[organism.id] = (background: energyBar.background, bar: newEnergyBar)
        }
    }

    private func checkCollisions() {
        for organism in organisms where !organism.hasFoodToday {
            if let target = organism.targetFood {
                let dx = target.position.x - organism.position.x
                let dy = target.position.y - organism.position.y
                let distance = sqrt(dx * dx + dy * dy)

                let collisionDistance = CGFloat(organism.effectiveRadius) + CGFloat(configuration.foodSize / 2)
                if distance < collisionDistance {
                    // Check for food contestation from nearby aggressive organisms
                    let winner = resolveFoodContest(for: organism, food: target)

                    if winner.id == organism.id {
                        // This organism won the food (or no contest)
                        organism.hasFoodToday = true
                        target.isClaimed = true

                        // Restore energy from eating
                        organism.gainEnergy(configuration.energyGainFromFood)

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

    private func checkHazardCollisions() {
        var organismsToRemove: [Organism] = []

        for organism in organisms {
            for obstacle in obstacles where obstacle.type == .hazard {
                if obstacle.collidesWith(organismPosition: organism.position, organismRadius: CGFloat(organism.effectiveRadius)) {
                    // Organism entered hazard - mark for removal
                    organismsToRemove.append(organism)
                    // Add death effect at hazard
                    addDeathParticles(at: organism.position, color: organism.color)
                    break
                }
            }
        }

        // Remove organisms that entered hazards
        for organism in organismsToRemove {
            removeOrganism(organism, animated: true)
        }
        organisms.removeAll { organism in
            organismsToRemove.contains { $0.id == organism.id }
        }
    }

    private func endDay() {
        var births = 0
        var deaths = 0
        corpsePositions.removeAll()  // Clear previous corpse positions

        // Age all organisms and apply metabolism cost
        for organism in organisms {
            organism.incrementAge()
            organism.consumeEnergy(configuration.metabolismEnergyCost)
        }

        // Handle reproduction for all organisms that ate today
        let fedOrganisms = organisms.filter { $0.hasFoodToday }
        for organism in fedOrganisms {
            if Double.random(in: 0...1) < organism.effectiveReproductionProbability {
                let angle = Double.random(in: 0...(2 * .pi))
                let offsetX = cos(angle) * configuration.spawnDistance
                let offsetY = sin(angle) * configuration.spawnDistance
                let childPosition = CGPoint(
                    x: organism.position.x + CGFloat(offsetX),
                    y: organism.position.y + CGFloat(offsetY)
                )

                // Clamp to scene bounds
                // Clamp to playable bounds
                let clampedPosition = CGPoint(
                    x: max(playableMinX, min(playableMaxX, childPosition.x)),
                    y: max(playableMinY, min(playableMaxY, childPosition.y))
                )

                var child = organism.reproduce(at: clampedPosition)

                // Check for speciation - if child diverged enough, it founds a new species
                if detectSpeciation(parent: organism, child: child) {
                    // Child becomes founder of new species
                    child.speciesId = child.id
                    registerSpecies(for: child, foundedOnDay: currentDay)
                } else {
                    // Child inherits parent's species
                    registerSpecies(for: child, foundedOnDay: currentDay)
                }

                // Show dramatic reproduction with buildup -> POP -> split
                showDramaticReproduction(parent: organism, child: child, childPosition: clampedPosition)

                births += 1
            }
        }

        // Handle deaths (organisms that didn't eat, starved, or died of old age)
        let survivors = organisms.filter { organism in
            if organism.isDead || !organism.hasFoodToday {
                deaths += 1
                corpsePositions.append(organism.position)  // Store corpse position

                // Different death animations based on cause
                if organism.isStarving {
                    // Starvation death - fade out slowly
                    removeOrganism(organism, animated: true)
                } else if organism.age >= organism.maxAge {
                    // Old age death - peaceful fade
                    removeOrganism(organism, animated: true)
                } else {
                    // Starvation (didn't eat)
                    removeOrganism(organism, animated: true)
                }
                return false
            } else {
                return true
            }
        }

        organisms = survivors

        // Update statistics
        statistics.births = births
        statistics.deaths = deaths
        updateStatistics()

        print("DEBUG: Day ended - Births: \(births), Deaths: \(deaths), Survivors: \(survivors.count)")
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

        // Sense range indicator is now only shown for selected organism
        // (created in selectOrganism method)

        // Create organism visual node (size-based radius)
        let node = SKShapeNode(circleOfRadius: CGFloat(organism.effectiveRadius))
        let speciesColor = getSpeciesColor(for: organism)
        node.fillColor = speciesColor
        node.strokeColor = .clear
        node.position = organism.position
        node.zPosition = 10

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

        // Create energy bar above organism
        let barWidth: CGFloat = 20
        let barHeight: CGFloat = 3
        let barOffsetY: CGFloat = CGFloat(organism.effectiveRadius) + 5

        // Background (gray bar)
        let barBackground = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        barBackground.fillColor = SKColor(white: 0.3, alpha: 0.8)
        barBackground.strokeColor = .clear
        barBackground.position = CGPoint(x: organism.position.x, y: organism.position.y + barOffsetY)
        barBackground.zPosition = 11
        addChild(barBackground)

        // Foreground (colored bar showing current energy)
        let energyRatio = organism.energy / configuration.maxEnergy
        let currentBarWidth = barWidth * CGFloat(energyRatio)
        let energyBar = SKShapeNode(rectOf: CGSize(width: currentBarWidth, height: barHeight))
        let energyColor = getEnergyColor(ratio: energyRatio)
        energyBar.fillColor = energyColor
        energyBar.strokeColor = .clear
        energyBar.position = CGPoint(x: organism.position.x, y: organism.position.y + barOffsetY)
        energyBar.zPosition = 12
        addChild(energyBar)

        energyBarNodes[organism.id] = (background: barBackground, bar: energyBar)
    }

    private func getEnergyColor(ratio: Double) -> SKColor {
        if ratio < 0.3 {
            return SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.9)  // Red
        } else if ratio < 0.6 {
            return SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)  // Orange
        } else {
            return SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.9)  // Green
        }
    }

    private func removeOrganism(_ organism: Organism, animated: Bool = false) {
        // Deselect if this organism is selected
        if selectedOrganismId == organism.id {
            deselectOrganism()
            selectedOrganismPublisher.send(nil)
        }

        // Remove sense range indicator
        if let senseNode = senseRangeNodes[organism.id] {
            senseNode.removeFromParent()
            senseRangeNodes.removeValue(forKey: organism.id)
        }

        // Remove energy bar
        if let energyBar = energyBarNodes[organism.id] {
            energyBar.background.removeFromParent()
            energyBar.bar.removeFromParent()
            energyBarNodes.removeValue(forKey: organism.id)
        }

        // Remove all trail segments
        if let trails = trailNodes[organism.id] {
            for trail in trails {
                trail.removeFromParent()
            }
            trailNodes.removeValue(forKey: organism.id)
        }

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

    // MARK: - Obstacle Management
    func addObstacle(_ obstacle: Obstacle) {
        obstacles.append(obstacle)

        let node: SKShapeNode
        switch obstacle.type {
        case .wall:
            node = SKShapeNode(rectOf: obstacle.size, cornerRadius: 5)
            node.fillColor = SKColor(white: 0.3, alpha: 0.9)
            node.strokeColor = SKColor(white: 0.5, alpha: 1.0)
            node.lineWidth = 2

        case .rock:
            node = SKShapeNode(circleOfRadius: obstacle.radius)
            node.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 0.9)
            node.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1.0)
            node.lineWidth = 2

        case .hazard:
            node = SKShapeNode(circleOfRadius: obstacle.radius)
            node.fillColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.4)
            node.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.8)
            node.lineWidth = 2
            node.glowWidth = 10

            // Add pulsing animation for hazards
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.8)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            let forever = SKAction.repeatForever(pulse)
            node.run(forever, withKey: "hazardPulse")
        }

        node.position = obstacle.position
        node.zRotation = obstacle.rotation
        node.zPosition = 3
        obstacleNodes[obstacle.id] = node
        addChild(node)
    }

    func removeObstacle(_ obstacle: Obstacle) {
        if let node = obstacleNodes[obstacle.id] {
            node.removeFromParent()
            obstacleNodes.removeValue(forKey: obstacle.id)
        }
        obstacles.removeAll { $0.id == obstacle.id }
    }

    func clearAllObstacles() {
        for node in obstacleNodes.values {
            node.removeFromParent()
        }
        obstacleNodes.removeAll()
        obstacles.removeAll()
    }

    func toggleLegend(show: Bool) {
        if show {
            showLegend()
        } else {
            childNode(withName: "legend")?.removeFromParent()
        }
    }

    func forceNextDay() {
        print("DEBUG: Force next day triggered at day \(currentDay)")
        endDay()
        currentDay += 1
        spawnFood()
        updateStatistics()
        print("DEBUG: Day transitioned to \(currentDay), population: \(organisms.count)")
    }

    // MARK: - Statistics
    private func updateStatistics() {
        statistics.currentDay = currentDay
        statistics.population = organisms.count

        // Update species populations and mark extinct species
        updateSpeciesPopulations()

        if organisms.isEmpty {
            statistics.averageSpeed = 0.0
            statistics.minSpeed = 0
            statistics.maxSpeed = 0
            statistics.averageSenseRange = 0.0
            statistics.minSenseRange = 0
            statistics.maxSenseRange = 0
            statistics.averageSize = 0.0
            statistics.minSize = 0.0
            statistics.maxSize = 0.0
            statistics.averageFertility = 0.0
            statistics.minFertility = 0.0
            statistics.maxFertility = 0.0
        } else {
            let speeds = organisms.map { $0.speed }
            statistics.averageSpeed = Double(speeds.reduce(0, +)) / Double(speeds.count)
            statistics.minSpeed = speeds.min() ?? 0
            statistics.maxSpeed = speeds.max() ?? 0

            let senseRanges = organisms.map { $0.senseRange }
            statistics.averageSenseRange = Double(senseRanges.reduce(0, +)) / Double(senseRanges.count)
            statistics.minSenseRange = senseRanges.min() ?? 0
            statistics.maxSenseRange = senseRanges.max() ?? 0

            let sizes = organisms.map { $0.size }
            statistics.averageSize = sizes.reduce(0.0, +) / Double(sizes.count)
            statistics.minSize = sizes.min() ?? 0.0
            statistics.maxSize = sizes.max() ?? 0.0

            let fertilities = organisms.map { $0.fertility }
            statistics.averageFertility = fertilities.reduce(0.0, +) / Double(fertilities.count)
            statistics.minFertility = fertilities.min() ?? 0.0
            statistics.maxFertility = fertilities.max() ?? 0.0

            let energies = organisms.map { $0.energy }
            statistics.averageEnergy = energies.reduce(0.0, +) / Double(energies.count)
            statistics.minEnergy = energies.min() ?? 0.0
            statistics.maxEnergy = energies.max() ?? 0.0

            let ages = organisms.map { $0.age }
            statistics.averageAge = Double(ages.reduce(0, +)) / Double(ages.count)
            statistics.minAge = ages.min() ?? 0
            statistics.maxAge = ages.max() ?? 0

            let efficiencies = organisms.map { $0.energyEfficiency }
            statistics.averageEnergyEfficiency = efficiencies.reduce(0.0, +) / Double(efficiencies.count)

            let maxAges = organisms.map { $0.maxAge }
            statistics.averageMaxAge = Double(maxAges.reduce(0, +)) / Double(maxAges.count)

            let aggressions = organisms.map { $0.aggression }
            statistics.averageAggression = aggressions.reduce(0.0, +) / Double(aggressions.count)

            let defenses = organisms.map { $0.defense }
            statistics.averageDefense = defenses.reduce(0.0, +) / Double(defenses.count)

            let metabolisms = organisms.map { $0.metabolism }
            statistics.averageMetabolism = metabolisms.reduce(0.0, +) / Double(metabolisms.count)

            // Update elite organism highlighting
            if showEliteHighlights {
                updateEliteOrganisms()
            }
        }

        statistics.organisms = organisms.map { organism in
            OrganismInfo(
                id: organism.id,
                speed: organism.speed,
                senseRange: organism.senseRange,
                size: organism.size,
                fertility: organism.fertility,
                energyEfficiency: organism.energyEfficiency,
                maxAge: organism.maxAge,
                aggression: organism.aggression,
                defense: organism.defense,
                metabolism: organism.metabolism,
                heatTolerance: organism.heatTolerance,
                coldTolerance: organism.coldTolerance,
                energy: organism.energy,
                age: organism.age,
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

    private func updateEliteOrganisms() {
        // Calculate fitness score for each organism
        let organismsWithFitness = organisms.map { organism -> (organism: Organism, fitness: Double) in
            let fitness = calculateFitness(for: organism)
            return (organism, fitness)
        }

        // Sort by fitness and identify top 20%
        let sorted = organismsWithFitness.sorted { $0.fitness > $1.fitness }
        let eliteCount = max(1, sorted.count / 5)  // Top 20%
        let elites = Set(sorted.prefix(eliteCount).map { $0.organism.id })

        // Update visual highlighting
        for organism in organisms {
            if let node = organismNodes[organism.id] {
                if elites.contains(organism.id) {
                    // Elite organism - add golden glow
                    node.strokeColor = .yellow
                    node.lineWidth = 2
                    node.glowWidth = 10

                    // Add subtle pulsing animation if not already present
                    if node.action(forKey: "elitePulse") == nil {
                        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
                        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
                        let pulse = SKAction.sequence([scaleUp, scaleDown])
                        let forever = SKAction.repeatForever(pulse)
                        node.run(forever, withKey: "elitePulse")
                    }
                } else {
                    // Regular organism - remove highlighting
                    if node.action(forKey: "elitePulse") != nil {
                        node.removeAction(forKey: "elitePulse")
                        node.setScale(1.0)
                    }
                    node.strokeColor = .clear
                    node.lineWidth = 0
                    node.glowWidth = 0
                }
            }
        }
    }

    private func calculateFitness(for organism: Organism) -> Double {
        // Multi-factor fitness calculation based on current environment
        var fitness = 0.0

        // Speed contribution (normalized)
        let speedRatio = Double(organism.speed - configuration.minSpeed) / Double(configuration.maxSpeed - configuration.minSpeed)

        // Sense range contribution (normalized)
        let senseRatio = Double(organism.senseRange - configuration.minSenseRange) / Double(configuration.maxSenseRange - configuration.minSenseRange)

        // Size contribution (normalized)
        let sizeRatio = (organism.size - configuration.minSize) / (configuration.maxSize - configuration.minSize)

        // Fertility contribution (normalized)
        let fertilityRatio = (organism.fertility - configuration.minFertility) / (configuration.maxFertility - configuration.minFertility)

        // Adjust weights based on current food pattern
        switch currentFoodPattern {
        case .random:
            // Balanced traits are best, fertility moderately important
            fitness = speedRatio * 0.35 + senseRatio * 0.25 + (1.0 - abs(sizeRatio - 0.5) * 2) * 0.25 + fertilityRatio * 0.15

        case .clustered:
            // Size matters most, fertility helps dominate clusters
            fitness = speedRatio * 0.15 + senseRatio * 0.25 + sizeRatio * 0.4 + fertilityRatio * 0.2

        case .scattered:
            // Speed and sense range, fertility less important when spread out
            fitness = speedRatio * 0.45 + senseRatio * 0.35 + (1.0 - sizeRatio) * 0.1 + fertilityRatio * 0.1

        case .ring:
            // Sense range is king, fertility moderately important
            fitness = speedRatio * 0.15 + senseRatio * 0.5 + (1.0 - abs(sizeRatio - 0.5) * 2) * 0.2 + fertilityRatio * 0.15
        }

        // Bonus for high generation (successful lineage)
        let generationBonus = min(0.2, Double(organism.generation) * 0.01)
        fitness += generationBonus

        // Bonus if organism has eaten today (immediate success)
        if organism.hasFoodToday {
            fitness *= 1.2
        }

        return fitness
    }

    // MARK: - Animations
    private func showDayTransition() {
        // Population health indicator
        let populationHealth = getPopulationHealth()
        let healthColor = getHealthColor(health: populationHealth)
        let healthEmoji = getHealthEmoji(health: populationHealth)

        // Create day transition label with health indicator
        let label = SKLabelNode(text: "Day \(currentDay) \(healthEmoji)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 48
        label.fontColor = healthColor
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 1000
        label.alpha = 0
        label.setScale(0.3)

        // Add population info
        let popLabel = SKLabelNode(text: "Population: \(statistics.population)")
        popLabel.fontName = "Helvetica"
        popLabel.fontSize = 20
        popLabel.fontColor = .white
        popLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        popLabel.zPosition = 1000
        popLabel.alpha = 0

        addChild(label)
        addChild(popLabel)

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
        popLabel.run(sequence)

        // Add expanding circle effect
        addDayTransitionRing(at: CGPoint(x: size.width / 2, y: size.height / 2))
    }

    private func getPopulationHealth() -> Double {
        // Calculate population health based on multiple factors
        let population = Double(statistics.population)
        let births = Double(statistics.births)
        let deaths = Double(statistics.deaths)

        // Ideal population range
        let idealMin: Double = 15
        let idealMax: Double = 40

        // Population size factor
        let popFactor: Double
        if population < idealMin {
            popFactor = population / idealMin  // 0-1 when below ideal
        } else if population > idealMax {
            popFactor = max(0.5, 1.0 - (population - idealMax) / idealMax)  // Penalty for overpopulation
        } else {
            popFactor = 1.0  // Optimal
        }

        // Birth/death ratio
        let totalChange = births + deaths
        let growthFactor = totalChange > 0 ? births / totalChange : 0.5

        // Combine factors
        return (popFactor + growthFactor) / 2.0
    }

    private func getHealthColor(health: Double) -> SKColor {
        if health > 0.7 {
            return .green
        } else if health > 0.4 {
            return .yellow
        } else {
            return .red
        }
    }

    private func getHealthEmoji(health: Double) -> String {
        if health > 0.8 {
            return "🌟"  // Thriving
        } else if health > 0.6 {
            return "✨"  // Healthy
        } else if health > 0.4 {
            return "⚠️"  // Warning
        } else {
            return "💀"  // Critical
        }
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

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        dragStartPosition = location

        // If in obstacle placement mode, check if tapping existing obstacle to drag
        if isPlacingObstacles {
            // Check if touched an existing obstacle
            for obstacle in obstacles {
                if obstacle.contains(point: location) {
                    // Start dragging existing obstacle
                    draggedObstacle = obstacle
                    isCreatingNewObstacle = false
                    createDragPreview(for: obstacle, at: location)
                    return
                }
            }

            // Not touching an obstacle - will create new one if drag continues
            isCreatingNewObstacle = true
            return
        }

        // Not in placement mode - check for organism selection
        var tappedOrganism: Organism?
        var shortestDistance: CGFloat = .infinity

        for organism in organisms {
            let dx = location.x - organism.position.x
            let dy = location.y - organism.position.y
            let distance = sqrt(dx * dx + dy * dy)

            // Check if tap is within organism's visual radius
            if distance <= CGFloat(organism.effectiveRadius) + 10 {  // Add 10 point margin
                if distance < shortestDistance {
                    shortestDistance = distance
                    tappedOrganism = organism
                }
            }
        }

        if let organism = tappedOrganism {
            // Tapped on an organism - show its stats
            print("DEBUG: Organism tapped - ID: \(String(organism.id.uuidString.prefix(8)))")
            if selectedOrganismId == organism.id {
                // Tapped same organism - deselect
                print("DEBUG: Deselecting organism")
                deselectOrganism()
                selectedOrganismPublisher.send(nil)
            } else {
                // Select new organism
                print("DEBUG: Selecting organism and sending to publisher")
                selectOrganism(organism)
                selectedOrganismPublisher.send(organism)
            }
        } else {
            // Tapped on empty space - deselect organism
            print("DEBUG: Tapped empty space - deselecting")
            deselectOrganism()
            selectedOrganismPublisher.send(nil)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Only handle dragging in obstacle placement mode
        guard isPlacingObstacles else { return }

        // If dragging existing obstacle
        if let obstacle = draggedObstacle {
            obstacle.position = location
            dragPreview?.position = location
            // Update the visual node
            if let node = obstacleNodes[obstacle.id] {
                node.position = location
            }
        }
        // If creating new obstacle and drag distance is significant
        else if isCreatingNewObstacle, let startPos = dragStartPosition {
            let dx = location.x - startPos.x
            let dy = location.y - startPos.y
            let distance = sqrt(dx * dx + dy * dy)

            // Start showing preview if dragged more than 20 points
            if distance > 20 && dragPreview == nil {
                // Determine wall orientation based on drag direction
                let orientation: WallOrientation = abs(dx) > abs(dy) ? .horizontal : .vertical

                let obstacle: Obstacle
                switch currentObstacleType {
                case .wall:
                    let size = orientation == .horizontal ?
                        CGSize(width: 100, height: 20) :
                        CGSize(width: 20, height: 100)
                    obstacle = Obstacle(position: location, size: size, type: .wall, wallOrientation: orientation)
                case .rock:
                    obstacle = Obstacle(position: location, radius: 30, type: .rock)
                case .hazard:
                    obstacle = Obstacle(position: location, radius: 35, type: .hazard)
                }
                draggedObstacle = obstacle
                createDragPreview(for: obstacle, at: location)
            } else if let preview = dragPreview {
                // Update preview position
                preview.position = location
                draggedObstacle?.position = location
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Remove preview
        dragPreview?.removeFromParent()
        dragPreview = nil

        // If we were dragging/creating an obstacle
        if isPlacingObstacles, let obstacle = draggedObstacle {
            // Add the obstacle if it's new, or update existing one
            if isCreatingNewObstacle {
                addObstacle(obstacle)
            } else {
                // Update the existing obstacle's visual
                if let node = obstacleNodes[obstacle.id] {
                    node.position = obstacle.position
                }
            }
        }

        // Reset drag state
        draggedObstacle = nil
        dragStartPosition = nil
        isCreatingNewObstacle = false
    }

    private func createDragPreview(for obstacle: Obstacle, at position: CGPoint) {
        // Remove old preview
        dragPreview?.removeFromParent()

        let preview: SKShapeNode
        switch obstacle.type {
        case .wall:
            preview = SKShapeNode(rectOf: obstacle.size, cornerRadius: 2)
            preview.fillColor = SKColor.gray.withAlphaComponent(0.5)
            preview.strokeColor = .white
            preview.lineWidth = 2
        case .rock:
            preview = SKShapeNode(circleOfRadius: obstacle.radius)
            preview.fillColor = SKColor.brown.withAlphaComponent(0.5)
            preview.strokeColor = .white
            preview.lineWidth = 2
        case .hazard:
            preview = SKShapeNode(circleOfRadius: obstacle.radius)
            preview.fillColor = SKColor.red.withAlphaComponent(0.5)
            preview.strokeColor = .white
            preview.lineWidth = 2
        }

        preview.position = position
        preview.zPosition = 50
        preview.glowWidth = 3
        dragPreview = preview
        addChild(preview)
    }

    private func selectOrganism(_ organism: Organism) {
        // Remove old selection visuals first
        deselectOrganism()

        selectedOrganismId = organism.id

        // Create selection indicator (pulsing ring around selected organism)
        let indicator = SKShapeNode(circleOfRadius: CGFloat(organism.effectiveRadius) + 5)
        indicator.strokeColor = .white
        indicator.lineWidth = 3
        indicator.fillColor = .clear
        indicator.position = organism.position
        indicator.zPosition = 15
        indicator.glowWidth = 5

        // Add pulsing animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        let forever = SKAction.repeatForever(pulse)
        indicator.run(forever, withKey: "selectionPulse")

        selectionIndicator = indicator
        addChild(indicator)

        // Create sense range indicator for selected organism
        let effectiveSenseRange = getEffectiveSenseRange(for: organism)
        let senseRangeNode = SKShapeNode(circleOfRadius: CGFloat(effectiveSenseRange))
        senseRangeNode.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.5)
        senseRangeNode.lineWidth = 2
        senseRangeNode.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.1)
        senseRangeNode.position = organism.position
        senseRangeNode.zPosition = 1
        senseRangeNodes[organism.id] = senseRangeNode
        addChild(senseRangeNode)
    }

    private func deselectOrganism() {
        // Remove sense range indicator for previously selected organism
        if let prevSelectedId = selectedOrganismId {
            if let senseNode = senseRangeNodes[prevSelectedId] {
                senseNode.removeFromParent()
                senseRangeNodes.removeValue(forKey: prevSelectedId)
            }
        }

        selectedOrganismId = nil

        // Remove selection indicator
        selectionIndicator?.removeFromParent()
        selectionIndicator = nil
    }
}

// MARK: - Supporting Types
enum Season: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"

    var emoji: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .fall: return "🍂"
        case .winter: return "❄️"
        }
    }

    var color: SKColor {
        switch self {
        case .spring: return SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        case .summer: return SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        case .fall: return SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        case .winter: return SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
        }
    }

    func next() -> Season {
        let allSeasons = Season.allCases
        guard let currentIndex = allSeasons.firstIndex(of: self) else { return .spring }
        let nextIndex = (currentIndex + 1) % allSeasons.count
        return allSeasons[nextIndex]
    }
}

struct GameStatistics {
    var currentDay: Int = 0
    var population: Int = 0
    var averageSpeed: Double = 0.0
    var minSpeed: Int = 0
    var maxSpeed: Int = 0
    var averageSenseRange: Double = 0.0
    var minSenseRange: Int = 0
    var maxSenseRange: Int = 0
    var averageSize: Double = 0.0
    var minSize: Double = 0.0
    var maxSize: Double = 0.0
    var averageFertility: Double = 0.0
    var minFertility: Double = 0.0
    var maxFertility: Double = 0.0
    var averageEnergy: Double = 0.0
    var minEnergy: Double = 0.0
    var maxEnergy: Double = 0.0
    var averageAge: Double = 0.0
    var minAge: Int = 0
    var maxAge: Int = 0
    var averageEnergyEfficiency: Double = 0.0
    var averageMaxAge: Double = 0.0
    var averageAggression: Double = 0.0
    var averageDefense: Double = 0.0
    var averageMetabolism: Double = 0.0
    var births: Int = 0
    var deaths: Int = 0
    var organisms: [OrganismInfo] = []
    var dailySnapshots: [DailySnapshot] = []
}

struct OrganismInfo: Identifiable {
    let id: UUID
    let speed: Int
    let senseRange: Int
    let size: Double
    let fertility: Double
    let energyEfficiency: Double
    let maxAge: Int
    let aggression: Double
    let defense: Double
    let metabolism: Double
    let heatTolerance: Double
    let coldTolerance: Double
    let energy: Double
    let age: Int
    let generation: Int
    let hasFoodToday: Bool
}
