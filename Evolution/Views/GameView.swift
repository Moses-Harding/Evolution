//
//  GameView.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SwiftUI
import SpriteKit
import Combine

struct GameView: View {
    @State private var viewModel: GameViewModel?
    @State private var showStats = false  // Charts hidden by default
    @State private var showConfiguration = true
    @State private var sceneSize: CGSize = .zero
    @State private var showLegend = false  // Legend hidden by default
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if showConfiguration {
            ConfigurationView { config in
                viewModel = GameViewModel(configuration: config)
                showConfiguration = false
            }
        } else if let viewModel = viewModel {
            gameContent(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func gameContent(viewModel: GameViewModel) -> some View {
        ZStack {
            // Black background extends to edges
            Color.black
                .ignoresSafeArea()

            // Game content respects safe areas
            GeometryReader { geometry in
                let safeAreaInsets = geometry.safeAreaInsets
                let isLandscape = geometry.size.width > geometry.size.height

                // Calculate game size based on available space (not including safe areas)
                let gameWidth = isLandscape ? (showStats ? geometry.size.width * 0.6 : geometry.size.width) : geometry.size.width
                let gameHeight = isLandscape ? geometry.size.height : (showStats ? geometry.size.height * 0.5 : geometry.size.height)
                let gameSize = CGSize(width: gameWidth, height: gameHeight)

                ZStack {
                    if isLandscape {
                        // Landscape - side by side
                        HStack(spacing: 0) {
                            SpriteView(scene: viewModel.scene)
                                .frame(width: gameWidth, height: gameHeight)
                                .background(Color.black)
                                .allowsHitTesting(true)
                                .onAppear {
                                    updateSceneSize(viewModel: viewModel, size: gameSize, safeAreaInsets: safeAreaInsets)
                                }
                                .onChange(of: gameSize) { oldSize, newSize in
                                    updateSceneSize(viewModel: viewModel, size: newSize, safeAreaInsets: safeAreaInsets)
                                }
                                .onChange(of: safeAreaInsets) { oldInsets, newInsets in
                                    updateSceneSize(viewModel: viewModel, size: gameSize, safeAreaInsets: newInsets)
                                }

                            if showStats {
                                StatisticsPanel(viewModel: viewModel)
                                    .frame(width: geometry.size.width * 0.4)
                                    .background(Color(white: 0.1))
                                    .transition(.move(edge: .trailing))
                            }
                        }
                    } else {
                        // Portrait - stacked
                        VStack(spacing: 0) {
                            SpriteView(scene: viewModel.scene)
                                .frame(width: gameWidth, height: gameHeight)
                                .background(Color.black)
                                .allowsHitTesting(true)
                                .onAppear {
                                    updateSceneSize(viewModel: viewModel, size: gameSize, safeAreaInsets: safeAreaInsets)
                                }
                                .onChange(of: gameSize) { oldSize, newSize in
                                    updateSceneSize(viewModel: viewModel, size: newSize, safeAreaInsets: safeAreaInsets)
                                }
                                .onChange(of: safeAreaInsets) { oldInsets, newInsets in
                                    updateSceneSize(viewModel: viewModel, size: gameSize, safeAreaInsets: newInsets)
                                }

                            if showStats {
                                StatisticsPanel(viewModel: viewModel)
                                    .frame(height: geometry.size.height * 0.5)
                                    .background(Color(white: 0.1))
                                    .transition(.move(edge: .bottom))
                            }
                        }
                    }

                    // Overlay controls on top
                    VStack {
                        HStack {
                            GameControls(
                                viewModel: viewModel,
                                showStats: $showStats,
                                showLegend: $showLegend
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            Spacer()
                        }

                        Spacer()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showStats)
        .overlay(
            // Organism stats modal
            Group {
                if let organism = viewModel.selectedOrganism {
                    OrganismStatsModal(
                        organism: organism,
                        species: viewModel.statistics.activeSpecies.first(where: { $0.id == organism.speciesId }),
                        populationStats: viewModel.statistics,
                        isPresented: Binding(
                            get: { viewModel.selectedOrganism != nil },
                            set: { if !$0 { viewModel.selectedOrganism = nil } }
                        )
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOrganism != nil)
                }
            }
        )
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                // Keep simulation running in background
                viewModel.scene.isPaused = false
                print("App moved to background - simulation continues")
            case .inactive:
                // Don't pause during transitions
                break
            case .active:
                // Ensure simulation is running when active
                viewModel.scene.isPaused = false
                print("App moved to foreground")
            @unknown default:
                break
            }
        }
    }

    private func updateSceneSize(viewModel: GameViewModel, size: CGSize, safeAreaInsets: EdgeInsets) {
        // Update the scene size to match the view
        viewModel.scene.size = size
        // Convert SwiftUI EdgeInsets to UIKit UIEdgeInsets for SpriteKit
        let uiInsets = UIEdgeInsets(
            top: safeAreaInsets.top,
            left: safeAreaInsets.leading,
            bottom: safeAreaInsets.bottom,
            right: safeAreaInsets.trailing
        )
        // Notify the scene that it needs to update positions with safe area info
        viewModel.scene.updateLayoutForNewSize(size, safeAreaInsets: uiInsets)
    }
}

struct OrganismStatsModal: View {
    let organism: Organism
    let species: SpeciesInfo?
    let populationStats: GameStatistics
    @Binding var isPresented: Bool

    private var agePercentage: Double {
        return Double(organism.age) / Double(organism.effectiveMaxAge)
    }

    private var energyPercentage: Double {
        return organism.energy / 100.0
    }

    var body: some View {
        ZStack {
            // Background blur/dimming
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Modal content
            VStack(spacing: 12) {
                // Header with species info
                HStack(spacing: 12) {
                    // Species color indicator
                    if let species = species {
                        Circle()
                            .fill(Color(red: species.color.red, green: species.color.green, blue: species.color.blue))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(species?.name ?? "Unknown Species")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("ID: \(String(organism.id.uuidString.prefix(8)))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }

                Divider()

                // Scrollable Stats
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Quick Overview
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Generation")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(organism.generation)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cyan)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Age")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack(spacing: 4) {
                                    Text("\(organism.age)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(agePercentage > 0.75 ? .orange : agePercentage > 0.9 ? .red : .green)
                                    Text("/ \(organism.effectiveMaxAge)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            // Energy circle gauge
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                    .frame(width: 60, height: 60)

                                Circle()
                                    .trim(from: 0, to: energyPercentage)
                                    .stroke(
                                        energyPercentage < 0.3 ? Color.red :
                                        energyPercentage < 0.6 ? Color.orange : Color.green,
                                        lineWidth: 6
                                    )
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 0) {
                                    Text("\(Int(organism.energy))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text("energy")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Divider()

                        // Status Badges
                        HStack(spacing: 8) {
                            StatusBadge(
                                icon: organism.hasFoodToday ? "checkmark.circle.fill" : "xmark.circle.fill",
                                label: organism.hasFoodToday ? "Fed" : "Hungry",
                                color: organism.hasFoodToday ? .green : .red
                            )

                            if organism.energy < 30 {
                                StatusBadge(icon: "bolt.fill", label: "Low Energy", color: .orange)
                            }

                            if agePercentage > 0.75 {
                                StatusBadge(icon: "hourglass.fill", label: "Elderly", color: .orange)
                            }
                        }

                        Divider()

                        // Movement Traits
                        TraitSection(title: "Movement", icon: "figure.run", color: .cyan) {
                            TraitBar(
                                label: "Speed",
                                value: Double(organism.speed),
                                maxValue: Double(organism.configuration.maxSpeed),
                                average: populationStats.averageSpeed,
                                color: .cyan
                            )

                            HStack {
                                Text("Effective Speed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(format: "%.1f", organism.effectiveSpeed))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.cyan)
                            }

                            TraitBar(
                                label: "Sense Range",
                                value: Double(organism.senseRange),
                                maxValue: Double(organism.configuration.maxSenseRange),
                                average: populationStats.averageSenseRange,
                                color: .purple
                            )
                        }

                        // Combat Traits
                        TraitSection(title: "Combat", icon: "shield.lefthalf.filled", color: .red) {
                            TraitBar(
                                label: "Aggression",
                                value: organism.aggression,
                                maxValue: 1.0,
                                average: populationStats.averageAggression,
                                color: .red,
                                isPercentage: true
                            )

                            TraitBar(
                                label: "Defense",
                                value: organism.defense,
                                maxValue: 1.0,
                                average: populationStats.averageDefense,
                                color: .blue,
                                isPercentage: true
                            )

                            if organism.configuration.pleiotropyEnabled {
                                HStack {
                                    Text("Effective Defense")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(String(format: "%.0f%%", organism.effectiveDefense * 100))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        // Physical Traits
                        TraitSection(title: "Physical", icon: "scalemass", color: .purple) {
                            TraitBar(
                                label: "Size",
                                value: organism.size,
                                maxValue: organism.configuration.maxSize,
                                average: populationStats.averageSize,
                                color: .purple
                            )

                            TraitBar(
                                label: "Fertility",
                                value: organism.fertility,
                                maxValue: organism.configuration.maxFertility,
                                average: populationStats.averageFertility,
                                color: .pink
                            )
                        }

                        // Energy & Metabolism
                        TraitSection(title: "Energy", icon: "bolt.fill", color: .yellow) {
                            TraitBar(
                                label: "Energy Efficiency",
                                value: organism.energyEfficiency,
                                maxValue: organism.configuration.maxEnergyEfficiency,
                                average: populationStats.averageEnergyEfficiency,
                                color: .green
                            )

                            TraitBar(
                                label: "Metabolism",
                                value: organism.metabolism,
                                maxValue: organism.configuration.maxMetabolism,
                                average: populationStats.averageMetabolism,
                                color: .orange
                            )
                        }

                        // Environmental Tolerance
                        TraitSection(title: "Environment", icon: "thermometer.sun.fill", color: .orange) {
                            TraitBar(
                                label: "Heat Tolerance",
                                value: organism.heatTolerance,
                                maxValue: 1.0,
                                average: 0.5,
                                color: .red,
                                isPercentage: true
                            )

                            TraitBar(
                                label: "Cold Tolerance",
                                value: organism.coldTolerance,
                                maxValue: 1.0,
                                average: 0.5,
                                color: .cyan,
                                isPercentage: true
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .frame(maxWidth: 420, maxHeight: 650)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 30)
            .shadow(radius: 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Supporting Views

struct TraitSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            content
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}

struct TraitBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let average: Double
    let color: Color
    var isPercentage: Bool = false

    private var normalizedValue: Double {
        return min(1.0, max(0.0, value / maxValue))
    }

    private var normalizedAverage: Double {
        return min(1.0, max(0.0, average / maxValue))
    }

    private var comparisonIcon: String {
        if value > average * 1.1 {
            return "↑"
        } else if value < average * 0.9 {
            return "↓"
        } else {
            return "≈"
        }
    }

    private var comparisonColor: Color {
        if value > average * 1.1 {
            return .green
        } else if value < average * 0.9 {
            return .red
        } else {
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text(comparisonIcon)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(comparisonColor)

                if isPercentage {
                    Text(String(format: "%.0f%%", value * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                } else {
                    Text(String(format: "%.1f", value))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Average marker
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * normalizedAverage - 1, y: -2)
                }
                .frame(height: 8)

                // Value bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(4, CGFloat(normalizedValue) * 200), height: 8)
            }
            .frame(maxWidth: 200)
        }
    }
}

struct StatusBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

struct GameControls: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showStats: Bool
    @Binding var showLegend: Bool
    @State private var showHeatmap: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Pause/Resume toggle
                Button(action: {
                    viewModel.isPaused.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.isPaused ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Super speed toggle
                Button(action: {
                    viewModel.isSuperSpeed.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isSuperSpeed ? "hare.fill" : "tortoise.fill")
                        Text(viewModel.isSuperSpeed ? "2x" : "1x")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.isSuperSpeed ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Stats toggle
                Button(action: {
                    showStats.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showStats ? "chart.bar.fill" : "chart.bar")
                        Text(showStats ? "Hide" : "Show")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Legend toggle
                Button(action: {
                    showLegend.toggle()
                    viewModel.toggleLegend(show: showLegend)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                        Text("Key")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showLegend ? Color.cyan : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Force next day button
                Button(action: {
                    viewModel.forceNextDay()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                        Text("Next Day")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Heatmap toggle
                Button(action: {
                    showHeatmap.toggle()
                    viewModel.toggleHeatmap(show: showHeatmap)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showHeatmap ? "heat.waves" : "squareshape.split.3x3")
                        Text("Heat")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showHeatmap ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            // Obstacle controls
            HStack(spacing: 12) {
                // Obstacle placement toggle
                Button(action: {
                    viewModel.isPlacingObstacles.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlacingObstacles ? "cube.fill" : "cube")
                        Text(viewModel.isPlacingObstacles ? "Place" : "Select")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.isPlacingObstacles ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Obstacle type picker (only show when placing)
                if viewModel.isPlacingObstacles {
                    Menu {
                        Button(action: { viewModel.obstacleType = .wall }) {
                            Label("Wall", systemImage: "rectangle.fill")
                        }
                        Button(action: { viewModel.obstacleType = .rock }) {
                            Label("Rock", systemImage: "circle.fill")
                        }
                        Button(action: { viewModel.obstacleType = .hazard }) {
                            Label("Hazard", systemImage: "exclamationmark.triangle.fill")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.obstacleType == .wall ? "rectangle.fill" : viewModel.obstacleType == .rock ? "circle.fill" : "exclamationmark.triangle.fill")
                            Text(viewModel.obstacleTypeLabel)
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    // Clear obstacles button
                    Button(action: {
                        viewModel.clearObstacles()
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

class GameViewModel: ObservableObject {
    @Published var statistics: GameStatistics = GameStatistics()
    @Published var selectedOrganism: Organism?
    @Published var isSuperSpeed: Bool = false {
        didSet {
            scene.timeScale = isSuperSpeed ? 2.0 : 1.0
        }
    }
    @Published var isPlacingObstacles: Bool = false {
        didSet {
            scene.isPlacingObstacles = isPlacingObstacles
        }
    }
    @Published var obstacleType: ObstacleType = .wall {
        didSet {
            scene.currentObstacleType = obstacleType
        }
    }
    @Published var isPaused: Bool = false {
        didSet {
            scene.isPaused = isPaused
        }
    }

    var obstacleTypeLabel: String {
        switch obstacleType {
        case .wall: return "Wall"
        case .rock: return "Rock"
        case .hazard: return "Hazard"
        }
    }

    let scene: GameScene
    let configuration: GameConfiguration

    private var cancellables = Set<AnyCancellable>()

    func clearObstacles() {
        scene.clearAllObstacles()
    }

    func toggleLegend(show: Bool) {
        scene.toggleLegend(show: show)
    }

    func forceNextDay() {
        scene.forceNextDay()
    }

    func toggleHeatmap(show: Bool) {
        scene.toggleHeatmap(show: show)
    }

    init(configuration: GameConfiguration = .default) {
        self.configuration = configuration
        // Start with a reasonable default size, will be updated when view appears
        scene = GameScene(size: CGSize(width: 400, height: 600), configuration: configuration)
        // Use fill to maintain proper scaling
        scene.scaleMode = .fill

        // Subscribe to statistics updates
        scene.statisticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatistics in
                self?.statistics = newStatistics
            }
            .store(in: &cancellables)

        // Subscribe to selected organism updates
        scene.selectedOrganismPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] organism in
                if let organism = organism {
                    print("DEBUG: GameViewModel received organism - ID: \(String(organism.id.uuidString.prefix(8)))")
                } else {
                    print("DEBUG: GameViewModel received nil organism")
                }
                self?.selectedOrganism = organism
            }
            .store(in: &cancellables)
    }
}
