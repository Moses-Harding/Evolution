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
    @StateObject private var viewModel = GameViewModel()
    @State private var showStats = true

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    // Landscape - side by side
                    HStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            SpriteView(scene: viewModel.scene)
                                .ignoresSafeArea()

                            GameControls(
                                isSuperSpeed: $viewModel.isSuperSpeed,
                                showStats: $showStats
                            )
                            .padding()
                        }
                        .frame(width: showStats ? geometry.size.width * 0.6 : geometry.size.width)

                        if showStats {
                            StatisticsPanel(statistics: viewModel.statistics)
                                .frame(width: geometry.size.width * 0.4)
                                .background(Color(white: 0.1))
                                .transition(.move(edge: .trailing))
                        }
                    }
                } else {
                    // Portrait - stacked
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            SpriteView(scene: viewModel.scene)
                                .ignoresSafeArea()

                            GameControls(
                                isSuperSpeed: $viewModel.isSuperSpeed,
                                showStats: $showStats
                            )
                            .padding()
                        }
                        .frame(height: showStats ? geometry.size.height * 0.5 : geometry.size.height)

                        if showStats {
                            StatisticsPanel(statistics: viewModel.statistics)
                                .frame(height: geometry.size.height * 0.5)
                                .background(Color(white: 0.1))
                                .transition(.move(edge: .bottom))
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showStats)
    }
}

struct GameControls: View {
    @Binding var isSuperSpeed: Bool
    @Binding var showStats: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Super speed toggle
                Button(action: {
                    isSuperSpeed.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isSuperSpeed ? "hare.fill" : "tortoise.fill")
                        Text(isSuperSpeed ? "2x" : "1x")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isSuperSpeed ? Color.orange : Color.blue)
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

    private var cancellables = Set<AnyCancellable>()

    init() {
        scene = GameScene(size: CGSize(width: 600, height: 800))
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
