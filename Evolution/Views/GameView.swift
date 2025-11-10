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

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape - side by side
                HStack(spacing: 0) {
                    SpriteView(scene: viewModel.scene)
                        .frame(width: geometry.size.width * 0.7)
                        .ignoresSafeArea()

                    StatisticsPanel(statistics: viewModel.statistics)
                        .frame(width: geometry.size.width * 0.3)
                        .background(Color(white: 0.1))
                }
            } else {
                // Portrait - stacked
                VStack(spacing: 0) {
                    SpriteView(scene: viewModel.scene)
                        .frame(height: geometry.size.height * 0.7)
                        .ignoresSafeArea()

                    StatisticsPanel(statistics: viewModel.statistics)
                        .frame(height: geometry.size.height * 0.3)
                        .background(Color(white: 0.1))
                }
            }
        }
    }
}

class GameViewModel: ObservableObject {
    @Published var statistics: GameStatistics = GameStatistics()

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
