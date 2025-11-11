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
    @State private var showStats = true
    @State private var showConfiguration = true
    @State private var sceneSize: CGSize = .zero
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
                                showStats: $showStats
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
                        isPresented: Binding(
                            get: { viewModel.selectedOrganism != nil },
                            set: { if !$0 { viewModel.selectedOrganism = nil } }
                        )
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOrganism != nil)
                    .onAppear {
                        print("🟡 GameView: OrganismStatsModal appeared for organism \(organism.id)")
                    }
                    .onDisappear {
                        print("🟡 GameView: OrganismStatsModal disappeared")
                    }
                } else {
                    Color.clear.onAppear {
                        print("🟡 GameView: Modal overlay is showing Color.clear (no organism selected)")
                    }
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
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background blur/dimming
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Modal content
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Organism Stats")
                        .font(.title2)
                        .fontWeight(.bold)

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

                // Stats Grid
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(label: "ID", value: String(organism.id.uuidString.prefix(8)))
                    StatRow(label: "Generation", value: "\(organism.generation)")
                    StatRow(label: "Speed", value: "\(organism.speed)")
                    StatRow(label: "Effective Speed", value: String(format: "%.1f", organism.effectiveSpeed))
                    StatRow(label: "Sense Range", value: "\(organism.senseRange)")
                    StatRow(label: "Size", value: String(format: "%.2f", organism.size))
                    StatRow(label: "Fertility", value: String(format: "%.1f%%", organism.fertility * 100))
                    StatRow(label: "Has Food Today", value: organism.hasFoodToday ? "Yes ✓" : "No ✗")
                        .foregroundColor(organism.hasFoodToday ? .green : .red)

                    if let targetFood = organism.targetFood {
                        StatRow(label: "Target Food", value: targetFood.isClaimed ? "Claimed" : "Available")
                    } else {
                        StatRow(label: "Target Food", value: "None")
                    }

                    // Visual indicator of organism color
                    HStack {
                        Text("Color")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)

                        Spacer()

                        Circle()
                            .fill(Color(
                                red: Double(organism.color.red),
                                green: Double(organism.color.green),
                                blue: Double(organism.color.blue)
                            ))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
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

    let scene: GameScene
    let configuration: GameConfiguration

    private var cancellables = Set<AnyCancellable>()

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
                    print("🔵 GameViewModel: Received organism \(organism.id), setting selectedOrganism")
                } else {
                    print("🔵 GameViewModel: Received nil, clearing selectedOrganism")
                }
                self?.selectedOrganism = organism
                print("🔵 GameViewModel: selectedOrganism is now \(self?.selectedOrganism?.id?.uuidString ?? "nil")")
            }
            .store(in: &cancellables)
    }
}
