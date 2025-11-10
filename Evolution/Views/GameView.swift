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
        // Capture safe area insets BEFORE ignoring them
        GeometryReader { outerGeometry in
            GeometryReader { geometry in
                ZStack {
                    if geometry.size.width > geometry.size.height {
                        // Landscape - side by side
                        HStack(spacing: 0) {
                            SpriteView(scene: viewModel.scene)
                                .ignoresSafeArea()
                                .frame(width: showStats ? geometry.size.width * 0.6 : geometry.size.width)

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
                                .ignoresSafeArea()
                                .frame(height: showStats ? geometry.size.height * 0.5 : geometry.size.height)

                            if showStats {
                                StatisticsPanel(viewModel: viewModel)
                                    .frame(height: geometry.size.height * 0.5)
                                    .background(Color(white: 0.1))
                                    .transition(.move(edge: .bottom))
                            }
                        }
                    }

                    // Overlay controls on top with explicit safe area padding
                    VStack(spacing: 0) {
                        // Spacer to keep controls visible below notch/safe area
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: max(60, outerGeometry.safeAreaInsets.top + 16))

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
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.3), value: showStats)
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
        scene = GameScene(size: CGSize(width: 600, height: 800), configuration: configuration)
        scene.scaleMode = .aspectFill

        // Subscribe to statistics updates
        scene.statisticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatistics in
                self?.statistics = newStatistics
            }
            .store(in: &cancellables)
    }
}
